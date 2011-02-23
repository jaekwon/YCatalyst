require.paths.unshift 'vendor/www-forms'
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
# http.ServerRequest.prototype.get_current_user = -> 
http.IncomingMessage.prototype.get_current_user = ->
  if not @_current_user?
    user_c = this.getSecureCookie('user')
    if user_c? and user_c.length > 0
      @_current_user = JSON.parse(user_c)
  return @_current_user

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

exports.Rowt = (fn) ->
  return (req, res) ->
    SERVER_LOG.write("#{(''+new Date()).substr(0,24)} #{req.headers['x-real-ip'] or req.connection.remoteAddress} #{req.httpVersion} #{req.method} #{req.url} #{req.headers.referer} \n")
    SERVER_LOG.flush()
    res.addListener 'writeHead', (statusCode) ->
      SERVER_LOG.write("#{(''+new Date()).substr(0,24)} #{req.headers['x-real-ip'] or req.connection.remoteAddress} #{req.httpVersion} #{req.method} #{req.url} --> #{statusCode} \n")
      SERVER_LOG.flush()
    try
      if (req.method == 'POST')
        called_back = false
        req.setEncoding 'utf8'
        req.addListener 'data', (chunk) ->
          req.post_data = www_forms.decodeForm(chunk)
          called_back = true
          return fn(req, res)
        req.addListener 'end', ->
          if not called_back
            called_back = true
            return fn(req, res)
      else
        return fn(req, res)
    catch e
      console.log("error in Rowt: " + e)
      try
        res.writeHead(500, status: 'woops')
      catch _
        # pass
      res.end()

exports.randid = () ->
    text = ""
    possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    for i in [1..12]
        text += possible.charAt(Math.floor(Math.random() * possible.length))
    return text

exports.static_file = (filepath) ->
  filepath = "static/#{filepath}"
  nonce = require('hashlib').md5(require('fs').statSync(filepath).mtime)[1..10]
  console.log("XXX static_file, nonce = #{nonce}")
  return "/#{filepath}?v=#{nonce}"

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
  newObj = if (this instanceof Array) then [] else {}
  for own key, value of obj
    if value instanceof Date
      newObj[key] = value
    else if typeof value == 'object'
      newObj[key] = deep_clone(value)
    else
      newObj[key] = value
  return newObj
