cc.module('pet.dog')
  .requires('jconsole')
  .defines () ->
    @talk = (word) ->
      jconsole.log 'wff', word, 'rff'

# vim:ts=2 sw=2
