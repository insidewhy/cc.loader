class Self
  constructor: (@__ccModName) ->
  _getName: (name) -> "#{@__ccModName}.#{name}"
  class: (name, val) ->
    cc.class @_getName(name), val
    this
  set: (name, val) ->
    cc.set @_getName(name), val
    this

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
    this

  class: (classContent) ->
    @defines ->
      cc.class @name, classContent
    this

  defines: (@defineCallback) ->
    if not @deps
      do @_define
    else
      toLoad = @deps.length
      onLoad = (errMod) =>
        # console.log "loaded dep of #{@name}"
        if errMod
          alert "#{@name}: error loading dependency #{errMod}"
          if @script and @script.onerror and @status != 'failed'
            do @script.onerror
        else if 0 == --toLoad
          do @_define

      for dep in @deps
        cc.require dep, onLoad
    this

  # define an empty module
  empty: ->
    do onload for onload in @onloads
    delete @onloads
    @status = 'defined'
    return

  _define: ->
    # console.log "define #{@name}"
    @status = 'loaded'
    self = new Self @name

    try
      @defineCallback self
    catch e
      @status = 'failed'
      alert "#{@name}.defines failed: #{e}"
      onload @name for onload in @onloads

    hasKey = () ->
      for own key of self when key isnt '__ccModName'
        return true
      false

    cc.set @name, self if hasKey()
    do @empty # from here on out these functions are the same

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
    @ieScriptPollTimeout = 5000

  module: (name) ->
    mod = @modules[name]
    if mod
      return mod
    else
      # this corresponds to a second module defined in a file that can't be
      # externally referenced via "cc.requires".
      return cc.modules[name] = new Module name

  # given "grandparent.parent.element"
  #    creates: cc.global.grandparent = { parent = {} }
  #    returns: [ cc.grandparent.parent, element ]
  namespaceFor: (ns) ->
    obj = @global
    components = ns.split '.'
    for space in components[0...(components.length - 1)]
      current = obj[space]
      if not current
        obj = obj[space] = {}
      else if typeof current == 'object'
        obj = current
      else
        alert "namespace conflict, #{ns} = #{current} of #{typeof current}"

    [ obj, components[components.length - 1] ]

  # set a value at a particular namespace under @global
  # e.g. ns = "hey.baby", val = "1"
  #   -> hey.baby = 1
  # If the namespace already exists then this call will throw an exception
  # unless the target and source are both objects, in which case the target
  # keys are merged into the source object.
  set: (ns, val) ->
    # console.log "cc.set #{ns} = #{val}"
    [ obj, lastComp ] = @namespaceFor ns
    current = obj[lastComp]
    if current
      # if existing and current are both objects then merge them
      if typeof current == 'object' and typeof val == 'object'
        for own key, subval of val
          current[key] = subval
      else
        alert "namespace conflict, #{ns} = #{current} of #{typeof current}"
    else
      obj[lastComp] = val
    this

  class: (ns, clss) ->
    if not Class?
      throw 'please install Joose to use cc.class'
    @namespaceFor ns
    Class ns, clss
    this

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
    this

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
      # IE just messes the onload up.
      @scriptOnload script, onload if onload if not @ieVersion
      # IE also messes up automatically calling this, so a timeout is set
      # in cc.require to test it later
      script.onerror = onerror if onerror

    script.src = path
    @head.appendChild script
    script
    this


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
        else if 'defined' != mod.status
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
    mod.script = @loadScript(
      path
      null
      # ->
      #   # success handler
      #   alert "loaded #{mod.name}"
      ->
        return if 'failed' == mod.status
        mod.status = 'failed'
        if callback
          callback(name)
        else
          alert "error requiring #{name}")

    if @ieVersion and not @_pollingForStupidIE
      loadingModules = []
      @_pollingForStupidIE = setInterval(
        =>
          for mod in loadingModules
            if 'loading' == mod.status
              do mod.script.onerror # will set status to "failed"

          loadingModules.length = 0
          for own key, mod of @modules when mod.script and mod.status == 'loading'
            loadingModules.push mod

          if not loadingModules.length
            clearInterval @_pollingForStupidIE
            delete @_pollingForStupidIE

          return
          # iterate through all modules looking for any that haven't loaded
        @ieScriptPollTimeout)

    this

window.cc = new CC

# vim:ts=2 sw=2
