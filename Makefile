#
# Makefile for Thyrd
#

usage:
	@echo "make fetch to get all libraries"

CSSLIB = assets/www/css
IMGLIB = assets/www/images
JSLIB = assets/www/js/lib
PLUGINS = assets/www/js/plugins

fetch: requirejs jquery 
	echo "Fetch complete"

misc:
	wget http://lesscss.googlecode.com/files/less-1.3.0.min.js -O $(JSLIB)/less.min.js
	cp server/node_modules/underscore/underscore.js $(JSLIB)/underscore.js
	cp server/node_modules/pagedown/Markdown.Converter.js $(JSLIB)/Markdown.Converter.js

requirejs: 
	wget http://requirejs.org/docs/release/2.1.10/minified/require.js -O $(JSLIB)/require.js
	wget https://raw.github.com/requirejs/text/latest/text.js -O $(PLUGINS)/text.js
	wget https://raw.github.com/requirejs/domReady/latest/domReady.js -O $(PLUGINS)/domReady.js
	#wget https://raw.github.com/requirejs/order/latest/order.js -O $(PLUGINS)/order.js

jquery:
	wget http://code.jquery.com/jquery-1.9.2.min.js -O $(JSLIB)/jquery.min.js


