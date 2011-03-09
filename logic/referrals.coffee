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

exports.submit = (referral, cb) ->
  referral._id = utils.randid()
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
