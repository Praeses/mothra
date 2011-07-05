
{spawn, exec} = require 'child_process'
util = require 'util'

task 'assets:watch', 'Watch source files and build JS', (options) ->
  runCommand = (name, args...) ->
    proc =           spawn name, args
    proc.stderr.on   'data', (buffer) -> util.print buffer
    proc.stdout.on   'data', (buffer) -> util.print buffer
    proc.on          'exit', (status) -> process.exit(1) if status isnt 0

  runCommand './node_modules/.bin/coffee', '-wc', '-o', 'public/js', 'lib/client'

task 'spec', 'Run the spec files', ->
  util.log 'Running specs'
  jasmine()

task 'build', 'Build Coffee and Less files into js and css files', ->
  coffee = spawn( './node_modules/.bin/coffee', [ '--compile', '--output', './public/js', 'lib/client' ] )
  out_process coffee

  lessc = spawn( './node_modules/.bin/lessc', [ 'public/css/less/master.less', 'public/css/master.css' ] )
  out_process lessc

task 'docs', 'Build the docco docs', ->
  exec './node_modules/.bin/docco server.coffee lib/**/*.coffee', (error,stdout,stderr) ->
    util.print error
    util.print stdout
    util.print stderr


jasmine = ( options = '', dir = './spec' ) ->
  process = spawn( './node_modules/.bin/jasmine-node', [ '--coffee', options, dir ] )
  out_process process

out_process = ( process ) ->
  process.stdout.on 'data', (data) -> util.print data
  process.stderr.on 'data', (data) -> util.print data
