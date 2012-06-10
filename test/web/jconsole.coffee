cc.module('jconsole')
  .defines (self) ->
    self.log = (args...) ->
      newLine = document.createElement 'div'
      newLine.innerHTML = args.join(' ') + '<br/>'
      document.getElementsByTagName('body')[0].appendChild newLine


# vim:ts=2 sw=2
