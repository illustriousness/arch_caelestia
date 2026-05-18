-- Pure native Hyprland Lua config (no runtime legacy parser).
-- Generated from existing hyprlang files to preserve behavior.

local HOME = os.getenv("HOME") or "~"
local HYPR = HOME .. "/.config/hypr"

hl.monitor({ output = "", mode = "highrr", position = "auto", scale = 1 })

-- 系统默认语言
-- 大多数程序读取的主 locale
-- 决定：
--   UI语言
--   日期格式
--   排序规则
--   编码
hl.env("LANG", "zh_CN.UTF-8")

-- GNU gettext 使用的语言优先级
-- 表示：
--   优先中文
--   找不到则 fallback zh
hl.env("LANGUAGE", "zh_CN:zh")


hl.env("EDITOR", "nvim")
hl.env("VISUAL", "nvim")

-- 字符类型 locale
-- 决定：
--   UTF-8字符处理
--   中文输入
--   宽字符
--   emoji
-- 很重要
-- hl.env("LC_CTYPE", "zh_CN.UTF-8")

-- Qt 使用 qt6ct 管理主题
-- 否则 Qt 程序可能不跟系统主题
-- 影响：
--   KDE程序
--   Qt应用
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

-- 禁止 Qt Wayland 客户端自己绘制窗口装饰
-- 让 Hyprland 接管边框
-- 避免：
--   双标题栏
--   双边框
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")

-- Qt 自动 DPI 缩放
-- 适合 HiDPI
-- 但很多 Hyprland 用户会关闭
-- 因为容易双重缩放
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")

-- 鼠标主题
hl.env("XCURSOR_THEME", "sweet-cursors")

-- 鼠标大小
hl.env("XCURSOR_SIZE", "24")

-- GTK 后端优先级
-- 优先：
--   Wayland
-- fallback：
--   X11
-- 影响：
--   Nautilus
--   Zen Browser
--   GTK app
hl.env("GDK_BACKEND", "wayland,x11")

-- Qt 平台后端
-- Wayland优先
-- xcb(X11)兜底
hl.env("QT_QPA_PLATFORM", "wayland;xcb")

-- SDL 图形后端
-- 游戏/模拟器常用
-- Wayland优先
hl.env("SDL_VIDEODRIVER", "wayland,x11,windows")

-- GNOME Clutter 后端
-- Wayland优先
hl.env("CLUTTER_BACKEND", "wayland")

-- Electron(Ozone) 平台自动检测
-- Electron程序：
--   VSCode
--   Discord
--   Obsidian
--   微信
-- 会尝试自动选择：
--   Wayland/X11
-- hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- GTK 输入法模块
-- fcitx 输入法支持
hl.env("GTK_IM_MODULE", "fcitx")

-- Qt 输入法模块
hl.env("QT_IM_MODULE", "fcitx")

-- X11 输入法协议变量
-- 即使 Wayland 下很多程序仍会读取
hl.env("XMODIFIERS", "@im=fcitx")

-- SDL 输入法模块
-- 游戏输入中文
hl.env("SDL_IM_MODULE", "fcitx")

-- 当前桌面环境
-- 很多程序通过它判断：
--   当前 DE/WM
-- 用于 portal/主题/行为适配
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")

-- 当前 session 类型
-- 标识：
--   wayland
-- 而不是 x11
hl.env("XDG_SESSION_TYPE", "wayland")

-- 当前 session 桌面名
-- portal/dbus 会读取
hl.env("XDG_SESSION_DESKTOP", "Hyprland")


hl.config({
  general = {
    layout = "scrolling",
    allow_tearing = false,
    gaps_workspaces = 4,
    gaps_in = 4,
    gaps_out = 4,
    border_size = 3,
    col = {
      active_border = "rgba(c2c1ffe6)",
      inactive_border = "rgba(c8c5d111)",
    },
  },
  dwindle = { preserve_split = true, smart_split = false, smart_resizing = true },
  master = { mfact = 0.60 },
  scrolling = {
    column_width = 0.5,
    explicit_column_widths = "0.5,  1.0",
    fullscreen_on_one_column = true,
    focus_fit_method = 1,
    follow_focus = true,
    wrap_focus = false,
    direction = "right",
  },
  input = {
    kb_layout = "us",
    numlock_by_default = true,
    repeat_delay = 500,
    repeat_rate = 35,
    focus_on_close = 1,
    touchpad = {
      natural_scroll = true,
      disable_while_typing = true,
      scroll_factor = 0.3,
    },
  },
  binds = { scroll_event_delay = 0 },
  cursor = { hotspot_padding = 1 },
  misc = {
    vrr = 0,
    animate_manual_resizes = 0,
    animate_mouse_windowdragging = 0,
    disable_hyprland_logo = true,
    force_default_wallpaper = 0,
    on_focus_under_fullscreen = 2,
    allow_session_lock_restore = true,
    middle_click_paste = false,
    focus_on_activate = true,
    session_lock_xray = true,
    mouse_move_enables_dpms = true,
    key_press_enables_dpms = true,
    background_color = "rgb(201f23)",
  },
  debug = { error_position = 1, vfr = true },
  decoration = {
    rounding = 10,
    blur = {
      enabled = false,
      xray = false,
      special = false,
      ignore_opacity = true,
      new_optimizations = true,
      popups = true,
      input_methods = true,
      size = 4,
      passes = 2,
    },
    shadow = {
      enabled = true,
      range = 5,
      render_power = 3,
      color = "rgba(131317d4)",
    },
  },
  group = {
    col = {
      border_active = "rgba(c2c1ffe6)",
      border_inactive = "rgba(c8c5d111)",
      border_locked_active = "rgba(c2c1ffe6)",
      border_locked_inactive = "rgba(c8c5d111)",
    },
    groupbar = {
      font_family = "JetBrains Mono NF",
      font_size = 15,
      gradients = true,
      gradient_round_only_edges = false,
      gradient_rounding = 5,
      height = 25,
      indicator_height = 0,
      gaps_in = 3,
      gaps_out = 3,
      text_color = "rgb(2a2a60)",
      col = {
        active = "rgba(c2c1ffd4)",
        inactive = "rgba(918f9ad4)",
        locked_active = "rgba(c2c1ffd4)",
        locked_inactive = "rgba(c6c4e0d4)",
      },
    },
  },
  gestures = {
    workspace_swipe_distance = 700,
    workspace_swipe_cancel_ratio = 0.15,
    workspace_swipe_min_speed_to_force = 5,
    workspace_swipe_direction_lock = true,
    workspace_swipe_direction_lock_threshold = 10,
    workspace_swipe_create_new = true,
  },
  animations = { enabled = true },
})

hl.curve("specialWorkSwitch", { type = "bezier", points = { {0.05, 0.7}, {0.1, 1.0} } })
hl.curve("emphasizedAccel", { type = "bezier", points = { {0.3, 0.0}, {0.8, 0.15} } })
hl.curve("emphasizedDecel", { type = "bezier", points = { {0.05, 0.7}, {0.1, 1.0} } })
hl.curve("standard", { type = "bezier", points = { {0.2, 0.0}, {0.0, 1.0} } })
hl.animation({ leaf = "layersIn", enabled = true, speed = 5, bezier = "emphasizedDecel", style = "slide" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 4, bezier = "emphasizedAccel", style = "slide" })
hl.animation({ leaf = "fadeLayers", enabled = true, speed = 5, bezier = "standard" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 5, bezier = "emphasizedDecel" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "emphasizedAccel" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 6, bezier = "standard" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "standard", style = "fade" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "specialWorkSwitch", style = "slidefadevert 15%" })
hl.animation({ leaf = "fade", enabled = true, speed = 6, bezier = "standard" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 6, bezier = "standard" })
hl.animation({ leaf = "border", enabled = true, speed = 6, bezier = "standard" })

hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "up", action = "special", workspace_name = "special" })
hl.gesture({ fingers = 3, direction = "down", action = function() hl.exec_cmd("caelestia toggle specialws") end })
hl.gesture({ fingers = 4, direction = "down", action = function() hl.exec_cmd("systemctl suspend-then-hibernate") end })

hl.on("hyprland.start", function()
  hl.exec_cmd("dbus-update-activation-environment --systemd --all && systemctl --user start hyprland-session.target")
  hl.exec_cmd("wl-paste --type text --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")

  hl.exec_cmd("mpris-proxy")
  hl.exec_cmd("blueman-applet")
  hl.exec_cmd("systemctl --user start dms")
  hl.exec_cmd("clash-verge -d")
  hl.exec_cmd("fcitx5 -d")
  -- hl.exec_cmd("~/.config/hypr/scripts/external-only.sh")
end)
hl.on("hyprland.shutdown", function()
  hl.exec_cmd("systemctl --user stop hyprland-session.target")
end)

hl.window_rule({ name = "设置全局窗口规则", match = { fullscreen = false }, opacity = "1.0 override 0.85 override" })
-- hl.window_rule({ name = "legacy-windowrule-2", match = { class = "foot|kitty|equibop|org\\.quickshell|imv|swappy" }, opaque = true })
hl.window_rule({ name = "所有浮动窗口自动居中", match = { float = true, xwayland = false }, center = true })

hl.window_rule({ name = "legacy-windowrule-8", match = { class = "^(com\\.danklinux\\.dms)$", title = "^(设置|添加部件)$" }, float = true })
hl.window_rule({ name = "legacy-windowrule-9", match = { class = "org\\.gnome\\.FileRoller" }, float = true })
hl.window_rule({ name = "legacy-windowrule-10", match = { class = "file-roller" }, float = true })
hl.window_rule({ name = "legacy-windowrule-11", match = { class = "blueman-manager" }, float = true })
hl.window_rule({ name = "legacy-windowrule-12", match = { class = "com\\.github\\.GradienceTeam\\.Gradience" }, float = true })
hl.window_rule({ name = "legacy-windowrule-13", match = { class = "feh" }, float = true })
hl.window_rule({ name = "legacy-windowrule-14", match = { class = "imv" }, float = true })
hl.window_rule({ name = "legacy-windowrule-15", match = { class = "^(mpv)$" }, float = true })
hl.window_rule({ name = "legacy-windowrule-16", match = { class = "system-config-printer" }, float = true })
hl.window_rule({ name = "legacy-windowrule-17", match = { class = "org\\.quickshell" }, float = true })
hl.window_rule({ name = "vscode_starting_width", match = { class = "^(code|Code|code-oss)$" }, scrolling_width = 1.0 })

hl.window_rule({ name = "legacy-windowrule-21", match = { class = "org\\.gnome\\.Settings" }, float = true })
hl.window_rule({ name = "legacy-windowrule-22", match = { class = "org\\.gnome\\.Settings" }, size = "70% 80%" })
hl.window_rule({ name = "legacy-windowrule-23", match = { class = "org\\.gnome\\.Settings" }, center = true })
hl.window_rule({ name = "legacy-windowrule-24", match = { class = "org\\.pulseaudio\\.pavucontrol|yad-icon-browser" }, float = true })
hl.window_rule({ name = "legacy-windowrule-25", match = { class = "org\\.pulseaudio\\.pavucontrol|yad-icon-browser" }, size = "60% 70%" })
hl.window_rule({ name = "legacy-windowrule-26", match = { class = "org\\.pulseaudio\\.pavucontrol|yad-icon-browser" }, center = true })

hl.window_rule({ name = "legacy-windowrule-35", match = { class = "^(QQ)$" }, float = true })
hl.window_rule({ name = "legacy-windowrule-36", match = { class = "^(QQ)$", initial_title = "^(QQ)$" }, float = true })
hl.window_rule({ name = "legacy-windowrule-37", match = { class = "^(QQ)$", title = "^(QQ)$" }, tile = true })

hl.window_rule({ name = "legacy-windowrule-38", match = { class = "^(wechat)$", initial_title = "^(打开|打开文件|保存|另存为|Open|Open File|Save As)$" }, float = true })
hl.window_rule({ name = "legacy-windowrule-39", match = { class = "^(wechat)$", initial_title = "^(打开|打开文件|保存|另存为|Open|Open File|Save As)$" }, size = "1200 780" })
hl.window_rule({ name = "legacy-windowrule-40", match = { class = "^(wechat)$", initial_title = "^(打开|打开文件|保存|另存为|Open|Open File|Save As)$" }, center = true })
hl.window_rule({ name = "legacy-windowrule-41", match = { class = "^(wechat)$", title = "^(图片和视频)$" }, float = true })

hl.window_rule({ name = "legacy-windowrule-42", match = { class = "^(org\\.freedesktop\\.impl\\.portal\\.desktop\\.kde|xdg-desktop-portal-gtk)$", initial_title = "^(打开文件|保存文件|选择文件夹|打开文件夹|Open File|Open Files|Save File|Select Folder|Open Folder)$" }, float = true })
hl.window_rule({ name = "legacy-windowrule-43", match = { class = "^(org\\.freedesktop\\.impl\\.portal\\.desktop\\.kde|xdg-desktop-portal-gtk)$", initial_title = "^(打开文件|保存文件|选择文件夹|打开文件夹|Open File|Open Files|Save File|Select Folder|Open Folder)$" }, size = "1400 920" })
hl.window_rule({ name = "legacy-windowrule-44", match = { class = "^(org\\.freedesktop\\.impl\\.portal\\.desktop\\.kde|xdg-desktop-portal-gtk)$", initial_title = "^(打开文件|保存文件|选择文件夹|打开文件夹|Open File|Open Files|Save File|Select Folder|Open Folder)$" }, center = true })

hl.window_rule({ name = "legacy-windowrule-45", match = { title = "(Select|Open)( a)? (File|Folder)(s)?" }, float = true })
hl.window_rule({ name = "legacy-windowrule-46", match = { title = "File (Operation|Upload)( Progress)?" }, float = true })
hl.window_rule({ name = "legacy-windowrule-47", match = { title = ".* Properties" }, float = true })
hl.window_rule({ name = "legacy-windowrule-48", match = { title = "Export Image as PNG" }, float = true })
hl.window_rule({ name = "legacy-windowrule-49", match = { title = "GIMP Crash Debug" }, float = true })
hl.window_rule({ name = "legacy-windowrule-50", match = { title = "Save As" }, float = true })
hl.window_rule({ name = "legacy-windowrule-51", match = { title = "Library" }, float = true })
hl.window_rule({ name = "legacy-windowrule-52", match = { title = "Picture(-| )in(-| )[Pp]icture" }, move = "100%-w-2% 100%-w-3%" })
hl.window_rule({ name = "legacy-windowrule-53", match = { title = "Picture(-| )in(-| )[Pp]icture" }, keep_aspect_ratio = true })
hl.window_rule({ name = "legacy-windowrule-54", match = { title = "Picture(-| )in(-| )[Pp]icture" }, float = true })
hl.window_rule({ name = "legacy-windowrule-55", match = { title = "Picture(-| )in(-| )[Pp]icture" }, pin = true })
hl.window_rule({ name = "legacy-windowrule-56", match = { class = "krita|gimp|inkscape|darktable|resolve|kdenlive|shotcut|blender|godot" }, opaque = true })
hl.window_rule({ name = "legacy-windowrule-57", match = { class = "^(ueberzugpp_.*)$" }, float = true })
hl.window_rule({ name = "legacy-windowrule-58", match = { class = "^(ueberzugpp_.*)$" }, no_initial_focus = true })
hl.window_rule({ name = "legacy-windowrule-59", match = { class = "steam" }, rounding = 10 })
hl.window_rule({ name = "legacy-windowrule-60", match = { title = "Friends List", class = "steam" }, float = true })
hl.window_rule({ name = "legacy-windowrule-61", match = { class = "(steam_app_(default|[0-9]+)|gamescope)" }, opaque = true })
hl.window_rule({ name = "legacy-windowrule-62", match = { class = "(steam_app_(default|[0-9]+)|gamescope)" }, immediate = true })
hl.window_rule({ name = "legacy-windowrule-63", match = { class = "(steam_app_(default|[0-9]+)|gamescope)" }, idle_inhibit = "always" })
hl.window_rule({ name = "legacy-windowrule-64", match = { class = "com-atlauncher-App", title = "ATLauncher Console" }, float = true })
hl.window_rule({ name = "legacy-windowrule-65", match = { class = "PandoraLauncher", title = "Minecraft Game Output" }, float = true })
hl.window_rule({ name = "legacy-windowrule-66", match = { title = "Fusion360|(Marking Menu)", class = "fusion360\\.exe" }, no_blur = true })
hl.window_rule({ name = "legacy-windowrule-67", match = { xwayland = true, title = "win[0-9]+" }, no_dim = true })
hl.window_rule({ name = "legacy-windowrule-68", match = { xwayland = true, title = "win[0-9]+" }, no_shadow = true })
hl.window_rule({ name = "legacy-windowrule-69", match = { xwayland = true, title = "win[0-9]+" }, rounding = 10 })
hl.workspace_rule({ workspace = "w[tv1]s[false]", gaps_out = 2 })
hl.workspace_rule({ workspace = "f[1]s[false]", gaps_out = 2 })
hl.layer_rule({ name = "legacy-layerrule-72", match = { namespace = "hyprpicker" }, animation = "fade" })
hl.layer_rule({ name = "legacy-layerrule-73", match = { namespace = "logout_dialog" }, animation = "fade" })
hl.layer_rule({ name = "legacy-layerrule-74", match = { namespace = "selection" }, animation = "fade" })
hl.layer_rule({ name = "legacy-layerrule-75", match = { namespace = "wayfreeze" }, animation = "fade" })
hl.layer_rule({ name = "legacy-layerrule-76", match = { namespace = "launcher" }, animation = "popin 80%" })
hl.layer_rule({ name = "legacy-layerrule-77", match = { namespace = "launcher" }, blur = true })

hl.window_rule({ name = "legacy-windowrule-82", match = { pin = true }, border_color = "rgba(42a5f5AA) rgba(42a5f577)" })

hl.bind("SUPER + Q", hl.dsp.window.close())

hl.bind("SUPER + M", hl.dsp.exec_cmd("hyprctl dispatch exit"))
hl.bind("SUPER + L", hl.dsp.exec_cmd("dms ipc call lock lock"))
hl.bind("SUPER + I", hl.dsp.exec_cmd("dms ipc call settings focusOrToggle"))
hl.bind("SUPER + V", hl.dsp.exec_cmd("dms ipc call clipboard toggle"))
hl.bind("SUPER + B", hl.dsp.exec_cmd("dms ipc call notepad toggle"))
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("dms ipc call audio increment 3"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("dms ipc call audio decrement 3"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("dms ipc call audio mute"), { locked = true })
hl.bind("SUPER + 1", hl.dsp.focus({ workspace = "1" }))
hl.bind("SUPER + 2", hl.dsp.focus({ workspace = "2" }))
hl.bind("SUPER + 3", hl.dsp.focus({ workspace = "3" }))
hl.bind("SUPER + 4", hl.dsp.focus({ workspace = "4" }))
hl.bind("SUPER + 5", hl.dsp.focus({ workspace = "5" }))
hl.bind("SUPER + 6", hl.dsp.focus({ workspace = "6" }))
hl.bind("SUPER + 7", hl.dsp.focus({ workspace = "7" }))
hl.bind("SUPER + 8", hl.dsp.focus({ workspace = "8" }))
hl.bind("SUPER + 9", hl.dsp.focus({ workspace = "9" }))
hl.bind("SUPER + 0", hl.dsp.focus({ workspace = "10" }))

hl.bind("SUPER + mouse_down", hl.dsp.layout("focus l"))
hl.bind("SUPER + mouse_up", hl.dsp.layout("focus r"))

hl.bind("SUPER + up", hl.dsp.window.move({ workspace = "-1" }), { repeating = true })
hl.bind("SUPER + down", hl.dsp.window.move({ workspace = "+1" }), { repeating = true })

hl.bind("SUPER + Page_Up", hl.dsp.focus({ workspace = "-1" }), { repeating = true })
hl.bind("SUPER + Page_Down", hl.dsp.focus({ workspace = "+1" }), { repeating = true })
hl.bind("ALT + Tab", hl.dsp.layout("focus r"), { repeating = true })
hl.bind("SUPER + left", hl.dsp.layout("focus l"))
hl.bind("SUPER + right", hl.dsp.layout("focus r"))
hl.bind("SUPER + SHIFT + left", hl.dsp.layout("swapcol l"))
hl.bind("SUPER + SHIFT + right", hl.dsp.layout("swapcol r"))

hl.bind("SUPER + F", hl.dsp.layout("colresize +conf"))

hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind("SUPER + Space", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + T", hl.dsp.exec_cmd("kitty"))

-- hl.bind("SUPER + G", hl.dsp.exec_cmd("dms ipc call hypr toggleOverview"))
hl.bind("SUPER + G", hl.dsp.exec_cmd("/home/lyc/.local/share/caelestia/hypr/scripts/window-picker.sh"))
hl.bind("SUPER + E", hl.dsp.exec_cmd("app2unit -- thunar & sleep .3; caelestia resizer Thunar titleContains 86% 86% float,center"))

hl.bind("Print", hl.dsp.exec_cmd("dms screenshot"))
hl.bind("CTRL + Print", hl.dsp.exec_cmd("dms screenshot full"))
hl.bind("ALT + Print", hl.dsp.exec_cmd("dms screenshot window --stdout | swappy -f -"))
hl.bind("CTRL + ALT + a", hl.dsp.exec_cmd("grim -g \"$(slurp -d)\" - | wl-copy"))
hl.bind("SUPER + p", hl.dsp.exec_cmd("[float;pin] sh -c 'f=$(mktemp --suffix=.png /tmp/hypr-pinshot.XXXXXX); grim -g \"$(slurp -d)\" \"$f\" && imv \"$f\"; rm -f \"$f\"'"))
hl.bind("SUPER + D", hl.dsp.exec_cmd("[float;center;size 1000 600;noanim;noborder;noshadow] wofi --show drun --allow-images --normal-window --width 1000 --height 600"))

