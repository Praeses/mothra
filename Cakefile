
{spawn, exec} = require 'child_process'
util = require 'util'

task 'assets:watch', 'Watch source files and build JS & CSS', (options) ->
  runCommand = (name, args...) ->
    proc =           spawn name, args
    proc.stderr.on   'data', (buffer) -> console.log buffer.toString()
    proc.stdout.on   'data', (buffer) -> console.log buffer.toString()
    proc.on          'exit', (status) -> process.exit(1) if status isnt 0
  #runCommand 'sass',   ['--watch', 'public/css/sass:public/css']
  runCommand 'coffee', '-wc', 'public/js', 'test-js'

task 'spec', 'Run the spec files', ->
  util.log 'Running specs'
  jasmine()


jasmine = ( options = '', dir = './spec' ) ->
  process = spawn( './node_modules/.bin/jasmine-node', [ '--coffee', options, dir ] )

  process.stdout.on 'data', (data) ->
    util.print data

  process.stderr.on 'data', (data) ->
    util.print data
