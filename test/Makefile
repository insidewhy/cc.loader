.PHONY: build bake-test serve

coffee = ../node_modules/coffee-script/bin/coffee

build: web/cc.js web/joose.js web/lib/packed.js
	@${coffee} >/dev/null -c web

bake-test: web/lib/packed.js

serve: build
	@${coffee} serve.coffee web

web/cc.js: ../cc.js
	@ln -nsf ../$< $@

web/joose.js:
	@cp ../node_modules/joose/joose-all-web.js web/joose.js

web/joose-2.1.js:
	wget http://joose-js.googlecode.com/files/joose.mini.js -O $@

web/lib/packed.js: ./web/lib/root.js ./web/lib/joose/root.js
	../bin/ccbaker -v $^ > $@
