
all:
	@echo "make [js|hl|test]"

js:
	haxe build_script/js.hxml
	cp build_script/index.html build/js/.

ld:
	cd build/js; zip ../../ld45.zip *

hl:
	haxe build_script/hl.hxml

test:
	haxe build_script/test.hxml

debug:
	haxe build_script/test.hxml --debug
