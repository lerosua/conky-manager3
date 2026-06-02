project('conky-manager3', ['c','vala'], version : '3.0.1', default_options : ['prefix=/usr'])

prefix = '/usr'
bindir = prefix + '/bin'
sharedir = prefix + '/share'
launcherdir = sharedir + '/applications'
metainfodir = sharedir + '/metainfo'
pixmapsdir = sharedir + '/pixmaps'
icondir = sharedir + '/icons/hicolor'
app_name = 'conky-manager3'
app_id = 'org.conkymanager3.ConkyManager'

sources = [
        'src/AboutWindow.vala',
        'src/GeneratePreviewWindow.vala',
        'src/Main.vala',
        'src/MainWindow.vala',
        'src/SettingsWindow.vala',
        'src/DonationWindow.vala',
        'src/EditThemeWindow.vala',
        'src/Utility.vala',
        'src/EditWidgetWindow.vala'
]

dependencies = [
    dependency('glib-2.0'),
    dependency('gio-unix-2.0'),
    dependency('gobject-2.0'),
    dependency('gtk4', version : '>= 4.10'),
    dependency('libadwaita-1', version : '>= 1.4'),
    dependency('gee-0.8'),
    dependency('json-glib-1.0'),
    meson.get_compiler('vala').find_library('posix'),
    meson.get_compiler('c').find_library('m', required : false)
]

install_data('src/' + app_id + '.desktop', install_dir : launcherdir)
install_data('src/share/pixmaps/' + app_name + '.png', install_dir : pixmapsdir)
install_data('src/share/pixmaps/' + app_name + '.png', rename : app_id + '.png', install_dir : pixmapsdir)
install_data('icons/conky-manager-64.png', rename : app_id + '.png', install_dir : icondir + '/64x64/apps')
install_data('src/share/pixmaps/' + app_name + '.png', rename : app_id + '.png', install_dir : icondir + '/128x128/apps')
install_data('icons/conky-manager-192.png', rename : app_id + '.png', install_dir : icondir + '/192x192/apps')
install_data('icons/conky-manager-256.png', rename : app_id + '.png', install_dir : icondir + '/256x256/apps')
install_data('src/' + app_id + '.metainfo.xml', install_dir : metainfodir)
install_data('man/' + app_name + '.1', install_dir : sharedir + '/man/man1')
install_subdir('src/share/conky-manager3/images', install_dir : sharedir + '/' + app_name)
install_subdir('src/share/conky-manager3/themepacks', install_dir : sharedir + '/' + app_name)

subdir('po')

#vala_lint = find_program('io.elementary.vala-lint', required : false)
#if vala_lint.found()
#    test (
#        'Vala lint',
#        vala_lint,
#        args: ['-d', join_paths(meson.source_root(), 'src')]
#    )
#endif

executable('conky-manager3', sources, install : true, install_dir : bindir, dependencies: dependencies)
