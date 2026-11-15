# Galaxy3D Shell

Galaxy3D Shell is a Quickshell-based desktop shell for Hyprland (Wayland). It features an interactive 3D background (Earth, Moon, and orbiting system status satellites), a 3D orbital application launcher, top bar, volume/brightness OSD, and notification overlays.

## Dependencies

Ensure the following packages are installed on your system:
- `quickshell` (>= 0.3.2)
- `hyprland`
- `qt6-declarative`, `qt6-5compat`
- `pipewire`, `wireplumber`
- `networkmanager`, `bluez`, `brightnessctl`, `curl`
- `rust`, `cargo` (for helper build)
- Fonts: `JetBrainsMono Nerd Font` or `Iosevka Nerd Font`

## Installation

1. Clone configuration into the Quickshell directory:
```bash
git clone https://github.com/makdumibrohim/galaxy3d.git ~/.config/quickshell/galaxy3d
cd ~/.config/quickshell/galaxy3d
```

2. Compile the helper binary:
```bash
cd services/helper
cargo build --release
cp target/release/galaxy3d-helper ../galaxy3d-helper
chmod +x ../galaxy3d-helper
cd ../..
```

3. Launch shell test run:
```bash
qs -c galaxy3d
```

## Hyprland Configuration

Add the following lines to `~/.config/hypr/hyprland.conf`:

```ini
# Autostart on login
exec-once = qs -c galaxy3d

# Keybindings
bind = SUPER, SUPER_L, exec, qs -c galaxy3d ipc call launcher toggle
bind = SUPER, A, exec, qs -c galaxy3d ipc call launcher toggle
bind = SUPER, I, exec, qs -c galaxy3d ipc call settings toggle
bind = SUPER, N, exec, qs -c galaxy3d ipc call network toggle
bind = SUPER, X, exec, qs -c galaxy3d ipc call power toggle
bind = SUPER, M, exec, qs -c galaxy3d ipc call media toggle
```

## IPC Commands

Use `qs -c galaxy3d ipc call <target> <function>` to control the shell from a terminal or script:

| Target | Function | Description |
| :--- | :--- | :--- |
| `launcher` | `toggle()` | Toggle App Launcher |
| `settings` | `toggle()` | Toggle Settings Window |
| `network` | `toggle()` | Toggle Wi-Fi Scanner |
| `power` | `toggle()` | Toggle Power / Session Menu |
| `media` | `toggle()` | Toggle Media Player Flyout |
| `wallpaper`| `random()` | Set random wallpaper from `~/Pictures/Wallpapers/` |
| `wallpaper`| `set(path)` | Set wallpaper to a specific file |
