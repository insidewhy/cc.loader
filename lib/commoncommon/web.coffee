class Module
  constructor: (@name) ->
    @loading = true
    @onloads = []
  requires: (libs...) ->
    @deps = libs
    this
  pushOnload: (callback) ->
    # push a callback to run after this module and all its dependencies have loaded
    @onloads.push callback
  defines: (@defineCallback) ->
    unless @deps
      do @_define
      return this

    toLoad = @deps.length
    onLoad = (errMod) =>
      if errMod
        alert "#{@name}: error loading dependency #{errMod}"
        delete @loading
      else if 0 == --toLoad
        do @_define

    for dep in @deps
      cc.require dep, onLoad

    this
  _define: ->
    # console.log "define #{@name}"
    delete @loading
    self = {}
    @defineCallback self

    hasKey = () ->
      for own key of self
        return true
      false

    if hasKey()
      cc.set @name, self

    for onload in @onloads
      do onload
    delete @onloads

class CC
  constructor: ->
    @libpath = 'lib'
    @modules = {}
    @global = window
    @head = document.getElementsByTagName('head')[0]

  module: (name) ->
    mod = @modules[name]
    if mod
      return mod
    else
      # this corresponds to a second module defined in a file that can't be
      # externally referenced via "cc.requires".
      return cc.modules[name] = new Module name

  # set a value at a particular namespace under @global
  # e.g. ns = "hey.baby", val = "1"
  #   -> hey.baby = 1
  set: (ns, val) ->
    obj = @global
    components = ns.split '.'
    for space in components[0...(components.length - 1)]
      newObj = obj[space]
      if not newObj
        obj = obj[space] = {}
      else if typeof newObj == 'object'
        obj = newObj
      else
        alert "namespace conflict, #{ns} = #{newObj} of #{typeof newObj}"

    lastComp = components[components.length - 1]
    obj[lastComp] = val

  # require module name, with optional callback on success.
  # passes failed module name to callback on error, null on success.
  # the callback is only called after the module and all of its dependencies
  # have loaded.
  require: (name, callback) ->
    mod = @modules[name]
    if mod
      if mod.failed
        # console.log "require #{name} failed"
        callback name
      else if mod.loading
        # console.log "require #{name} is loading"
        mod.pushOnload callback if callback
      else
        # console.log "require #{name} loaded"
        do callback
      return this

    # console.log "require #{name} first"

    mod = @modules[name] = new Module name
    mod.pushOnload callback if callback

    path = @libpath + '/' + name.replace(/\./g, '/') + '.js'
    script = mod.script = document.createElement 'script'
    script.type = 'text/javascript'
    script.src = path
    # script.onload = -> console.log "#{path} loaded"
    script.onerror = ->
      # this doesn't work directly.. is called later after dom completion
      mod.failed = true
      delete mod.loading
      if callback
        callback(name)
      else
        alert "error requiring #{name}"

    @head.appendChild script

    # script.onerror doesn't work directly so have to wait for the document
    # readystatechange to go back to complete. at this stage any unloaded
    # script has its "onerror" event manually called.
    unless @_monitored
      @_monitored = true
      document.onreadystatechange = =>
        return unless 'complete' == document.readyState
        delete @_monitored
        for own name, mod of @modules
          if mod.loading and mod.script
            do mod.script.onerror

    @this

window.cc = new CC

# vim:ts=2 sw=2
