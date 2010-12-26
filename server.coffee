require.paths.unshift 'vendor/jade'
require.paths.unshift 'vendor/sherpa/lib'

http = require 'http'
jade = require 'jade'
sherpa = require 'sherpa/nodejs'
utils = require './utils'
mongo = require './mongo'
fu = require './fu'
underscore = require './static/underscore'
Record = require('./static/record').Record

get_records = (root_id, level, fn) ->
  mongo.records.findOne _id: root_id, (err, root) ->
    all = {}
    all[root_id] = new Record(root)
    tofetch = [root_id]
    fetchmore = (i) ->
      mongo.records.find parent_id: {$in: tofetch}, (err, cursor) ->
        cursor.toArray (err, records) ->
          tofetch = []
          for record in records
            record = new Record(record)
            tofetch.push(record._id)
            all[record._id] = record
          if i > 0
            fetchmore(i-1)
          else
            fn(all)
    fetchmore(level)

http.createServer(utils.Rowt(new Sherpa.NodeJs([

  ['/static/:filepath', (req, res) ->
    switch req.method
      when 'GET'
        filepath = req.sherpaResponse.params.filepath
        filepath = require('path').join './static/', filepath
        if filepath.indexOf('static/') != 0
          res.writeHead 404, 'does not exist'
          res.end()
        else
          fu.staticHandler(filepath)(req, res)
  ]

  ['/', (req, res) ->
    switch req.method
      when 'GET'
        mongo.records.find (err, cursor) ->
          cursor.toArray (err, records) ->
            res.writeHead 200, status: 'ok'
            jade.renderFile 'templates/index.jade', locals: {records: records}, (err, html) ->
              if err
                console.log err
              res.end html
      when 'POST'
        parent_id = req.post_data.parent_id
        comment = req.post_data.comment
        data = parent_id: parent_id, _id: utils.randid(), comment: comment
        if parent_id
          mongo.records.findOne _id: parent_id, (err, item) ->
            if err
              console.log err
            else
              # good, it exists!
              mongo.records.save data, (err, stuff) ->
                res.writeHead 302, Location: '/r/'+stuff._id
                res.end()
        else
          console.log 'no parent? wheres ur dad?'
  ]

  ['/r/:id', (req, res) ->
    switch req.method
      when 'GET'
        id = req.sherpaResponse.params.id
        get_records id, 2, (all) ->
          jade.renderFile 'templates/record.jade', locals: {all: all, root_id: id}, (err, html) ->
            console.log err if err
            res.writeHead 200, status: 'ok'
            res.end html
  ],

]).listener())).listen 8124, '127.0.0.1'

console.log 'Server running at http://127..0.1:8124'
