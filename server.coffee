require.paths.unshift 'vendor/jade'
require.paths.unshift 'vendor'
require.paths.unshift 'vendor/validator'

http = require 'http'
jade = require 'jade'
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

server = utils.Rowter([

  ['/static/:filepath', (req, res) ->
    switch req.method
      when 'GET'
        filepath = req.path_data.filepath
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
        #views = logic.sessions.get_viewers()
        #rids = (v[0] for v in views)
        #mongo.records.find {_id: {$in: rids}}, (err, cursor) ->
        mongo.records.find {parent_id: null, deleted_at: {$exists: false}}, {sort: [['score', -1]]}, (err, cursor) ->
          cursor.toArray (err, records) ->
            if err
              console.log err
              return
            records = (new rec.Record(r) for r in records)
            render_layout "index.jade", {records: records}, req, res
  ]

  ['/r/:id', (req, res) ->
    current_user = req.get_current_user()
    root_id = req.path_data.id
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
          if not record.object.parent_id
            record.object.title = req.post_data.title
            record.object.url = req.post_data.url
            if req.post_data.url
              try
                record.object.host = utils.url_hostname(req.post_data.url)
              catch e
                record.object.host = 'unknown'
                console.log "record with url #{req.post_data.url}: couldn't parse the hostname"
            else
              delete record.object.host
          record.object.comment = req.post_data.comment
          record.object.updated_at = new Date()
          mongo.records.save record.object, (err, stuff) ->
            res.simpleJSON 200, status: 'ok'
            trigger_update [record]
  ],

  ['/r/:id/watching', (req, res) ->
    switch req.method
      when 'GET'
        rid = req.path_data.id
        watching = logic.sessions.get_watching(rid)
        res.simpleJSON(200, watching)
  ],

  ['/r/:id/delete', (req, res) ->
    console.log "qwe"
    current_user = req.get_current_user()
    if not current_user?
      res.writeHead 401, status: 'login_error'
      res.end 'not logged in'
      return
    switch req.method
      when 'POST'
        rid = req.path_data.id
        logic.records.get_one_record rid, (err, record) ->
          if record
            record.object.deleted_at = new Date()
            record.object.deleted_by = current_user.username
            mongo.records.save record.object, (err, stuff) ->
              res.simpleJSON 200, status: 'ok'
              trigger_update [record]
          else
            res.writeHead 404, status: 'error'
            res.end html
  ],

  ['/r/:id/reply', (req, res) ->
    current_user = req.get_current_user()
    if not current_user?
      res.writeHead 401, status: 'login_error'
      res.end 'not logged in'
      return
    switch req.method
      when 'GET'
        parent_id = req.path_data.id
        logic.records.get_one_record parent_id, (err, parent) ->
          render_layout "reply.jade", {parent: parent}, req, res
      when 'POST'
        parent_id = req.path_data.id
        comment = req.post_data.comment
        logic.records.get_one_record parent_id, (err, parent) ->
          if parent
            root_id = if parent.object.root_id? then parent.object.root_id else parent.object._id
            recdata = _id: utils.randid(), comment: comment, created_by: current_user.username, root_id: root_id
            if req.post_data.type == 'choice'
              # only the parent's creator can add a poll choice
              if parent.object.created_by != current_user.username
                res.writeHead 401, status: 'unauthorized'
                res.end "I can't let you do that"
                return
              recdata.type = 'choice'
            record = logic.records.create_record(recdata, parent)
            mongo.records.save record.object, (err, stuff) ->
              if req.headers['x-requested-with'] == 'XMLHttpRequest'
                res.simpleJSON 200, status: 'ok'
              else
                res.writeHead 302, Location: '/r/'+parent_id
                res.end()
              if record.object.type == 'choice'
                # we could trigger a live update, but
                # needs an update of the process.
                trigger_update [record]
              else
                # update the parent as well, specifically num_children
                parent.object.num_children += 1
                mongo.records.save parent.object, (err, stuff) ->
                  if err
                    console.err "failed to update parent.num_children: #{parent_id}"
                # update the root, num_discussions.
                logic.records.get_one_record root_id, (err, root) ->
                  if err
                    console.err "failed ot update root.num_discussions: #{root_id}"
                    return
                  if not root.object.num_discussions?
                    root.object.num_discussions = 1
                  else
                    root.object.num_discussions += 1
                  mongo.records.save root.object, (err, stuff) ->
                    if err
                      console.err "failed to update root.num_discussions: #{root_id}"
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
        key = req.path_data.key
        if not all_callbacks[key]
          all_callbacks[key] = []
        all_callbacks[key].push
          callback: ((recdatas) ->
            res.simpleJSON(200, recdatas))
          timestamp: new Date()
          username: current_user.username if current_user?
        if current_user?
          logic.sessions.touch_session(key, current_user.username)
  ],

  ['/r/:id/upvote', (req, res) ->
    current_user = req.get_current_user()
    if not current_user?
      res.writeHead 401, status: 'login_error'
      res.end 'not logged in'
      return
    switch req.method
      when 'POST'
        rid = req.path_data.id
        logic.records.get_one_record rid, (err, record) ->
          if not record.object.upvoters?
            record.object.upvoters = []
          if record.object.upvoters.indexOf(current_user._id) == -1
            record.object.upvoters.push(current_user._id)
          record.object.points = record.object.upvoters.length
          # rescore the record
          logic.records.score_record(record)
          # save this record
          mongo.records.save record.object, (err, stuff) ->
            res.simpleJSON(200, status: 'ok')
            # notify clients
            trigger_update [record]
  ],

  ['/submit', (req, res) ->
    current_user = req.get_current_user()
    if not current_user?
      render_layout "login.jade", {message: 'You need to log in to submit'}, req, res
      return
    switch req.method
      when 'GET'
        render_layout "submit.jade", {headerbar_text: 'Submit', type: (req.query_data.type or 'link')}, req, res
      when 'POST'
        data = req.post_data
        # validate data
        try
          _v.check(data.title, 'title must be 2 to 200 characters').len(2, 200)
          if data.url
            _v.check(data.url, 'url must be a valid http(s):// url.').isUrl()
          if data.text
            _v.check(data.text, 'text must be less than 10K characters for now').len(0, 10000)
          if data.choices
            _v.check(data.choices, 'choices must be less than 10K characters for now').len(0, 10000)
          if data.type == 'poll'
            choices = data.choices = (data.choices or '').replace(/\r\n/g, "\n").split("\n\n")
            if choices.length < 2
              throw 'you must enter some choices separated by newlines'
          else
            if not data.url and not data.text and not data.choices
              throw 'you must enter a URL or text'
        catch e
          render_layout "message.jade", {message: ''+e}, req, res
          return
        # create new record
        recdata = {title: data.title, comment: data.text, created_by: current_user.username}
        if data.url
          recdata.url = data.url
          try
            recdata.host = utils.url_hostname(data.url)
          catch e
            recdata.host = 'unknown'
            console.log "record with url #{data.url}: couldn't parse the hostname"
        else if data.choices
          recdata.type = 'poll'
          
        record = logic.records.create_record(recdata)
        mongo.records.save record.object, (err, stuff) ->
          record.object = stuff
          # if data.choices, then add the choices too
          if data.choices
            for choice in data.choices
              choice_recdata = {comment: choice, created_by: current_user.username, type: 'choice'}
              choice_record = logic.records.create_record(choice_recdata, record)
              mongo.records.save choice_record.object, (err, stuff) ->
                # nothing to do
            # TODO assume it worked.
            res.redirect "/r/#{stuff._id}"
          else
            res.redirect "/r/#{stuff._id}"
  ],

  ['/login', (req, res) ->
    switch req.method
      when 'GET'
        res.setCookie 'goto', req.query_data.goto
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
            res.redirect req.getCookie('goto') or '/'
          else
            form_error('wrong password')
            return
  ],

  ['/password_reset', (req, res) ->
    switch req.method
      when 'GET'
        if not req.query_data.key
          # show the email form
          render_layout "password_reset.jade", {}, req, res
        else
          # ask for the password & repeat
          mongo.users.findOne username: req.query_data.username, (err, user) ->
            if not user
              # invalid user
              render_layout "message.jade", {message: "Sorry, invalid request"}, req, res
            else if user.password_reset_nonce == req.query_data.key
              # reset the password
              render_layout "password_reset.jade", {user: user}, req, res
            else
              # wrong key/nonce
              render_layout "message.jade", {message: "Sorry, the URL is bad or expired. Check your latest email or try again"}, req, res
      when 'POST'
        if req.post_data.email
          # we got the user's email
          mongo.users.findOne email: req.post_data.email, (err, user) ->
            if user
              res.clearCookie 'user'
              logic.mailer.send_password user: user, (err, results) ->
                if err?
                  render_layout "message.jade", {message: "Error sending an email, please try again."}, req, res
                  return
                render_layout "message.jade", {message: "check your email please."}, req, res
            else
              render_layout "message.jade", {message: "Sorry, unknown email #{req.post_data.email}."}, req, res
              return
        else if req.post_data.password
          # we got the password and all that. do all validation here.
          if req.post_data.password != req.post_data.password2
            render_layout "message.jade", {message: "Password doesn't match. Go back."}, req, res
            return
          mongo.users.findOne username: req.post_data.username, (err, user) ->
            if user
              # ensure that the nonce was actually there.
              if not user.password_reset_nonce or user.password_reset_nonce.length < 5 or (user.password_reset_nonce != req.post_data.password_reset_nonce)
                render_layout "message.jade", {message: "Invalid request. Check your latest email or try again"}, req, res
                return
              # ensure good password
              if not (5 <= req.post_data.password.length <= 20)
                render_layout "message.jade", {message: "Invalid password. Your password must be between 5 and 20 characters in length"}, req, res
                return
              # save this new password and reset/delete the nonce
              salt = utils.randid()
              hashtimes = 10000 # runs about 80ms on my laptop
              user.password = [utils.passhash(req.post_data.password, salt, hashtimes), salt, hashtimes]
              delete user.password_reset_nonce
              mongo.users.save user, (err, stuff) ->
                # set the user in session
                res.setSecureCookie 'user', JSON.stringify(user)
                res.redirect '/'
            else
              render_layout "message.jade", {message: "Sorry, unknown user #{req.post_data.username}."}, req, res
              return
        else
          # dunno
          res.redirect '/password_reset'
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
          else if invite.claimed_by? and invite.claimed_by.length >= (invite.count or 1)
            form_error("invite code already used #{invite.count or 1}")
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
])
server.listen 8126, '127.0.0.1'
console.log 'Server running at http://127.0.0.1:8126'
