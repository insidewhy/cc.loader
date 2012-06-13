console = require 'console'
path = require 'path'

libdir = null # full path to root of library tree
rootModulePath = null # directory containing root module
modules = {}
moduleOrder = [] # modules ordered with dependencies first
options = {} # options based on command line arguments

verbose = (tolog...) ->
  return unless options.verbose
  console.warn tolog.join(' ')

moduleToPath = (modName) ->
  filebase = modName.replace /\./g, '/'
  return path.join libdir, filebase

packModule = (modName) ->
  mod = modules[modName]
  if not mod
    mod = modules[modName] = new Module modName
  else if mod.status == 'packed'
    verbose "already packed #{modName}"
    return
  else if mod.status == 'packing'
    # TODO: output cycle
    throw "cyclic dependency to #{modName}"

  pathbase = moduleToPath modName
  verbose "packing #{modName} at #{pathbase}"

  require pathbase

class Module
  constructor: (@name) ->
    @status = 'packing'

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
    @status = 'packed'
    verbose "packed #{@name}"
    moduleOrder.push this
    this

  jooseClass: -> do @defines

class CC
  module: (name) ->
    module = modules[name]
    if not module
      modules[name] = new Module name
    else
      module

global.cc = new CC

usage = () ->
  console.log """
    ccbaker [arguments] <paths to source files>
      arguments:
        -c            compile coffeescript modules to javascript only
        -C            do not compile coffeescript to javascript
        -m            minify javascript
        -o            obfuscate javascript
        -w  [path]    output baked file to [path] and keep watching all reachable
                      paths for changes, recreating baked file as they change
        -v            print extra information to the terminal on stderr"""

exports.run = (argv) ->
  if argv.length < 3
    do usage
    return

  argvIdx = 2
  while argv[argvIdx] and argv[argvIdx][0] == '-'
    switch argv[argvIdx]
      when '-c'
        options.compileCoffeOnly = true
      when '-C'
        options.doNotCompileCoffee = true
      when '-m'
        options.minify = true
      when '-v'
        options.verbose = true
      when '-o'
        options.obfuscate = true
      when '-h'
        do usage
        return
      when '-w'
        console.warn "sorry, #{argv[argvIdx]} is not yet supported"
        return
    ++argvIdx

  verbose "options:", JSON.stringify options

  filePath = argv[argvIdx]
  if not filePath
    console.warn "must supply at least one file"
    do usage
    return

  rootModulePath = path.dirname filePath
  require path.join process.cwd(), filePath

  ++argvIdx
  while argv[argvIdx]
    require path.join process.cwd(), argv[argvIdx]
    ++argvIdx

  verbose "modules:", [ mod.name for mod in moduleOrder ]

# vim:ts=2 sw=2
