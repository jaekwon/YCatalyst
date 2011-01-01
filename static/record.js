(function() {
  var Record, app, coffeekup, dangle;
  coffeekup = typeof CoffeeKup != "undefined" && CoffeeKup !== null ? CoffeeKup : require('coffeekup');
  app = typeof window != "undefined" && window !== null ? window.app : require('../app');
  Record = (function() {
    function Record(object) {
      this.object = object;
      if (!(this.object.points != null)) {
        this.object.points = 0;
      }
      if (!(this.object.num_children != null)) {
        this.object.num_children = 0;
      }
    }
    Record.prototype.render_kup = function() {
      console.log("hide_upvote: " + hide_upvote);
      return div({
        "class": "record",
        id: this.object._id,
        "data-parents": JSON.stringify(this.object.parents),
        "data-root": is_root
      }, function() {
        span({
          "class": "top_items"
        }, function() {
          if (!hide_upvote) {
            a({
              "class": "upvote",
              href: '#',
              onclick: "app.upvote('" + (h(this.object._id)) + "'); return false;"
            }, function() {
              return "&spades;";
            });
          }
          span(function() {
            return " " + (this.object.points || 0) + " pts";
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
          return a({
            "class": "link",
            href: "/r/" + this.object._id
          }, function() {
            return "link";
          });
        });
        p(function() {
          text(h(this.object.comment));
          text(" ");
          return a({
            "class": "reply",
            href: "/r/" + this.object._id + "/reply"
          }, function() {
            return "reply";
          });
        });
        return div({
          "class": "children"
        }, function() {
          var child, _i, _len, _ref, _results;
          if (this.children) {
            _ref = this.children;
            _results = [];
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              child = _ref[_i];
              _results.push(text(child.render({
                is_root: false
              })));
            }
            return _results;
          }
        });
      });
    };
    Record.prototype.render = function(options) {
      var hide_upvote, is_root;
      is_root = !(options != null) || options.is_root;
      hide_upvote = options != null ? options.hide_upvote : void 0;
      if ((this.object.upvoters != null) && this.object.upvoters.indexOf(app.current_user) !== -1) {
        hide_upvote = true;
      }
      return coffeekup.render(this.render_kup, {
        context: this,
        locals: {
          is_root: is_root,
          hide_upvote: hide_upvote
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
      recdata.parents = parents;
      record = new Record(recdata);
      record.is_new = true;
      return record;
    };
    Record.prototype.redraw = function() {
      var children, old, old_is_root;
      old = $("\#" + this.object._id);
      old_is_root = old.attr('data-root') === "true";
      children = old.find('.children:eq(0)').detach();
      old.replaceWith(this.render({
        is_root: old_is_root
      }));
      return $("\#" + this.object._id).find('.children:eq(0)').replaceWith(children);
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
    if (!(window.app != null)) {
      window.app = {};
    }
    window.app.Record = Record;
    window.app.dangle = dangle;
  }
}).call(this);
