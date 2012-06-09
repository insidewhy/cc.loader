cc.module('friend')
  .requires('pet.cat')
  .defines (meta) ->
    meta.log = ->
      jconsole.log 'friend'
    pet.cat.talk "friend"

# vim:ts=2 sw=2
