cc.module('joose.root').requires('joose.Enemy', 'joose.Boss').defines (function(self) {
  // Use self.class to create a class inside of the module namespace.
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
      enemy  = new joose.Enemy(),
      boss   = new joose.Boss();

  friend.greet();
  enemy.greet();
  boss.attack();
});
// vim:ts=2 sw=2
