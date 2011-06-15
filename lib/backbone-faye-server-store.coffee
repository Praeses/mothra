
class FayeRedis

  constructor: (@channel, @model) ->
    redis  = require('redis')
    client = redis.createClient();

