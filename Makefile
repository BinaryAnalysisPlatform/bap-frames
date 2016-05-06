SETUP = ocaml setup.ml

build: setup.data
	$(SETUP) -build $(BUILDFLAGS)

doc: setup.data build
	$(SETUP) -doc $(DOCFLAGS)

test: setup.data build
	$(SETUP) -test $(TESTFLAGS)


install: setup.data
	$(SETUP) -install $(INSTALLFLAGS)
	make plugin

uninstall: setup.data
	$(SETUP) -uninstall $(UNINSTALLFLAGS)

plugin:
	make -C plugin

reinstall:
	make uninstall;
	make install

clean:
	$(SETUP) -clean $(CLEANFLAGS)

distclean:
	$(SETUP) -distclean $(DISTCLEANFLAGS)

setup.data:
	$(SETUP) -configure $(CONFIGUREFLAGS)

configure:
	$(SETUP) -configure $(CONFIGUREFLAGS)

.PHONY: build doc test all install uninstall reinstall clean distclean configure plugin

PIQI=piqi
OCI=ocp-indent

.PHONY: check
check: check-piqi check-ocp-indent

.PHONY: check-piqi
check-piqi: *.piqi
	for piqifile in $^; do $(PIQI) check --strict $$piqifile; done

.PHONY: check-ocp-indent
check-ocp-indent: *.ml
	for mlfile in $^; do $(OCI) $$mlfile | diff - $$mlfile; done

.PHONY: auto-ocp-indent
auto-ocp-indent: *.ml
	for mlfile in $^; do $(OCI) -i $$mlfile; done
