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

# members can upvote/downvote, admins can also invite/delete
# vote: 'upvote', 'downvote', 'invite', or 'delete'
exports.vote = (application_id, current_user, vote, cb) ->
  switch vote
    when 'accept'
      update_operation = {$addToSet: {accepted_by: current_user.username}, $pull: {denied_by: current_user.username}}
    when 'deny'
      update_operation = {$addToSet: {denied_by: current_user.username}, $pull: {accepted_by: current_user.username}}
    when 'invite'
      if not current_user.is_admin
        cb("unauthorized")
        return
      update_operation = {$set: {invited_at: new Date(), invited_by: current_user.username}}
      # also send an invite
      do_invite(application_id)
    when 'delete'
      if not current_user.is_admin
        cb("unauthorized")
        return
      update_operation = {$set: {deleted_at: new Date(), deleted_by: current_user.username}}
  mongo.applications.update {_id: application_id}, update_operation, (err, stuff) ->
    if err
      cb(err)
      return
    cb()

# send the newly invited user an email with an invitation code.
do_invite = (application_id) ->
  mongo.applications.findOne {_id: application_id}, (err, application) ->
    new_invite = _id: utils.randid(), application_id: application_id, created_at: new Date()
    mongo.invites.save new_invite, (err, invite) ->
      mailer.send_invitation application, invite
