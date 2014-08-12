tsuru-deb
=========

A public repository build from latest tsuru-deb (philiptzou's fork).
Supported Ubuntu 12.04 (precise), 14.04 (trusty) and Debian 7.x(wheezy).

Run these commands to add this repostory to you APT source list:

```bash
# Ubuntu 12.04 (precise)
$ echo "deb http://philiptzou.github.io/tsuru-deb/ precise main contrib" | \
sudo tee /etc/apt/sources.list.d/tsuru-deb.list
$ echo "deb-src http://philiptzou.github.io/tsuru-deb/ precise main contrib" | \
sudo tee -a /etc/apt/sources.list.d/tsuru-deb.list

# Ubuntu 14.04 (trusty)
$ echo "deb http://philiptzou.github.io/tsuru-deb/ trusty main contrib" | \
sudo tee /etc/apt/sources.list.d/tsuru-deb.list
$ echo "deb-src http://philiptzou.github.io/tsuru-deb/ trusty main contrib" | \
sudo tee -a /etc/apt/sources.list.d/tsuru-deb.list

# Debian 7.x (wheezy), required official Debian backports
$ echo "deb http://philiptzou.github.io/tsuru-deb/ wheezy-backports main contrib" | \
sudo tee /etc/apt/sources.list.d/tsuru-deb.list
$ echo "deb-src http://philiptzou.github.io/tsuru-deb/ wheezy-backports main contrib" | \
sudo tee -a /etc/apt/sources.list.d/tsuru-deb.list

```

And the public GPG key:

```bash
$ curl http://philiptzou.github.io/tsuru-deb/public.key | sudo apt-key add -

```

You can use the packages after update your APT index:

```bash
$ sudo apt-get update

```
