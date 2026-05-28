# How to build Conky Manager 3

The current build system is Meson. Debian packaging also uses Meson through
debhelper.

## additional required packages to build:
 build-essential
 git
 debhelper-compat
 dpkg-dev
 meson
 ninja-build
 valac
 libgee-0.8-dev
 libgtk-4-dev (>= 4.10)
 libadwaita-1-dev (>= 1.4)
 libjson-glib-dev
 gettext
 libgettextpo-dev

## additional required run time packages:
 conky
 p7zip-full
 rsync
 imagemagick
 libglib2.0-bin
 x11-utils

## here is a one-shot installation command for all of the above packages:
```
sudo apt install build-essential git debhelper-compat dpkg-dev meson ninja-build valac libgee-0.8-dev libgtk-4-dev libadwaita-1-dev libjson-glib-dev gettext libgettextpo-dev conky p7zip-full rsync imagemagick libglib2.0-bin x11-utils
```


## clone this repository
the following command will create a subdirectory from whatever directory you are currently in called conky-manager3 then download the files from github and put them in that subdirectory:
```
git clone https://github.com/zcot/conky-manager3.git
```

## change the directory to that source code location:
```
cd conky-manager3
```

## compile the source with Meson:
```
meson setup builddir
meson compile -C builddir
```

## install from a Meson build:
```
sudo meson install -C builddir
```

## build a Debian/Ubuntu package:
```
./build-deb.sh
```

The generated `.deb`, `.changes`, and `.buildinfo` files are written to `../builds`.

## build source and release artifacts:
```
./build-source.sh
./build-release.sh
```

The old Makefile, Autotools template files, and ad-hoc installer script were
removed. Use Meson or the Debian package scripts instead.
