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
    // any variables you add to "self" will be proprogated an object reachable at
    // other.submodule, although you can always ignore the argument and just manipulate
    // global variables directly.
  })
```

A modules name relates to its browser path, so "other.submodule" is loaded from "lib/other/submodule.js" or "lib/other/submodule.coffee" (the prefix "lib" can be customised).

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

dependencies
============
 * baker: node.js, npm will fetch other node module dependencies for you.
 * web: nothing to use the library or a baked library.
