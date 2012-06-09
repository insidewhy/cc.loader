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
  .defines (function() {
    // code for this module
  })
```

A modules name relates to its path in the filesystem, so "other.submodule" is loaded from "lib/other/submodule.js" or "lib/other/submodule.coffee".

baking
------
Baked html can be used directly from the browser. This speeds up loading your website a great deal but you will lose path information when javascript debugging. 

To bake the module above together with its dependencies:

```shell
$ ccbaker root > output.js
```

A different library prefix can be set with -l.
```shell
$ ccbaker -l lib2 root > output.js
```

Full arguments:
```shell
$ ccbaker -h
ccbaker [arguments] module.path
  arguments:
    -c            compile coffeescript modules to javascript only.
    -l  [path]    path containing all libraries, default: lib
    -m            minify javascript
    -w  [path]    output baked file to [path] and keep watching all reachable
                  paths for changes, recreating baked file as they change
    -v            print extra information to the terminal on stderr
```

using unbaked modules
---------------------
To use from html without baking:
```html
<script type="text/javascript" src="commoncommon.js">
    cc.libpath = 'lib' // the default path containing all your modules.

    // assumes your root module is at "lib/root/master.js". This will in turn load
    // all dependency modules and you will be able to debug them with their full
    // file paths.
    cc.require("root.master");
</script>
```

dependencies
============
 * baker: npm and node. npm will fetch other node module depencies for you.
 * web: nothing to use the library or a baked library.
