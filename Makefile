export PATH := $(PATH):$(HOME)/.pub-cache/bin:.
DART=dart


init:
	${DART} pub global activate webdev

release:
	webdev build --output web:build


debug:
	${DART} pub build --mode debug

get:
	${DART} pub get

serve:
	webdev serve

serve_release:
	webdev serve --release