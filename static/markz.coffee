coffeekup = if CoffeeKup? then CoffeeKup else require 'coffeekup'

# regexes ripped from the node.js validator project
# https://github.com/chriso/node-validator.git
re_email = /(?:[\w\!\#\$\%\&\'\*\+\-\/\=\?\^\`\{\|\}\~]+\.)*[\w\!\#\$\%\&\'\*\+\-\/\=\?\^\`\{\|\}\~]+@(?:(?:(?:[a-zA-Z0-9](?:[a-zA-Z0-9\-](?!\.)){0,61}[a-zA-Z0-9]?\.)+[a-zA-Z0-9](?:[a-zA-Z0-9\-](?!$)){0,61}[a-zA-Z0-9]?)|(?:\[(?:(?:[01]?\d{1,2}|2[0-4]\d|25[0-5])\.){3}(?:[01]?\d{1,2}|2[0-4]\d|25[0-5])\]))/
re_url = /(?:(?:ht|f)tp(?:s?)\:\/\/|~\/|\/)?(?:\w+:\w+@)?((?:(?:[-\w\d{1-3}]+\.)+(?:com|org|net|gov|mil|biz|info|mobi|name|aero|jobs|edu|co\.uk|ac\.uk|it|fr|tv|museum|asia|local|travel|[a-z]{2}))|((\b25[0-5]\b|\b[2][0-4][0-9]\b|\b[0-1]?[0-9]?[0-9]\b)(\.(\b25[0-5]\b|\b[2][0-4][0-9]\b|\b[0-1]?[0-9]?[0-9]\b)){3}))(?::[\d]{1,5})?(?:(?:(?:\/(?:[-\w~!$+|.,=]|%[a-f\d]{2})+)+|\/)+|\?|#)?(?:(?:\?(?:[-\w~!$+|.,*:]|%[a-f\d{2}])+=?(?:[-\w~!$+|.,*:=]|%[a-f\d]{2})*)(?:&(?:[-\w~!$+|.,*:]|%[a-f\d{2}])+=?(?:[-\w~!$+|.,*:=]|%[a-f\d]{2})*)*)*(?:#(?:[-\w~!$ |\/.,*:;=]|%[a-f\d]{2})*)?/
re_link = /\[([^\n]+)\] *\(([^\n]+)(?: +"([^\n]+)")?\)/
re_bold = /\*([^\*\n]+)\*/
re_newline = /\n/

hE = (text) ->
  text = text.toString()
  return text.replace(/&/g, "&amp;")
             .replace(/</g, "&lt;")
             .replace(/>/g, "&gt;")
             .replace(/"/g, "&quot;")
             .replace(/'/g, "&#39;")

REPLACE_LOOKUP = [
  ['link', re_link, (match) ->
    "<a href=\"#{hE match[2]}\" title=\"#{hE match[3] or ''}\">#{hE match[1]}</a>"]
  ['url', re_url, (match) ->
    "<a href=\"#{hE match[0]}\">#{hE match[0]}</a>"]
  ['email', re_email, (match) ->
    "<a href=\"mailto:#{hE match[0]}\">#{hE match[0]}</a>"]
  ['bold', re_bold, (match) ->
    "<b>#{Markz::markup match[1]}</b>"]
  ['newline', re_newline, (match) ->
    "<br/>"]
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
# if client-side
if window?
  window.Markz = Markz
