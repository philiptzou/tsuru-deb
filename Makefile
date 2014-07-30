.SECONDEXPANSION:
SHELL=/bin/bash

comma:= ,
empty:= 
space:= $(empty) $(empty)
pipe:= \|
hyphen:=-

GOVERSION=$(shell go version 2>/dev/null | sed 's/go version[^0-9]*\([0-9.]*\).*/\1/')
GOPATH=$(shell echo $$PWD)

include header.mk

ifdef DEBEMAIL
	debsign_opt := "-e$$DEBEMAIL"
else
	debsign_opt := ""
endif

all:
	@exit 0

clean:
	@git clean -dfX

prepare:
	sudo apt-get update -qq
	sudo apt-get install python-software-properties debhelper devscripts git mercurial ubuntu-dev-tools cowbuilder gnupg-agent golang cdbs -y

upload:
	if [ ! $(PPA) ]; then echo "PPA var must be set to upload packages... use: PPA=<value> make upload"; exit 1; fi
	eval $$(gpg-agent --daemon) && for file in *.changes; do debsign $(debsign_opt) $$file; done; unset file
	for file in *.changes; do dput ppa:$(PPA) $$file; done

builddeb: $(patsubst %-deb,%.builddeb,$(wildcard *-deb))

buildsrc: $(patsubst %-deb,%.buildsrc,$(wildcard *-deb))

# upload to PPA
# =============

$(patsubst %-deb,%.upload,$(wildcard *-deb)): %.upload: %.buildsrc
	@if [ ! $(PPA) ]; then \
		echo "PPA var must be set to upload packages... use: PPA=<value> make upload"; \
		exit 1; \
	fi
	eval $$(gpg-agent --daemon) && for file in $(SRCRESULT)/*.changes; \
		do debsign $(debsign_opt) $$file; \
	done; \
	unset file

# reprepro initialization
# =======================

$(VERSIONS:%=_distributions.%):
	$(eval VERSION := $(@:_distributions.%=%))
	$(eval dist := $(CURDIR)/localrepo.tmp/conf/distributions)
	echo "Origin: tsuru-deb" >> $(dist)
	echo "Label: tsuru-deb" >> $(dist)
	echo "Codename: $(or $(BUILDDIST_$(VERSION)),$(VERSION))" >> $(dist)
	echo "Architectures: i386 amd64 source" >> $(dist)
	echo "Components: main contrib" >> $(dist)
	echo "UDebComponents: main contrib" >> $(dist)
	echo "Description: tsuru-deb local repository" >> $(dist)
	echo "SignWith: yes" >> $(dist)
	echo >> $(dist)

localrepo:
	# Creating a local APT repository...
	# based on http://joseph.ruscio.org/blog/2010/08/19/setting-up-an-apt-repository/
	# thanks to Joseph Ruuscio
	@if [ ! $(GPGID) ]; then \
		echo 'Specify your GPG id/email in `variables.local.mk`:' >&2; \
		echo 'GPGID = [GPG id|GPG email]' >&2; \
		echo >&2; \
		echo 'You can generate your own GPG key with gnupg:' >&2; \
		echo '$$ sudo apt-get install gnupg' >&2; \
		echo '$$ gpg --gen-key' >&2; \
		exit 1; \
	fi
	sudo apt-get update -qq
	sudo apt-get install reprepro gnupg -y
	rm -rf $(CURDIR)/$@.tmp 2>/dev/null || true
	mkdir -p $(CURDIR)/$@.tmp/conf
	$(MAKE) $(patsubst %,_distributions.%,$(filter-out $(EXCEPT),$(VERSIONS)))
	echo "verbose" >> $(CURDIR)/$@.tmp/conf/options
	echo "ask-passphrase" >> $(CURDIR)/$@.tmp/conf/options
	echo "basedir ." >> $(CURDIR)/$@.tmp/conf/options
	gpg --armor --output $(CURDIR)/$@.tmp/public.key --export $(GPGID)
	cd $(CURDIR)/$@.tmp && reprepro export
	mv $(CURDIR)/$@.tmp $(CURDIR)/$@

# cowbuilder initialization
# =========================

$(VERSIONS:%=builder/%-base.cow):
	$(eval VERSION := $(@:builder/%-base.cow=%))
	$(eval export MIRRORSITE = $(MIRROR_$(VERSION)))
	$(eval export OTHERMIRROR = $(OTHERMIRROR_$(VERSION)))
	$(eval export PBUILDFOLDER = $(CURDIR)/builder)
	$(eval builddist := $(or $(BUILDDIST_$(VERSION)),$(VERSION)))
	$(eval localrepo := $(CURDIR)/localrepo)
	cowbuilder-dist $(VERSION) create --updates-only || true
	rm /tmp/repo.sh 2>/dev/null || true
	echo "apt-get update -qq" > /tmp/repo.sh
	echo "apt-get install apt-utils -y" >> /tmp/repo.sh
	echo "echo 'deb file://$(localrepo) $(builddist) main' > /etc/apt/sources.list.d/local_$(builddist).list" >> /tmp/repo.sh
	echo "echo 'deb-src file://$(localrepo) $(builddist) main' >> /etc/apt/sources.list.d/local_$(builddist).list" >> /tmp/repo.sh
	echo "cat $(localrepo)/public.key | apt-key add -" >> /tmp/repo.sh
	cowbuilder-dist $(VERSION) execute --bindmounts $(localrepo) --save --override-config --updates-only /tmp/repo.sh
	cowbuilder-dist $(VERSION) update --bindmounts $(localrepo) --override-config --updates-only
	rm /tmp/repo.sh 2>/dev/null || true

builder: $(patsubst %,builder/%-base.cow,$(filter-out $(EXCEPT),$(VERSIONS)))

# builddeb-related rules
# ======================

$(VERSIONS:%=_builddeb.%): builder
	$(eval VERSION := $(@:_builddeb.%=%))
	$(eval export MIRRORSITE = $(MIRROR_$(VERSION)))
	$(eval export OTHERMIRROR = $(OTHERMIRROR_$(VERSION)))
	$(eval export PBUILDFOLDER = $(CURDIR)/builder)
	mkdir -p $(DEBRESULT).tmp
	@rm $(DEBRESULT).tmp/* 2>/dev/null || true
	cowbuilder-dist $(VERSION) update --bindmounts $(CURDIR)/localrepo --override-config --updates-only
	cowbuilder-dist $(VERSION) build $(CURDIR)/$(TMP)$(TARGET)_*$(BUILDSUFFIX_$(VERSION))*.dsc --buildresult=$(DEBRESULT).tmp --debbuildopts="-sa" --bindmounts=$(CURDIR)/localrepo
	cd $(CURDIR)/localrepo && ls $(DEBRESULT).tmp/*.changes | xargs --verbose -L 1 reprepro include $(or $(BUILDDIST_$(VERSION)),$(VERSION))
	mv $(DEBRESULT).tmp $(DEBRESULT)

_builddeb: localrepo $(patsubst %,_builddeb.%,$(filter-out $(EXCEPT),$(VERSIONS)))

tsuru-server.builddeb serf.builddeb gandalf-server.builddeb archive-server.builddeb crane.builddeb tsuru-client.builddeb tsuru-admin.builddeb hipache-hchecker.builddeb docker-registry.builddeb tsuru-mongoapi.builddeb: golang.builddeb
lxc-docker.builddeb: golang.builddeb dh-golang.builddeb lvm2.builddeb btrfs-tools.builddeb

$(patsubst %-deb,%.builddeb,$(wildcard *-deb)): %.builddeb: %.buildsrc
	$(eval include scopedvars.mk)
	$(MAKE) _builddeb
	touch $@

# original tarball rules
# ======================

tsuru-server_$(TAG_tsuru-server).orig.tar.gz serf_$(TAG_serf).orig.tar.gz gandalf-server_$(TAG_gandalf-server).orig.tar.gz archive-server_$(TAG_archive-server).orig.tar.gz crane_$(TAG_crane).orig.tar.gz tsuru-client_$(TAG_tsuru-client).orig.tar.gz tsuru-admin_$(TAG_tsuru-admin).orig.tar.gz hipache-hchecker_$(TAG_hipache-hchecker).orig.tar.gz docker-registry_$(TAG_docker-registry).orig.tar.gz tsuru-mongoapi_$(TAG_tsuru-mongoapi).orig.tar.gz:
	$(eval include scopedvars.mk)
	mkdir -p $(GOBASE)
	rm -rf $(TARGET) 2>/dev/null || true
	GOPATH=$(TARGET) go get -v -u -d $(or $(GOURL),$(GITPATH)/...)
	git -C $(TARGET)/src/$(GITPATH) checkout $(or $(GITTAG),$(TAG))
	if [[ -d $(TARGET)/src/$(GITPATH)/Godeps ]]; then \
		cd $(TARGET)/src/$(GITPATH); \
		GOPATH=$(abspath $(TARGET)) godep restore ./...; \
	fi
	tar -zcf $@ -C $(GOBASE) $(TARGET)-$(TAG) --exclude-vcs $(TAR_OPTIONS)

lxc-docker_$(TAG_lxc-docker).orig.tar.gz:
	$(eval include scopedvars.mk)
	mkdir -p $(GITBASE)
	set -e; \
	if [ -d $(GITBASE)$(TARGET) ]; then \
		cd $(GITBASE)$(TARGET); git fetch; \
	else \
		git clone $(GITPATH) $(GITBASE)$(TARGET); \
	fi
	cd $(GITBASE)$(TARGET); \
	git archive --output $(abspath $@) --prefix=$(TARGET)-$(TAG)/ $(or $(GITTAG),$(TAG))

dh-golang_$(TAG_dh-golang).orig.tar.gz btrfs-tools_$(TAG_btrfs-tools).orig.tar.xz golang_$(TAG_golang).orig.tar.gz lvm2_$(TAG_lvm2).orig.tar.gz nodejs_$(TAG_nodejs).orig.tar.gz:
	$(eval include scopedvars.mk)
	curl -L -o $@ $(URL)

# buildsrc-related rules
# ======================

$(VERSIONS:%=_buildsrc.%):
	$(eval VERSION := $(@:_buildsrc.%=%))
	cp $(SRCRESULT).tmp/$(TARGET)/debian/changelog /tmp/$(TARGET).changelog.orig
	cd $(SRCRESULT).tmp/$(TARGET); DEBEMAIL=$(DEBEMAIL) DEBFULLNAME=$(DEBFULLNAME) dch -l $(BUILDSUFFIX_$(VERSION)) -D $(or $(BUILDDIST_$(VERSION)),$(VERSION)) $(BUILDTEXT_$(VERSION))
	cd $(SRCRESULT).tmp/$(TARGET); debuild --no-tgz-check -S -sa -us -uc
	mv /tmp/$(TARGET).changelog.orig $(SRCRESULT).tmp/$(TARGET)/debian/changelog

_buildsrc: $(patsubst %,_buildsrc.%,$(filter-out $(EXCEPT),$(VERSIONS)))

btrfs-tools.buildsrc: btrfs-tools_$(TAG_btrfs-tools).orig.tar.xz
tsuru-server.buildsrc serf.buildsrc gandalf-server.buildsrc archive-server.buildsrc crane.buildsrc tsuru-client.buildsrc tsuru-admin.buildsrc hipache-hchecker.buildsrc docker-registry.buildsrc tsuru-mongoapi.buildsrc lxc-docker.buildsrc lvm2.buildsrc golang.buildsrc: $$(patsubst %.buildsrc,%,$$@)_$$(TAG_$$(patsubst %.buildsrc,%,$$@)).orig.tar.gz
	$(eval include scopedvars.mk)
	rm -rf $(SRCRESULT).tmp/* || true
	mkdir -p $(SRCRESULT).tmp/$(TARGET)
	cp -r $(CURDIR)/$(TARGET)-deb/* $(SRCRESULT).tmp/$(TARGET)
	-cp $(CURDIR)/$(TARGET)_$(TAG).orig.tar.{xz,gz,bz2} $(SRCRESULT).tmp 2>/dev/null
	$(MAKE) _buildsrc
	rm -rf $(SRCRESULT).tmp/$(TARGET) || true
	mv $(SRCRESULT).tmp $(SRCRESULT)

dh-golang.buildsrc: dh-golang_$(TAG_dh-golang).orig.tar.gz
	$(eval include scopedvars.mk)
	rm -rf $(SRCRESULT).tmp/* || true
	mkdir -p $(SRCRESULT).tmp/
	tar -zxf $(CURDIR)/$(TARGET)_$(TAG).orig.tar.gz -C $(SRCRESULT).tmp/
	mv $(SRCRESULT).tmp/$(TARGET)-$(TAG) $(SRCRESULT).tmp/$(TARGET)
	$(MAKE) _buildsrc
	rm -rf $(SRCRESULT).tmp/$(TARGET) || true
	mv $(SRCRESULT).tmp $(SRCRESULT)
