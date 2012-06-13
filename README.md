ccloader
========

A JavaScript module loading/creation system for the web including support for baking. It includes support for asynchronously loading modules and their dependencies from multiple script files using a simple but powerful JavaScript API. It can optionally integrate with [Joose](http://joose.github.com/Joose/doc/html/Joose/Manual.html) to ease adding classes to modules or creating module files that are classes. ccloader is written in CoffeeScript but supports JavaScript and CoffeeScript modules and compiles/bakes all CoffeeScript to JavaScript. 

installation
============

To install globally:

    sudo npm install -g ccloader

usage
=====

creating modules
----------------
To create a module with dependencies:
```javascript
cc.module('root')
  .requires('module', 'other.submodule')
  .defines (function(self) {
    // code for this module, runs after required modules are loaded.
  });
```

Each ccloader module file must define a module name corresponding to its path otherwise the module  will fail to load (but with a helpful error message). For example "other.submodule" must be defined in "other/submodule.js" or "other/submodule.coffee". A configurable prefix which defaults to "lib" can also be prepended to the script path. Conversely when requiring a module as a dependency the filesystem path to load it from is determined from the module path.

Populating a module with cc.set:
```javascript
// file must exist at <prefix>/friend/root.js based on the module name.
cc.module('friend.root').defines(function() {
  // Populating the JavaScript namespace corresponding to the module name
  // isn't mandatory, it is just a fairly sensible convention to use for
  // most modules and/or projects.
  cc.set('friend.root.favourite', 'cat');

  // You can populate any namespace from a module.
  cc.set('friend.Root.SayingsOf', { cat: 'meow', dog: 'woof' });

  // friend.* now available to this module and the `defines' callbacks
  // of all including modules.
  var favourite = friend.root.favourite,
      catSays   = friend.Root.SayingsOf.cat;
});
```

modules and namespaces
----------------------
Each module has an associated JavaScript namespace with an identical name. There is no requirement for a module to populate this namespace but ccloader provides simple mechanisms to do so if you want to use them. Personally I believe that this is the most sensible way to structure modules.

The first argument passed to the "defines" callback can be used to inject functions and variables into the JavaScript namespace associated with a module name:
```javascript
cc.module('pet.cat').defines(function(self) {
  // This makes pet.cat.style available to all modules that require pet.cat
  // Equivalent to: cc.set('pet.cat.style', 'sleepy');
  self.style = 'sleepy';

  // Equivalent to self.sound = 'meow'.
  self.set('sound', 'meow');

  // Also works:
  self.set('friend.dog',   false);
  self.set('friend.human', true);

  // The "pet.cat" namespace will only be created if the self object
  // contains at least one key, otherwise other mechanisms like cc.set can
  // be used to populate the module namespace and/or other namespaces.
});
```

Two modules split over two files:
```javascript
// file: lib/pet/cat.js
cc.module('pet.cat').defines (function(self) {
  self.talk = function(word) { console.log('mew' + word + 'mew'); }
});
```

```javascript
// file: lib/root.js
cc.module('root').requires('pet.cat').defines (function() {
  pet.cat.talk('prr');

  // this module elects not to use self and sets global variables manually.
  cc.global.Root = "important string!!"

  // cc.global is a reference to the global "window" object in JavaScript, or
  // "global" under node.
});
```

Multiple modules can exist in a single file but only things defined by the module which has a name corresponding to the filesystem path are publicly available when "defines" callbacks of including modules are run.

loading modules
---------------
To use from html without baking:
```html
<script type="text/JavaScript" src="cc.js"></script>
<script type="text/JavaScript">
    cc.libpath = 'lib'; // URL to the folder containing all your modules.
                        // lib is the default.

    // assumes your module is at "lib/root/master.js". This will in turn load
    // all dependency modules and you will be able to debug them with their full
    // file paths.
    cc.require("root.master");
</script>
```

advanced usage
==============

integration with joose
----------------------
[Joose](http://joose.github.com/Joose/doc/html/Joose/Manual.html) is a object system for JavaScript. ccloader provides some utility functions for creating Joose classes using the suggested namespace structure.

To create a Joose class under the module namespace:
```javascript
cc.module('joose.root').defines (function(self) {
  self.class('Friend', {
    methods: {
      greet: function() { console.log("friendly greets"); }
    }
  });
  // equivalent to: cc.class('joose.root.Friend', ...)

  var friend = new joose.root.Friend();
  friend.greet();
})
```

A module itself can be a Joose class. The following two files show how to create and use such a class:
```javascript
// file: lib/root/Enemy.js
cc.module('root.Enemy').class({
  // The module is the Joose class. I start these files with a capital letter
  // but it isn't mandatory.
  methods: {
    greet: function() { console.log("angry greets"); }
  }
})
```

```javascript
// file: lib/root.js
cc.module('root').requires('root.Enemy').defines (function(self) {
  self.class('Friend', {
    methods: {
      greet: function() { console.log("friendly greets"); }
    }
  });

  var friend = new root.Friend(),
      enemy  = new root.Enemy();

  friend.greet();
  enemy.greet();
})
```

baking
======
When using cc.require or &lt;script&gt; tags one web request is made to load each script. Each request involves a potentially large set of replicated headers which slows down the load speed of the page. Installing ccloader provides the "ccbaker" command which can be used to combine all modules reachable from a certain module file into a single (potentially minified/obfuscated) JavaScript file which can be loaded quickly.

To bake the module above together with its dependencies:

```shell
$ ccbaker root.js > output.js
```

The root directory is determined from the name of the module in the first source file passed and where it sits in the filesystem tree. "hello.baker" at lib/hello/baker.js would set the root to "lib" but a module named "baker" at lib/hello/baker.js would set the root as "lib/hello".

Full arguments:
```shell
$ ccbaker -h
ccbaker [arguments] <paths to source files>
  arguments:
    -c            compile CoffeeScript modules to JavaScript only
    -C            do not compile CoffeeScript to JavaScript
    -m            minify JavaScript
    -o            obfuscate JavaScript
    -w  [path]    output baked file to [path] and keep watching all reachable
                  paths for changes, recreating baked file as they change
    -v            print extra information to the terminal on stderr
```
Bake the modules reachable from two files and minify the output:
```shell
$ ccbaker -m primary.js secondary > output.min.js
```

notes on development
--------------------
IE makes it impossible to reliably determine whether a script has loaded without polling, so you will not see errors indicating module load failures until after a 10 second or so delay. For this reason developing your module structure under IE is not recommended. Once the module structure works then debugging code under IE with full path names should be as easy as in a decent browser.

The poll timeout can be set with the following code and should be set before requiring the first module:

```javascript
cc.ieScriptPollTimeout = 5000; // in milliseconds, 5000 is the default
```

dependencies
============
 * baker: node.js, npm will fetch other node module dependencies for you.
 * web: nothing to use the library or a baked library. If Joose is loaded then a small amount of extra API is available.

FAQ
===
 * What does the name mean? I like [C.C. Lemon](http://en.wikipedia.org/wiki/C.C._Lemon)
 * Why not [RequireJS](http://requirejs.org/)? - RequireJS supports a lot of things, but has a large manual so it can be perceived as rather difficult to use. I prefer to use the namespacing system ccloader provides over assigning every dependency to a variable as in RequireJS.
