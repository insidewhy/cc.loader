// test that extra empty modules don't interfere with the baker when
// processing modules suppliend through argv.
cc.module('punch').empty()

cc.module('root')
  .requires('dropper', 'friend', 'funct', 'functo', 'pandar')
  .defines (function() {
    friend.log(friend.hero)
    jconsole.log(funct())
    jconsole.log(functo())
  })

// vim:ts=2 sw=2
