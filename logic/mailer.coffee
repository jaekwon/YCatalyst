###
# YCatalyst
# Copyright(c) 2011 Jae Kwon (jae@ycatalyst.com)
# MIT Licensed
###

email = require('nodemailer')
base64 = require('../static/base64')
utils = require('../utils')
mongo = require('../mongo')
config = require('../config')

# configure nodemailer
# HACK: quick workaround around https://github.com/andris9/Nodemailer/issues/8
oslib = require('os')
if not oslib.hostname?
  oslib.hostname = oslib.getHostname

email.SMTP = {
  host: 'smtp.sendgrid.net'
  port: 587
  use_authentication: true
  user: config.sendgrid_auth.user
  pass: config.sendgrid_auth.password
}

# options: 
#  to, from, subject, body
exports.mail_text = mail_text = (options, cb) ->
  if not options.to or not options.from or not options.subject or not options.body
    throw 'to/from/subject/body not set in call to mail_text'
  email.send_mail
    to: options.to
    sender: options.from
    subject: options.subject
    body: options.body
    cb

# set some nonce on the user
exports.send_password = (options, cb) ->
  options.user.password_reset_nonce = nonce = utils.randid()
  mongo.users.save options.user, (err, stuff) ->
    if err
      cb(err)
    else
      body = "To reset your password for YCatalyst, visit this link: http://ycatalyst.com/password_reset?key=#{nonce}&username=#{options.user.username}\n"
      mail_text({from: config.support_email, to: options.user.email, subject: "YCatalyst Password Reset", body: body}, cb)

# send the user a referral
exports.send_referral = (referral, cb) ->
  body = """Hello #{referral.first_name},
\n
A member of YCatalyst who goes by #{referral.referred_by} referred you to the network.
Please visit this link to continue: http://ycatalyst.com/apply?referral_id=#{referral._id}
\n
-ycat """
  mail_text {from: config.support_email, to: referral.email, subject: "You've been referred to YCatalyst by (#{referral.referred_by})", body: body}, (err) ->
    if err
      referral.err = err
    else
      referral.emailed_at = new Date()
    cb(err)
    mongo.referrals.save referral, (err, stuff) ->
      if err
        console.log "Error in updating referral: #{err}"
