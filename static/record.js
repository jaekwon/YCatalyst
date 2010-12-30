(function() {
  var Record, dangle, escape, hE;
  escape = hE = function(html) {
    return String(html).replace(/&(?!\w+;)/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  };
  Record = (function() {
    function Record(object) {
      this.object = object;
    }
    Record.prototype.render = function(options) {
      var child, data_parents, is_root, lines, top_links, _i, _len, _ref;
      is_root = !(options != null) || options.is_root;
      lines = [];
      top_links = [];
      data_parents = [];
      if (is_root) {
        data_parents = "data-parents=\"" + (hE(JSON.stringify(this.object.parents))) + "\"";
      }
      if (is_root && this.object.parent_id) {
        top_links.push("<a href=\"/r/" + this.object.parent_id + "\" class=\"parent\">parent</a>");
      }
      top_links.push("<a href=\"/r/" + this.object._id + "\" class=\"link\">link</a>");
      top_links.push("" + (hE(JSON.stringify(this.object.parents))));
      lines.push("<span class=\"top_links\">" + (top_links.join(" | ")) + "</span>");
      lines.push("<p>" + (hE(this.object.comment)) + "</p>");
      lines.push("<a href=\"/r/" + this.object._id + "/reply\" class=\"reply\">reply</a>");
      lines.push("<div class=\"children\">");
      if (this.children) {
        _ref = this.children;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          child = _ref[_i];
          lines.push(child.render({
            is_root: false
          }));
        }
      }
      lines.push("</div>");
      return "<div class=\"record\" id=\"" + this.object._id + "\" " + data_parents + " " + (is_root ? 'data-root="true"' : void 0) + ">\n  " + (lines.join("\n")) + "\n</div>";
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
