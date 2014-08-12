Format: 3.0 (quilt)
Source: lvm2
Binary: lvm2, lvm2-udeb, libdevmapper-dev, libdevmapper1.02.1, libdevmapper1.02.1-udeb, dmsetup, dmsetup-udeb, libdevmapper-event1.02.1, dmeventd, liblvm2app2.2, liblvm2cmd2.02, liblvm2-dev
Architecture: any
Version: 2.02.103-1tsuru1~bpo70+1
Maintainer: Ubuntu Core Developers <ubuntu-devel-discuss@lists.ubuntu.com>
Uploaders: Bastian Blank <waldi@debian.org>
Homepage: http://sources.redhat.com/lvm2/
Standards-Version: 3.7.3
Vcs-Browser: http://svn.debian.org/wsvn/pkg-lvm/lvm2/trunk/
Vcs-Svn: svn://svn.debian.org/pkg-lvm/lvm2/trunk/
Build-Depends: debhelper (>> 4.2), automake, libdlm-dev (>> 2), libreadline-dev, libselinux1-dev, libudev-dev, pkg-config, quilt
Package-List: 
 dmeventd deb admin optional
 dmsetup deb admin optional
 dmsetup-udeb udeb debian-installer optional
 libdevmapper-dev deb libdevel optional
 libdevmapper-event1.02.1 deb libs optional
 libdevmapper1.02.1 deb libs required
 libdevmapper1.02.1-udeb udeb debian-installer optional
 liblvm2-dev deb libdevel optional
 liblvm2app2.2 deb libs optional
 liblvm2cmd2.02 deb libs optional
 lvm2 deb admin optional
 lvm2-udeb udeb debian-installer optional
Checksums-Sha1: 
 314a1ab2699acbebdb321c67340811bbaeaae6dc 1336731 lvm2_2.02.103.orig.tar.gz
 33870cb73e58ad97a19866c5d91951fe5ab84891 33853 lvm2_2.02.103-1tsuru1~bpo70+1.debian.tar.gz
Checksums-Sha256: 
 5a6428b6d9169a09100c83403e386daa7bb96296066414750f54dfbf4ebb6f90 1336731 lvm2_2.02.103.orig.tar.gz
 eddc8dfb92d8b91205c7732f42caa5b2249a999a397bdc5e0b44ae7049bc5d97 33853 lvm2_2.02.103-1tsuru1~bpo70+1.debian.tar.gz
Files: 
 970a5ae2bb24830c1d1a716032117c33 1336731 lvm2_2.02.103.orig.tar.gz
 f7ea4b0e7d5b55a6b401d229ca516af2 33853 lvm2_2.02.103-1tsuru1~bpo70+1.debian.tar.gz
Original-Maintainer: Debian LVM Team <pkg-lvm-maintainers@lists.alioth.debian.org>
