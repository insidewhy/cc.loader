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
      cc.namespaceValue @name, self

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
    return mod if mod
    alert "cannot instantiate module #{name} before requiring it"


  # set a value at a particular namespace under global
  # e.g. ns = "hey.baby", val = "1"
  #   -> global.hey.baby = 1
  namespaceValue: (ns, val) ->
    obj = @global
    components = ns.split '.'
    for space in components[0...(components.length - 1)]
      newObj = obj[space]
      if not newObj
        obj = obj[space] = {}
      else if typeof newObj == 'Object'
        obj = newObj
      else
        alert "namespace conflict, #{ns} = #{newObj}"

    lastComp = components[components.length - 1]
    obj[lastComp] = val

  # require module name, with optional callback on success.
  # passes failed module name to callback on error, null on success.
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
    script = document.createElement 'script'
    script.type = 'text/javascript'
    if callback
      script.onerror = () ->
        mod.failed = true
        callback(name)
    else
      script.onerror = () ->
        mod.failed = true
        alert "error requiring #{name}"
    script.src = path
    @head.appendChild script
    # require a module, which in turn will require its dependencies

window.cc = new CC

# vim:ts=2 sw=2
