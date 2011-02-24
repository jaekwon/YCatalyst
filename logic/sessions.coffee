mongo = require '../mongo'

# a global hash from record id to {username: {timestamp}}
all_sessions = undefined
mongo.after_open 'app', ->
  mongo.app.findOne({_id: 'all_sessions'}, (err, stuff) ->
    all_sessions = stuff or {_id: 'all_sessions'}
  )

# clear old sessions after 60 secondsish
setInterval (->
  now = new Date()
  num_cleared = 0
  num_seen = 0
  for key, sessions of all_sessions
    continue if key == '_id'
    # we count the number of sessions per key, cuz javascript has no suitable object.length
    num_seen_for_key = 0
    for username, session of sessions
      # TODO this is stupid. replace with a better dict implementation with length
      continue if username == '_fake_length'
      num_seen_for_key += 1
      if now - session.timestamp > 60*1000
        num_cleared += 1
        delete sessions[username]
    sessions._fake_length = num_seen_for_key
    num_seen += num_seen_for_key
  if num_cleared > 0
    console.log "cleared #{num_cleared} of #{num_seen} in #{new Date() - now} sessions"
  # every interval save the sessions object
  mongo.app.save all_sessions, (err, stuff) ->
    if err?
      console.log "error saving all_sessions: " + err
), 15000

# create or update the session for key/username
exports.touch_session = (key, username) ->
  sessions = all_sessions[key]
  if not sessions?
    sessions = all_sessions[key] = {}
  s = sessions[username]
  if not s?
    s = sessions[username] = {}
  s.timestamp = new Date()

# get sorted list of [record_id, num views]
exports.get_viewers = ->
  views = [] # list of [record id, num viewers]
  for key, sessions of all_sessions
    continue if key == '_id'
    if key != '_fake_length' # not sure why i put this here
      views.push( [key, sessions._fake_length] )
  views.sort( (a, b) -> b[1] - a[1] )
  return views

# get list of usernames watching an item
exports.get_watching = (rid) ->
  watching = if all_sessions[rid]? then (username for username, session of (all_sessions[rid] or {})) else []
  return watching
