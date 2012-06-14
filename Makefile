.PHONY: npm clean

coffee = ./node_modules/coffee-script/bin/coffee

cc.js: npm

npm:
	@npm >/dev/null install

clean:
	rm -f `grep "/*.js" .gitignore | sed 's,^/,,'`

test: npm
	@${MAKE} -Ctest serve

-include Makefile.local
