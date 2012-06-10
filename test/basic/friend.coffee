cc.module('friend')
  .requires('pet.cat')
  .defines (meta) ->
    meta.log = ->
      jconsole.log 'friend'
    pet.cat.talk "friend"

# a second module that can't be externally referenced as it hasn't been
# required, and doesn't have a name corresponding to any filesystem path.
cc.module('enemy')
  .requires('pet.dog')
  .defines () ->
    pet.dog.talk "enemy"

# vim:ts=2 sw=2
