# Conky Manager 3 项目整理报告

报告日期：2026-05-28

## 1. 项目定位

本项目是 `conky-manager3`，即 Conky Manager 的延续/分叉版本。它的核心目标是为 Conky 配置提供图形化管理能力，包括扫描、预览、启动、停止、编辑、导入主题包，以及把当前运行的 Conky 组合保存为主题。

代码主体是 Vala 编写的 GTK 桌面应用，安装后生成一个原生二进制程序 `conky-manager3`。当前源码版本号在 `src/Main.vala` 中定义为 `2.73`。

项目规模大致如下：

| 项目 | 当前情况 |
| --- | --- |
| 主语言 | Vala，少量 shell/desktop/XML/PO 文件 |
| UI 技术 | GTK 3，手写窗口布局 |
| Vala 源文件 | 10 个 |
| Vala 代码量 | 约 7,000 行 |
| 本地化 | `cs/de/es/fr/hr/ko/nl/pt_BR` 8 组 PO |
| 许可证 | GPL-2.0+ |
| 目标平台 | 主要是 Ubuntu/Mint 及其衍生发行版 |

## 2. 当前编译方式

项目现在同时保留两套构建路径：Meson 与旧式 Makefile。

### 2.1 Meson 构建

根目录存在 `meson.build`，Debian 打包文件 `debian/rules` 也指定：

```make
dh $@ --buildsystem=meson
```

因此从当前仓库状态看，Meson 是更接近现代打包流程的入口。可用命令：

```bash
meson setup builddir
meson compile -C builddir
```

本机验证结果：

| 项目 | 结果 |
| --- | --- |
| Meson | 1.7.0 |
| GCC | 15.2.0 |
| valac | 0.56.18 |
| GTK | 3.24.50 |
| GLib | 2.86.0 |
| 编译结果 | 成功 |
| 主要问题 | 编译通过但有大量弃用 API 警告，Vala 阶段约 72 条 |

Meson 安装内容包括：

- `conky-manager3` 二进制；
- `.desktop` 桌面启动文件；
- AppStream/metainfo 文件；
- man page；
- 图标、图片资源与默认 theme pack；
- PO 翻译。

### 2.2 Makefile 构建

根目录小写 `makefile` 会进入 `src` 目录执行 `make all`。`src/makefile` 直接调用 `valac`：

```bash
valac ... -o conky-manager3 \
  --pkg glib-2.0 \
  --pkg gio-unix-2.0 \
  --pkg posix \
  --pkg gtk+-3.0 \
  --pkg gee-0.8 \
  --pkg json-glib-1.0
```

README 与 `HOWTOBUILD.md` 仍把 `make` / `sudo make install` 描述为源码安装方式。这个路径可读性直接，但缺少现代构建系统的依赖检查、安装规则抽象和更细的打包集成。

### 2.3 Debian 打包

`debian/control` 声明的构建依赖：

- `debhelper (>= 8.0.0)`
- `meson`
- `valac`
- `libgtk-3-dev`
- `libgee-0.8-dev`
- `libjson-glib-dev`

运行依赖：

- `coreutils (>= 8.28)`
- `conky | conky-all | conky-std`
- `p7zip-full`
- `rsync`
- `imagemagick`

仓库中也有 `build-deb.sh`、`build-install.sh`、`build-release.sh` 等脚本，但这些脚本仍带有较老的个人发布流程痕迹，例如 `bzr builddeb`、`gdebi`、固定的 Dropbox 路径等，不应被视为当前最可靠的通用发布入口。

## 3. UI 版本与依赖关系

### 3.1 编译期 UI 依赖

`meson.build` 明确依赖：

- `gtk+-3.0`
- `gdk-x11-3.0`
- `glib-2.0`
- `gio-unix-2.0`
- `gobject-2.0`
- `gee-0.8`
- `json-glib-1.0`
- Vala `posix`
- C math library `m`

其中 `gdk-x11-3.0` 是关键点：项目不仅是 GTK3 应用，还显式依赖 X11 后端相关 API。

### 3.2 UI 代码形态

UI 没有使用 GtkBuilder `.ui` 文件，也没有资源编译系统。窗口与控件全部在 Vala 中手写构造，主要文件包括：

- `src/MainWindow.vala`：主窗口、工具栏、列表、预览区域、导入与扫描流程；
- `src/EditWidgetWindow.vala`：单个 Conky 配置的可视化编辑；
- `src/EditThemeWindow.vala`：主题保存/编辑；
- `src/SettingsWindow.vala`：启动项与主题目录设置；
- `src/GeneratePreviewWindow.vala`：预览图生成配置；
- `src/AboutWindow.vala`、`src/DonationWindow.vala`：辅助窗口。

这种结构的优点是逻辑集中、依赖少；缺点是 UI、状态、命令执行和业务规则耦合较深，后续迁移到 GTK4、libadwaita 或其他 UI 框架时，难以逐步替换。

### 3.3 已触发的 GTK 弃用点

当前在 GTK 3.24.50 下可编译，但编译器报告大量弃用 API，典型包括：

- `Gtk.ToolButton.from_stock`，GTK 3.10 起弃用；
- `Gtk.Image.from_stock`，GTK 3.10 起弃用；
- `Gtk.Dialog.get_action_area`，GTK 3.12 起弃用；
- `Gtk.Widget.margin_left/right`，GTK 3.12 起弃用；
- `Gtk.TreeView.set_rules_hint`，GTK 3.14 起弃用；
- `Gdk.Color`、`Gtk.Widget.modify_fg`、`Gtk.StateType`，GTK 3 系列中已弃用；
- `Gdk.Screen.width/height`，GTK 3.22 起弃用；
- `Gtk.show_uri`，GTK 3.22 起弃用；
- `GLib.Thread.create`，GLib 2.32 起弃用；
- `Gdk.Cursor.new`，GTK 3.16 起弃用。

这些不阻止当前 GTK3 编译，但说明 UI 层仍停留在 GTK3 早期写法。官方 GTK4 迁移文档也明确 GTK4 是破坏 ABI/API 的大版本迁移，GTK3 中很多旧 API 已有替代方案，迁移前应先消除 GTK3 弃用符号。

参考：

- https://docs.gtk.org/gtk4/migrating-3to4.html
- https://docs.gtk.org/gtk3/class.ToolButton.html

## 4. 运行时行为与系统耦合

### 4.1 对外部命令依赖较强

`src/Main.vala` 启动时检查以下命令：

- `conky`
- `rsync`
- `killall`
- `cp`
- `rm`
- `touch`
- `7za`
- `import`

其中 `import` 来自 ImageMagick，项目使用它为 Conky 窗口抓图生成预览。ImageMagick 官方文档说明 `import` 是从 X server 屏幕/窗口抓图的工具，这与项目的 X11 依赖一致。

参考：

- https://imagemagick.org/script/import.php

### 4.2 桌面环境适配方式偏传统

项目通过进程名和命令行工具判断或操作桌面环境，例如：

- Cinnamon/GNOME：使用 `gsettings` 改壁纸；
- XFCE：使用 `xfconf-query`；
- LXDE：使用 `pcmanfm --set-wallpaper`；
- 终端运行：尝试 `xfce4-terminal`、`gnome-terminal`；
- 启动项：写入 `~/.config/autostart/conky.desktop`。

这套方式对传统 X11 桌面环境较实用，但对现代桌面系统的门户化、沙箱化、Wayland 权限模型、多显示器和 GNOME/KDE 新版行为并不充分。

### 4.3 预览图生成依赖 X11 窗口 ID

`src/XidHelper.vala` 直接从 `Gdk.X11.Window` 取 XID，`src/Main.vala` 里再调用：

```bash
import -window 0x... ...
```

这意味着预览功能天然偏 X11。Wayland 下应用通常不能任意读取其他窗口内容，也不能稳定依赖 X11 window id。即使 GTK3 本身可在 Wayland 上运行，这部分功能也会成为现代桌面兼容性的主要风险。

GTK 官方文档中，X11 相关 API 也被单独归入平台专用构建入口，例如 GTK4 下需要使用 `gtk4-x11` / GDK X11 专用接口。

参考：

- https://docs.gtk.org/gdk4/x11.html

## 5. 与现代 Linux 桌面系统的距离

下面按“当前可用性”和“现代化距离”分层评估。

### 5.1 构建系统：中等距离

优点：

- 已有 Meson 构建；
- Debian 打包已使用 Meson；
- 依赖声明清晰；
- 本机新工具链可编译通过。

差距：

- `project()` 没有声明版本号；
- `po/meson.build` 使用了已弃用的 `meson.source_root()`；
- README 仍主推旧 `make` 路线，与 Debian/Meson 路线不完全一致；
- 发布脚本残留 `bzr builddeb`、个人路径等老流程；
- 没有 CI、没有自动测试、没有静态检查作为默认质量门。

结论：构建层已经有现代化基础，但文档和发布流程没有统一。

### 5.2 UI 技术：较大距离

优点：

- GTK3 仍能在当前系统上编译；
- UI 轻量，依赖少；
- 功能直接围绕 Conky 工作流设计。

差距：

- 尚未迁移 GTK4；
- 没有 libadwaita/GNOME HIG 风格组件；
- 大量 stock icon、旧 toolbar、旧 dialog action area 等 GTK3 早期 API；
- UI 直接写在 Vala 代码里，缺少资源化、分层和可测试边界；
- `TreeView`、手写工具栏和传统对话框风格与现代 GNOME/KDE 应用观感有明显年代感。

结论：作为传统 GTK3 工具仍可用，但离现代 GTK4/libadwaita 应用有较明显距离。

### 5.3 Wayland 与安全模型：较大距离

优点：

- 常规 GTK 窗口本身不一定阻止在 Wayland 会话中启动；
- Conky 管理、文件扫描、配置编辑等非截图功能理论上可继续工作。

差距：

- 显式依赖 `gdk-x11-3.0`；
- 预览功能依赖 XID 与 ImageMagick `import -window`；
- 修改壁纸依赖 DE 私有命令；
- 没有使用 XDG Desktop Portal；
- 运行时大量 shell 命令拼接，对沙箱/Flatpak 化不友好。

结论：项目更适合 X11 或 XWayland 兼容路径；要成为现代 Wayland 一等公民，需要重做预览、截图和桌面集成方式。

### 5.4 打包与元数据：中等距离

优点：

- 有 `.desktop`；
- 有 AppStream/metainfo；
- 有 man page；
- 有 Debian metadata。

差距：

- `src/conky-manager3.appdata.xml` 使用旧 `<application>` 根元素和旧 screenshot 链接；
- Meson 安装到 `/usr/share/metainfo`，旧 Makefile 安装到 `/usr/share/appdata`，路径不一致；
- AppStream 官方文档已把 metainfo 作为现代应用元数据格式，`/usr/share/appdata/` 更多是遗留兼容；
- 没有 Flatpak manifest；
- 没有截图资源、release 元数据、content rating 等现代软件中心常见字段。

参考：

- https://freedesktop.org/software/appstream/docs/chap-Metadata.html

结论：已有基础元数据，但需要更新格式与安装路径，并补充现代软件中心需要的内容。

### 5.5 代码结构：中等到较大距离

优点：

- 代码量不大；
- 业务领域清晰；
- 文件数量少，理解门槛不高。

差距：

- `Main.vala` 同时承担应用初始化、配置持久化、主题包导入、Conky 配置解析、进程管理、预览生成、主题模型等职责；
- `Utility.vala` 聚合大量通用工具函数，命名空间虽分开，但文件仍是大杂烩；
- 多处通过字符串拼接构造 shell 命令，路径和输入处理风险较高；
- 缺少测试，尤其是 Conky 配置读写、主题包导入、命令拼接、路径处理等高风险逻辑；
- 业务模型没有和 UI/进程执行明确解耦。

结论：规模还可控，但如果要继续演进，应先拆分领域模型与系统集成层，再考虑大规模 UI 迁移。

## 6. 现代化优先级建议

### P0：先统一当前可构建状态

目标：让项目在当前 Linux 发行版上稳定构建，并让文档与实际入口一致。

建议：

- 明确推荐 Meson 为主构建方式；
- 更新 README/HOWTOBUILD，保留 Makefile 为 legacy 说明；
- 在 `meson.build` 中声明项目版本；
- 替换 `meson.source_root()` 为 `meson.project_source_root()`；
- 删除或标记过时发布脚本；
- 增加最小 CI：`meson setup` + `meson compile`。

### P1：清理 GTK3 弃用 API

目标：在不立即迁移 GTK4 的前提下，先把 GTK3 内部可替代的旧 API 清掉。

建议：

- 用 icon name 替换 stock icon；
- 替换 `Gtk.Dialog.get_action_area`；
- 替换 `margin_left/right` 为 `margin_start/end`；
- 替换 `Gdk.Screen.width/height`；
- 替换 `Gtk.show_uri`；
- 替换 `GLib.Thread.create`；
- 处理 `TreeView.set_rules_hint`、`Gdk.Color`、`modify_fg` 等旧样式接口。

完成后再评估 GTK4 迁移成本会更真实。

### P2：隔离 X11/Wayland 相关功能

目标：不要让 X11 截图能力成为整个应用的硬依赖。

建议：

- 把预览生成抽象成独立 backend；
- X11 backend 继续保留 `import -window`；
- 新增 Wayland/portal 可行性实验；
- 在 Wayland 下禁用或降级不可用功能，并给出明确 UI 状态；
- 避免主程序强依赖 `gdk-x11-3.0`，能延迟加载或条件编译更好。

### P3：拆分核心业务逻辑

目标：为测试和 UI 迁移做准备。

建议拆分：

- `ConkyConfig`：读取、搜索、修改 conkyrc；
- `ThemePackImporter`：解压、识别、导入主题包；
- `ConkyProcessService`：启动、停止、状态刷新；
- `DesktopIntegration`：壁纸、启动项、终端、打开目录；
- `PreviewService`：生成预览图；
- `AppConfigStore`：读写 `~/.config/conky-manager3.json`。

### P4：再考虑 GTK4/libadwaita 或其他前端

目标：把迁移建立在更清晰的模型层上，而不是直接把当前窗口代码逐行翻译到 GTK4。

建议路径：

1. GTK3 内先消除弃用 API；
2. 将 UI 与业务逻辑分离；
3. 给配置解析/主题导入补测试；
4. 做一个小型 GTK4 原型窗口，验证 TreeView 替代方案、预览区域、工具栏/菜单模型；
5. 决定是继续 Vala+GTK4，还是迁移到其他语言绑定。

## 7. 总体结论

`conky-manager3` 当前不是不可维护的老项目：它代码量不大，Meson 构建已经存在，且在 2026 年的本机工具链上可以编译成功。它的问题主要不是“构建不了”，而是 UI 与桌面集成方式明显停留在 GTK3/X11 时代。

最现实的判断是：

- 短期：可以作为传统 GTK3/X11 工具继续维护；
- 中期：应统一 Meson、清理弃用 API、补 CI 和基础测试；
- 长期：如果目标是现代 GNOME/Wayland/软件中心体验，需要重做预览截图、桌面集成和 UI 架构。

建议不要一开始就直接“全量 GTK4 重写”。更稳妥的路线是先把构建、弃用 API、业务分层和测试补起来，再进入 GTK4/libadwaita 或 Wayland 适配。
