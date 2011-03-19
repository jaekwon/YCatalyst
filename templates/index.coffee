exports.template = ->
  ul class: 'records', ->
    @records.forEach (record) ->
      li ->
        record.render_headline current_user: @current_user

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
