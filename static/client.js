(function() {
  var app;
  if (!(window.app != null)) {
    window.app = {};
  }
  app = window.app;
  app.current_user = null;
  app.DEFAULT_DEPTH = 5;
  app.upvoted = null;
  app.include = function(filename) {
    var script;
    script = document.createElement('script');
    script.src = filename;
    script.type = 'text/javascript';
    return $('head').append(script);
  };
  app.poll_errors = 0;
  app.poll = function(root) {
    return $.ajax({
      cache: false,
      type: "GET",
      url: "/r/" + (root.attr('id')) + "/recv",
      dataType: "json",
      error: function() {
        app.poll_errors += 1;
        return setTimeout((function() {
          return app.poll(root);
        }), 10 * 1000);
      },
      success: function(data) {
        var is_leaf, parent, recdata, record, _i, _len;
        try {
          app.poll_errors = 0;
          if (data) {
            for (_i = 0, _len = data.length; _i < _len; _i++) {
              recdata = data[_i];
              parent = $('#' + recdata.parent_id);
              if ($('#' + recdata.parent_id).length > 0 && $('#' + recdata._id).length === 0) {
                if (parent.parents('.record').length >= app.DEFAULT_DEPTH) {} else {
                  record = new window.app.Record(recdata);
                  parent.find('.children:eq(0)').prepend(record.render({
                    is_root: false,
                    current_user: app.current_user
                  }));
                }
              } else {
                is_leaf = parent.parents('.record').length >= (app.DEFAULT_DEPTH - 1);
                record = new window.app.Record(recdata);
                record.redraw({
                  is_leaf: is_leaf,
                  current_user: app.current_user
                });
              }
            }
            return app.poll(root);
          } else {
            app.poll_errors += 1;
            return setTimeout((function() {
              return app.poll(root);
            }), 10 * 1000);
          }
        } catch (e) {
          return console.log(e);
        }
      }
    });
  };
  app.make_autoresizable = function(textarea) {
    var autoresize, cloned_textarea;
    cloned_textarea = $(document.createElement('div'));
    cloned_textarea.css({
      minHeight: textarea.css('min-height'),
      minWidth: textarea.css('min-width'),
      fontFamily: textarea.css('font-family'),
      fontSize: textarea.css('font-size'),
      padding: textarea.css('padding'),
      overflow: 'hidden'
    });
    $(document.body).prepend(cloned_textarea);
    autoresize = function(event) {
      var line, _i, _len, _ref;
      cloned_textarea.css({
        width: textarea.css('width')
      });
      console.log(textarea.css('height'));
      cloned_textarea.text('');
      _ref = textarea.val().split("\n");
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        line = _ref[_i];
        cloned_textarea.append(hE(line));
        cloned_textarea.append('<br/>');
      }
      cloned_textarea.append('<br/>');
      return textarea.css('height', cloned_textarea[0].scrollHeight);
    };
    textarea.bind('keyup', autoresize);
    return setTimeout(autoresize, 0);
  };
  $(document).ready(function() {
    var root;
    app.current_user = $('#current_user').length > 0 ? {
      _id: $("#current_user").attr('data-id'),
      username: $("#current_user").attr('data-username')
    } : null;
    if ($('[data-root="true"]').length > 0) {
      root = $('[data-root="true"]:eq(0)');
      setTimeout((function() {
        return app.poll(root);
      }), 500);
    }
    return app.upvoted = $.map($('.record[data-upvoted="true"]'), function(e) {
      return e.id;
    });
  });
}).call(this);
