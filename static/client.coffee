include = (filename) ->
  script = document.createElement('script')
  script.src = filename
  script.type = 'text/javascript'
  $(document.head).append(script)

$(document).ready ->
  # include record.js
  include "/static/record.js"
  
  if $('[data-root="true"]').length > 0
    root = $('[data-root="true"]:eq(0)')

    $.ajax {
      cache: false,
      type: "GET",
      url: "/r/#{root.attr('id')}/recv",
      dataType: "json",
      error: ->
        alert("error")
      success: (data) ->
        if data
          alert(data)
    }

#  //make another request
#  $.ajax({ cache: false
#         , type: "GET"
#         , url: "/recv"
#         , dataType: "json"
#         , data: { since: CONFIG.last_message_time, id: CONFIG.id }
#         , error: function () {
#             addMessage("", "long poll error. trying again...", new Date(), "error");
#             transmission_errors += 1;
#             //don't flood the servers on error, wait 10 seconds before retrying
#             setTimeout(longPoll, 10*1000);
#           }
#         , success: function (data) {
#             transmission_errors = 0;
#             //if everything went well, begin another request immediately
#             //the server will take a long time to respond
#             //how long? well, it will wait until there is another message
#             //and then it will return it to us and close the connection.
#             //since the connection is closed when we get data, we longPoll again
#             longPoll(data);
#           }
#         });
#
