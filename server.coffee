require.paths.unshift 'vendor/jade'
require.paths.unshift 'vendor/sherpa/lib'
require.paths.unshift 'vendor'
require.paths.unshift 'vendor/validator'

http = require 'http'
jade = require 'jade'
sherpa = require 'sherpa/nodejs'
utils = require './utils'
mongo = require './mongo'
fu = require './fu'
rec = require './static/record'
cookie = require 'cookie-node'
_ = require './static/underscore'
_v = require 'validator'

cookie.secret = "supersecretbanananana"

DEFAULT_DEPTH = 5

#if false
#  process.on 'uncaughtException', (err) ->
#    console.log "XXX HOLY SHIT"
#    console.log err
#    console.log "FIX THIS ASAP, http://debuggable.com/posts/node-js-dealing-with-uncaught-exceptions:4c933d54-1428-443c-928d-4e1ecbdd56cb"

get_records = (root_id, level, fn) ->
  now = new Date()
  mongo.records.findOne _id: root_id, (err, root) ->
    all = {}
    if not root?
      fn(err, null)
      return
    all[root_id] = new rec.Record(root)
    tofetch = [root_id]
    fetchmore = (i) ->
      # NOTE: http://talklikeaduck.denhaven2.com/2009/04/15/ordered-hashes-in-ruby-1-9-and-javascript
      # and   http://ejohn.org/blog/javascript-in-chrome/
      # The side effect of sorting here is that the record.coffe/dangle method will automagically sort the children by points.
      mongo.records.find {parent_id: {$in: tofetch}}, {sort: [['points', -1]]}, (err, cursor) ->
        cursor.toArray (err, records) ->
          tofetch = []
          for record in records
            tofetch.push(record._id)
            all[record._id] = new rec.Record(record)
          if i > 1
            fetchmore(i-1)
          else
            console.log "get_records in #{new Date() - now}"
            fn(err, all)
    fetchmore(level)

get_one_record = (rid, fn) ->
  mongo.records.findOne _id: rid, (err, recdata) ->
    if recdata
      fn(err, new rec.Record(recdata))
    else
      fn(err, null)

# given a record object, return an object we can return to the client
scrubbed_recdata = (record) ->
  object = record.object
  

# a global hash from record id to [callbacks]
all_callbacks = {}
# a global hash from record id to {username: {timestamp}}
all_sessions = {}

# create or update the session for key/username
touch_session = (key, username) ->
  sessions = all_sessions[key]
  if not sessions?
    sessions = all_sessions[key] = {}
  s = sessions[username]
  if not s?
    s = sessions[username] = {}
  s.timestamp = new Date()

# clear old callbacks
# they can hang around for at most 30 seconds.
setInterval (->
  now = new Date()
  num_purged = 0
  num_seen = 0
  for key, callbacks of all_callbacks
    num_seen += callbacks.length
    while (callbacks.length > 0 && now - callbacks[0].timestamp > 30*1000)
      num_purged += 1
      callbacks.shift().callback([])
    if callbacks.length == 0
      delete all_callbacks[key]
  if num_purged > 0
    console.log "purged #{num_purged} of #{num_seen} in #{new Date() - now}"
  ), 3000

# clear old sessions after 60 secondsish
setInterval (->
  now = new Date()
  num_cleared = 0
  num_seen = 0
  for key, sessions of all_sessions
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
  ), 15000

# given records, tell clients that this record had been updated
# -> if record is new
# -> if record was deleted
# -> if record got voted on
# -> if record has new number of children
# 
# TODO we need to keep track of more state
# NOTE it is assumed that the records are in proximity to each other,
# specifically that the union of r.object.parents is small in size.
trigger_update = (records) ->
  # compute the keys to notify
  notify_keys = []
  for record in records
    if record.object.upvoters?
      delete record.object.upvoters
    if not record.is_new
      notify_keys.push(record.object._id)
    notify_keys = notify_keys.concat(record.object.parents or [])
  notify_keys = _.uniq(notify_keys)

  for key in notify_keys
    for callback in all_callbacks[key] or []
      callback.callback(records)
    delete all_callbacks[key]

server = http.createServer(utils.Rowt(new Sherpa.NodeJs([

  ['/static/:filepath', (req, res) ->
    switch req.method
      when 'GET'
        filepath = req.sherpaResponse.params.filepath
        filepath = require('path').join './static/', filepath
        if filepath.indexOf('static/') != 0
          res.writeHead 404, 'does not exist'
          res.end()
        else
          fu.staticHandler(filepath)(req, res)
  ]

  # get the most viewed sessions
  # TODO cache this
  ['/', (req, res) ->
    switch req.method
      when 'GET'
        current_user = req.get_current_user()
        views = [] # list of [record id, num viewers]
        for key, sessions of all_sessions
          if key != '_fake_length' # see why it's stupid?
            views.push( [key, sessions._fake_length] )
        views.sort( (a, b) -> b[1] - a[1] )
        rids = (v[0] for v in views)
        mongo.records.find {_id: {$in: rids}}, (err, cursor) ->
          cursor.toArray (err, records) ->
            records = (new rec.Record(r) for r in records)
            if err
              console.log err
              return
            jade.renderFile 'templates/index.jade', locals: {require: require, records: records, current_user: current_user}, (err, html) ->
              if err
                console.log err
                return
              res.writeHead 200, status: 'ok'
              res.end html
  ]

  ['/r/:id', (req, res) ->
    current_user = req.get_current_user()
    root_id = req.sherpaResponse.params.id
    switch req.method
      when 'GET'
        # requested from json, just return a single record
        if req.headers['x-requested-with'] == 'XMLHttpRequest'
          get_one_record root_id, (err, record) ->
           
        else
          get_records root_id, DEFAULT_DEPTH, (err, all) ->
            if err? or not all?
              res.writeHead 404, status: 'error'
              res.end()
              return
            jade.renderFile 'templates/record.jade', locals: {root: rec.dangle(all, root_id), require: require, current_user: current_user}, (err, html) ->
              console.log err if err
              res.writeHead 200, status: 'ok'
              res.end html
      when 'POST'
        # updating
        get_one_record root_id, (err, record) ->
          if err? or not record?
            res.writeHead 404, status: 'error'
            res.end()
            return
          if record.created_by != current_user.username
            res.simpleJSON 400, status: 'unauthorized'
            return
          record.comment = req.post_data.comment
          record.updated_at = new Date()
          mongo.records.save record, (err, stuff) ->
            res.simpleJSON 200, status: 'ok'
  ],

  ['/r/:id/watching', (req, res) ->
    switch req.method
      when 'GET'
        rid = req.sherpaResponse.params.id
        watching = if all_sessions[rid]? then (username for username, session of (all_sessions[rid] or {})) else []
        res.simpleJSON(200, watching)
  ],

  ['/r/:id/reply', (req, res) ->
    current_user = req.get_current_user()
    if not current_user?
      res.writeHead 401, status: 'login_error'
      res.end 'not logged in'
      return
    switch req.method
      when 'GET'
        parent_id = req.sherpaResponse.params.id
        get_one_record parent_id, (err, parent) ->
          jade.renderFile 'templates/reply.jade', locals: {parent: parent, current_user: current_user, require: require}, (err, html) ->
            console.log err if err
            res.writeHead 200, status: 'ok'
            res.end html
      when 'POST'
        parent_id = req.sherpaResponse.params.id
        comment = req.post_data.comment
        get_one_record parent_id, (err, parent) ->
          if parent
            data = parent_id: parent_id, _id: utils.randid(), comment: comment, created_by: current_user.username
            record = rec.Record::create(data, parent)
            mongo.records.save record.object, (err, stuff) ->
              if req.headers['x-requested-with'] == 'XMLHttpRequest'
                res.simpleJSON 200, status: 'ok'
              else
                res.writeHead 302, Location: '/r/'+parent_id
                res.end()
              # update the parent as well, specifically num_children
              parent.object.num_children += 1
              mongo.records.save parent.object, (err, stuff) ->
                if err
                  console.err "failed to update parent.num_children: #{parent_id}"
              # notify clients
              trigger_update [parent, record]
          else
            res.writeHead 404, status: 'error'
            res.end html
  ],

  ['/r/:key/recv', (req, res) ->
    current_user = req.get_current_user()
    switch req.method
      when 'GET'
        key = req.sherpaResponse.params.key
        if not all_callbacks[key]
          all_callbacks[key] = []
        all_callbacks[key].push
          callback: ((records) ->
            res.simpleJSON(200, (r.object for r in records)))
          timestamp: new Date()
          username: current_user.username if current_user?
        if current_user?
          touch_session(key, current_user.username)
  ],

  ['/r/:id/upvote', (req, res) ->
    current_user = req.get_current_user()
    if not current_user?
      res.writeHead 401, status: 'login_error'
      res.end 'not logged in'
      return
    switch req.method
      when 'POST'
        rid = req.sherpaResponse.params.id
        get_one_record rid, (err, record) ->
          if not record.object.upvoters?
            record.object.upvoters = []
          if record.object.upvoters.indexOf(current_user._id) == -1
            record.object.upvoters.push(current_user._id)
          record.object.points = record.object.upvoters.length
          mongo.records.save record.object, (err, stuff) ->
            res.simpleJSON(200, status: 'ok')
            # notify clients
            trigger_update [record]
  ],

  ['/login', (req, res) ->
    switch req.method
      when 'GET'
        jade.renderFile 'templates/login.jade', locals: {require: require}, (err, html) ->
          res.writeHead 200, status: 'ok'
          res.end html
      when 'POST'
        form_error = (error) ->
          jade.renderFile 'templates/message.jade', locals: {require: require, message: error}, (err, html) ->
            res.writeHead 200, status: 'ok'
            res.end html
        try
          _v.check(req.post_data.username, 'username must be alphanumeric, 2 to 12 characters').len(2,12).isAlphanumeric()
          _v.check(req.post_data.password, 'password must be 5 to 20 characters').len(5,20)
        catch e
          form_error(''+e)
          return
        # get user
        mongo.users.findOne username: req.post_data.username, (err, user) ->
          if err or not user? or not user.password?
            form_error('error, no such user?')
            return
          # check password
          hashtimes = 10000 # runs about 80ms on my laptop
          if user.password[0] == utils.passhash(req.post_data.password, user.password[1], hashtimes)
            # set the user in session
            res.setSecureCookie 'user', JSON.stringify(user)
            res.redirect '/'
          else
            form_error('wrong password')
            return
  ],

  ['/register', (req, res) ->
    switch req.method
      when 'POST'
        form_error = (error) ->
          jade.renderFile 'templates/message.jade', locals: {require: require, message: error}, (err, html) ->
            res.writeHead 200, status: 'ok'
            res.end html

        # validate data
        data = req.post_data
        try
          _v.check(data.username, 'username must be alphanumeric, 2 to 12 characters').len(2,12).isAlphanumeric()
          _v.check(data.password, 'password must be 5 to 20 characters').len(5,20)
          _v.check(data.email).isEmail()
        catch e
          form_error(''+e)
        if not data.invite?
          form_error("no invite specified")

        mongo.invites.findOne _id: data.invite, (err, invite) ->
          if err or not invite?
            form_error("invalid invite")
          else if invite.claimed_by?
            form_error("invite code already used")
          else
            # create the user
            user = data
            user._id = utils.randid()
            salt = utils.randid()
            hashtimes = 10000 # runs about 80ms on my laptop
            user.password = [utils.passhash(user.password, salt, hashtimes), salt, hashtimes]
            mongo.users.save user, (err, stuff) ->
              # set the user in session
              res.setSecureCookie 'user', JSON.stringify(user)
              res.redirect '/'
              # update the invite
              invite.claimed_by = [user._id]
              mongo.invites.save invite, (err, stuff) ->
                #pass
  ]

]).listener()))
server.listen 8126, '127.0.0.1'
console.log 'Server running at http://127.0.0.1:8126'
