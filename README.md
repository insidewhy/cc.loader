ccloader
========

A javascript module loading/creation system for the web including support for baking. Written in coffeescript but supports javascript and coffeescript modules and compiles/bakes all coffeescript to javascript.

installation
============

To install globally:

    sudo npm install -g ccloader

usage
=====
To create a module with dependencies:
```javascript
cc.module('root')
  .requires('module', 'other.submodule')
  .defines (function(self) {
    // code for this module
  });
```
defines runs after the required modules have loaded.

Each ccloader module file must define a module name corresponding to its path otherwise the module  will fail to load (but with a helpful error message). For example "other.submodule" must be defined in "other/submodule.js" or "other/submodule.coffee". A configurable prefix which defaults to "lib" can also be prepended to the script path. Conversely when requiring a module as a dependency the filesystem path to load it from is determined from the module path.

examples
--------
Populating a module with cc.set
```javascript
// file must exist at <prefix>/friend/root.js based on the module name.
cc.module('friend.root').defines(function() {
  // Populating the javascript namespace corresponding to the module name
  // isn't mandatory, it is just a fairly sensible convention to use for
  // most modules and/or projects.
  cc.set('friend.root.favourite', 'cat');

  // You can populate any namespace from a module.
  cc.set('friend.Root.SayingsOf', { cat: 'meow', dog: 'woof' });

  // friend.* now available to this module and the `defines' callbacks
  // of all including modules.
  var favourite = friend.root.favourite;
      catSays   = friend.Root.SayingsOf.cat,
});
```

Populating a module through the defines callback argument
```javascript
cc.module('pet.cat').defines(function(self) {
  // This makes pet.cat.style available to all modules that require pet.cat
  self.style = "sleepy";

  // The "pet.cat" namespace will only be created if the self object
  // contains at least one key, otherwise other mechanisms like cc.set can
  // be used to populate the module namespace and/or other namespaces.
});
```

Two modules split over two files:
```javascript
// file: lib/pet/cat.js
cc.module('pet.cat').defines (function(self) {
  self.talk = function(word) { alert('mew' + word + 'mew'); }
});
```

```javascript
// file: lib/root.js
cc.module('root').requires('pet.cat').defines (function() {
  pet.cat.talk('prr');

  // this module elects not to use self and sets global variables manually.
  cc.global.Root = "important string!!"

  // cc.global is a reference to the global "window" object in javascript, or
  // "global" under node.
});
```

You can put multiple modules in a single file but only things defined by the module which has a name corresponding to the filesystem path is publically available.

baking
------
When using cc.require or &lt;script&gt; in a head of a javascript, many web conections are created in order to load each script. Each request involves a potentially large set of replicated headers which slows down the load speed of the page. Installing ccloader provides the "ccbaker" command which can be used to combine all modules reachable from a certain module file into a single (potentially minified/obfuscated) javascript file which can be loaded very fast by the browser.

To bake the module above together with its dependencies:

```shell
$ ccbaker root.js > output.js
```

The root directory is worked out based on the name of the module in the first source file passed and where it sits in the filesystem tree. "hello.baker" at lib/hello/baker.js would set the root to "lib" but "baker" at lib/hello/baker.js would set the root to "lib/hello".

Full arguments:
```shell
$ ccbaker -h
ccbaker [arguments] <paths to source files>
  arguments:
    -c            compile coffeescript modules to javascript only
    -C            do not compile coffeescript to javascript.
    -m            minify javascript
    -o            obfuscate javascript
    -w  [path]    output baked file to [path] and keep watching all reachable
                  paths for changes, recreating baked file as they change
    -v            print extra information to the terminal on stderr
```
Bake the modules reachable from two files and minify the output:
```shell
$ ccbaker -m primary.js secondary > output.min.js
```

using unbaked modules
---------------------
To use from html without baking:
```html
<script type="text/javascript" src="cc.js"></script>
<script type="text/javascript">
    cc.libpath = 'lib'; // URL to the folder containing all your modules.
                        // lib is the default.

    // assumes your module is at "lib/root/master.js". This will in turn load
    // all dependency modules and you will be able to debug them with their full
    // file paths.
    cc.require("root.master");
</script>
```

If some of your scripts require access to the dom then you may wish to do your original require in body.onload or jquery.ready:
```html
<script type="text/javascript" src="cc.js"></script>
<script type="text/javascript">
    cc.libpath = 'lib';
    $.ready(function() {
        cc.require("root.master");
    })
</script>
```

notes on development
--------------------
IE makes it impossible to reliably determine whether a script has loaded without polling, so you will not see errors indicating module load failures until after a 10 second or so delay. For this reason developing your module strucure under IE is not recommended. Once the module structure works then debugging code under IE with full path names should be as easy as in a decent browser.

The poll timeout can be set with the following code and should be set before requiring the first module:

```javascript
cc.ieScriptPollTimeout = 5000; // in milliseconds, 5000 is the default
```

dependencies
============
 * baker: node.js, npm will fetch other node module dependencies for you.
 * web: nothing to use the library or a baked library.

Why ccloader
============
I like [C.C. Lemon](http://en.wikipedia.org/wiki/C.C._Lemon)
