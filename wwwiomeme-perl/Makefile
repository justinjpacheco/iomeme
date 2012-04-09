VERSION = 0.01

package:

	make clean

	mkdir build
	cp -r usr var etc build/
	cp -r DEBIAN build/

	fakeroot dpkg-deb --build build wwwiomeme-perl-$(VERSION).deb

install:

	make clean && make && sudo dpkg -i wwwiomeme*.deb

uninstall:

	sudo dpkg -P wwwiomeme-perl

clean:

	rm -rf build/ *.deb
