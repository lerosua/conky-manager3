# How to build this software. It was tested on modern Ubuntu/Mint versions and now builds against GTK 4.

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
 p7zip-full
 imagemagick

## here is a one-shot installation command for all of the above packages:
```
apt install build-essential git debhelper-compat dpkg-dev meson ninja-build valac libgee-0.8-dev libgtk-4-dev libadwaita-1-dev libjson-glib-dev gettext libgettextpo-dev p7zip-full imagemagick
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

## build a Debian/Ubuntu package:
```
./build-deb.sh
```

The generated `.deb`, `.changes`, and `.buildinfo` files are written to `../builds`.

## legacy Makefile build:
```
make
```
## install the finished program into the local file system:
```
sudo make install
```

## can be uninstalled as follows:
```
sudo make uninstall
```
