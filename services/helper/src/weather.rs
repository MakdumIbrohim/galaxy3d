use crate::common;
use serde_json::{json, Value};
use std::fs;
use std::process::Command;
use std::time::SystemTime;

pub fn get_weather_icon(code: i64) -> (&'static str, &'static str) {
    match code {
        0 => ("󰖙", "#f9e2af"),
        1 => ("󰖕", "#f9e2af"),
        2 => ("󰖐", "#cdd6f4"),
        3 => ("󰖐", "#a6adc8"),
        45 | 48 => ("󰖑", "#bac2de"),
        51 | 53 | 55 => ("󰖗", "#89b4fa"),
        61 | 63 | 65 => ("󰖖", "#74c7ec"),
        71 | 73 | 75 => ("󰖘", "#b4befe"),
        80 | 81 | 82 => ("󰖖", "#74c7ec"),
        95 => ("󰖓", "#f38ba8"),
        _ => ("󰖙", "#f9e2af"),
    }
}

pub fn fetch_weather(current_only: bool) {
    let cache_file = common::get_cache_dir().join("weather.json");

    if let Ok(metadata) = fs::metadata(&cache_file) {
        if let Ok(modified) = metadata.modified() {
            if let Ok(elapsed) = SystemTime::now().duration_since(modified) {
                if elapsed.as_secs() < 900 {
                    if let Ok(content) = fs::read_to_string(&cache_file) {
                        if let Ok(parsed) = serde_json::from_str::<Value>(&content) {
                            output_weather(&parsed, current_only);
                            return;
                        }
                    }
                }
            }
        }
    }

    let mut lat = -6.2f64;
    let mut lon = 106.8f64;
    let ip_out = Command::new("curl")
        .args(["-s", "--max-time", "3", "http://ip-api.com/json"])
        .output();
    if let Ok(out) = ip_out {
        if let Ok(parsed) = serde_json::from_slice::<Value>(&out.stdout) {
            if let (Some(la), Some(lo)) = (parsed["lat"].as_f64(), parsed["lon"].as_f64()) {
                lat = la;
                lon = lo;
            }
        }
    }

    let url = format!(
        "https://api.open-meteo.com/v1/forecast?latitude={}&longitude={}\
        &current=temperature_2m,weather_code,relative_humidity_2m,apparent_temperature,precipitation,wind_speed_10m\
        &hourly=temperature_2m,weather_code,apparent_temperature,precipitation_probability,relative_humidity_2m,wind_speed_10m\
        &timezone=auto",
        lat, lon
    );

    let weather_out = Command::new("curl")
        .args(["-s", "--max-time", "5", &url])
        .output();

    let raw_val: Option<Value> = match weather_out {
        Ok(out) => serde_json::from_slice(&out.stdout).ok(),
        Err(_) => None,
    };

    let result = if let Some(data) = raw_val {
        let curr = &data["current"];
        let code = curr["weather_code"].as_i64().unwrap_or(0);
        let (icon, hex) = get_weather_icon(code);
        let curr_temp = curr["temperature_2m"].as_f64().unwrap_or(28.0).round().to_string();

        let times = data["hourly"]["time"].as_array();
        let temps = data["hourly"]["temperature_2m"].as_array();
        let codes = data["hourly"]["weather_code"].as_array();

        let mut hourly_list = Vec::new();
        let count = times.map(|t| t.len()).unwrap_or(0).min(8);
        for i in 0..count {
            let t_raw = times.and_then(|a| a.get(i)).and_then(|v| v.as_str()).unwrap_or("");
            let t_str = if let Some((_, time)) = t_raw.split_once('T') {
                &time[..time.len().min(5)]
            } else {
                "--:--"
            };
            let h_code = codes.and_then(|a| a.get(i)).and_then(|v| v.as_i64()).unwrap_or(0);
            let (h_icon, h_hex) = get_weather_icon(h_code);
            let h_temp = temps
                .and_then(|a| a.get(i))
                .and_then(|v| v.as_f64())
                .map(|t| t.round().to_string())
                .unwrap_or_else(|| curr_temp.clone());

            hourly_list.push(json!({
                "time": t_str,
                "temp": h_temp,
                "icon": h_icon,
                "hex": h_hex
            }));
        }

        let wind = format!("{:.1}", curr["wind_speed_10m"].as_f64().unwrap_or(2.0));
        let humidity = curr["relative_humidity_2m"].as_f64().unwrap_or(60.0).round().to_string();
        let feels_like = curr["apparent_temperature"].as_f64().unwrap_or(30.0).round().to_string();
        let pop = data["hourly"]["precipitation_probability"]
            .as_array()
            .and_then(|a| a.first())
            .and_then(|v| v.as_i64())
            .unwrap_or(10)
            .to_string();

        json!({
            "current": {
                "temp": curr_temp,
                "icon": icon,
                "hex": hex
            },
            "forecast": [{
                "wind": wind,
                "humidity": humidity,
                "pop": pop,
                "feels_like": feels_like,
                "hourly": hourly_list
            }]
        })
    } else {
        json!({
            "current": {"temp": "31", "icon": "󰖙", "hex": "#f9e2af"},
            "forecast": [{"wind": "2.5", "humidity": "65", "pop": "10", "feels_like": "33", "hourly": []}]
        })
    };

    let _ = fs::write(&cache_file, serde_json::to_string(&result).unwrap_or_default());
    output_weather(&result, current_only);
}

pub fn output_weather(data: &Value, current_only: bool) {
    if current_only {
        let icon = data["current"]["icon"].as_str().unwrap_or("󰖙");
        let temp = data["current"]["temp"].as_str().unwrap_or("31");
        let hex = data["current"]["hex"].as_str().unwrap_or("#f9e2af");
        println!("{}\n{}°\n{}", icon, temp, hex);
    } else {
        println!("{}", serde_json::to_string(data).unwrap_or_else(|_| "{}".into()));
    }
}
