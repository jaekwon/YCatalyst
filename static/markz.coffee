###
# YCatalyst
# Copyright(c) 2011 Jae Kwon (jae@ycatalyst.com)
# MIT Licensed
###

coffeekup = if CoffeeKup? then CoffeeKup else require './coffeekup'

# some regexes ripped from the node.js validator project
# https://github.com/chriso/node-validator.git
# NOTE: > The /m flag is multiline matching.
#       > (?!...) is a negative lookahead.
#       > The only way to match a multi-line spanning pattern is to use [\s\S] type classes.
#       * Try to capture the trailing newline of block elements like codeblocks.
# TODO: possibly convert all to XRegExp for client compatibility, or at least support it.
re_header = /^(\#{1,6})(.*)$\n?|^(.*)$\n^(={4,}|-{4,})$\n?/m
re_email = /(?:[\w\!\#\$\%\&\'\*\+\-\/\=\?\^\`\{\|\}\~]+\.)*[\w\!\#\$\%\&\'\*\+\-\/\=\?\^\`\{\|\}\~]+@(?:(?:(?:[a-zA-Z0-9](?:[a-zA-Z0-9\-](?!\.)){0,61}[a-zA-Z0-9]?\.)+[a-zA-Z0-9](?:[a-zA-Z0-9\-](?!$)){0,61}[a-zA-Z0-9]?)|(?:\[(?:(?:[01]?\d{1,2}|2[0-4]\d|25[0-5])\.){3}(?:[01]?\d{1,2}|2[0-4]\d|25[0-5])\]))/
re_url = /((?:ht|f)tp(?:s?)\:\/\/|~\/|\/)?(?:\w+:\w+@)?((?:(?:[-\w\d{1-3}]+\.)+(?:com|org|net|gov|mil|biz|info|mobi|name|aero|jobs|edu|co\.uk|ac\.uk|it|fr|tv|museum|asia|local|travel|[a-z]{2}))|((\b25[0-5]\b|\b[2][0-4][0-9]\b|\b[0-1]?[0-9]?[0-9]\b)(\.(\b25[0-5]\b|\b[2][0-4][0-9]\b|\b[0-1]?[0-9]?[0-9]\b)){3}))(?::[\d]{1,5})?(?:(?:(?:\/(?:[-\w~!$+|.,=]|%[a-f\d]{2})+)+|\/)+|\?|#)?(?:(?:\?(?:[-\w~!$+|.,*:]|%[a-f\d{2}])+=?(?:[-\w~!$+|.,*:=]|%[a-f\d]{2})*)(?:&(?:[-\w~!$+|.,*:]|%[a-f\d{2}])+=?(?:[-\w~!$+|.,*:=]|%[a-f\d]{2})*)*)*(?:#(?:[-\w~!$ |\/.,*:;=]|%[a-f\d]{2})*)?/
re_link = /\[([^\n\[\]]+)\] *\(([^\n\[\]]+)(?: +"([^\n\[\]]+)")?\)/
re_bold = /\*([^\*\n]+)\*/
re_newline = /\n/
re_ulbullets = /(?:^\* +.+$\n?){2,}/m
re_olbullets = /(?:^\d{1,2}\.? +.+$\n?){2,}/m
re_blockquote = /(?:^>.*$\n?)+/m
re_codeblock = /<code(?: +lang=['"]?(\w+)['"]?)?>([\s\S]*?)<\/code>\n?/

hE = (text) ->
  text = text.toString()
  return text.replace(/&/g, "&amp;")
             .replace(/</g, "&lt;")
             .replace(/>/g, "&gt;")
             .replace(/"/g, "&quot;")
             .replace(/'/g, "&#39;")

REPLACE_LOOKUP = [
  ['header', re_header, (match) ->
    if match[1]
      # is a ### HEADER type header
      "<h#{match[1].length}>#{hE match[2]}</h#{match[1].length}>"
    else
      # is a HEADER
      #      ====== type header
      header_type = if match[4][0] == '=' then 'h1' else 'h2'
      "<#{header_type}>#{hE match[3]}</#{header_type}>"
  ]
  ['link', re_link, (match) ->
    "<a href=\"#{hE match[2]}\" title=\"#{hE match[3] or ''}\">#{hE match[1]}</a>"]
  ['url', re_url, (match) ->
    if match[1] and match[1].length > 0
      "<a href=\"#{hE match[0]}\">#{hE match[0]}</a>"
    else
      "<a href=\"http://#{hE match[0]}\">#{hE match[0]}</a>"
  ]
  ['email', re_email, (match) ->
    "<a href=\"mailto:#{hE match[0]}\">#{hE match[0]}</a>"]
  ['blockquote', re_blockquote, (match) ->
    unquoted = (line.substr(1) for line in match[0].split("\n")).join("\n")
    "<blockquote>#{Markz::markup unquoted}</blockquote>"]
  ['olbullets', re_olbullets, (match) ->
    lines = (line.substr(2).trim() for line in match[0].trim().split("\n"))
    markup_lines = ("<li><span class='back_to_black'>#{Markz::markup(line)}</span></li>" for line in lines)
    "<ol>#{markup_lines.join('')}</ol>"]
  ['ulbullets', re_ulbullets, (match) ->
    lines = (line.substr(1).trim() for line in match[0].trim().split("\n"))
    markup_lines = ("<li><span class='back_to_black'>#{Markz::markup(line)}</span></li>" for line in lines)
    "<ul>#{markup_lines.join('')}</ul>"]
  ['bold', re_bold, (match) ->
    "<b>#{Markz::markup match[1]}</b>"]
  ['newline', re_newline, (match) ->
    "<br/>"]
  ['codeblock', re_codeblock, (match) ->
    "<pre class='brush: #{match[1] or 'coffeescript'}'>#{hE match[2]}</pre>"]
]

class Markz
  markup: (text) ->
    type2match = {} # type -> {match, func}

    #for l in replace_lookup
    #  [type, regex, func] = l

    find_next_match = (type2match, text, cursor) ->
      # returns {match, func, type, offset} or null
      # fill type2match
      for type_regex_func in REPLACE_LOOKUP
        [type, regex, func] = type_regex_func
        # cleanup or prune
        if type2match[type]?
          if type2match[type].offset < cursor
            delete type2match[type]
          else
            continue
        match = text.substr(cursor).match(regex)
        if match?
          type2match[type] = match: match, func: func, type: type, offset: match.index+cursor
      # return the earliest
      earliest = null
      for type, stuff of type2match
        if not earliest?
          earliest = stuff
        else if stuff.offset < earliest.offset
          earliest = stuff
      return earliest
    
    # collect entities
    cursor = 0
    coll = []
    while true
      next_match = find_next_match(type2match, text, cursor)
      if not next_match?
        break
      if next_match.offset > cursor
        coll.push(hE(text.substr(cursor, (next_match.offset - cursor))))
      coll.push(next_match.func(next_match.match))
      cursor = next_match.offset + next_match.match[0].length
    coll.push(hE(text.substr(cursor)))

    # add breaks
    return coll.join(" ")


# if server-side
if exports?
  exports.Markz = Markz
  exports.hE = hE
# if client-side
if window?
  window.Markz = Markz
  window.hE = hE
