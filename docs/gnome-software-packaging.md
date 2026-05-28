# GNOME Software Packaging Notes

GNOME Software consumes AppStream metadata from distribution repositories and Flatpak remotes. For this project the upstream package should install three user-facing integration files:

- `org.conkymanager3.ConkyManager.desktop` into `/usr/share/applications`
- `org.conkymanager3.ConkyManager.metainfo.xml` into `/usr/share/metainfo`
- `org.conkymanager3.ConkyManager.png` into the hicolor icon theme, preferably including a 256x256 icon

The Meson install rules now install those files for Debian packages and source installs.

## Validate Metadata

Run these checks before publishing a package:

```bash
desktop-file-validate src/org.conkymanager3.ConkyManager.desktop
appstreamcli validate --no-net src/org.conkymanager3.ConkyManager.metainfo.xml
DESTDIR="$(pwd)/tmp/appdir" meson install -C builddir-gtk4
appstreamcli validate-tree --no-net "$(pwd)/tmp/appdir/usr"
```

`appstreamcli validate --pedantic` currently reports that the AppStream ID contains uppercase letters. The existing ID is kept to avoid changing the desktop file, settings identity and package integration. If a store reviewer requires a lowercase or GitHub-derived ID, plan that as a separate application ID migration.

## Debian Repository Path

This is the simplest path for GNOME Software on Debian, Ubuntu and derivatives:

```bash
./build-deb.sh
```

Publish the generated `.deb` through an APT repository that also exports AppStream metadata. GNOME Software will display the application when the repository metadata includes the installed metainfo, desktop file and icon.

Before release, add public screenshots to `src/org.conkymanager3.ConkyManager.metainfo.xml`. Without screenshots GNOME Software can still list the app, but the details page will show a placeholder.

## Flathub Path

Flathub submissions are reviewed through a pull request to `flathub/flathub` against the `new-pr` branch. A submission normally contains a top-level manifest named after the application ID, for example:

```text
org.conkymanager3.ConkyManager.yml
```

For a final Flathub submission, use the latest supported GNOME runtime and build only from source archives or Git tags. Do not submit this whole source tree to the Flathub repository.

Conky Manager 3 is host-facing software: it launches Conky, inspects windows and edits files under the user's Conky configuration. A Flatpak package therefore needs careful review because broad filesystem, X11 and process permissions may be required. If that user experience is not acceptable inside the sandbox, prefer the Debian/AppStream repository path for GNOME Software.
