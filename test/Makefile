.PHONY: build serve

coffee = ../node_modules/coffee-script/bin/coffee

build: web/cc.js web/joose.js
	${coffee} -c web

web/cc.js: ../cc.js
	ln -nsf ../$< $@

web/joose.js:
	cp ../node_modules/joose/joose-all-web.js web/joose.js

web/joose-2.1.js:
	wget http://joose-js.googlecode.com/files/joose.mini.js -O $@

serve: build
	${coffee} serve.coffee web
