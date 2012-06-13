cc.module('joose.root').requires('joose.enemy').defines (function() {
  // Using cc.class to set any global joose class.
  cc.class('joose.root.Friend', {
    methods: {
      greet: function() { jconsole.log("friendly greets"); }
    }
  });

  var friend = new joose.root.Friend(),
      enemy  = new joose.enemy.Enemy();

  friend.greet();
  enemy.greet();
})
// vim:ts=2 sw=2
