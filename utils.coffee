require.paths.unshift 'vendor/www-forms'
www_forms = require 'www-forms'

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

exports.Rowt = (fn) ->
  return (req, res) ->
    # TODO this could do better elsewhere
    res.simpleJSON = (code, obj) ->
      body = new Buffer(JSON.stringify(obj))
      res.writeHead(code, { "Content-Type": "text/json", "Content-Length": body.length })
      res.end(body)
    try
      if (req.method == 'POST')
        req.setEncoding 'utf8'
        req.addListener 'data', (chunk) ->
          req.post_data = www_forms.decodeForm(chunk)
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
