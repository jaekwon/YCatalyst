var http = require('http');
var jade = require('jade');
require.paths.unshift('vendor/mongoose');
require.paths.unshift('vendor/www-forms');
var mongoose = require('mongoose').Mongoose;
var www_forms = require('www-forms');

var ipRE = (function() {
  var octet = '(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])';
  var ip    = '(?:' + octet + '\\.){3}' + octet;
  var quad  = '(?:\\[' + ip + '\\])|(?:' + ip + ')';
  var ipRE  = new RegExp( '^(' + quad + ')$' );
  return ipRE;
})();

mongoose.model('Record', {
  properties: ['from', 'name', 'to', 'updated_at'],
  indexes: ['name', 'updated_at'],
  methods: {
    save: function(fn) {
      this.updated_at = new Date();
      this.__super__(fn);
    }
  },
  setters: {
    'to': function(v) {
      if (!ipRE.test(v)) {
        throw "InvalidIP";
      }
      return v;
    }
  }
});

var db = mongoose.connect('mongodb://localhost/1amendment');
var Record = db.model('Record');

http.createServer(function (req, res) {
  var remote_address = req.connection.remoteAddress;

  if (req.method == 'GET') {
    if (req.url == '/favicon.ico' || req.url == '/robots.txt') {
      res.end();
    }
    if (req.url == '/') {
      res.writeHead(200, {'Content-Type': 'text/html'});
      jade.renderFile('templates/test.jade', {locals:{name: null, records: null, remote_address: remote_address}}, function(err, html) {
          if (err) {
              console.log(err);
          }
          res.end(html);
      });
    } else {
      var records = Record.find({name: req.url.substring(1)}).sort(['name', ['updated_at', 'descending']]);
      records.all(function(records) {
        res.writeHead(200, {'Content-Type': 'text/html'});
        jade.renderFile('templates/test.jade', {locals:{name: req.url.substring(1), records: records, remote_address: remote_address}}, function(err, html) {
            if (err) {
                console.log(err);
            }
            res.end(html);
        });
      });
    }

  } else if (req.method == 'POST') {
    req.setEncoding('utf8');
    req.addListener('data', function(chunk) {
      var form = www_forms.decodeForm(chunk);
      if (form.name && form.ip) {
        try {
          var r = new Record();
          r.from = remote_address;
          r.name = form.name;
          r.to = form.ip;
          r.save(function() {
            console.log('saved');
          });
        } catch (e) {
          console.log(e);
        }
        res.writeHead(302, {'Location': 'http://1amendment.com/'+form.name});
        res.end();
      }
    });
  } else {
    res.writeHead(404, {});
    res.end();
  }
}).listen(8124, "127.0.0.1");

console.log('Server running at http://127.0.0.1:8124/');
