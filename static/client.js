(function() {
  var include, poll, poll_errors;
  include = function(filename) {
    var script;
    script = document.createElement('script');
    script.src = filename;
    script.type = 'text/javascript';
    return $(document.head).append(script);
  };
  poll_errors = 0;
  poll = function(root) {
    return $.ajax({
      cache: false,
      type: "GET",
      url: "/r/" + (root.attr('id')) + "/recv",
      dataType: "json",
      error: function() {
        poll_errors += 1;
        return setTimeout(poll, 10 * 1000);
      },
      success: function(data) {
        var parent, recdata, record, _i, _len;
        try {
          poll_errors = 0;
          if (data) {
            for (_i = 0, _len = data.length; _i < _len; _i++) {
              recdata = data[_i];
              if ($('#' + recdata.parent_id).length > 0 && $('#' + recdata._id).length === 0) {
                parent = $('#' + recdata.parent_id);
                record = new window.app.Record(recdata);
                parent.find('.children:eq(0)').prepend(record.render({
                  is_root: false
                }));
              }
            }
          }
          return poll(root);
        } catch (e) {
          return console.log(e);
        }
      }
    });
  };
  $(document).ready(function() {
    var root;
    include("/static/record.js");
    if ($('[data-root="true"]').length > 0) {
      root = $('[data-root="true"]:eq(0)');
      return setTimeout((function() {
        return poll(root);
      }), 500);
    }
  });
}).call(this);
