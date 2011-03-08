mongo = require '../mongo'

mongo.after_open 'users', ->
  mongo.users.find {}, (err, cursor) ->
    cursor.toArray (err, users) ->
      console.log "adding created_at for #{users.length} users"
      for user in users
        if user.created_at
          continue
        user.created_at = (new Date())
        mongo.users.save user, (err, stuff) ->
          if err
            console.log "Error for user #{user._id}: #{err}"
          # do nothing
      console.log "end"
