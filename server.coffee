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
logic = require './logic/logic'

cookie.secret = "supersecretbanananana"

DEFAULT_DEPTH = 5

#if false
#  process.on 'uncaughtException', (err) ->
#    console.log "XXX HOLY SHIT"
#    console.log err
#    console.log "FIX THIS ASAP, http://debuggable.com/posts/node-js-dealing-with-uncaught-exceptions:4c933d54-1428-443c-928d-4e1ecbdd56cb"

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
    if not record.is_new
      notify_keys.push(record.object._id)
    notify_keys = notify_keys.concat(record.object.parents or [])
  notify_keys = _.uniq(notify_keys)

  recdatas = (logic.records.scrubbed_recdata(record) for record in records)

  for key in notify_keys
    for callback in all_callbacks[key] or []
      callback.callback(recdatas)
    delete all_callbacks[key]

# helper to render with layout
render_layout = (template, locals, req, res, fn) ->
  locals.title = 'YCatalyst' if not locals.title?
  locals.require = require
  locals.current_user = req.get_current_user()
  jade.renderFile "templates/#{template}", locals: locals, (err, body) ->
    if err?
      console.log err
      console.log err.stack
      console.log err.message
      if fn?
        fn(err, undefined)
      return
    locals.body = body
    jade.renderFile "templates/layout.jade", locals: locals, (err, html) ->
      if err?
        console.log err
        console.log err.stack
        console.log err.message
        if fn?
          fn(err, undefined)
        return
      if res?
        res.writeHead 200, status: 'ok'
        res.end html

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
            render_layout "index.jade", {records: records}, req, res
  ]

  ['/r/:id', (req, res) ->
    current_user = req.get_current_user()
    root_id = req.sherpaResponse.params.id
    switch req.method
      when 'GET'
        # requested from json, just return a single record
        if req.headers['x-requested-with'] == 'XMLHttpRequest'
          logic.records.get_one_record root_id, (err, record) ->
            res.simpleJSON 200, record: logic.records.scrubbed_recdata(record)
            return
        else
          logic.records.get_records root_id, DEFAULT_DEPTH, (err, all) ->
            if err? or not all?
              res.writeHead 404, status: 'error'
              res.end()
              return
            render_layout "record.jade", {root: logic.records.dangle(all, root_id)}, req, res
      when 'POST'
        # updating
        logic.records.get_one_record root_id, (err, record) ->
          if err? or not record?
            res.writeHead 404, status: 'error'
            res.end()
            return
          if record.object.created_by != current_user.username
            res.simpleJSON 400, status: 'unauthorized'
            return
          record.object.comment = req.post_data.comment
          record.object.updated_at = new Date()
          mongo.records.save record.object, (err, stuff) ->
            res.simpleJSON 200, status: 'ok'
            trigger_update [record]
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
        logic.records.get_one_record parent_id, (err, parent) ->
          render_layout "reply.jade", {parent: parent}, req, res
      when 'POST'
        parent_id = req.sherpaResponse.params.id
        comment = req.post_data.comment
        logic.records.get_one_record parent_id, (err, parent) ->
          if parent
            recdata = _id: utils.randid(), comment: comment, created_by: current_user.username
            record = logic.records.create_record(recdata, parent)
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
          callback: ((recdatas) ->
            res.simpleJSON(200, recdatas))
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
        logic.records.get_one_record rid, (err, record) ->
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

  ['/submit', (req, res) ->
    current_user = req.get_current_user()
    if not current_user?
      res.writeHead 401, status: 'login_error'
      res.end 'not logged in'
      return
    switch req.method
      when 'GET'
        render_layout "submit.jade", {headerbar_text: 'Submit'}, req, res
      when 'POST'
        data = req.post_data
        # validate data
        try
          _v.check(data.title, 'title must be 2 to 200 characters').len(2, 200)
          if data.url
            _v.check(data.url, 'url must be a valid http(s):// url.').isUrl()
          if data.text
            _v.check(data.text, 'text must be less than 10K characters for now').len(0, 10000)
          if not data.url and not data.text
            throw 'you must enter a URL or text'
        catch e
          render_layout "message.jade", {message: ''+e}, req, res
          return
        # create new record
        recdata = {title: data.title, created_by: current_user.username}
        if data.url
          recdata.url = data.url
          try
            recdata.host = require('url').parse(data.url).hostname
            if recdata.host.substr(0, 4) == 'www.' and recdata.host.length > 7
              recdata.host = recdata.host.substr(4)
          catch e
            render_layout "message.jade", {message: "#{data.url} is not a valid URL?"}, req, res
            return
        if data.text
          recdata.comment = data.text
        record = logic.records.create_record(recdata)
        mongo.records.save record.object, (err, stuff) ->
          res.redirect "/r/#{stuff._id}"
  ],

  ['/login', (req, res) ->
    switch req.method
      when 'GET'
        render_layout "login.jade", {}, req, res
      when 'POST'
        form_error = (error) ->
          render_layout "message.jade", {message: error}, req, res
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

  ['/logout', (req, res) ->
    switch req.method
      when 'GET'
        res.clearCookie 'user'
        res.redirect '/'
  ],

  ['/register', (req, res) ->
    switch req.method
      when 'POST'
        form_error = (error) ->
          render_layout "message.jade", {message: error}, req, res

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
