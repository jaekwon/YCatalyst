require.paths.unshift 'vendor'
Nubnub = require 'nubnub/src'
xml2js = require 'xml2js/lib'
mongo = require '../mongo'
parser = new xml2js.Parser()
jsdom = require 'jsdom'
utils = require '../utils'
config = require '../config'

# initialize a dom window we'll use for html management
window = jsdom.jsdom().createWindow()
jsdom.jQueryify window, "static/jquery-1.4.2.min.js", () ->
  console.log "JSDOM window is ready"

# initialize the parser to do the right thing upon parser.parseString.
parser.addListener 'end', (result) ->
  items = process_items(result)

  # let's see which items already exist
  mongo.diffbot.find {guid: {$in: (item.guid for item in items)}}, (err, cursor) ->
    cursor.toArray (err, existing) ->
      # existing is a bunch of existing items
      existing_guids = (item.guid for item in existing)
      # reject all item in 'items' that have guid in existing_guids
      new_items = (item for item in items when existing_guids.indexOf(item.guid) == -1)

      if new_items.length > 0
        # save 
        # TODO bulk inserts? really not supported?! 
        for item in new_items
          mongo.diffbot.save item, (err, stuff) ->
            if err
              console.log "Error in saving diffbot entry: #{link}/#{item.link}. Ignoring"
            # pass
        console.log ("new diffbot item #{item.guid}" for item in new_items).join("\n")

# utility function...
# see whether response is RSS or Atom.
# RSS comes from google appspot hub,
# ATOM comes from superfeedr.com
process_items = (result) ->
  type = if result.channel then 'rss' else 'atom'
  if type == 'atom'
    link = result.link['@']['href']
    if link.indexOf("http://www.diffbot.com/api/rss/") == -1
      console.log "Warning, expected atom>link[@][href] to be a diffbot RSS feed but got #{link}"
    else
      link = link.replace("http://www.diffbot.com/api/rss/", "")
    items = result.entry
  else
    link = result.channel.link
    items = result.channel.item
  itens = [items] if not items instanceof Array
  items = (process_item(item, link, type, window) for item in items)

process_item = (item, link, type, window) ->
  # Basics
  item.url = link
  if type == 'atom'
    item.guid = item.id
    item.pubDate = new Date(item.published)
    item.summary = item.summary['#']
    delete item.id
    delete item.link
    delete item['@']
    delete item.updated
    delete item.published
  else
    item.guid = item.guid['#']
    delete item.link
    delete item.enclosure
  # Generate a clean ID
  if not item._id
    item._id = utils.randid()
  # Get timestamp
  try
    if item.pubDate?
      item.timestamp = (new Date(item.pubDate)).getTime()
    else
      item.timestamp = (new Date()).getTime()
  catch e
    console.log "Error parsing date #{item.pubDate}"
    item.timestamp = (new Date()).getTime()

  # Ensure a title. if not, make one up.
  if not item.title or not item.title.length
    window.$('body').empty()
    window.$('body').append(item.description)
    window.$('div') # TODO HACK BUG WORKAROUND
    title = window.$('body').text().replace(/\r?\n/g, ' ').trim()
    if title.length > 100
      title = title.substr(0, 100) + "..."
    item.title = title
  return item

exports.process_response = (datastring, cb) ->
  #raw pubsub push here.
  #console.log "INCOMING>>#{datastring}\n"
  parser.parseString datastring

exports.subscribe = (url, username, fn) ->
  # make sure the URL isn't already subscribed
  mongo.diffbot_subscriptions.findOne {url: url}, (err, subscription) ->
    if err or subscription
      fn(err or 'Subscription already exists')
      return
    client = Nubnub.client
      #hub: 'http://pubsubhubbub.appspot.com/subscribe'
      basic_authorization: config.superfeedr_auth
      hub: 'http://superfeedr.com/hubbub'
      topic: "http://www.diffbot.com/api/rss/#{url}"
      callback: 'http://ycatalyst.com/__pubsub__'
    client.subscribe (err, resp, body) ->
      if err or resp.statusCode != 204
        console.log "Error trying to subscribe to diffbot for url #{url}: #{err} #{body} #{resp.statusCode}"
        fn(err or 'Subscription failed, please try again.')
        return
      # save it into the db
      mongo.diffbot_subscriptions.save {_id: utils.randid(), url: url, created_at: (new Date()), created_by: username}, (err, stuff) ->
        if err
          console.log "Error trying to save subscription to db: #{err}"
      fn(null)

exports.get_subscriptions = (fn) ->
  mongo.diffbot_subscriptions.find {}, {sort: [['created_at', -1]]}, (err, cursor) ->
    if err
      fn(err)
      return
    cursor.toArray fn
