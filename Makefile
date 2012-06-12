.PHONY: npm

coffee = ./node_modules/coffee-script/bin/coffee

cc.js: npm

npm:
	npm install

-include Makefile.local
