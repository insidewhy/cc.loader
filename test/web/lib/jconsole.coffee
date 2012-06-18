cc.module('jconsole')
  .defines (self) ->
    logPane = null
    backup = []
    clearLog = () ->
      logPane.appendChild line for line in backup
      backup.length = 0

    # clearLogInterval = () ->

    self.log = (args...) ->
      newLine = document.createElement 'div'
      newLine.innerHTML = args.join(' ') + '<br/>'
      try
        logPane = document.getElementsByTagName('body')[0]
      catch e
        backup.append newLine
        # TODO: start interval in which to clear backup
        return

      do clearLog
      logPane.appendChild newLine


# vim:ts=2 sw=2
