console = require 'console'
path = require 'path'
fs = require 'fs'
coffee = require 'coffee-script'
uglParser = require("uglify-js").parser
uglifier = require("uglify-js").uglify

libdir = null # full path to root of library tree
modules = {}
modulesInDepOrder = [] # modules ordered with dependencies first
options = {} # options based on command line arguments

currFilePath = null # path of current file being required
currArgFile = null # current file from argv being processed
currFileMods = [] # modules in current file being processed
fileModuleRequired = true
# true when the module with the name of the current file is required

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
  else if mod.status is 'packed'
    verbose "already packed #{modName}"
    return
  else
    # TODO: output cycle
    throw "cyclic dependency to #{modName}"

  pathbase = moduleToPath modName
  verbose "packing #{modName} at #{pathbase}"

  requireModule pathbase
  if mod.status isnt 'packed'
    throw "file #{currArgFile} does not contain a module named #{modName}"

  return

class Module
  constructor: (@name) ->
    @status = 'packing'
    @libs = []
    currFileMods.push this

  requires: (libs...) ->
    verbose "module #{@name} requires #{libs}"
    @libs.push lib for lib in libs
    this

  parent: (lib) ->
    verbose "module #{@name} has parent #{lib}"
    @libs.push lib
    this

  defines: -> {}
  empty: -> {}
  class: -> {}
  jooseClass: -> {}

  defineRequirements: ->
    if @libs
      packModule lib for lib in @libs
    this

  define: ->
    verbose "packed #{@name}"
    modulesInDepOrder.push this if @status is 'packing'
    @status = 'packed'
    this

requireModule = (path) ->
  currFilePath = path
  require path

  pathMods = currFileMods
  currFileMods = []

  do mod.defineRequirements for mod in pathMods
  do mod.define for mod in pathMods
  return

class CC
  module: (name) ->
    module = modules[name]
    if not module
      module = modules[name] = new Module name
      module.path = currFilePath
      if not fileModuleRequired
        module.status = 'withoutfile'
      else
        # then it is a file passed from argv
        # make sure module name components match path, if they don't then
        # assume it's a secondary file module
        _libdir = path.join process.cwd(), path.dirname currArgFile
        comps = name.split '.'
        lastComp = do comps.pop

        if lastComp isnt path.basename(currArgFile).replace /\..*$/,''
          module.status = 'withoutfile'
          return module

        while comps.length
          verbose "#{_libdir} to #{path.dirname _libdir}"
          if comps.pop() isnt path.basename _libdir
            module.status = 'withoutfile'
            return module
          _libdir = path.dirname _libdir

        if not libdir
          libdir = _libdir
          verbose "determined libdir #{libdir}"
        else if libdir isnt _libdir
          throw "module #{name} at libdir #{_libdir} which differs from #{libdir}"

        fileModuleRequired = false
    module.path = currFilePath
    module

global.cc = new CC

usage = () ->
  console.log """
    ccbaker [arguments] <paths to source files>
      arguments:
        -c            compile coffeescript modules to javascript only
        -C            do not compile coffeescript to javascript
        -m            do not minify javascript
        -o            obfuscate javascript
        -s            use strict mode for packed file
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
      when '-s'
        options.useStrict = true
      when '-m'
        options.doNotMinify = true
      when '-v'
        options.verbose = true
      when '-h'
        do usage
        return
      when '-w', '-o'
        console.warn "sorry, #{argv[argvIdx]} is not yet supported"
        return
      else
        console.warn "unknown argument: #{argv[argvIdx]}"
        return
    ++argvIdx

  verbose "options:", JSON.stringify options

  if not argv[argvIdx]
    console.warn "must supply at least one file"
    do usage
    return

  while argv[argvIdx]
    fileModuleRequired = true
    currArgFile = argv[argvIdx]
    requireModule path.join process.cwd(), currArgFile
    if fileModuleRequired
      console.warn "file #{currArgFile} does not contain an appropriately named module"
      return
    ++argvIdx

  verbose "modules:", [ mod.name for mod in modulesInDepOrder ]
  targetCode = modulesToSource(modulesInDepOrder)
  unless options.doNotMinify
    ast = uglParser.parse targetCode
    ast = uglifier.ast_mangle ast
    ast = uglifier.ast_squeeze ast
    oldLen = targetCode.length
    targetCode = uglifier.gen_code ast
    newLen = targetCode.length
    if verbose
      console.warn "old code length: #{oldLen}, after minifying: #{newLen} " +
                   "saved #{oldLen - newLen}"

  console.log '"use strict";' if options.useStrict
  console.log targetCode

# outputs modules in order given
modulesToSource = (modules) ->
  targetCode = ''

  outputJs = (path) ->
    targetCode += fs.readFileSync(path).toString() unless options.compileCoffeOnly

  outputCoffee = (root) ->
    jsCode = coffee.compile(fs.readFileSync("#{root}.coffee").toString())
    targetCode += jsCode unless options.compileCoffeOnly
    unless options.doNotCompileCoffee
      fs.writeFileSync("#{root}.js", jsCode)

  outputJs path.join path.dirname(path.dirname __dirname), 'cc.loader.js'

  for mod in modules
    if mod.path.match(/\.js$/)
      outputJs mod.path
    else if mod.path.match(/\.coffee$/)
      outputCoffee mod.path.replace /\.coffee$/, ''
    else if path.existsSync "#{mod.path}.coffee"
      outputCoffee mod.path
    else
      outputJs "#{mod.path}.js"

  targetCode

# vim:ts=2 sw=2
