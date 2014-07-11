DEFINED_VERSION=precise
VERSIONS=precise trusty wheezy
SHELL=/bin/bash

comma:= ,
empty:= 
space:= $(empty) $(empty)
pipe:= \|
hyphen:=-

GOVERSION=$(shell go version 2>/dev/null | sed 's/go version[^0-9]*\([0-9.]*\).*/\1/')
GOPATH=$(shell echo $$PWD)

-include variables.mk

ifdef DEBEMAIL
	debsign_opt := "-e$$DEBEMAIL"
else
	debsign_opt := ""
endif

all:
	@exit 0

clean:
	@git clean -dfX

.download-godeb:
	@wget https://godeb.s3.amazonaws.com/godeb-amd64.tar.gz -O godeb-amd64.tar.gz
	@tar xzf godeb-amd64.tar.gz
	@chmod +x godeb
	@touch .download-godeb

.download-go: .download-godeb
	@./godeb download 1.2.2
	@touch .download-go

.install-go:
	@if [ $(GOVERSION) \< 1.2.0 ]; then \
		make .download-go; \
		sudo dpkg -i go_*-godeb1_amd64.deb; \
	fi
	@touch .install-go

/usr/bin/godep: .install-go
	@if [ ! -d /tmp/gopath ]; then mkdir /tmp/gopath; fi
	GOPATH=/tmp/gopath go get github.com/kr/godep
	@sudo mv /tmp/gopath/bin/godep /usr/bin
	@rm -rf /tmp/gopath

.install-godep: /usr/bin/godep

.build-deps:
	@sudo apt-get update
	sudo apt-get install python-software-properties debhelper devscripts git mercurial ubuntu-dev-tools cowbuilder gnupg-agent -y
	@touch .build-deps

.PHONY: build-deps builder build .builder-create

build-deps: .build-deps .install-godep

.builder-wheezy:
	@rm /tmp/ppa.sh 2>/dev/null || true
	@echo "/usr/bin/apt-get update" >> /tmp/ppa.sh
	@touch $@

.builder-precise .builder-saucy .builder-trusty:
	@rm /tmp/ppa.sh 2>/dev/null || true
	@echo "/usr/bin/apt-get update" >> /tmp/ppa.sh
	@echo "/usr/bin/apt-get install -y python-software-properties software-properties-common" >> /tmp/ppa.sh
	@echo "/usr/bin/add-apt-repository -y ppa:tsuru/ppa" >> /tmp/ppa.sh
	@echo "/usr/bin/add-apt-repository -y ppa:tsuru/lvm2" >> /tmp/ppa.sh
	@echo "/usr/bin/add-apt-repository -y ppa:tsuru/golang" >> /tmp/ppa.sh
	@echo "/usr/bin/add-apt-repository -y ppa:tsuru/docker" >> /tmp/ppa.sh
	@export MIRRORSITE=$(MIRROR_$(DIST)); \
	export OTHERMIRROR=$(OTHERMIRROR_$(DIST)); \
	cowbuilder-dist $(DIST) execute --save --override-config --updates-only /tmp/ppa.sh; \
	cowbuilder-dist $(DIST) update --override-config --updates-only
	@rm /tmp/ppa.sh 2>/dev/null || true
	@touch $@

.builder-create:
	@export MIRRORSITE=$(MIRROR_$(DIST)); \
	export OTHERMIRROR=$(OTHERMIRROR_$(DIST)); \
	cowbuilder-dist $(DIST) create --updates-only || true
	make DIST=$(DIST) .builder-$(DIST)

builder:
	@for version in $(VERSIONS); do \
		make DIST=$$version .builder-create; \
	done

build:
	for version in $(VERSIONS); do \
	    cowbuilder-dist $$version build *$${version}*.dsc; \
	done
	
upload:
	if [ ! $(PPA) ]; then echo "PPA var must be set to upload packages... specify the PPA=<value> in ./variables"; exit 1; fi
	eval $$(gpg-agent --daemon) && for file in *.changes; do debsign $(debsign_opt) $$file; done; unset file
	for file in *.changes; do dput ppa:$(PPA) $$file; done

_pre_tarball:
	@if [ -f $(TARGET)_ppa_ok ]; then rm $(TARGET)_ppa_ok; fi
	@if [ ! $$TAG ]; then echo "TAG env var must be set... use: TAG=<value> make $(TARGET)"; exit 1; fi
	@if [ -d $(TARGET)-$$TAG ]; then rm -rf $(TARGET)-$$TAG; fi
	@if [ -f $(TARGET)_$${TAG}.orig.tar.gz ]; then rm $(TARGET)_$${TAG}.orig.tar.gz; fi
	@mkdir $(TARGET)-$$TAG

_post_tarball:
	@pushd . && cd $(TARGET)-$(TAG) && find . \( -iname ".git*" -o -iname "*.bzr" -o -iname "*.hg" \) | xargs rm -rf \{} && \
	popd && tar zcvf $(TARGET)_$${TAG}.orig.tar.gz $(TARGET)-$$TAG
	@rm -rf $(TARGET)-$$TAG

buildsfx := $(BUILDSUFFIX_$(VERSION))
builddist := $(VERSION)
buildtext := $(BUILDTEXT_$(VERSION))

ifdef BUILDDIST_$(VERSION)
	builddist := $(BUILDDIST_$(VERSION))
endif

_build:
	@cp $(CWD)/debian/changelog /tmp/$(TARGET).changelog.orig
	@cd $(CWD); DEBEMAIL=$(DEBEMAIL) DEBFULLNAME=$(DEBFULLNAME) dch -l $(buildsfx) -D $(builddist) $(buildtext)
	#@dpkg-source --before-build $(CWD) >/dev/null || true
	@cd $(CWD); debuild --no-tgz-check -S -sa -us -uc
	@mv /tmp/$(TARGET).changelog.orig $(CWD)/debian/changelog

_do:
	@for version in $(VERSIONS); do \
		for exp in $$EXCEPT; do \
			if [ "$$version" == "$$exp" ]; then \
				ignore_version=1 ; \
			fi ; \
		done ; \
		[[ $$ignore_version != 1 ]] && make VERSION=$$version TARGET=$(TARGET) CWD=tmp/$(TARGET) _build ; \
		unset ignore_version; \
	done

_pre_check_launchpad:
	@if [ ! $$PPA ]; then \
		exit 0 ; \
	else \
		wget https://launchpad.net/~$$(echo $$PPA |cut -d'/' -f1)/+archive/$$(echo $$PPA |cut -d'/' -f2)/+files/$(TARGET)_$(TAG).orig.tar.gz -O /tmp/precheck.tar.gz;  \
		content_tar_ball=$$(tar -tzf /tmp/precheck.tar.gz >/dev/null ; echo $$?) ; \
		if [ "$$content_tar_ball" == "0" ]; then \
			touch $(TARGET)_ppa_ok; \
			rm -rf /tmp/precheck.tar.gz; \
		fi; \
	fi

PACKAGES_$(GOBASE)tsuru-server-$(TAG_tsuru-server) := github.com/tsuru/tsuru/...

$(GOBASE)%:
	mkdir -p $(GOBASE)
	GOPATH=$@ go get -v -u -d $(or $(GOURL), $(GITPATH)/...)
	rm $@ 2>/dev/null || true
	git -C $@/src/$(GITPATH) checkout $(or $(GITTAG), $(TAG))
	if [[ -d $@/src/$(GITPATH)/Godeps ]]; then \
		cd $@/src/$(GITPATH); \
		GOPATH=$(abspath $@) godep restore ./...; \
	fi

tsuru-server_$(TAG_tsuru-server).orig.tar.gz: $(GOBASE)tsuru-server-$(TAG_tsuru-server)
tsuru-node-agent_$(TAG_tsuru-node-agent).orig.tar.gz: $(GOBASE)tsuru-node-agent-$(TAG_tsuru-node-agent)
serf_$(TAG_serf).orig.tar.gz: $(GOBASE)serf-$(TAG_serf)
gandalf-server_$(TAG_gandalf-server).orig.tar.gz: $(GOBASE)gandalf-server-$(TAG_gandalf-server)
archive-server_$(TAG_archive-server).orig.tar.gz: $(GOBASE)archive-server-$(TAG_archive-server)
crane_$(TAG_crane).orig.tar.gz: $(GOBASE)crane-$(TAG_crane)
tsuru-client_$(TAG_tsuru-client).orig.tar.gz: $(GOBASE)tsuru-client-$(TAG_tsuru-client)
tsuru-admin_$(TAG_tsuru-admin).orig.tar.gz: $(GOBASE)tsuru-admin-$(TAG_tsuru-admin)
hipache-hchecker_$(TAG_hipache-hchecker).orig.tar.gz: $(GOBASE)hipache-hchecker-$(TAG_hipache-hchecker)
docker-registry_$(TAG_docker-registry).orig.tar.gz: $(GOBASE)docker-registry-$(TAG_docker-registry)
tsuru-mongoapi_$(TAG_tsuru-mongoapi).orig.tar.gz: $(GOBASE)tsuru-mongoapi-$(TAG_tsuru-mongoapi)
lxc-docker_$(TAG_lxc-docker).orig.tar.gz: $(GOBASE)lxc-docker-$(TAG_lxc-docker)
%.orig.tar.gz:
	tar -zcf $@ -C $(GOBASE) $(TARGET)-$(TAG) --exclude-vcs $(TAR_OPTIONS)

URL_golang_$(TAG_golang).orig.tar.gz := https://launchpad.net/debian/+archive/primary/+files/golang_$(TAG_golang).orig.tar.gz
URL_lvm2_$(TAG_lvm2).orig.tar.gz := https://git.fedorahosted.org/cgit/lvm2.git/snapshot/lvm2-$(subst .,_,$(TAG_lvm2)).tar.gz
URL_btrfs-tools_$(TAG_btrfs-tools).orig.tar.xz := https://launchpad.net/ubuntu/+archive/primary/+files/btrfs-tools_$(TAG_btrfs-tools).orig.tar.xz

btrfs-tools_$(TAG_btrfs-tools).orig.tar.xz \
golang_$(TAG_golang).orig.tar.gz \
lvm2_$(TAG_lvm2).orig.tar.gz:
	curl -L -o $@ $(URL_$@)

tsuru-server: TAG := $(TAG_tsuru-server)
tsuru-server: TARGET = tsuru-server
tsuru-server: GITPATH = github.com/tsuru/tsuru
tsuru-server: $(GOBASE)tsuru-server-$(TAG_tsuru-server)
tsuru-server: tsuru-server_$(TAG_tsuru-server).orig.tar.gz
tsuru-server: TAR_OPTIONS := --exclude tsuru-server-$(TAG_tsuru-server)/src/github.com/tsuru/tsuru/src
tsuru-node-agent: TAG := $(TAG_tsuru-node-agent)
tsuru-node-agent: TARGET = tsuru-node-agent
tsuru-node-agent: GITPATH = github.com/tsuru/tsuru-node/agent
tsuru-node-agent: tsuru-node-agent_$(TAG_tsuru-node-agent).orig.tar.gz
tsuru-node-agent: TAR_OPTIONS := --exclude tsuru-node-agent-$(TAG_tsuru-node-agent)/src/github.com/tsuru/tsuru-node-agent/src
serf: TAG := $(TAG_serf)
serf: GITTAG := v$(TAG_serf)
serf: TARGET = serf
serf: GITPATH = github.com/hashicorp/serf
serf: serf_$(TAG_serf).orig.tar.gz
gandalf-server: TAG := $(TAG_gandalf-server)
gandalf-server: TARGET = gandalf-server
gandalf-server: GITPATH = github.com/tsuru/gandalf
gandalf-server: gandalf-server_$(TAG_gandalf-server).orig.tar.gz
archive-server: TAG := $(TAG_archive-server)
archive-server: TARGET = archive-server
archive-server: GOURL = github.com/tsuru/archive-server
archive-server: GITPATH = github.com/tsuru/archive-server
archive-server: archive-server_$(TAG_archive-server).orig.tar.gz
crane: TAG := $(TAG_crane)
crane: TARGET = crane
crane: GOURL = github.com/tsuru/crane
crane: GITPATH = github.com/tsuru/crane
crane: crane_$(TAG_crane).orig.tar.gz
tsuru-client: TAG := $(TAG_tsuru-client)
tsuru-client: TARGET = tsuru-client
tsuru-client: GITPATH = github.com/tsuru/tsuru-client
tsuru-client: tsuru-client_$(TAG_tsuru-client).orig.tar.gz
tsuru-admin: TAG := $(TAG_tsuru-admin)
tsuru-admin: TARGET = tsuru-admin
tsuru-admin: GOURL = github.com/tsuru/tsuru-admin
tsuru-admin: GITPATH = github.com/tsuru/tsuru-admin
tsuru-admin: tsuru-admin_$(TAG_tsuru-admin).orig.tar.gz
hipache-hchecker: TAG := $(TAG_hipache-hchecker)
hipache-hchecker: TARGET = hipache-hchecker
hipache-hchecker: GITPATH = github.com/morpheu/hipache-hchecker
hipache-hchecker: hipache-hchecker_$(TAG_hipache-hchecker).orig.tar.gz
docker-registry: TAG := $(TAG_docker-registry)
docker-registry: TARGET = docker-registry
docker-registry: GOURL = github.com/fsouza/docker-registry/contrib/golang_impl
docker-registry: GITPATH = github.com/fsouza/docker-registry/contrib/golang_impl
docker-registry: docker-registry_$(TAG_docker-registry).orig.tar.gz
tsuru-mongoapi: TAG := $(TAG_tsuru-mongoapi)
tsuru-mongoapi: TARGET = tsuru-mongoapi
tsuru-mongoapi: GOURL = github.com/tsuru/mongoapi
tsuru-mongoapi: GITPATH = github.com/tsuru/mongoapi
tsuru-mongoapi: tsuru-mongoapi_$(TAG_tsuru-mongoapi).orig.tar.gz
lxc-docker: TAG := $(TAG_lxc-docker)
lxc-docker: GITTAG := v$(TAG_lxc-docker)
lxc-docker: TARGET = lxc-docker
lxc-docker: GOURL = github.com/dotcloud/docker/docker...
lxc-docker: GITPATH = github.com/dotcloud/docker
lxc-docker: lxc-docker_$(TAG_lxc-docker).orig.tar.gz
lvm2: lvm2_$(TAG_lvm2).orig.tar.gz
btrfs-tools: btrfs-tools_$(TAG_btrfs-tools).orig.tar.xz
golang: golang_$(TAG_golang).orig.tar.gz
tsuru-server tsuru-node-agent serf gandalf-server archive-server crane tsuru-client tsuru-admin hipache-hchecker docker-registry tsuru-mongoapi lxc-docker lvm2 btrfs-tools golang:
	mkdir -p $(TMP)$@/
	rm -rf $(TMP)$@/* || true
	cp -r $@-deb/debian $(TMP)$@/
	cp $< $(TMP)
	make TARGET=$@ _do

nodejs:
	make TARGET=$@ _do

node-hipache:
	make TARGET=$@ _do
