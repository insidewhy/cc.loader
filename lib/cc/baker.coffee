console = require 'console'
path = require 'path'
fs = require 'fs'
coffee = require 'coffee-script'
chamomile = require 'chamomile'
uglParser = require("uglify-js").parser
uglifier = require("uglify-js").uglify

# globals.. see reset function.
# globals are necessary to intercept modules loads.
libdir = modules = modulesInDepOrder = currFilePath = null
currArgFile = currFileMods = fileModuleRequired = null

__verbose = false

reset = ->
  libdir = null # full path to root of library tree
  modules = {}
  modulesInDepOrder = [] # modules ordered with dependencies first

  currFilePath = null # path of current file being required
  currArgFile = null # current file from argv being processed
  currFileMods = [] # modules in current file being processed
  fileModuleRequired = true

verbose = (tolog...) ->
  return unless __verbose
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
  jClass: -> {}
  set: -> {}

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
  # ccbaker relies on re-running stuff in global scope on module require, so
  # the module must be deleted from the cache if it is there
  if /\.(js|coffee|chmo)/.test path
    delete require.cache[path]
  else
    delete require.cache[path + ".js"]
    delete require.cache[path + ".coffee"]
    delete require.cache[path + ".chmo"]

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
        -H            do not compile chamomile to javascript
        -i [path]     include raw source file before modules, can be used
                      multiple times
        -l            do not include cc.loader in output
        -m            do not minify javascript
        -o            obfuscate javascript
        -s            use strict mode for packed file
        -w  [path]    output baked file to [path] and keep watching all reachable
                      paths for changes, recreating baked file as they change
        -v            print extra information to the terminal on stderr"""

exports.bake = bake = (files, outputPath, options) ->
  do reset
  if not options
    options = outputPath
    outputPath = null

  if not (files instanceof Array)
    files = [ files ]

  for file in files
    fileModuleRequired = true
    currArgFile = file
    requireModule path.join process.cwd(), currArgFile
    if fileModuleRequired
      console.warn "file #{currArgFile} does not contain an appropriately named module"
      return

  sourceFiles = options.includeFiles or []

  # ccloader comes after include files
  if not options.noCcLoader
    sourceFiles.push(
      path.join path.dirname(path.dirname __dirname), 'cc', 'loader.js')

  for mod in modulesInDepOrder
    sourceFiles.push mod.path

  targetCode = modulesToSource sourceFiles, options

  unless options.compileCoffeeOnly
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


    targetCode = '"use strict";' + targetCode if options.useStrict
    if not outputPath
      console.log targetCode
    else
      fs.writeFileSync(outputPath, targetCode)

exports.run = (argv, options) ->
  options = {} unless options

  if argv.length < 3
    do usage
    return

  argvIdx = 2
  while argv[argvIdx] and argv[argvIdx][0] == '-'
    switch argv[argvIdx]
      when '-c'
        options.compileCoffeeOnly = true
      when '-C'
        options.doNotCompileCoffee = true
      when '-H'
        options.doNotCompileChamomile = true
      when '-i'
        ++argvIdx
        newFile = argv[argvIdx]
        throw "-i requires argument" unless newFile
        if options.includeFiles
          options.includeFiles.push newFile
        else
          options.includeFiles = [ newFile ]
      when '-l'
        options.noCcLoader = true
      when '-s'
        options.useStrict = true
      when '-m'
        options.doNotMinify = true
      when '-v'
        __verbose = true
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

  if not argv[argvIdx]
    console.warn "must supply at least one file"
    do usage
    return

  verbose "options:", JSON.stringify options

  files = []
  while argv[argvIdx]
    files.push argv[argvIdx]
    ++argvIdx

  bake files, options

# outputs modules in order given
modulesToSource = (files, options) ->
  targetCode = ''

  outputJs = (path) ->
    targetCode += fs.readFileSync(path).toString() unless options.compileCoffeeOnly

  outputCoffee = (root) ->
    jsCode = coffee.compile(fs.readFileSync("#{root}.coffee").toString())
    targetCode += jsCode unless options.compileCoffeeOnly
    fs.writeFileSync("#{root}.js", jsCode) unless options.doNotCompileCoffee

  outputChamomile = (root) ->
    jsCode = chamomile(fs.readFileSync("#{root}.chmo").toString())
    targetCode += jsCode
    fs.writeFileSync("#{root}.js", jsCode) unless options.doNotCompileChamomile

  for file in files
    if /\.js$/.test file
      outputJs file
    else if /\.coffee$/.test file
      outputCoffee file.replace(/\.coffee$/, '')
    else if /\.chmo$/.test file
      outputChamomile file.replace(/\.chmo$/, '')
    else if fs.existsSync "#{file}.coffee"
      outputCoffee file
    else if fs.existsSync "#{file}.chmo"
      outputChamomile file
    else
      outputJs "#{file}.js"

  targetCode

# vim:ts=2 sw=2
