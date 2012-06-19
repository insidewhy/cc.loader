cc.module('joose.EndBoss').parent('joose.Boss').class({
  after: {
    attack: function() {
      jconsole.log("special attack");
      jconsole.log("defeat");
      jconsole.log("is the princess");
    }
  }
});
