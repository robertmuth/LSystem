export PATH := $(PATH):$(HOME)/.pub-cache/bin:.
PUB=/usr/lib/dart/bin/pub
DART=dart


init:
	{PUB} global activate webdev

release:
	webdev build --output web:build


debug:
	${PUB} build --mode debug

get:
	${PUB} get

serve:
	webdev serve

serve_release:
	webdev serve --release