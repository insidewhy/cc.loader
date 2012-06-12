.PHONY: npm clean

coffee = ./node_modules/coffee-script/bin/coffee

cc.js: npm

npm:
	npm install

clean:
	rm `grep "/*.js" .gitignore | sed 's,^/,,'`

-include Makefile.local
