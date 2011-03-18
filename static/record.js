(function() {
  /*
  # YCatalyst
  # Copyright(c) 2011 Jae Kwon (jae@ycatalyst.com)
  # MIT Licensed
  */  var CoffeeKup, Markz, Record;
  CoffeeKup = typeof window != "undefined" && window !== null ? window.CoffeeKup : require('./coffeekup');
  Markz = typeof window != "undefined" && window !== null ? window.Markz : require('./markz').Markz;
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
      } else if (typeof this.object.created_at === 'string') {
        this.object.created_at = new Date(this.object.created_at);
      }
    }
    Record.prototype.render_kup = function() {
      return div({
        "class": "record",
        id: this.object._id,
        "data-root": is_root,
        "data-upvoted": upvoted,
        "data-following": following
      }, function() {
        if (!(this.object.deleted_at != null)) {
          if (current_user) {
            if (this.object.created_by === current_user.username && this.object.type !== 'choice') {
              span({
                "class": "self_made"
              }, function() {
                return "*";
              });
            } else if (!upvoted) {
              a({
                "class": "upvote",
                href: '#',
                onclick: "Record.upvote('" + this.object._id + "'); return false;"
              }, function() {
                return "&#9650;";
              });
            }
          }
          if (this.object.title) {
            if (this.object.url) {
              a({
                href: this.object.url,
                "class": "title"
              }, function() {
                return this.object.title;
              });
              if (this.object.host) {
                span({
                  "class": "host"
                }, function() {
                  return "&nbsp;(" + this.object.host + ")";
                });
              }
            } else {
              a({
                href: "/r/" + this.object._id,
                "class": "title"
              }, function() {
                return this.object.title;
              });
            }
            br({
              foo: "bar"
            });
          }
          span({
            "class": "item_info"
          }, function() {
            span(function() {
              return " " + (this.object.points || 0) + " pts ";
            });
            if (this.object.type !== 'choice') {
              text(" by ");
              a({
                href: "/user/" + (h(this.object.created_by))
              }, function() {
                return h(this.object.created_by);
              });
              span(function() {
                return " " + this.object.created_at.time_ago();
              });
              text(" | ");
            }
            if (is_root && this.object.parent_id) {
              a({
                "class": "parent",
                href: "/r/" + this.object.parent_id
              }, function() {
                return "parent";
              });
              text(" | ");
            }
            if (this.object.type !== 'choice') {
              a({
                "class": "link",
                href: "/r/" + this.object._id
              }, function() {
                return "link";
              });
            }
            if (current_user && this.object.type !== 'choice') {
              text(" | ");
              if (following) {
                a({
                  "class": "follow unfollow",
                  href: "#",
                  onclick: "Record.follow('" + this.object._id + "', false); return false;"
                }, function() {
                  return "unfollow";
                });
              } else {
                a({
                  "class": "follow",
                  href: "#",
                  onclick: "Record.follow('" + this.object._id + "', true); return false;"
                }, function() {
                  return "follow";
                });
              }
            }
            if (current_user && this.object.created_by === current_user.username) {
              text(" | ");
              a({
                "class": "edit",
                href: "#",
                onclick: "Record.show_edit_box('" + this.object._id + "'); return false;"
              }, function() {
                return "edit";
              });
              text(" | ");
              return a({
                "class": "delete",
                href: "#",
                onclick: "Record.delete('" + this.object._id + "'); return false;"
              }, function() {
                return "delete";
              });
            }
          });
          div({
            "class": "contents"
          }, function() {
            if (this.object.comment) {
              text(Markz.prototype.markup(this.object.comment));
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
                  if (choice.object.deleted_at != null) {
                    continue;
                  }
                  _results.push(text(choice.render({
                    is_root: false,
                    current_user: current_user
                  })));
                }
                return _results;
              });
            }
          });
          div({
            "class": "footer"
          }, function() {
            if (current_user && this.object.type === 'poll' && this.object.created_by === current_user.username) {
              a({
                "class": "addchoice",
                href: "#",
                onclick: "Record.show_reply_box('" + this.object._id + "', {choice: true}); return false;"
              }, function() {
                return "add choice";
              });
            }
            if (this.object.type !== 'choice') {
              a({
                "class": "reply",
                href: "/r/" + this.object._id + "/reply",
                onclick: "Record.show_reply_box('" + this.object._id + "'); return false;"
              }, function() {
                return "reply";
              });
            }
            div({
              "class": "edit_box_container"
            });
            if (this.object.type !== 'choice') {
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
        if (this.object.type !== 'choice') {
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
        }
      });
    };
    Record.prototype.render = function(options) {
      var current_user, following, is_root, upvoted;
      is_root = !(options != null) || options.is_root;
      if (options != null) {
        current_user = options.current_user;
      }
      upvoted = typeof window != "undefined" && window !== null ? App.upvoted.indexOf(this.object._id) !== -1 : current_user ? (this.object.upvoters != null) && this.object.upvoters.indexOf(current_user._id) !== -1 : void 0;
      following = typeof window != "undefined" && window !== null ? App.following.indexOf(this.object._id) !== -1 : current_user ? (this.object.followers != null) && this.object.followers.indexOf(current_user._id) !== -1 : void 0;
      return CoffeeKup.render(this.render_kup, {
        context: this,
        locals: {
          Markz: Markz,
          is_root: is_root,
          upvoted: upvoted,
          following: following,
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
        if (current_user) {
          if (this.object.created_by === current_user.username && this.object.type !== 'choice') {
            span({
              "class": "self_made"
            }, function() {
              return "*";
            });
          } else if (!upvoted) {
            a({
              "class": "upvote",
              href: '#',
              onclick: "Record.upvote('" + this.object._id + "'); $(this).parent().find('>.item_info>.points').increment(); $(this).remove(); return false;"
            }, function() {
              return "&#9650;";
            });
          }
        }
        if (this.object.url) {
          a({
            href: this.object.url,
            "class": "title"
          }, function() {
            return this.object.title;
          });
          if (this.object.host) {
            span({
              "class": "host"
            }, function() {
              return "&nbsp;(" + this.object.host + ")";
            });
          }
        } else {
          a({
            href: "/r/" + this.object._id,
            "class": "title"
          }, function() {
            return this.object.title;
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
            return "" + (this.object.points || 0);
          });
          span(function() {
            return " pts by ";
          });
          a({
            href: "/user/" + (h(this.object.created_by))
          }, function() {
            return h(this.object.created_by);
          });
          span(function() {
            return " " + this.object.created_at.time_ago();
          });
          text(" | ");
          if (this.object.num_discussions) {
            return a({
              href: "/r/" + this.object._id
            }, function() {
              return "" + this.object.num_discussions + " comments";
            });
          } else {
            return a({
              href: "/r/" + this.object._id
            }, function() {
              return "discuss";
            });
          }
        });
      });
    };
    Record.prototype.render_headline = function(options) {
      var current_user, upvoted;
      if (options != null) {
        current_user = options.current_user;
      }
      upvoted = typeof window != "undefined" && window !== null ? App.upvoted.indexOf(this.object._id) !== -1 : current_user ? (this.object.upvoters != null) && this.object.upvoters.indexOf(current_user._id) !== -1 : void 0;
      return CoffeeKup.render(this.render_headline_kup, {
        context: this,
        locals: {
          Markz: Markz,
          upvoted: upvoted,
          current_user: current_user
        },
        dynamic_locals: true
      });
    };
    Record.prototype.comment_url = function() {
      return "/r/" + this.object._id + "/reply";
    };
    Record.prototype.redraw = function(options) {
      var children, choices, old, old_is_root;
      old = $("\#" + this.object._id);
      old_is_root = old.attr('data-root') === "true";
      choices = old.find('>.contents>.choices').detach();
      children = old.find('>.children').detach();
      options.is_root = old_is_root;
      old.replaceWith(this.render(options));
      if (choices.length > 0) {
        $("\#" + this.object._id).find('>.contents').append(choices);
      }
      if (!(options != null) || !options.is_leaf) {
        return $("\#" + this.object._id).find('>.children').replaceWith(children);
      }
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
        success: function(data) {}
      });
    };
    Record.prototype.show_reply_box = function(rid, options) {
      var container, kup, record_e;
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
            if ((options != null) && options.choice) {
              button({
                onclick: "Record.post_reply('" + rid + "', 'choice')"
              }, function() {
                return 'add choice';
              });
            } else {
              button({
                onclick: "Record.post_reply('" + rid + "')"
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
          context: this,
          locals: {
            rid: rid,
            options: options
          },
          dynamic_locals: true
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
                if (!data.record.parent_id) {
                  input({
                    type: "text",
                    name: "title",
                    value: hE(data.record.title || '')
                  });
                  br({
                    foo: 'bar'
                  });
                  input({
                    type: "text",
                    name: "url",
                    value: hE(data.record.url || '')
                  });
                  br({
                    foo: 'bar'
                  });
                  textarea({
                    name: "comment"
                  }, function() {
                    return hE(data.record.comment || '');
                  });
                } else {
                  textarea({
                    name: "comment"
                  }, function() {
                    return hE(data.record.comment || '');
                  });
                }
                br({
                  foo: 'bar'
                });
                button({
                  onclick: "Record.post_edit('" + rid + "')"
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
              context: this,
              locals: {
                rid: rid,
                data: data
              },
              dynamic_locals: true
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
            return record_e.find('>.footer>.reply_box_container>.reply_box').remove();
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
            return record_e.find('>.footer>.edit_box_container>.edit_box').remove();
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
