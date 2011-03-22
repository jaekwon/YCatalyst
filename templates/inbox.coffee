exports.template = ->
  ol class: 'records light_bullets', ->
    @records.forEach (record) ->
      li ->
        record.render "default", current_user: @current_user, is_root: true

exports.sass = """
  body .record .contents
    :margin 2px 0px
"""
