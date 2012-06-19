cc.module('joose.Boss').requires('joose.Enemy').defines(function() {
  // uses self.class as it must be postponed until after joose.Enemy has loaded
  // in order for the inheritance to work.
  this.class({
    isa: joose.Enemy,
    methods: {
      attack: function() {
        jconsole.log("throw hammer");
        this.SUPER();
        jconsole.log("breath fire");
      }
    }
  });
});
