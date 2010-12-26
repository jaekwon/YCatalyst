class Record
  constructor: (object) ->
    @object = object
  render: ->
    """this would be the #{@object}"""

if exports?
  exports.Record = Record
