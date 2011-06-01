process.addListener 'uncaughtException', (err, stack) ->
  console.log('------------------------')
  console.log('Exception: ' + err)
  console.log(err.stack)
  console.log('------------------------')

Mothra = require "./lib/mothra"

new Mothra port: 1337
