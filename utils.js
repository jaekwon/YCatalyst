require.paths.unshift('vendor/www-forms');
var www_forms = require('www-forms');

exports.ipRE = (function() {
  var octet = '(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])';
  var ip    = '(?:' + octet + '\\.){3}' + octet;
  var quad  = '(?:\\[' + ip + '\\])|(?:' + ip + ')';
  var ipRE  = new RegExp( '^(' + quad + ')$' );
  return ipRE;
})();

exports.dir = function(object) {
    methods = [];
    for (z in object) if (typeof(z) != 'number') methods.push(z);
    return methods.join(', ');
}

exports.Rowt = function(fn) {
  return function(req, res) {
    if (req.method == 'POST') {
      req.setEncoding('utf8');
      req.addListener('data', function(chunk) {
        req.post_data = www_forms.decodeForm(chunk);
        return fn(req, res);
      });
    } else {
      return fn(req, res);
    }
  }
}

exports.randid = function() {
    var text = "";
    var possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    for( var i=0; i < 12; i++ )
        text += possible.charAt(Math.floor(Math.random() * possible.length));
    return text;
}
