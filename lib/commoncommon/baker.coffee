console = require 'console'
path = require 'path'

libdir = 'lib'

packing = {}
packed = {}

_verbose = false
verbose = (tolog...) ->
  return unless _verbose
  console.warn tolog.join(' ')

moduleToPath = (mod) ->
  filebase = mod.replace(/\./g, '/')
  return path.join(process.cwd(), libdir, filebase)

packModule = (mod) ->
  if packed[mod]
    verbose "already packed #{mod}"
    return
  else if packing[mod]
    # TODO: output cycle
    throw "cyclic dependency"

  packing[mod] = true

  pathbase = moduleToPath mod
  verbose "packing #{mod} at #{pathbase}"

  require pathbase
  packed[mod] = true
  delete packing[mod]

class Module
  constructor: (@name) ->
  requires: (libs...) ->
    verbose "module #{@name} requires #{libs}"
    for lib in libs
      packModule lib
    this
  defines: () ->
    this

class CC
  module: (name) ->
    new Module name

global.cc = new CC

usage = () ->
  console.log """
    ccbaker [arguments] module.path
      arguments:
        -c            compile coffeescript modules to javascript only.
        -l  [path]    path containing all libraries, default: lib
        -m            minify javascript
        -w  [path]    output baked file to [path] and keep watching all reachable
                      paths for changes, recreating baked file as they change
        -v            print extra information to the terminal on stderr"""

exports.run = (argv) ->
  if argv.length < 3
    do usage
    return

  argvIdx = 2
  loop
    switch argv[argvIdx]
      when '-l'
        libdir = argv[argvIdx + 1]
        argvIdx += 2
      when '-v'
        _verbose = true
        ++argvIdx
      when '-h'
        do usage
        return
      when '-w', '-m'
        console.warn "sorry, #{argv[argvIdx]} is not yet supported"
        return
      else break

  if not libdir
    console.log "missing argument after -l"
    return

  packModule argv[argvIdx]

# vim:ts=2 sw=2
