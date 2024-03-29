# cc.loader

A JavaScript module loading/creation system for the web including support for baking. It includes support for asynchronously loading modules and their dependencies from multiple script files using a simple but powerful JavaScript API. It can optionally integrate with [Joose](http://joose.github.com/Joose/doc/html/Joose/Manual.html) to ease adding classes to modules or creating module files that are classes. cc.loader is written in CoffeeScript but supports JavaScript and CoffeeScript modules and compiles/bakes all CoffeeScript to JavaScript. 

# installation

To install globally:

    sudo npm install -g cc.loader

# usage

## creating modules
To create a module with dependencies:
```javascript
cc.module('root')
  .requires('module', 'other.submodule')
  .defines (function() {
    // code for this module, runs after required modules are loaded.
  });
```

Each cc.loader module file must define a module name corresponding to its path otherwise the module  will fail to load (but with a helpful error message). For example "other.submodule" must be defined in "other/submodule.js" or "other/submodule.coffee". A configurable prefix which defaults to "lib" can also be prepended to the script path. Conversely when requiring a module as a dependency the filesystem path to load it from is determined from the module path.

Populating a module with cc.set:
```javascript
// file must exist at <prefix>/friend/root.js based on the module name.
cc.module('friend.root').defines(function() {
  // Populating the JavaScript namespace corresponding to the module name
  // isn't mandatory, it is just a fairly sensible convention to use for
  // most modules and/or projects.
  cc.set('friend.root.favourite', 'cat');

  // Namespaces other than the associated namespace can be populated.
  cc.set('friendly.Root.SayingsOf', { cat: 'meow', dog: 'woof' });

  // The namespace elements defined in this module will be available to the
  // `defines' callbacks of all including modules.
  var favourite = friend.root.favourite,
      catSays   = friend.Root.SayingsOf.cat;
});
```

## modules and namespaces
Each module has an associated JavaScript namespace with an identical name. There is no requirement for a module to populate this namespace but cc.loader provides simple mechanisms to do so if you want to use them.

The this object inside of the "defines" callback can be used to inject functions and variables into the JavaScript namespace associated with a module name:
```javascript
cc.module('pet.cat').defines(function() {
  // This makes pet.cat.style available to all modules that require pet.cat
  // Equivalent to: cc.set('pet.cat.style', 'sleepy');
  this.style = 'sleepy';

  // Equivalent to this.sound = 'meow'.
  this.set('sound', 'meow');

  // Also works to set pet.cat.friend.(dog/human):
  this.set('friend.dog',   false);
  this.set('friend.human', true);

  // The "pet.cat" namespace will only be created if "this"
  // contains at least one key, otherwise other mechanisms like cc.set can
  // be used to populate the module namespace and/or other namespaces.
});
```

Two modules split over two files:
```javascript
// file: lib/pet/cat.js
cc.module('pet.cat').defines (function() {
  this.talk = function(word) { console.log('mew' + word + 'mew'); }
});
```

```javascript
// file: lib/root.js
cc.module('root').requires('pet.cat').defines (function() {
  pet.cat.talk('prr');

  // this module elects not to use "this" and sets global variables manually.
  cc.global.Root = "important string!!"

  // cc.global is a reference to the global "window" object in JavaScript, or
  // "global" under node.
});
```

Multiple modules can exist in a single file but only things defined by the module which has a name corresponding to the filesystem path are publicly available when "defines" callbacks of including modules are run.

## loading modules
To use from html without baking:
```html
<script type="text/javascript" src="cc/loader.js"></script>
<script type="text/javascript">
    cc.libpath = 'lib'; // URL to the folder containing all modules.
                        // lib is the default.

    // assumes required module is at "lib/root/master.js". This will in turn load
    // all dependency modules and they can be debugged with full file paths.
    cc.require("root.master");
</script>
```

# baking
When using cc.require or &lt;script&gt; tags one web request is made to load each script. Each request involves a potentially large set of replicated headers which slows down the load speed of the page. Installing cc.loader provides the "ccbaker" command which can be used to combine all modules reachable from a certain module file into a single (potentially minified/obfuscated) JavaScript file which can be loaded quickly.

To bake a module together with its dependencies and minify the output:
```
% ccbaker module.js > output.js
```

The root directory is determined from the name of the module in the first source file passed and where it sits in the filesystem tree. "hello.baker" at lib/hello/baker.js would set the root to "lib" but a module named "baker" at lib/hello/baker.js would set the root as "lib/hello".

Full arguments:
```
% ccbaker -h
ccbaker [arguments] <paths to source files>
  arguments:
    -c            compile coffeescript modules to javascript only
    -C            do not compile coffeescript to javascript
    -i [path]     include raw source file before modules, can be used
                  multiple times
    -l            do not include cc.loader in output
    -m            do not minify javascript
    -o            obfuscate javascript
    -s            use strict mode for packed file
    -w  [path]    output baked file to [path] and keep watching all reachable
                  paths for changes, recreating baked file as they change
    -v            print extra information to the terminal on stderr
```

e.g. Bake the modules reachable from two files without minifying the output:
```
% ccbaker -m primary.js secondary.coffee > output.min.js
```

# advanced usage
## integration with joose
[Joose](http://joose.github.com/Joose/doc/html/Joose/Manual.html) is a object system for JavaScript. cc.loader provides some utility functions for creating Joose classes using the suggested namespace structure.

To create a Joose class under the module namespace:
```javascript
cc.module('joose.root').defines (function() {
  this.jClass('Friend', {
    methods: {
      greet: function() { console.log("friendly greets"); }
    }
  });
  // equivalent to: cc.jClass('joose.root.Friend', ...)

  var friend = new joose.root.Friend();
  friend.greet();
})
```

A module itself can be a Joose class:
```javascript
// file: lib/root/Enemy.js
cc.module('root.Enemy').jClass({
  // The module is the Joose class. I start these files with a capital letter
  // but it isn't mandatory.
  methods: {
    greet: function() { console.log("angry greets"); }
  }
})
```

An alternative way of making a module that is a Joose class:
```javascript
// file: lib/root/Boss.js
cc.module('joose.Boss').requires('joose.Enemy').defines(function() {
  // uses this.jClass as it must be postponed until after joose.Enemy has loaded
  // in order for the inheritance to work.
  this.jClass({
    isa: joose.Enemy,
    override: {
      attack: function() {
        console.log("throw hammer");
        this.SUPER();
        console.log("breath fire");
      }
    }
  });
});
```

Shorthand to create a module class that inherits another:
```javascript
// file: lib/root/EndBoss.js
cc.module('joose.EndBoss').parent('joose.Boss').jClass({
  // isa: joose.Boss, // not necessary, handled by .parent(...)
  after: {
    attack: function() {
      jconsole.log("special attack");
      jconsole.log("defeat");
      jconsole.log("is the princess");
    }
  }
});
```

```javascript
// file: lib/root.js
cc.module('root').requires('root.EndBoss').defines (function() {
  this.jClass('Friend', {
    methods: {
      greet: function() { console.log("friendly greets"); }
    }
  });

  var friend = new root.Friend(),
      enemy  = new joose.EndBoss();

  friend.greet();
  enemy.attack();
})
```

## hooks for custom class systems
```javascript
cc.module('Cat').defines(function() {
  // A 'extend' function can be used as a custom hook into the class system
  // for when a module sets this one as a parent.
  self.set('extend', function(clss) {
    clss.catlike = true;
    return clss;
  })
})
```

```javascript
// Since the parent namespace "Cat" defines "extend", then HouseCat is set to
// the return value of Cat.extend({ playful: true })
cc.module('HouseCat').parent('Cat').jClass({ playful: true })
```

```javascript
console.log(HouseCat.catlike, HouseCat.playful) // true, true
```

## empty modules
A module doesn't have to have a "defines" call but if not it must call "empty". This can be useful for creating modules that serve only to bundle other modules together:

```javascript
cc.module('util').requires('util.file', 'util.path').empty();
```

## module that is a function
```javascript
// This module only defines a function at the corresponding namespace.
cc.module('some.function').set(function() {
  console.log("some!");
})
```

## notes on development
IE makes it very difficult to reliably determine whether a script has loaded without polling, so errors indicating module load failures will not be seen until after a 10 second or so delay. For this reason developing module structures under IE is not recommended. Once the module structure works then debugging code under IE with full path names should be as easy as in a decent browser.

The poll timeout can be set with the following code and should be set before requiring the first module:
```javascript
cc.ieScriptPollTimeout = 5000; // in milliseconds, 5000 is the default
```
The reason every file requires a module corresponding to the filename is to support IE 8 and below.

# dependencies
 * baker: node.js, npm will fetch other node module dependencies.
 * web: nothing to use the library or a baked library. If Joose is loaded then a small amount of extra API is available.

# testing
```
% git clone git://github.com/nuisanceofcats/cc.loader.git
% cd cc.loader
% npm test
cc.loader test server listening on: 8012
please go to http://localhost:8012/
```

# FAQ
 * What does the name mean? I like [C.C. Lemon](http://en.wikipedia.org/wiki/C.C._Lemon)
 * Why not [RequireJS](http://requirejs.org/)? - RequireJS supports a lot of things, but has a large manual so it can be perceived as rather difficult to use. I prefer to use the namespacing system cc.loader provides over assigning every dependency to a variable as in RequireJS.
