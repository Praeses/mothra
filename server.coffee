# Requiring the libs we are going to use for the app. To install theses libs run
# `npm install` and they will be installed using the package.json
http      = require 'http'
Faye      = require 'faye'
Static    = require 'node-static'
RedisSync = require './lib/backbone-faye-server-store'

# Starting up our  servers. There will be  two. The first is for  the web socket
# layer. It will be running under the location `'/faye'`. The second is the static
# file server.  This will server up our assets (css|js|html).
bayeux      = new Faye.NodeAdapter { mount : '/faye' }
static_file = new Static.Server './public'

# This is the http node.js server. Here  is where we will attach the static file
# server.
server = http.createServer (request, response) ->
  request.addListener 'end', -> static_file.serve request, response

sync = new RedisSync.Sync
bayeux.addExtension sync

# Attaching the faye server to the http serve
bayeux.attach server 
# Starting the http server on port 1337
server.listen 1337

push_model = (channel, model) -> bayeux.getClient().publish channel, model

bayeux.getClient().subscribe '/models', -> out_message

sync.on 'data', push_model

# When a message is received from a client, then write that message out to
# the console.
out_message = (messages) -> 
  console.log 'in out message'
  console.log messages

# Let the user know what is going on
console.log 'Server running at http://127.0.0.1:1337/'
