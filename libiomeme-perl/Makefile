VERSION = 0.01

package:

	mkdir build
	cp -r usr build/
	cp -r DEBIAN build/

	fakeroot dpkg-deb --build build libiomeme-perl-$(VERSION).deb

clean:

	rm -rf build/ *.deb
