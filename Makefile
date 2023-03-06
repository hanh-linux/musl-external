workdir = $(.CURDIR)
prefix ?= /usr/local
libdir ?= $(prefix)/lib
bindir ?= $(prefix)/bin
includedir ?= $(prefix)/include
sysconfdir ?= etc/
CARCH ?= x86_64

MSGFMT ?= msgfmt
CC     ?= gcc
LD     ?= ld 
AR     ?= ar
RANLIB ?= ranlib
CPPFLAGS += -I./include -I./config

installprog    = install -Dm755 
installshared  = install -Dm755
installstatic  = install -Dm644
installstuff   = install -Dm644
installdir     = install -dm755

all_locales = cs_CZ en_GB fi_FI it_IT nb_NO \
	pt_PT sv_SE de_CH en_US fr_CA \
	nl_NL ru_RU de_DE es_ES fr_FR \
	pt_BR sr_RS

all: config/config.h headers lib/libc_external.so.0.0.0 lib/libc_external.a bin/locale bin/gencat bin/genent musl-po po i18n lc

install: install-basedir install-bin install-dev install-shared install-static install-lc install-i18n 

config/config.h: config/config.h.in
	cp -r config/config.h.in config/config.h
	sed -i 's|@prefix@|$(prefix)|g' config/config.h

headers: config/config.h
	CC="$(CC)" ./config/test_headers

out/locale.o: config/config.h locales/locale.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -O3 -DNDEBUG -std=gnu11 -Wno-pedantic -o out/locale.o -c locales/locale.c

out/categories.o: locales/categories.c 
	$(CC) $(CPPFLAGS) $(CFLAGS) -O3 -DNDEBUG -std=gnu11 -Wno-pedantic -o  out/categories.o -c locales/categories.c 

bin/locale: out/locale.o out/categories.o 
	$(CC) -O3 -DNDEBUG -rdynamic -o bin/locale out/locale.o out/categories.o 

i18n:
	MSGFMT="$(MSGFMT)" ./build i18n

lc:
	MSGFMT="$(MSGFMT)" ./build lc

out/fts.o: config/config.h fts/fts.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -fPIC -o out/fts.o -c fts/fts.c 

out/obstack.o: config/config.h obstack/obstack.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -fPIC -o out/obstack.o -c obstack/obstack.c 

out/obstack_printf.o: config/config.h obstack/obstack_printf.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -fPIC -o out/obstack_printf.o -c obstack/obstack_printf.c

out/stacktraverse.o: execinfo/stacktraverse.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -fPIC -std=gnu99 -fno-strict-aliasing -fstack-protector -o out/stacktraverse.o -c execinfo/stacktraverse.c

out/execinfo.o: execinfo/execinfo.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -fPIC -std=gnu99 -fno-strict-aliasing -fstack-protector -o out/execinfo.o -c execinfo/execinfo.c

bin/gencat: gencat.c 
	$(CC) $(CFLAGS) $(CPPFLAGS) $(LDFLAGS) -lc -o bin/gencat gencat.c

bin/genent: genent.c
	$(CC) $(CFLAGS) $(CPPFLAGS) $(LDFLAGS) -lc -o bin/genent genent.c

lib/libc_external.so.0.0.0: out/fts.o out/obstack.o out/obstack_printf.o out/stacktraverse.o out/execinfo.o
	$(LD) $(LDFLAGS) -lc -shared -o lib/libc_external.so.0.0.0 out/fts.o out/obstack.o out/obstack_printf.o out/stacktraverse.o out/execinfo.o

lib/libc_external.a: out/fts.o out/obstack.o out/obstack_printf.o out/stacktraverse.o out/execinfo.o
	$(AR) -rc lib/libc_external.a out/fts.o out/obstack.o out/obstack_printf.o out/stacktraverse.o out/execinfo.o
	$(RANLIB) lib/libc_external.a

install-basedir: 
	$(installdir) $(DESTDIR)/$(bindir)
	$(installdir) $(DESTDIR)/$(libdir)
	$(installdir) $(DESTDIR)/$(includedir)

install-bin: install-basedir
	$(installprog) bin/locale $(DESTDIR)/$(bindir)/locale
	$(installprog) bin/genent $(DESTDIR)/$(bindir)/genent
	$(installprog) bin/gencat $(DESTDIR)/$(bindir)/gencat

install-dev: install-basedir
	DESTDIR="$(DESTDIR)" prefix="$(prefix)" ./build install_dev

install-shared: lib/libc_external.so.0.0.0 install-basedir
	$(installshared) lib/libc_external.so.0.0.0 $(DESTDIR)/$(libdir)/libc_external.so.0.0

install-static: lib/libc_external.a install-basedir 
	$(installstatic) lib/libc_external.a $(DESTDIR)/$(libdir)/libc_external.a

install-i18n: 
	MSGFMT="$(MSGFMT)" DESTDIR="$(DESTDIR)" prefix="$(prefix)" ./build install_i18n

install-lc: 
	MSGFMT="$(MSGFMT)" DESTDIR="$(DESTDIR)" prefix="$(prefix)" ./build install_lc

install-glibc-compat: install-basedir 
	$(installprog) ldconfig $(DESTDIR)/$(bindir)/ldconfig
	$(installstuff) ld-musl.path $(DESTDIR)/$(sysconfdir)/ld-musl-$(CARCH).path 

clean:
	rm -rf config/config.h
	rm -rf out lib bin po musl-po tmp 
	mkdir out lib bin po musl-po tmp


