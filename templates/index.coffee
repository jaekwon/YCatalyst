exports.template = ->
  ol class: 'records light_bullets', ->
    @records.forEach (record) ->
      li ->
        record.render "headline", current_user: @current_user

exports.sass = """
  body
    .record
      :margin 0px 0px
      .item_info
        :position relative
        :top -4px
        :font-size 7pt
"""

exports.coffeescript = ->
  App.start_longpolling()
