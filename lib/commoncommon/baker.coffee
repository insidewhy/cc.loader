console = require 'console'
path = require 'path'

libdir = null # full path to root of library tree
rootModulePath = null # directory containing root module
packing = {}
packed = {}
moduleOrder = [] # modules ordered with dependencies first

_verbose = false
verbose = (tolog...) ->
  return unless _verbose
  console.warn tolog.join(' ')

moduleToPath = (mod) ->
  filebase = mod.replace /\./g, '/'
  return path.join libdir, filebase

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
    if not libdir
      libdir = path.join process.cwd(), rootModulePath
      idx = @name.indexOf '.'
      while -1 != idx
        console.log "#{libdir} to #{path.dirname libdir}"
        libdir = path.dirname libdir
        idx = @name.indexOf '.', idx
      verbose "got libdir #{libdir}"

      # determine from current path

    verbose "module #{@name} requires #{libs}"
    for lib in libs
      packModule lib
    this

  defines: () ->
    moduleOrder.push this
    this

  jooseClass: -> do @defines

class CC
  module: (name) ->
    new Module name

global.cc = new CC

usage = () ->
  console.log """
    ccbaker [arguments] <path to root module>
      arguments:
        -c            compile coffeescript modules to javascript only
        -m            minify javascript
        -w  [path]    output baked file to [path] and keep watching all reachable
                      paths for changes, recreating baked file as they change
        -v            print extra information to the terminal on stderr"""

exports.run = (argv) ->
  if argv.length < 3
    do usage
    return

  argvIdx = 2
  while argv[argvIdx][0] == '-'
    switch argv[argvIdx]
      when '-v'
        _verbose = true
        ++argvIdx
      when '-h'
        do usage
        return
      when '-w', '-m'
        console.warn "sorry, #{argv[argvIdx]} is not yet supported"
        return

  mod = argv[argvIdx]
  packing[mod] = true
  rootModulePath = path.dirname mod
  require path.join process.cwd(), mod
  delete packing[mod]
  packed[mod] = 1

  verbose "modules:", [ mod.name for mod in moduleOrder ]

# vim:ts=2 sw=2
