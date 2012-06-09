.PHONY: npm

coffee = ./node_modules/coffee-script/bin/coffee

cc.js: lib/commoncommon/web.coffee npm
	${coffee} -p $< > $@

npm:
	npm install

-include Makefile.local
