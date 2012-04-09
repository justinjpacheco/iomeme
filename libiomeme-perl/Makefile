VERSION = 0.01

package:

	make clean

	mkdir build
	cp -r usr build/
	cp -r DEBIAN build/

	fakeroot dpkg-deb --build build libiomeme-perl-$(VERSION).deb

install:

	make clean && make && sudo dpkg -i libiomeme*.deb && make clean

uninstall:

	sudo dpkg -P libiomeme-perl

clean:

	rm -rf build/ *.deb
