cc.module('joose.root').requires('joose.EndBoss').defines (function() {
  // Use this.jClass to create a class inside of the module namespace.
  this.jClass('Friend', {
    methods: {
      greet: function() { jconsole.log("friendly greets"); }
    }
  });

  // Using cc.jClass to do the same thing the long way
  cc.jClass('joose.root.Colleague', {
    methods: { greet: function() { jconsole.log("..."); } }
  });

  var friend = new joose.root.Friend(),
      enemy  = new joose.Enemy(),
      boss   = new joose.EndBoss();

  friend.greet();
  enemy.greet();
  boss.attack();
});
// vim:ts=2 sw=2
