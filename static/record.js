(function() {
  var Record, app, coffeekup, dangle, markz;
  coffeekup = typeof CoffeeKup != "undefined" && CoffeeKup !== null ? CoffeeKup : require('coffeekup');
  markz = typeof Markz != "undefined" && Markz !== null ? Markz : require('./markz').Markz;
  if (typeof window != "undefined" && window !== null) {
    if (!(window.app != null)) {
      window.app = {};
    }
    app = window.app;
  } else {
    app = require('../app');
  }
  Record = (function() {
    function Record(object) {
      this.object = object;
      if (!(this.object.points != null)) {
        this.object.points = 0;
      }
      if (!(this.object.num_children != null)) {
        this.object.num_children = 0;
      }
      if (!(this.object.created_at != null)) {
        this.object.created_at = new Date();
      }
    }
    Record.prototype.render_kup = function() {
      return div({
        "class": "record",
        id: this.object._id,
        "data-root": is_root,
        "data-upvoted": upvoted
      }, function() {
        span({
          "class": "top_items"
        }, function() {
          if ((typeof current_user != "undefined" && current_user !== null) && !upvoted) {
            a({
              "class": "upvote",
              href: '#',
              onclick: "app.upvote('" + (h(this.object._id)) + "'); return false;"
            }, function() {
              return "&spades;";
            });
          }
          span(function() {
            return " " + (this.object.points || 0) + " pts by ";
          });
          a({
            href: "/user/" + (h(this.object.created_by))
          }, function() {
            return h(this.object.created_by);
          });
          text(" | ");
          if (is_root && this.object.parent_id) {
            a({
              "class": "parent",
              href: "/r/" + this.object.parent_id
            }, function() {
              return "parent";
            });
            text(" | ");
          }
          a({
            "class": "link",
            href: "/r/" + this.object._id
          }, function() {
            return "link";
          });
          if ((typeof current_user != "undefined" && current_user !== null) && this.object.created_by === current_user.username) {
            text(" | ");
            a({
              "class": "edit",
              href: "#",
              onclick: "app.show_edit_box('" + (h(this.object._id)) + "'); return false;"
            }, function() {
              return "edit";
            });
            text(" | ");
            return a({
              "class": "delete",
              href: "#",
              onclick: "app.delete('" + (h(this.object._id)) + "'); return false;"
            }, function() {
              return "delete";
            });
          }
        });
        div({
          "class": "contents"
        }, function() {
          if (this.object.comment != null) {
            text(markz.prototype.markup(this.object.comment));
          }
          text(" ");
          a({
            "class": "reply",
            href: "/r/" + this.object._id + "/reply",
            onclick: "app.show_reply_box('" + (h(this.object._id)) + "'); return false;"
          }, function() {
            return "reply";
          });
          div({
            "class": "edit_box_container"
          });
          return div({
            "class": "reply_box_container"
          });
        });
        return div({
          "class": "children"
        }, function() {
          var child, loaded_children, _i, _len, _ref;
          if (this.children) {
            _ref = this.children;
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              child = _ref[_i];
              text(child.render({
                is_root: false,
                current_user: current_user
              }));
            }
          }
          loaded_children = this.children ? this.children.length : 0;
          if (loaded_children < this.object.num_children) {
            return a({
              "class": "more",
              href: "/r/" + this.object._id
            }, function() {
              return "" + (this.object.num_children - loaded_children) + " more replies";
            });
          }
        });
      });
    };
    Record.prototype.render = function(options) {
      var current_user, is_root, upvoted;
      is_root = !(options != null) || options.is_root;
      if (options != null) {
        current_user = options.current_user;
      }
      upvoted = typeof window != "undefined" && window !== null ? app.upvoted.indexOf(this.object._id) !== -1 : current_user != null ? (this.object.upvoters != null) && this.object.upvoters.indexOf(current_user._id) !== -1 : void 0;
      return coffeekup.render(this.render_kup, {
        context: this,
        locals: {
          markz: markz,
          is_root: is_root,
          upvoted: upvoted,
          current_user: current_user
        },
        dynamic_locals: true
      });
    };
    Record.prototype.render_headline_kup = function() {
      return div({
        "class": "record",
        id: this.object._id
      }, function() {
        span({
          "class": "top_items"
        }, function() {
          span(function() {
            return " " + (this.object.points || 0) + " pts by ";
          });
          return a({
            href: "/user/" + (h(this.object.created_by))
          }, function() {
            return h(this.object.created_by);
          });
        });
        br({
          foo: "bar"
        });
        return a({
          href: "/r/" + this.object._id,
          "class": "contents"
        }, function() {
          if (this.object.comment != null) {
            return text(markz.prototype.markup(this.object.comment));
          }
        });
      });
    };
    Record.prototype.render_headline = function(options) {
      return coffeekup.render(this.render_headline_kup, {
        context: this,
        locals: {
          markz: markz
        },
        dynamic_locals: true
      });
    };
    Record.prototype.comment_url = function() {
      return "/r/" + this.object._id + "/reply";
    };
    Record.prototype.create = function(recdata, parent) {
      var parents, record;
      parents = [];
      if (parent != null) {
        if (parent.object.parents != null) {
          parents = [parent.object._id].concat(parent.object.parents.slice(0, 6));
        } else {
          parents = [parent.object._id];
        }
      }
      recdata.created_at = new Date();
      recdata.parents = parents;
      record = new Record(recdata);
      record.is_new = true;
      return record;
    };
    Record.prototype.redraw = function(options) {
      var children, old, old_is_root;
      old = $("\#" + this.object._id);
      old_is_root = old.attr('data-root') === "true";
      children = old.find('.children:eq(0)').detach();
      options.is_root = old_is_root;
      old.replaceWith(this.render(options));
      if (!(options != null) || !options.is_leaf) {
        return $("\#" + this.object._id).find('.children:eq(0)').replaceWith(children);
      }
    };
    Record.prototype.upvote = function(rid) {
      app.upvoted.push(rid);
      return $.ajax({
        cache: false,
        type: "POST",
        url: "/r/" + rid + "/upvote",
        dataType: "json",
        error: function() {
          return console.log('meh');
        },
        success: function(data) {}
      });
    };
    Record.prototype.show_reply_box = function(rid) {
      var container, kup, record_e;
      record_e = $('#' + rid);
      window.qwe = record_e;
      if (record_e.find('>.contents>.reply_box_container>.reply_box').length === 0) {
        kup = function() {
          return div({
            "class": "reply_box"
          }, function() {
            textarea({
              name: "comment"
            });
            br({
              foo: 'bar'
            });
            button({
              onclick: "app.post_reply('" + rid + "')"
            }, function() {
              return 'post comment';
            });
            return button({
              onclick: "$(this).parent().remove()"
            }, function() {
              return 'cancel';
            });
          });
        };
        container = record_e.find('>.contents>.reply_box_container').append(coffeekup.render(kup, {
          context: this,
          locals: {
            rid: rid
          },
          dynamic_locals: true
        }));
        return app.make_autoresizable(container.find('textarea'));
      }
    };
    Record.prototype.show_edit_box = function(rid) {
      var container, kup, record_e;
      record_e = $('#' + rid);
      if (record_e.find('>.contents>.edit_box_container>.edit_box').length === 0) {
        kup = function() {
          return div({
            "class": "edit_box"
          }, function() {
            textarea({
              name: "comment"
            });
            br({
              foo: 'bar'
            });
            button({
              onclick: "app.post_edit('" + rid + "')"
            }, function() {
              return 'update';
            });
            return button({
              onclick: "$(this).parent().remove()"
            }, function() {
              return 'cancel';
            });
          });
        };
        container = record_e.find('>.contents>.edit_box_container').append(coffeekup.render(kup, {
          context: this,
          locals: {
            rid: rid
          },
          dynamic_locals: true
        }));
        return app.make_autoresizable(container.find('textarea'));
      }
    };
    Record.prototype["delete"] = function(rid) {
      return alert('not implemented yet');
    };
    Record.prototype.post_reply = function(rid) {
      var comment, record_e;
      record_e = $('#' + rid);
      comment = record_e.find('>.contents>.reply_box_container>.reply_box>textarea').val();
      return $.ajax({
        cache: false,
        type: "POST",
        url: "/r/" + rid + "/reply",
        data: {
          comment: comment
        },
        dataType: "json",
        error: function() {
          return console.log('meh');
        },
        success: function(data) {
          if (data != null) {
            return record_e.find('>.contents>.reply_box_container>.reply_box').remove();
          } else {
            return alert('uh oh, server might be down. try again later?');
          }
        }
      });
    };
    return Record;
  })();
  dangle = function(records, root_id) {
    var id, parent, record, root;
    root = records[root_id];
    for (id in records) {
      record = records[id];
      parent = records[record.object.parent_id];
      if (parent) {
        if (!parent.children) {
          parent.children = [];
        }
        parent.children.push(record);
      }
    }
    return root;
  };
  if (typeof exports != "undefined" && exports !== null) {
    exports.Record = Record;
    exports.dangle = dangle;
  }
  if (typeof window != "undefined" && window !== null) {
    app.Record = Record;
    app.upvote = Record.prototype.upvote;
    app.show_reply_box = Record.prototype.show_reply_box;
    app.show_edit_box = Record.prototype.show_edit_box;
    app.post_reply = Record.prototype.post_reply;
    app.dangle = dangle;
  }
}).call(this);
