class Module
  constructor: (@name) ->
  requires: (libs...) ->
    for lib in libs
      cc.require lib
    this
  defines: () ->
    moduleOrder.push this
    this

class CC
  constructor: () ->
    @libdir = 'lib'
    @loaded = {}

  module: (name) ->
    if @loaded[name]
      alert "module #{name} already defined"
    else
      new Module name

  require: (mod) ->
    return @loaded[mod] if @loaded[mod]

    path = @libdir + '/' + mod.replace /\./g, '/'
    # require a module, but only after its dependencies are done

window.cc = new CC

# vim:ts=2 sw=2
