cc.module('pet.cat')
  .requires('jconsole')
  .defines (self) ->
    self.talk = (word) ->
      jconsole.log 'mew', word, 'mew'

# vim:ts=2 sw=2
