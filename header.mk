-include variables.mk

MIRROR_precise := $(UBUNTU_MIRROR)
MIRROR_saucy := $(UBUNTU_MIRROR)
MIRROR_trusty := $(UBUNTU_MIRROR)
MIRROR_wheezy := $(DEBIAN_MIRROR)
#OTHERMIRROR_wheezy := "deb $(MIRROR_wheezy) wheezy-backports main contribs non-free"

gosrc = tsuru-server.buildsrc serf.buildsrc gandalf-server.buildsrc archive-server.buildsrc crane.buildsrc tsuru-client.buildsrc tsuru-admin.buildsrc hipache-hchecker.buildsrc docker-registry.buildsrc tsuru-mongoapi.buildsrc

%.globvars:
	$(eval export TARGET := $(@:%.globvars=%))
	$(eval export TAG := $(TAG_$(TARGET)))

%.vars: %.globvars
	@exit 0

archive-server.vars: %.vars: %.globvars
	$(eval GITPATH = github.com/tsuru/archive-server)
	$(eval GOURL := $(GITPATH))

btrfs-tools.vars: %.vars: %globvars
	$(eval URL := https://launchpad.net/ubuntu/+archive/primary/+files/btrfs-tools_$(TAG).orig.tar.xz)

crane.vars: %.vars: %.globvars
	$(eval GITPATH = github.com/tsuru/crane)
	$(eval GOURL := $(GITPATH))

dh-golang.vars: %.vars: %.globvars
	$(eval URL := https://launchpad.net/debian/+archive/primary/+files/dh-golang_$(TAG).tar.gz)

docker-registry.vars: %.vars: %.globvars
	$(eval GITPATH = github.com/fsouza/docker-registry/contrib/golang_impl)
	$(eval GOURL := $(GITPATH))

gandalf-server.vars: %.vars: %.globvars
	$(eval GITPATH = github.com/tsuru/gandalf)
	$(eval GOURL := $(GITPATH)...)

golang.vars: %.vars: %.globvars
	$(eval URL := https://launchpad.net/debian/+archive/primary/+files/golang_$(TAG).orig.tar.gz)

hipache-hchecker.vars: %.vars: %.globvars
	$(eval GITPATH = github.com/morpheu/hipache-hchecker)
	$(eval GOURL := $(GITPATH)...)

lvm2.vars: %.vars: %.globvars
	$(eval URL := https://git.fedorahosted.org/cgit/lvm2.git/snapshot/lvm2-$(subst .,_,$(TAG)).tar.gz)

lxc-docker.vars: %.vars: %.globvars
	$(eval GITTAG :=v$(TAG))
	$(eval GITPATH = https://github.com/docker/docker.git)

nodejs.vars: %.vars: %.globvars
	$(eval URL := http://nodejs.org/dist/v$(TAG)/node-v$(TAG).tar.gz)

serf.vars: %.vars: %.globvars
	$(eval GITTAG := v$(TAG))
	$(eval GITPATH = github.com/hashicorp/serf)
	$(eval GOURL := $(GITPATH)...)

tsuru-admin.vars: %.vars: %.globvars
	$(eval GITPATH = github.com/tsuru/tsuru-admin)
	$(eval GOURL := $(GITPATH))

tsuru-client.vars: %.vars: %.globvars
	$(eval GITPATH = github.com/tsuru/tsuru-client)
	$(eval GOURL := $(GITPATH)...)

tsuru-mongoapi.vars: %.vars: %.globvars
	$(eval GITPATH = github.com/tsuru/mongoapi)
	$(eval GOURL := $(GITPATH))

tsuru-server.vars: %.vars: %.globvars
	$(eval GITPATH = github.com/tsuru/tsuru)
	$(eval GOURL := $(GITPATH)...)
	$(eval TAR_OPTIONS := --exclude $(TARGET)-$(TAG)/src/$(GITPATH)/src)
