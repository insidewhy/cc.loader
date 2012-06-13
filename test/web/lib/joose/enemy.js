cc.module('joose.enemy').requires('jconsole').defines (function() {
  cc.class('joose.enemy.Enemy', {
    methods: {
      greet: function() { jconsole.log("angry greets"); }
    }
  });
})
// vim:ts=2 sw=2
