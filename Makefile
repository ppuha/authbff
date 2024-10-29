install-system-deps-ubuntu:
	sudo apt-get update
	sudo apt-get upgrade
	sudo apt-get install libgmp-dev openssl libssl-dev libev-dev

build:
	eval $(opam env)
	opam install dream yojson ppx_yojson_conv mustache cohttp cohttp-lwt-unix uuidm base64
	opam exec -- dune build .

prepare-deployment:
	mkdir deployment
	cp -r ./_build/default/bin/main.exe ./deployment
