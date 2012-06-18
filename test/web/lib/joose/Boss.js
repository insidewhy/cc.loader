cc.module('joose.Boss').requires('joose.Enemy').defines(function(self) {
  // uses self.class as it must be postponed until after joose.Enemy has loaded
  // in order for the inheritance to work.
  self.class({
    isa: joose.Enemy,
    override: {
      attack: function() {
        jconsole.log("throw hammer");
        this.SUPER();
        jconsole.log("breath fire");
      }
    }
  });
});
