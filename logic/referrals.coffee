###
# YCatalyst
# Copyright(c) 2011 Jae Kwon (jae@ycatalyst.com)
# MIT Licensed
###

require.paths.unshift 'vendor'
mongo = require '../mongo'
mailer = require './mailer'
utils = require '../utils'
config = require '../config'

# submit/create a new referral.
# referral = :first_name, :last_name, :email, :referred_by
exports.submit = (referral, cb) ->
  referral._id = utils.randid()
  referral.created_at = new Date()
  # look for a previous referral with the same email
  mongo.referrals.findOne {email: referral.email}, (err, existing) ->
    if err
      cb(err)
      return
    if existing
      cb('That user appears to already have been referred')
      return
    mongo.referrals.save referral, (err, stuff) ->
      cb(err)
      if not err
        # send an email to the email
        mailer.send_referral referral, (err) ->
          cb(err)
