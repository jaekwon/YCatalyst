exports.template = ->
  ul class: 'records', ->
    @records.forEach (record) ->
      li ->
        record.render current_user: @current_user, is_root: true

exports.sass = """
  body .record .contents
    :margin 2px 0px
"""
