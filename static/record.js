(function() {
  /*
  # YCatalyst
  # Copyright(c) 2011 Jae Kwon (jae@ycatalyst.com)
  # MIT Licensed
  */  var CoffeeKup, Markz, Record, coffeekup_locals, compose;
  var __slice = Array.prototype.slice, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  CoffeeKup = typeof window != "undefined" && window !== null ? window.CoffeeKup : require('./coffeekup');
  Markz = typeof window != "undefined" && window !== null ? window.Markz : require('./markz').Markz;
  compose = function() {
    var fns, next_gen, _this;
    fns = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    _this = typeof fns[0] === 'function' ? null : fns.shift();
    next_gen = function(index) {
      return function() {
        var next_block;
        if (!((0 <= index && index < fns.length))) {
          throw new Error("should not happen: 0 <= " + index + " < " + fns.length);
        }
        next_block = fns[index];
        if (index < fns.length - 1) {
          Array.prototype.unshift.call(arguments, next_gen(index + 1));
        }
        return next_block.apply(_this, arguments);
      };
    };
    return next_gen(0)();
  };
  coffeekup_locals = {
    Markz: Markz,
    compose: compose
  };
  Date.prototype.time_ago = function() {
    var difference;
    difference = (new Date()) - this;
    if (difference < 60 * 1000) {
      return "a moment ago";
    }
    if (difference < 60 * 60 * 1000) {
      return Math.floor(difference / (60 * 1000)) + " minutes ago";
    }
    if (difference < 2 * 60 * 60 * 1000) {
      return "1 hour ago";
    }
    if (difference < 24 * 60 * 60 * 1000) {
      return Math.floor(difference / (60 * 60 * 1000)) + " hours ago";
    }
    if (difference < 2 * 24 * 60 * 60 * 1000) {
      return "1 day ago";
    }
    if (difference < 30 * 24 * 60 * 60 * 1000) {
      return Math.floor(difference / (24 * 60 * 60 * 1000)) + " days ago";
    }
    if (difference < 2 * 30 * 24 * 60 * 60 * 1000) {
      return "1 month ago";
    }
    if (difference < 365 * 24 * 60 * 60 * 1000) {
      return Math.floor(difference / (30 * 24 * 60 * 60 * 1000)) + " months ago";
    }
    if (difference < 2 * 365 * 24 * 60 * 60 * 1000) {
      return "1 year ago";
    }
    return Math.floor(difference / (365 * 24 * 60 * 60 * 1000)) + " years ago";
  };
  Record = (function() {
    function Record(recdata) {
      this.recdata = recdata;
      if (!(this.recdata.points != null)) {
        this.recdata.points = 0;
      }
      if (!(this.recdata.num_children != null)) {
        this.recdata.num_children = 0;
      }
      if (!(this.recdata.created_at != null)) {
        this.recdata.created_at = new Date();
      } else if (typeof this.recdata.created_at === 'string') {
        this.recdata.created_at = new Date(this.recdata.created_at);
      }
    }
    Record.prototype.set_render_options = function(options) {
      this.is_root = options.is_root || false;
      this.heading_title = options.heading_title || false;
      this.current_user = options.current_user || null;
      this.upvoted = typeof window != "undefined" && window !== null ? App.upvoted.indexOf(this.recdata._id) !== -1 : this.current_user ? (this.recdata.upvoters != null) && this.recdata.upvoters.indexOf(this.current_user._id) !== -1 : void 0;
      return this.following = typeof window != "undefined" && window !== null ? App.following.indexOf(this.recdata._id) !== -1 : this.current_user ? (this.recdata.followers != null) && this.recdata.followers.indexOf(this.current_user._id) !== -1 : void 0;
    };
    Record.prototype.render = function(coffeekup_name, options) {
      var coffeekup_fn;
      if (!(typeof coffeekup_name === "string")) {
        throw "invalid template name " + (JSON.stringify(coffeekup_name));
      }
      if (options) {
        this.set_render_options(options);
      }
      coffeekup_fn = this[coffeekup_name + "_kup"];
      return CoffeeKup.render(coffeekup_fn, {
        context: this,
        locals: coffeekup_locals,
        dynamic_locals: true
      });
    };
    Record.prototype.default_kup = function() {
      return div({
        "class": "record",
        id: this.recdata._id,
        "data-root": this.is_root,
        "data-upvoted": this.upvoted,
        "data-following": this.following,
        "data-heading-title": this.heading_title
      }, function() {
        if (!(this.recdata.deleted_at != null)) {
          if (this.current_user) {
            if (this.recdata.created_by === this.current_user.username && this.recdata.type !== 'choice') {
              span({
                "class": "self_made"
              }, function() {
                return "*";
              });
            } else if (!this.upvoted) {
              a({
                "class": "upvote",
                href: '#',
                onclick: "Record.upvote('" + this.recdata._id + "'); return false;"
              }, function() {
                return "&#9650;";
              });
            }
          }
          if (this.recdata.title) {
            compose(__bind(function(next) {
              if (this.heading_title) {
                return h1({
                  "class": "title"
                }, function() {
                  return next();
                });
              } else {
                next();
                return br({
                  foo: "bar"
                });
              }
            }, this), __bind(function() {
              if (this.recdata.url) {
                a({
                  href: this.recdata.url,
                  "class": "title"
                }, function() {
                  return this.recdata.title;
                });
                if (this.recdata.host) {
                  return span({
                    "class": "host"
                  }, function() {
                    return "&nbsp;(" + this.recdata.host + ")";
                  });
                }
              } else {
                return a({
                  href: "/r/" + this.recdata._id,
                  "class": "title"
                }, function() {
                  return this.recdata.title;
                });
              }
            }, this));
          }
          span({
            "class": "item_info"
          }, function() {
            span(function() {
              return " " + (this.recdata.points || 0) + " pts ";
            });
            if (this.recdata.type !== 'choice') {
              text(" by ");
              a({
                href: "/user/" + (h(this.recdata.created_by))
              }, function() {
                return h(this.recdata.created_by);
              });
              span(function() {
                return " " + this.recdata.created_at.time_ago();
              });
              text(" | ");
            }
            if (this.is_root && this.recdata.parent_id) {
              a({
                "class": "parent",
                href: "/r/" + this.recdata.parent_id
              }, function() {
                return "parent";
              });
              text(" | ");
            }
            if (this.recdata.type !== 'choice') {
              a({
                "class": "link",
                href: "/r/" + this.recdata._id
              }, function() {
                return "link";
              });
            }
            if (this.current_user && this.recdata.type !== 'choice') {
              text(" | ");
              if (this.following) {
                a({
                  "class": "follow unfollow",
                  href: "#",
                  onclick: "Record.follow('" + this.recdata._id + "', false); return false;"
                }, function() {
                  return "unfollow";
                });
              } else {
                a({
                  "class": "follow",
                  href: "#",
                  onclick: "Record.follow('" + this.recdata._id + "', true); return false;"
                }, function() {
                  return "follow";
                });
              }
            }
            if (this.current_user && this.recdata.created_by === this.current_user.username) {
              text(" | ");
              a({
                "class": "edit",
                href: "#",
                onclick: "Record.show_edit_box('" + this.recdata._id + "'); return false;"
              }, function() {
                return "edit";
              });
              text(" | ");
              return a({
                "class": "delete",
                href: "#",
                onclick: "Record.delete('" + this.recdata._id + "'); return false;"
              }, function() {
                return "delete";
              });
            }
          });
          div({
            "class": "contents"
          }, function() {
            if (this.recdata.comment) {
              text(Markz.prototype.markup(this.recdata.comment));
            }
            if (this.choices) {
              return div({
                "class": "choices"
              }, function() {
                var choice, _i, _len, _ref, _results;
                _ref = this.choices;
                _results = [];
                for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                  choice = _ref[_i];
                  if (choice.recdata.deleted_at != null) {
                    continue;
                  }
                  _results.push(text(choice.render("default", {
                    current_user: this.current_user
                  })));
                }
                return _results;
              });
            }
          });
          div({
            "class": "footer"
          }, function() {
            if (this.current_user && this.recdata.type === 'poll' && this.recdata.created_by === this.current_user.username) {
              a({
                "class": "addchoice",
                href: "#",
                onclick: "Record.show_reply_box('" + this.recdata._id + "', {is_choice: true}); return false;"
              }, function() {
                return "add choice";
              });
            }
            if (this.recdata.type !== 'choice') {
              a({
                "class": "reply",
                href: "/r/" + this.recdata._id + "/reply",
                onclick: "Record.show_reply_box('" + this.recdata._id + "'); return false;"
              }, function() {
                return "reply";
              });
            }
            div({
              "class": "edit_box_container"
            });
            if (this.recdata.type !== 'choice') {
              return div({
                "class": "reply_box_container"
              });
            }
          });
        } else {
          div({
            "class": "contents deleted"
          }, function() {
            return "[deleted]";
          });
        }
        if (this.recdata.type !== 'choice') {
          return div({
            "class": "children"
          }, function() {
            var child, loaded_children, show_more_link, _i, _len, _ref;
            if (this.children) {
              _ref = this.children;
              for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                child = _ref[_i];
                text(child.render("default", {
                  current_user: this.current_user
                }));
              }
            }
            loaded_children = this.children ? this.children.length : 0;
            show_more_link = loaded_children < this.recdata.num_children;
            return a({
              "class": "more " + (!show_more_link ? 'hidden' : void 0),
              href: "/r/" + this.recdata._id
            }, function() {
              span({
                "class": "number"
              }, function() {
                return "" + (this.recdata.num_children - loaded_children);
              });
              return text(" more replies");
            });
          });
        }
      });
    };
    Record.prototype.headline_kup = function() {
      return div({
        "class": "record",
        id: this.recdata._id
      }, function() {
        if (this.current_user) {
          if (this.recdata.created_by === this.current_user.username && this.recdata.type !== 'choice') {
            span({
              "class": "self_made"
            }, function() {
              return "*";
            });
          } else if (!this.upvoted) {
            a({
              "class": "upvote",
              href: '#',
              onclick: "Record.upvote('" + this.recdata._id + "'); $(this).parent().find('>.item_info>.points').increment(); $(this).remove(); return false;"
            }, function() {
              return "&#9650;";
            });
          }
        }
        if (this.recdata.url) {
          a({
            href: this.recdata.url,
            "class": "title"
          }, function() {
            return this.recdata.title;
          });
          if (this.recdata.host) {
            span({
              "class": "host"
            }, function() {
              return "&nbsp;(" + this.recdata.host + ")";
            });
          }
        } else {
          a({
            href: "/r/" + this.recdata._id,
            "class": "title"
          }, function() {
            return this.recdata.title;
          });
        }
        br({
          foo: "bar"
        });
        return span({
          "class": "item_info"
        }, function() {
          span({
            "class": "points"
          }, function() {
            return "" + (this.recdata.points || 0);
          });
          span(function() {
            return " pts by ";
          });
          a({
            href: "/user/" + (h(this.recdata.created_by))
          }, function() {
            return h(this.recdata.created_by);
          });
          span(function() {
            return " " + this.recdata.created_at.time_ago();
          });
          text(" | ");
          if (this.recdata.num_discussions) {
            return a({
              href: "/r/" + this.recdata._id
            }, function() {
              return "" + this.recdata.num_discussions + " comments";
            });
          } else {
            return a({
              href: "/r/" + this.recdata._id
            }, function() {
              return "discuss";
            });
          }
        });
      });
    };
    Record.prototype.comment_url = function() {
      return "/r/" + this.recdata._id + "/reply";
    };
    Record.prototype.redraw = function(options) {
      var children, choices, old;
      old = $("\#" + this.recdata._id);
      choices = old.find('>.contents>.choices').detach();
      children = old.find('>.children').detach();
      options.is_root = old.attr('data-root') === 'true';
      options.heading_title = old.attr('data-heading-title') === 'true';
      old.replaceWith(this.render("default", options));
      if (choices.length > 0) {
        $("\#" + this.recdata._id).find('>.contents').append(choices);
      }
      return $("\#" + this.recdata._id).find('>.children').replaceWith(children);
    };
    Record.prototype.upvote = function(rid) {
      App.upvoted.push(rid);
      return $.ajax({
        cache: false,
        type: "POST",
        url: "/r/" + rid + "/upvote",
        dataType: "json",
        error: function() {
          return console.log('meh');
        },
        success: function(data) {
          if (data && data.updates && !App.is_longpolling) {
            return App.handle_updates(data.updates);
          }
        }
      });
    };
    Record.prototype.show_reply_box = function(rid, options) {
      var container, kup, record_e;
      options || (options = {});
      if (!App.current_user) {
        window.location = "/login?goto=/r/" + rid + "/reply";
        return;
      }
      record_e = $('#' + rid);
      if (record_e.find('>.footer>.reply_box_container>.reply_box').length === 0) {
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
            if (this.is_choice) {
              button({
                onclick: "Record.post_reply('" + this.rid + "', 'choice')"
              }, function() {
                return 'add choice';
              });
            } else {
              button({
                onclick: "Record.post_reply('" + this.rid + "')"
              }, function() {
                return 'post comment';
              });
            }
            return button({
              onclick: "$(this).parent().remove()"
            }, function() {
              return 'cancel';
            });
          });
        };
        container = record_e.find('>.footer>.reply_box_container').append(CoffeeKup.render(kup, {
          context: {
            rid: rid,
            is_choice: options.is_choice
          }
        }));
        return container.find('textarea').make_autoresizable();
      }
    };
    Record.prototype.show_edit_box = function(rid) {
      var record_e;
      record_e = $('#' + rid);
      if (record_e.find('>.footer>.edit_box_container>.edit_box').length === 0) {
        return $.ajax({
          cache: false,
          type: "GET",
          url: "/r/" + rid,
          dataType: "json",
          error: function() {
            return console.log('meh');
          },
          success: function(data) {
            var container, kup;
            kup = function() {
              return div({
                "class": "edit_box"
              }, function() {
                if (!this.data.record.parent_id) {
                  input({
                    type: "text",
                    name: "title",
                    value: hE(this.data.record.title || '')
                  });
                  br({
                    foo: 'bar'
                  });
                  input({
                    type: "text",
                    name: "url",
                    value: hE(this.data.record.url || '')
                  });
                  br({
                    foo: 'bar'
                  });
                  textarea({
                    name: "comment"
                  }, function() {
                    return hE(this.data.record.comment || '');
                  });
                } else {
                  textarea({
                    name: "comment"
                  }, function() {
                    return hE(this.data.record.comment || '');
                  });
                }
                br({
                  foo: 'bar'
                });
                button({
                  onclick: "Record.post_edit('" + this.rid + "')"
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
            container = record_e.find('>.footer>.edit_box_container').append(CoffeeKup.render(kup, {
              context: {
                rid: rid,
                data: data
              }
            }));
            container.find('textarea').make_autoresizable();
            container.find('input[name="title"]').set_default_text('title');
            container.find('input[name="url"]').set_default_text('URL');
            return container.find('textarea[name="comment"]').set_default_text('comment');
          }
        });
      }
    };
    Record.prototype["delete"] = function(rid) {
      return $.ajax({
        cache: false,
        type: "POST",
        url: "/r/" + rid + "/delete",
        datatype: "json",
        error: function() {
          return console.log('meh');
        },
        success: function(data) {
          return console.log('deleted');
        }
      });
    };
    Record.prototype.post_reply = function(rid, type) {
      var comment, record_e;
      record_e = $('#' + rid);
      comment = record_e.find('>.footer>.reply_box_container>.reply_box>textarea').val();
      return $.ajax({
        cache: false,
        type: "POST",
        url: "/r/" + rid + "/reply",
        data: {
          comment: comment,
          type: type
        },
        dataType: "json",
        error: function() {
          return console.log('meh');
        },
        success: function(data) {
          if (data != null) {
            record_e.find('>.footer>.reply_box_container>.reply_box').remove();
            if (data.updates && !App.is_longpolling) {
              return App.handle_updates(data.updates);
            }
          } else {
            return alert('uh oh, server might be down. try again later?');
          }
        }
      });
    };
    Record.prototype.post_edit = function(rid) {
      var comment, record_e, title, url;
      record_e = $('#' + rid);
      title = record_e.find('>.footer>.edit_box_container>.edit_box>input[name="title"]').get_value();
      url = record_e.find('>.footer>.edit_box_container>.edit_box>input[name="url"]').get_value();
      comment = record_e.find('>.footer>.edit_box_container>.edit_box>textarea[name="comment"]').get_value();
      return $.ajax({
        cache: false,
        type: "POST",
        url: "/r/" + rid,
        data: {
          title: title,
          url: url,
          comment: comment
        },
        dataType: "json",
        error: function() {
          return console.log('meh');
        },
        success: function(data) {
          if (data != null) {
            record_e.find('>.footer>.edit_box_container>.edit_box').remove();
            if (data.updates && !App.is_longpolling) {
              return App.handle_updates(data.updates);
            }
          } else {
            return alert('uh oh, server might be down. try again later?');
          }
        }
      });
    };
    Record.prototype.follow = function(rid, do_follow) {
      var record_e;
      record_e = $('#' + rid);
      return $.ajax({
        cache: false,
        type: "POST",
        url: "/r/" + rid + "/follow",
        data: {
          follow: do_follow
        },
        dataType: "json",
        error: function() {
          return console.log('meh');
        },
        success: function(data) {
          var x;
          if (data != null) {
            if (do_follow) {
              App.following.push(rid);
              return record_e.attr('data-following', true).find('>.item_info>.follow').addClass('unfollow').unbind('click').attr('onclick', null).click(function(event) {
                Record.follow(rid, false);
                return false;
              }).text('unfollow');
            } else {
              App.following = (function() {
                var _i, _len, _ref, _results;
                _ref = App.following;
                _results = [];
                for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                  x = _ref[_i];
                  if (x !== rid) {
                    _results.push(x);
                  }
                }
                return _results;
              })();
              return record_e.attr('data-following', false).find('>.item_info>.follow').removeClass('unfollow').unbind('click').attr('onclick', null).click(function(event) {
                Record.follow(rid, true);
                return false;
              }).text('follow');
            }
          } else {
            return alert('uh oh, server might be down. try again later?');
          }
        }
      });
    };
    return Record;
  })();
  if (typeof exports != "undefined" && exports !== null) {
    exports.Record = Record;
  }
  if (typeof window != "undefined" && window !== null) {
    window.Record = Record;
    Record.upvote = Record.prototype.upvote;
    Record.follow = Record.prototype.follow;
    Record.show_reply_box = Record.prototype.show_reply_box;
    Record.show_edit_box = Record.prototype.show_edit_box;
    Record.post_reply = Record.prototype.post_reply;
    Record.post_edit = Record.prototype.post_edit;
    Record["delete"] = Record.prototype["delete"];
  }
}).call(this);
