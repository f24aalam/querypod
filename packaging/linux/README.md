# Linux Packaging

Put the Linux app icon at:

`packaging/linux/icon.png`

Use a square PNG. `512x512` is the recommended size for the Debian package.

Build the package with either:

`make linux-deb`

or:

`./scripts/build-linux-deb.sh`

The generated package is written to:

`build/linux/deb/querypod_<version>_amd64.deb`

The application bundle is installed under:

`/usr/lib/querypod`

The package installs the launcher as:

`/usr/share/applications/me.aalam.querypod.desktop`

and installs icons under:

`/usr/share/icons/hicolor/<size>x<size>/apps/me.aalam.querypod.png`

Runtime dependencies are generated automatically with `dpkg-shlibdeps` from the
built bundle, so they will reflect the distro used to build the package.
