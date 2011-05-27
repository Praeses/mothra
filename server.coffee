# Init vars
http   = require 'http'
Faye   = require 'faye'
Static = require 'node-static'
redis  = require 'redis'

# Init Servers
bayeux      = new Faye.NodeAdapter { mount : '/faye' }
static_file = new Static.Server './public'


server = http.createServer (request, response) ->
  request.addListener 'end', ->
    static_file.serve request, response

bayeux.attach server 
server.listen 1337

out_message = (messages) ->
  console.log messages.text

bayeux.getClient().subscribe '/messages', out_message

push = (message = 'w00t') -> 
  bayeux.getClient().publish '/messages' , { text: message }
  console.log 'pushing'

db = redis.createClient()

db.subscribe 'live'

db.on 'message', ( channel, message ) ->
  console.log channel
  console.log message
  push message
  

#setInterval push, 5000
console.log 'Server running at http://127.0.0.1:1337/'
