# EventEmitter is Node.js events.
EventEmitter = require( 'events' ).EventEmitter

# The Sync class will intercept messages from the client
# and if they are on the correct channel then we will
class Sync extends EventEmitter

  constructor: ->
    redis  = require('redis')
    client = redis.createClient()

    @on 'create' , @create
    @on 'read'   , @read

  incoming: (message, callback) ->
    # Don't use the message if we don't like it
    regex = /\/models\/(\w+)/
    unless regex.test message.channel
      return callback message

    # Here is where we will persist the data
    @emit message.data.method, regex.exec( message.channel )[1], message.data.model

    callback message

  create: (base_key, model) ->
    # Create
    console.log( '*** from create ***' )
    console.log( base_key )
    console.log( model )
    publish base_key, model

  read: (base_key, model) ->
    # Create
    console.log( '*** from read ***' )
    console.log( base_key )
    console.log( model )
    publish base_key, model

  publish: (channel, model) ->
    @emit 'data', '/models/#{channel}', model

   


exports.Sync = Sync
