cc.module('joose.Enemy').requires('jconsole').jClass({
  methods: {
    greet: function()  { jconsole.log("angry greets"); },
    attack: function() { jconsole.log("bump"); }
  }
});
// vim:ts=2 sw=2
