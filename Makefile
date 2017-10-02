PREFIX?=/usr/local
INSTALL_NAME = stylesync

install: build install_bin

build:
	swift package --enable-prefetching update
	swift build --enable-prefetching -c release -Xswiftc -static-stdlib

install_bin:
	mkdir -p $(PREFIX)/bin
	mv .build/Release/StyleSync .build/Release/$(INSTALL_NAME)
	install .build/Release/$(INSTALL_NAME) $(PREFIX)/bin

uninstall:
	rm -rf .build/Release/StyleSync
	rm -rf .build/Release/$(INSTALL_NAME)
	rm -rf $(PREFIX)/bin/$(INSTALL_NAME)
