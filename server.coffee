# Requiring the libs we are going to use for the app. To install theses libs run
# `npm install` and they will be installed using the package.json
http          = require 'http'
Faye          = require 'faye'
Static        = require 'node-static'
redis         = require 'redis'
BackboneRedis = require './lib/backbone-faye-server-store'

# Starting up our  servers. There will be  two. The first is for  the web socket
# layer. It will be running under the location `'/faye'`. The second is the static
# file server.  This will server up our assets (css|js|html).
bayeux      = new Faye.NodeAdapter { mount : '/faye' }
static_file = new Static.Server './public'

# This is the http node.js server. Here  is where we will attach the static file
# server.
server = http.createServer (request, response) ->
  request.addListener 'end', ->
    static_file.serve request, response

# Attaching the faye server to the http serve
bayeux.attach server 
# Starting the http server on port 1337
server.listen 1337

bayeux.addExtension new BackboneRedis()
# When a message is received from a client, then write that message out to
# the console.
out_message = (messages) ->
  console.log messages.text

# Hooking into the client's message queue.
bayeux.getClient().subscribe '/messages', out_message

# pushing a message ( string ) back to the clients
push = (message = 'w00t') -> 
  bayeux.getClient().publish '/messages' , { text: message }
  console.log 'pushing'

# Connecting the the redis database
db = redis.createClient()
# Hooking into the 'live' channel
db.subscribe 'live'

# When there is a message on any of the channels publish it to the log
db.on 'message', ( channel, message ) ->
  console.log channel
  console.log message
  push message
  

# Let the user know what is going on
console.log 'Server running at http://127.0.0.1:1337/'
