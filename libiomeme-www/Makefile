VERSION = 0.01

package:

	make clean

	mkdir build
	cp -r usr var etc build/
	cp -r DEBIAN build/

	fakeroot dpkg-deb --build build libiomeme-www-$(VERSION).deb

install:

	make clean && make && sudo dpkg -i *.deb && make clean

uninstall:

	sudo dpkg -P libiomeme-www

clean:

	rm -rf build/ *.deb
