http   = require 'http'
sys    = require 'sys'
Faye   = require 'faye'
Static = require 'node-static'
redis  = require 'redis'

class Mothra
  # Constructor for the mothra Application
  initialize: (options) ->
    @settings = port: options.port
    init()

  init: ->
    @bayeux = createBayeuxServer()
    @httpServer = createHTTPServer()
    @db = createRedisServer()

    @bayeux.attach @httpServer
    @httpServer.listen @settings.port
    sys.log "Server started on PORT " + @settings.port

    @bayeux.getClient().subscribe '/messages', out_message

    @db.subscribe 'live'

    @db.on 'message', (channel, message) ->
      console.log channel
      console.log message
      push message


  createBayeuxServer: ->
    bayeux = new Faye.NodeAdapter mount: '/faye', timeout: 45

  createHTTPServer: ->
    server = http.createServer (request, response) ->
      file = new Static.Server './public'

      request.addListener "end", ->
        file.server request, response

  createRedisServer: ->
    redis.createClient()

  out_message: (messages) ->
    console.log messages.text

  push: (message = 'w00t') ->
    bayeux.getClient().publish '/messages', text: message
    console.log 'pushing'


