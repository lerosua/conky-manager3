# GTK4 Migration Status

Date: 2026-05-28

## Completed

- Meson now builds against `gtk4` instead of `gtk+-3.0`.
- The explicit `gdk-x11-3.0` dependency was removed from the active build.
- Debian build dependencies now require `libgtk-4-dev (>= 4.10)`.
- The legacy `src/makefile` uses `--pkg gtk4`.
- `HOWTOBUILD.md` now documents GTK4 build dependencies and Meson commands.
- The application entry point now uses `Gtk.Application` instead of `Gtk.main`.
- Removed direct GTK3-only API usage from active source, including:
  - `Gtk.Toolbar` / `Gtk.ToolButton`
  - `Gtk.RadioButton`
  - `Gtk.EventBox`
  - `Gtk.FileChooserButton`
  - `Gtk.Widget.add` / `pack_start` / `pack_end`
  - `Gtk.Dialog.run`
  - `Gtk.FileChooserDialog`
  - `Gtk.Widget.get_window`
  - `Gdk.Screen.width/height`
  - stock icon APIs such as `Image.from_stock`

## Verification

The GTK4 build was verified with:

```bash
meson setup builddir-gtk4
meson compile -C builddir-gtk4
```

The resulting binary links to GTK4:

```text
libgtk-4.so.1
```

## Remaining Modernization Work

The project is now on GTK4, but still uses several GTK4-deprecated compatibility widgets/APIs:

- `Gtk.TreeView`, `Gtk.TreeStore`, `Gtk.ListStore`
- `Gtk.ComboBox`
- `Gtk.Dialog` and `Gtk.MessageDialog`
- `Gtk.ColorButton`
- `Gtk.Image.set_from_pixbuf`

File and folder selection already uses GTK4 `FileDialog`. The remaining items are no longer GTK3 dependencies, but they should be replaced in a follow-up modernization pass with GTK4-native APIs such as `ListView`/`ColumnView`, `DropDown`, `AlertDialog`/custom windows, and `ColorDialogButton` where available.

## Runtime Notes

Preview generation no longer shells out to `import -window` or reads X11 window ids. It now creates static preview images from conkyrc text via ImageMagick `convert`, which keeps preview generation compatible with Wayland's window-capture permission model. The tradeoff is that generated previews are configuration summaries rather than live Conky window screenshots.
