cc.module('joose.EndBoss').parent('joose.Boss').jClass({
  after: {
    attack: function() {
      jconsole.log("special attack");
      jconsole.log("defeat");
      jconsole.log("is the princess");
    }
  }
});
