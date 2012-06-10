class Module
  constructor: (@name) ->
    @status = 'loading'
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
      # console.log "loaded dep of #{@name}"
      if errMod
        alert "#{@name}: error loading dependency #{errMod}"
        @status = 'failed'
      else if 0 == --toLoad
        do @_define

    for dep in @deps
      cc.require dep, onLoad

    this
  _define: ->
    # console.log "define #{@name}"
    @status = 'defined'
    self = {}

    try
      @defineCallback self
    catch e
      @status = 'failed'
      alert "#{@name}.defines failed: #{e}"
      onload @name for onload in @onloads

    hasKey = () ->
      for own key of self
        return true
      false

    if hasKey()
      cc.set @name, self

    do onload for onload in @onloads
    delete @onloads

class CC
  constructor: ->
    @firefoxVersion = -1 != navigator.userAgent.indexOf "Firefox"
    @ieVersion =
      if navigator.appName == 'Microsoft Internet Explorer'
        re  = /MSIE ([0-9]{1,}[\.0-9]{0,})/
        if re.exec navigator.userAgent
          parseFloat RegExp.$1
        else 0
      else 0
    # alert "firefox: #{@firefoxVersion}, ie: #{@ieVersion}"
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

  scriptOnload: (script, onload) ->
    if script.readyState
      # IE is different
      script.onreadystatechange = ->
        switch script.readyState
          when "loaded", "complete"
            do onload
            script.onreadystatechange = null
    else
      script.onload = onload
    return

  # loads a script into the head of the browser and call success/error callbacks
  loadScript: (path, onload, onerror) ->
    script = document.createElement 'script'
    script.type = 'text/javascript'

    if 'file:' == document.location?.protocol and @firefoxVersion
      # firefox can't catch onerror for files so have to poll
      loaded = false
      @scriptOnload script, ->
        loaded = true
        do onload if onload

      setTimeout(
        -> do onerror unless loaded
        2000)
    else
      @scriptOnload script, onload if onload
      script.onerror = onerror if onerror

    script.src = path
    @head.appendChild script
    script


  # require module name, with optional callback on success.
  # passes failed module name to callback on error, null on success.
  # the callback is only called after the module and all of its dependencies
  # have loaded.
  require: (name, callback) ->
    mod = @modules[name]
    if mod
      if callback
        if 'failed' == mod.status
          # console.log "require #{name} failed"
          callback name
        else if 'loading' == mod.status
          # console.log "require #{name} is loading"
          mod.pushOnload callback
        else
          # console.log "require #{name} loaded"
          do callback
      return this

    # console.log "require #{name} first"

    mod = @modules[name] = new Module name
    mod.pushOnload callback if callback

    path = @libpath + '/' + name.replace(/\./g, '/') + '.js'
    @loadScript(
      path
      null
      # ->
      #   # success handler
      #   alert "loaded #{mod.name}"
      ->
        mod.status = 'failed'
        if callback
          callback(name)
        else
          alert "error requiring #{name}")

    @this

window.cc = new CC

# vim:ts=2 sw=2
