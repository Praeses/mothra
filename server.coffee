http = require 'http'

server = http.createServer (request, response) ->
  response.writeHead 200, ContentType: "text/plain"
  response.end "Hello World!\n"

server.listen 1337, "127.0.0.1"
console.log 'Server running at http://127.0.0.1:1337/'
