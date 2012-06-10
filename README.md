commoncommon
============

A javascript module loading/creation system for the web including support for baking. Written in coffeescript but supports javascript and coffeescript modules and compiles/bakes all coffeescript to javascript.

installation
============

To install globally:

    sudo npm install -g commoncommon

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
defines runs after the module dependencies have loaded.

A modules name relates to its browser path, so "other.submodule" is loaded from "lib/other/submodule.js" or "lib/other/submodule.coffee" (the prefix "lib" can be customised).

examples
--------
Populating a module with cc.set
```javascript
cc.module('root')
  .defines(function() {
    cc.set('root.SayingsOf', { cat: 'meow', dog: 'woof' });
    cc.set('root.favourite', 'cat');

    // also now avaliable to all including modules.
    var catSays   = root.SayingsOf.cat,
        favourite = root.favourite;
  });
```

Populating a module through the defines callback argument
```javascript
cc.module('pet.cat')
  .defines(function(self) {
    self.style = "sleepy";
    // pet.cat.style will be available to all modules that require pet.cat
    // The "pet.cat" namespace will only be created if the self object contains
    // at least one key, otherwise other mechanisms like cc.set can be used
    // to populate the module namespace and/or other namespaces.
  });
```

Two modules split over two files:
```javascript
// file: lib/pet/cat.js
cc.module('pet.cat')
  .defines (function(self) {
    self.talk = function(word) { alert('mew' + word + 'mew'); }
  });
```

```javascript
// file: lib/root.js
cc.module('root')
  .defines (function() {
    pet.cat.talk('prr');

    // this module elects not to use self and sets global variables manually.
    cc.global.Root = "important string!!"

    // cc.global is a reference to the global "window" object in javascript, or
    // "global" under node.
  });
```

You can put multiple modules in a single file but only the module which has a name corresponding to the filesystem path is publically available.

baking
------
Baked html can be used directly from the browser. This speeds up loading your website a great deal but you will lose path information when javascript debugging. 

To bake the module above together with its dependencies:

```shell
$ ccbaker root.js > output.js
```

The root directory is worked out based on the name of the root module and where it sits in the file-system tree. "hello.baker" at lib/hello/baker.js would set the root to "lib" but "baker" at lib/hello/baker.js would set the root to "lib/hello".

Full arguments:
```shell
$ ccbaker -h
ccbaker [arguments] <path to root module>
  arguments:
    -c            compile coffeescript modules to javascript only
    -m            minify javascript
    -w  [path]    output baked file to [path] and keep watching all reachable
                  paths for changes, recreating baked file as they change
    -v            print extra information to the terminal on stderr
```

using unbaked modules
---------------------
To use from html without baking:
```html
<script type="text/javascript" src="cc.js"></script>
<script type="text/javascript">
    cc.libpath = 'lib'; // URL to the folder containing all your modules.
                        // lib is the default.

    // assumes your root module is at "lib/root/master.js". This will in turn load
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
