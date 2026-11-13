use std::fs;
use std::path::PathBuf;

pub fn get_cache_dir() -> PathBuf {
    let home = std::env::var("HOME").unwrap_or_else(|_| "/tmp".into());
    let cache_home = std::env::var("XDG_CACHE_HOME").unwrap_or_else(|_| format!("{}/.cache", home));
    let dir = PathBuf::from(cache_home).join("galaxy3d");
    let _ = fs::create_dir_all(&dir);
    dir
}
