cc.module('root')
  .requires('dropper', 'friend')
  .defines (function() {
    friend.log(friend.hero)
  })

// vim:ts=2 sw=2
