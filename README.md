# Galaxy3D Shell

Galaxy3D Shell adalah desktop shell berbasis Quickshell untuk Hyprland (Wayland). Shell ini menyediakan background 3D interaktif (Bumi, Bulan, dan satelit status sistem), 3D orbital app launcher, top bar, OSD volume/kecerahan, dan panel notifikasi.

## Dependensi

Pastikan paket berikut terpasang di sistem:
- `quickshell` (>= 0.3.2)
- `hyprland`
- `qt6-declarative`, `qt6-5compat`
- `pipewire`, `wireplumber`
- `networkmanager`, `bluez`, `brightnessctl`, `curl`
- `rust`, `cargo` (untuk build helper)
- Font: `JetBrainsMono Nerd Font` atau `Iosevka Nerd Font`

## Instalasi

1. Salin konfigurasi ke direktori Quickshell:
```bash
git clone https://github.com/makdumibrohim/galaxy3d.git ~/.config/quickshell/galaxy3d
cd ~/.config/quickshell/galaxy3d
```

2. Kompilasi binary helper:
```bash
cd services/helper
cargo build --release
cp target/release/galaxy3d-helper ../galaxy3d-helper
chmod +x ../galaxy3d-helper
cd ../..
```

3. Uji coba jalankan shell:
```bash
qs -c galaxy3d
```

## Konfigurasi Hyprland

Tambahkan baris berikut ke `~/.config/hypr/hyprland.conf`:

```ini
# Autostart saat login
exec-once = qs -c galaxy3d

# Keybinds
bind = SUPER, SUPER_L, exec, qs -c galaxy3d ipc call launcher toggle
bind = SUPER, A, exec, qs -c galaxy3d ipc call launcher toggle
bind = SUPER, I, exec, qs -c galaxy3d ipc call settings toggle
bind = SUPER, N, exec, qs -c galaxy3d ipc call network toggle
bind = SUPER, X, exec, qs -c galaxy3d ipc call power toggle
bind = SUPER, M, exec, qs -c galaxy3d ipc call media toggle
```

## Perintah IPC

Gunakan perintah `qs -c galaxy3d ipc call <target> <fungsi>` untuk mengontrol shell dari terminal atau skrip:

| Target | Fungsi | Keterangan |
| :--- | :--- | :--- |
| `launcher` | `toggle()` | Buka / tutup App Launcher |
| `settings` | `toggle()` | Buka / tutup jendela pengaturan |
| `network` | `toggle()` | Buka / tutup scanner Wi-Fi |
| `power` | `toggle()` | Buka / tutup menu power/sesi |
| `media` | `toggle()` | Buka / tutup flyout media player |
| `wallpaper`| `random()` | Ganti wallpaper acak dari `~/Pictures/Wallpapers/` |
| `wallpaper`| `set(path)` | Set wallpaper ke file tertentu |
