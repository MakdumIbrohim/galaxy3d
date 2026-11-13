use serde::Serialize;
use std::collections::HashSet;
use std::fs::{self, File};
use std::io::{BufRead, BufReader};
use std::path::Path;

#[derive(Serialize)]
pub struct AppItem {
    pub name: String,
    pub icon: String,
    pub exec: String,
}

pub fn fetch_apps() {
    let mut apps = Vec::new();
    let mut seen = HashSet::new();

    let home = std::env::var("HOME").unwrap_or_default();
    let dirs = [
        format!("{}/.local/share/applications", home),
        "/usr/local/share/applications".to_string(),
        "/usr/share/applications".to_string(),
    ];

    for d in &dirs {
        let p = Path::new(d);
        if !p.exists() {
            continue;
        }
        if let Ok(entries) = fs::read_dir(p) {
            for entry in entries.flatten() {
                let path = entry.path();
                if path.extension().and_then(|s| s.to_str()) != Some("desktop") {
                    continue;
                }
                if let Ok(file) = File::open(&path) {
                    let reader = BufReader::new(file);
                    let mut in_entry = false;
                    let mut name = None;
                    let mut icon = "application-x-executable".to_string();
                    let mut exec = None;
                    let mut nodisplay = false;

                    for line in reader.lines().flatten() {
                        let line = line.trim();
                        if line == "[Desktop Entry]" {
                            in_entry = true;
                            continue;
                        }
                        if line.starts_with('[') && line.ends_with(']') {
                            if in_entry {
                                break;
                            }
                            continue;
                        }
                        if !in_entry {
                            continue;
                        }

                        if let Some(val) = line.strip_prefix("Name=") {
                            if name.is_none() {
                                name = Some(val.trim().to_string());
                            }
                        } else if let Some(val) = line.strip_prefix("Icon=") {
                            if icon == "application-x-executable" {
                                icon = val.trim().to_string();
                            }
                        } else if let Some(val) = line.strip_prefix("Exec=") {
                            if exec.is_none() {
                                exec = Some(val.trim().to_string());
                            }
                        } else if line == "NoDisplay=true" {
                            nodisplay = true;
                        }
                    }

                    if let (Some(name), Some(exec)) = (name, exec) {
                        if !nodisplay && seen.insert(name.clone()) {
                            apps.push(AppItem { name, icon, exec });
                        }
                    }
                }
            }
        }
    }

    apps.sort_by(|a, b| a.name.to_lowercase().cmp(&b.name.to_lowercase()));
    println!("{}", serde_json::to_string(&apps).unwrap_or_else(|_| "[]".into()));
}
