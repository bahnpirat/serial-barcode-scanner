PREFIX=/usr/local

VALA_SRC = $(wildcard *.vala)
C_SRC = $(wildcard *.c)

barcode-scanner: main.vala datatypes.vala session.vala device.vala db.vala web.vala
	valac-0.16 --output=$@ --pkg posix --pkg linux --pkg libsoup-2.4 --pkg json-glib-1.0 --pkg sqlite3 $^

#barcode-scanner: vala
#	clang -o $@ $(C_SRC) `pkg-config --cflags --libs libsoup-2.4 sqlite3`
#
#vala: $(VALA_SRC) 
#	valac-0.16 -C --pkg posix --pkg linux --pkg libsoup-2.4 --pkg sqlite3 $^

shop.db: create_db.sql insert-prices.sql insert-products.sql
	sqlite3 shop.db < create_db.sql 
	sqlite3 shop.db < insert-prices.sql 
	sqlite3 shop.db < insert-products.sql

install: barcode-scanner
	install -m755 barcode-scanner $(DESTDIR)$(PREFIX)/bin/barcode-scanner

clean:
	rm -f *.c
	rm -f barcode-scanner

.PHONY: clean install
