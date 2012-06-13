cc.module('joose.root').requires('joose.enemy').defines (function(self) {
  // Using cc.class to set any global joose class.
  self.class('Friend', {
    methods: {
      greet: function() { jconsole.log("friendly greets"); }
    }
  });

  // Using cc.class to do the same thing the long way
  cc.class('joose.root.Colleague', {
    methods: { greet: function() { jconsole.log("..."); } }
  });

  var friend = new joose.root.Friend(),
      enemy  = new joose.enemy.Enemy();

  friend.greet();
  enemy.greet();
})
// vim:ts=2 sw=2
