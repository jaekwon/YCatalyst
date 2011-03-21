(function() {
  /*
  # YCatalyst
  # Copyright(c) 2011 Jae Kwon (jae@ycatalyst.com)
  # MIT Licensed
  */  var Markz, REPLACE_LOOKUP, coffeekup, hE, re_blockquote, re_bold, re_codeblock, re_email, re_header, re_link, re_newline, re_olbullets, re_ulbullets, re_url;
  coffeekup = typeof CoffeeKup != "undefined" && CoffeeKup !== null ? CoffeeKup : require('./coffeekup');
  re_header = /^(\#{1,6})(.*)$\n?|^(.*)$\n^(={4,}|-{4,})$\n?/m;
  re_email = /(?:[\w\!\#\$\%\&\'\*\+\-\/\=\?\^\`\{\|\}\~]+\.)*[\w\!\#\$\%\&\'\*\+\-\/\=\?\^\`\{\|\}\~]+@(?:(?:(?:[a-zA-Z0-9](?:[a-zA-Z0-9\-](?!\.)){0,61}[a-zA-Z0-9]?\.)+[a-zA-Z0-9](?:[a-zA-Z0-9\-](?!$)){0,61}[a-zA-Z0-9]?)|(?:\[(?:(?:[01]?\d{1,2}|2[0-4]\d|25[0-5])\.){3}(?:[01]?\d{1,2}|2[0-4]\d|25[0-5])\]))/;
  re_url = /((?:ht|f)tp(?:s?)\:\/\/|~\/|\/)?(?:\w+:\w+@)?((?:(?:[-\w\d{1-3}]+\.)+(?:com|org|net|gov|mil|biz|info|mobi|name|aero|jobs|edu|co\.uk|ac\.uk|it|fr|tv|museum|asia|local|travel|[a-z]{2}))|((\b25[0-5]\b|\b[2][0-4][0-9]\b|\b[0-1]?[0-9]?[0-9]\b)(\.(\b25[0-5]\b|\b[2][0-4][0-9]\b|\b[0-1]?[0-9]?[0-9]\b)){3}))(?::[\d]{1,5})?(?:(?:(?:\/(?:[-\w~!$+|.,=]|%[a-f\d]{2})+)+|\/)+|\?|#)?(?:(?:\?(?:[-\w~!$+|.,*:]|%[a-f\d{2}])+=?(?:[-\w~!$+|.,*:=]|%[a-f\d]{2})*)(?:&(?:[-\w~!$+|.,*:]|%[a-f\d{2}])+=?(?:[-\w~!$+|.,*:=]|%[a-f\d]{2})*)*)*(?:#(?:[-\w~!$ |\/.,*:;=]|%[a-f\d]{2})*)?/;
  re_link = /\[([^\n\[\]]+)\] *\(([^\n\[\]]+)(?: +"([^\n\[\]]+)")?\)/;
  re_bold = /\*([^\*\n]+)\*/;
  re_newline = /\n/;
  re_ulbullets = /(?:^\* +.+$\n?){2,}/m;
  re_olbullets = /(?:^\d{1,2}\.? +.+$\n?){2,}/m;
  re_blockquote = /(?:^>.*$\n?)+/m;
  re_codeblock = /<code(?: +lang=['"]?(\w+)['"]?)?>([\s\S]*?)<\/code>\n?/;
  hE = function(text) {
    text = text.toString();
    return text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&#39;");
  };
  REPLACE_LOOKUP = [
    [
      'header', re_header, function(match) {
        var header_type;
        if (match[1]) {
          return "<h" + match[1].length + ">" + (hE(match[2])) + "</h" + match[1].length + ">";
        } else {
          header_type = match[4][0] === '=' ? 'h1' : 'h2';
          return "<" + header_type + ">" + (hE(match[3])) + "</" + header_type + ">";
        }
      }
    ], [
      'link', re_link, function(match) {
        return "<a href=\"" + (hE(match[2])) + "\" title=\"" + (hE(match[3] || '')) + "\">" + (hE(match[1])) + "</a>";
      }
    ], [
      'url', re_url, function(match) {
        if (match[1] && match[1].length > 0) {
          return "<a href=\"" + (hE(match[0])) + "\">" + (hE(match[0])) + "</a>";
        } else {
          return "<a href=\"http://" + (hE(match[0])) + "\">" + (hE(match[0])) + "</a>";
        }
      }
    ], [
      'email', re_email, function(match) {
        return "<a href=\"mailto:" + (hE(match[0])) + "\">" + (hE(match[0])) + "</a>";
      }
    ], [
      'blockquote', re_blockquote, function(match) {
        var line, unquoted;
        unquoted = ((function() {
          var _i, _len, _ref, _results;
          _ref = match[0].split("\n");
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            line = _ref[_i];
            _results.push(line.substr(1));
          }
          return _results;
        })()).join("\n");
        return "<blockquote>" + (Markz.prototype.markup(unquoted)) + "</blockquote>";
      }
    ], [
      'olbullets', re_olbullets, function(match) {
        var line, lines, markup_lines;
        lines = (function() {
          var _i, _len, _ref, _results;
          _ref = match[0].trim().split("\n");
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            line = _ref[_i];
            _results.push(line.substr(2).trim());
          }
          return _results;
        })();
        markup_lines = (function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = lines.length; _i < _len; _i++) {
            line = lines[_i];
            _results.push("<li><span class='back_to_black'>" + (Markz.prototype.markup(line)) + "</span></li>");
          }
          return _results;
        })();
        return "<ol>" + (markup_lines.join('')) + "</ol>";
      }
    ], [
      'ulbullets', re_ulbullets, function(match) {
        var line, lines, markup_lines;
        lines = (function() {
          var _i, _len, _ref, _results;
          _ref = match[0].trim().split("\n");
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            line = _ref[_i];
            _results.push(line.substr(1).trim());
          }
          return _results;
        })();
        markup_lines = (function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = lines.length; _i < _len; _i++) {
            line = lines[_i];
            _results.push("<li><span class='back_to_black'>" + (Markz.prototype.markup(line)) + "</span></li>");
          }
          return _results;
        })();
        return "<ul>" + (markup_lines.join('')) + "</ul>";
      }
    ], [
      'bold', re_bold, function(match) {
        return "<b>" + (Markz.prototype.markup(match[1])) + "</b>";
      }
    ], [
      'newline', re_newline, function(match) {
        return "<br/>";
      }
    ], [
      'codeblock', re_codeblock, function(match) {
        return "<pre class='brush: " + (match[1] || 'coffeescript') + "'>" + (hE(match[2])) + "</pre>";
      }
    ]
  ];
  Markz = (function() {
    function Markz() {}
    Markz.prototype.markup = function(text) {
      var coll, cursor, find_next_match, next_match, type2match;
      type2match = {};
      find_next_match = function(type2match, text, cursor) {
        var earliest, func, match, regex, stuff, type, type_regex_func, _i, _len;
        for (_i = 0, _len = REPLACE_LOOKUP.length; _i < _len; _i++) {
          type_regex_func = REPLACE_LOOKUP[_i];
          type = type_regex_func[0], regex = type_regex_func[1], func = type_regex_func[2];
          if (type2match[type] != null) {
            if (type2match[type].offset < cursor) {
              delete type2match[type];
            } else {
              continue;
            }
          }
          match = text.substr(cursor).match(regex);
          if (match != null) {
            type2match[type] = {
              match: match,
              func: func,
              type: type,
              offset: match.index + cursor
            };
          }
        }
        earliest = null;
        for (type in type2match) {
          stuff = type2match[type];
          if (!(earliest != null)) {
            earliest = stuff;
          } else if (stuff.offset < earliest.offset) {
            earliest = stuff;
          }
        }
        return earliest;
      };
      cursor = 0;
      coll = [];
      while (true) {
        next_match = find_next_match(type2match, text, cursor);
        if (!(next_match != null)) {
          break;
        }
        if (next_match.offset > cursor) {
          coll.push(hE(text.substr(cursor, next_match.offset - cursor)));
        }
        coll.push(next_match.func(next_match.match));
        cursor = next_match.offset + next_match.match[0].length;
      }
      coll.push(hE(text.substr(cursor)));
      return coll.join(" ");
    };
    return Markz;
  })();
  if (typeof exports != "undefined" && exports !== null) {
    exports.Markz = Markz;
    exports.hE = hE;
  }
  if (typeof window != "undefined" && window !== null) {
    window.Markz = Markz;
    window.hE = hE;
  }
}).call(this);
