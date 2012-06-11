.PHONY: build serve

coffee = ../node_modules/coffee-script/bin/coffee

build: web/cc.js
	${coffee} -c web

web/cc.js: ../cc.js
	ln -nsf ../$< $@

serve: build
	${coffee} serve.coffee web
