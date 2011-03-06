email = require('mailer')
base64 = require('../static/base64')
utils = require('../utils')
mongo = require('../mongo')
config = require('../config')

# options: 
#  to, from, subject, body
exports.mail_text = mail_text = (options, cb) ->
  if not options.to or not options.from or not options.subject or not options.body
    throw 'to/from/subject/body not set in call to mail_text'
  email.send
    host: 'smtp.sendgrid.net'
    port: 587
    to: options.to
    from: options.from
    subject: options.subject
    body: options.body
    authentication: 'login'
    username: base64.encode(config.sendgrid_auth.user)
    password: base64.encode(config.sendgrid_auth.password)
    cb

# set some nonce on the user
exports.send_password = (options, cb) ->
  options.user.password_reset_nonce = nonce = utils.randid()
  mongo.users.save options.user, (err, stuff) ->
    if err
      cb(err)
    else
      body = "To reset your password for YCatalyst, visit this link: http://ycatalyst.com/password_reset?key=#{nonce}&username=#{options.user.username}\n"
      mail_text({from: "jae@ycatalyst.com", to: options.user.email, subject: "YCatalyst Password Reset", body: body}, cb)
