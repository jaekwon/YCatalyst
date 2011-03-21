(function() {
  /*
  # YCatalyst
  # Copyright(c) 2011 Jae Kwon (jae@ycatalyst.com)
  # MIT Licensed
  */  var App;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  App = window.App = {};
  App.is_longpolling = false;
  App.current_user = null;
  App.DEFAULT_DEPTH = 5;
  App.upvoted = null;
  App.following = null;
  App.include = function(filename) {
    var script;
    script = document.createElement('script');
    script.src = filename;
    script.type = 'text/javascript';
    return $('head').append(script);
  };
  App.poll_errors = 0;
  App.handle_updates = function(recdatas) {
    var parent, recdata, record, _i, _len, _results;
    _results = [];
    for (_i = 0, _len = recdatas.length; _i < _len; _i++) {
      recdata = recdatas[_i];
      parent = $('#' + recdata.parent_id);
      _results.push($('#' + recdata.parent_id).length > 0 && $('#' + recdata._id).length === 0 ? parent.parents('.record').length >= App.DEFAULT_DEPTH ? parent.find('>.children>.more').removeClass('hidden').find('>.number').increment() : (record = new Record(recdata), record.object.type === 'choice' ? parent.find('>.contents>.choices').append(record.render({
        is_root: false,
        current_user: App.current_user
      })) : parent.find('>.children').prepend(record.render({
        is_root: false,
        current_user: App.current_user
      }))) : (record = new Record(recdata), record.redraw({
        current_user: App.current_user
      })));
    }
    return _results;
  };
  App.poll = function(root) {
    return $.ajax({
      cache: false,
      type: "GET",
      url: "/r/" + (root.attr('id')) + "/recv",
      dataType: "json",
      error: function() {
        App.poll_errors += 1;
        console.log("polling again in 10: error");
        return setTimeout((function() {
          return App.poll(root);
        }), 10 * 1000);
      },
      success: function(data) {
        try {
          App.poll_errors = 0;
          if (data) {
            App.handle_updates(data);
            console.log("polling again immediately");
            return App.poll(root);
          } else {
            App.poll_errors += 1;
            console.log("polling again in 10: error?");
            return setTimeout((function() {
              return App.poll(root);
            }), 10 * 1000);
          }
        } catch (e) {
          return console.log(e);
        }
      }
    });
  };
  App.set_default_text = function(input, default_text) {
    var on_blur, on_focus, orig_name;
    orig_name = input.attr('name');
    default_text || (default_text = input.attr('data-default-text'));
    on_focus = __bind(function() {
      input.removeClass('default_text');
      input.attr('name', orig_name);
      if (input.val() === default_text) {
        return input.val('');
      }
    }, this);
    on_blur = __bind(function() {
      if (input.val() === default_text || input.val() === '') {
        input.val(default_text);
        input.attr('name', '_not_' + orig_name);
        return input.addClass('default_text');
      }
    }, this);
    on_blur();
    input.focus(on_focus);
    input.blur(on_blur);
    return input.data('default_text', default_text);
  };
  jQuery.fn.extend({
    'set_default_text': function(default_text) {
      return this.each(function(i, thor) {
        var elem;
        elem = $(thor);
        return App.set_default_text(elem, default_text);
      });
    },
    'get_value': function() {
      var value;
      value = $(this).val();
      if ($(this).data('default_text') === value) {
        return '';
      } else {
        return value;
      }
    },
    'increment': function() {
      return this.text(parseInt(this.text()) + 1);
    },
    'decrement': function() {
      return this.text(parseInt(this.text()) - 1);
    },
    'make_autoresizable': function() {
      return this.each(function(i, textarea) {
        var autoresize, cloned_textarea;
        textarea = $(textarea);
        cloned_textarea = $(document.createElement('div'));
        cloned_textarea.attr({
          cols: textarea.attr('cols'),
          rows: textarea.attr('rows')
        });
        cloned_textarea.css({
          minHeight: textarea.css('min-height'),
          minWidth: textarea.css('min-width'),
          fontFamily: textarea.css('font-family'),
          fontSize: textarea.css('font-size'),
          padding: textarea.css('padding'),
          overflow: 'hidden'
        });
        cloned_textarea.css({
          position: 'absolute',
          left: '-1000000px',
          disabled: true
        });
        $(document.body).prepend(cloned_textarea);
        autoresize = function(event) {
          var line, _i, _len, _ref;
          cloned_textarea.css({
            width: textarea.css('width')
          });
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
      });
    }
  });
  App.start_longpolling = function() {
    var root;
    App.is_longpolling = true;
    if ($('[data-root="true"]').length > 0) {
      root = $('[data-root="true"]:eq(0)');
      return setTimeout((function() {
        return App.poll(root);
      }), 500);
    }
  };
  $(document).ready(function() {
    App.current_user = $('#current_user').length > 0 ? {
      _id: $("#current_user").attr('data-id'),
      username: $("#current_user").attr('data-username')
    } : null;
    App.upvoted = $.map($('.record[data-upvoted="true"]'), function(e) {
      return e.id;
    });
    return App.following = $.map($('.record[data-following="true"]'), function(e) {
      return e.id;
    });
  });
}).call(this);
