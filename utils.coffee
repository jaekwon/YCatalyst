###
# YCatalyst
# Copyright(c) 2011 Jae Kwon (jae@ycatalyst.com)
# MIT Licensed
###

require.paths.unshift 'vendor/www-forms'
qs = require 'querystring'
url = require 'url'
www_forms = require 'www-forms'
http = require 'http'
fs = require 'fs'

exports.ipRE = (() ->
  octet = '(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])'
  ip    = '(?:' + octet + '\\.){3}' + octet
  quad  = '(?:\\[' + ip + '\\])|(?:' + ip + ')'
  ipRE  = new RegExp( '^(' + quad + ')$' )
  return ipRE
)()

exports.dir = (object) ->
    methods = []
    for z in object
      if (typeof(z) != 'number')
        methods.push(z)
    return methods.join(', ')

SERVER_LOG = fs.createWriteStream('./log/server.log', flags: 'a', encoding: 'utf8')

# get current user
# sorry, node doesn't actually have a ServerRequest class?? TODO fix
Object.defineProperty(http.IncomingMessage.prototype, 'current_user', {
  get: () ->
    if not @_current_user?
      user_c = this.getSecureCookie('user')
      if user_c? and user_c.length > 0
        @_current_user = JSON.parse(user_c)
    return @_current_user
})

# set current user
Object.defineProperty(http.ServerResponse.prototype, 'current_user', {
  set: (user_object) ->
    @_current_user = user_object
    this.setSecureCookie 'user', JSON.stringify(user_object)
})

# respond with JSON
http.ServerResponse.prototype.simpleJSON = (code, obj) ->
  body = new Buffer(JSON.stringify(obj))
  this.writeHead(code, { "Content-Type": "text/json", "Content-Length": body.length })
  this.end(body)

# redirect
http.ServerResponse.prototype.redirect = (url) ->
  this.writeHead(302, Location: url)
  this.end()

# emit an event so we can log w/ req below in Rowt
_o_writeHead = http.ServerResponse.prototype.writeHead
http.ServerResponse.prototype.writeHead = (statusCode) ->
  this.emit('writeHead', statusCode)
  _o_writeHead.apply(this, arguments)

# ROWTER
# Sets some sensible defaults,
# and also sets req.path_data / req.query_data / req.post_data
# routes: an array of ['/route', fn(req, res)] pairs
exports.Rowter = (routes) ->
  # convert [route, fn] to [regex, param_names, fn]
  # or, [options, route, fn] to [regex, param_names, fn, options]
  parsed = []
  for route_fn in routes
    if route_fn.length > 2
      [options, route, fn] = route_fn
    else
      [route, fn] = route_fn
      options = undefined
    symbols = (x.substr(1) for x in (route.match(/:[^\/]+/g) or []))
    regex = new RegExp("^"+route.replace(/:[^\/]+/g, "([^\/]+)")+"$")
    regex._re_string = route.replace(/:[^\/]+/g, "([^\/]+)")
    parsed.push([regex, symbols, fn, options])

  # create a giant function that takes a (req, res) pair and finds the right fn to call.
  # we need a giant function for each server because that's how node.js works.
  giant_function = (req, res) ->
    # find matching route
    for regex_symbols_fn in parsed
      [regex, symbols, fn, options] = regex_symbols_fn
      matched = regex(req.url.split("?", 1))
      #console.log "/#{regex._re_string}/ matched #{req.url.split("?", 1)} to get #{matched}"
      if not matched?
        continue
      # otherwise, we found our match.
      # construct the req.path_data object
      req.path_data = {}
      if symbols.length > 0
        for i in [0..symbols.length]
          req.path_data[symbols[i]] = matched[i+1]
      chain = if options and options.wrappers then options.wrappers.slice(0) else []
      chain.push(default_wrapper(fn))
      # This function will get passed through the wrapper chain like a hot potato.
      # all wrappers (except the last one) will receive this function as the third parameter,
      # and the wrapper is responsible for calling next(req, res) (or not).
      # I love closures.
      next = (req, res) ->
        next_wrapper = chain.shift()
        next_wrapper(req, res, next)
      # and finally
      next(req, res)
      return
    # if we're here, we failed to find a matching route.
    console.log("TODO request to unknown path #{req.url}")
    return

  server = http.createServer(giant_function)
  server.routes = parsed # you can dynamically alter this array if you want.
  return server
      
# a default decorator that handles logging and stuff
default_wrapper = (fn) ->
  return (req, res) ->
    SERVER_LOG.write("#{(''+new Date()).substr(0,24)} #{req.headers['x-real-ip'] or req.connection.remoteAddress} #{req.httpVersion} #{req.method} #{req.url} #{req.headers.referer} \n")
    SERVER_LOG.flush()
    res.addListener 'writeHead', (statusCode) ->
      SERVER_LOG.write("#{(''+new Date()).substr(0,24)} #{req.headers['x-real-ip'] or req.connection.remoteAddress} #{req.httpVersion} #{req.method} #{req.url} --> #{statusCode} \n")
      SERVER_LOG.flush()
    try
      if req.url.indexOf('?') != -1
        req.query_data = qs.parse(url.parse(req.url).query)
      else
        req.query_data = {}
      if (req.method == 'POST')
        body = ''
        req.setEncoding 'utf8'
        req.addListener 'data', (chunk) ->
          body += chunk
        req.addListener 'end', ->
          if body
            try
              if req.headers['content-type'].toLowerCase().indexOf('application/x-www-form-urlencoded') != -1
                req.post_data = www_forms.decodeForm(body)
              else
                req.post_data = body
            catch e
              console.log e.message
              console.log e.stack
              console.log "Exception in parsing post data #{body}. Ignoring exception."
              req.post_data = body
          return fn(req, res)
      else
        return fn(req, res)
    catch e
      console.log("error in Rowt: " + e)
      console.log(e.stack)
      try
        res.writeHead(500, status: 'woops')
      catch _
        # pass
      res.end()

# other utility stuff
exports.randid = () ->
    text = ""
    possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    for i in [1..12]
        text += possible.charAt(Math.floor(Math.random() * possible.length))
    return text

# a function to add a digest nonce parameter to a static file to help with client cache busting
_static_file_cache = {}
exports.static_file = (filepath) ->
  if not _static_file_cache[filepath]
    fullfilepath = "static/#{filepath}"
    nonce = require('hashlib').md5(require('fs').statSync(fullfilepath).mtime)[1..10]
    console.log("SYNC CALL: static_file, nonce = #{nonce}")
    _static_file_cache[filepath] = "/#{fullfilepath}?v=#{nonce}"
  return _static_file_cache[filepath]

crypto = require('crypto')
exports.passhash = (password, salt, times) ->
  hashed = crypto.createHash('md5').update(password).digest('base64')
  for i in [1..times]
    hashed = crypto.createHash('md5').update(hashed).digest('base64')
  return hashed

# clone nested objects, though
# it gets tricky with special objects like Date...
# add extensions here.
exports.deep_clone = deep_clone = (obj) ->
  if obj == null
    return null
  newObj = if (obj instanceof Array) then (new Array()) else {}
  for own key, value of obj
    if value instanceof Date
      newObj[key] = value
    else if typeof value == 'object'
      newObj[key] = deep_clone(value)
    else
      newObj[key] = value
  return newObj

# for displaying the hostname in parentheses
exports.url_hostname = (url) ->
  try
    host = require('url').parse(url).hostname
    if host.substr(0, 4) == 'www.' and host.length > 7
      host = host.substr(4)
  catch e
    throw 'invalid url?'
  return host

# sometimes you want to call a second block of code synchronously or asynchronously depending
# on the first block of code. In this case, use the 'compose' method.
#
# compose (next) ->
#   if(synchronous?)
#     next("some_arg")
#   else
#     db.asynchronous_call (err, values) ->
#       next("other_arg")
# , (arg) ->
#   console.log arg
# 
# You can chain many functions together.
#
# compose (next) ->
#   console.log "this is the first line"
#   next("this is the second line")
#
# , (next, line) ->
#   console.log line
#   next("this is", "the third line")
#
# , (part1, part2) ->
#   console.log "#{part1} {part2}"

compose = (fns...) ->
  _this = if (typeof(fns[0]) == 'function') then null else fns.shift()
  # return a function that calls the index'th function in fns
  next_gen = (index) ->
    () ->
      if not (0 <= index < fns.length)
        throw new Error "should not happen: 0 <= #{index} < #{fns.length}"
      next_block = fns[index]
      if index < fns.length - 1
        Array::unshift.call(arguments, next_gen(index+1))
      next_block.apply(_this, arguments)
  next_gen(0)()
