#!/usr/bin/env python3
import sys, json, os, urllib.request

WEATHER_ICONS = {
    0: ("󰖙", "#f9e2af"), # Clear sky
    1: ("󰖕", "#f9e2af"), # Mainly clear
    2: ("󰖐", "#cdd6f4"), # Partly cloudy
    3: ("󰖐", "#a6adc8"), # Overcast
    45: ("󰖑", "#bac2de"), # Fog
    48: ("󰖑", "#bac2de"),
    51: ("󰖗", "#89b4fa"), # Drizzle
    53: ("󰖗", "#89b4fa"),
    55: ("󰖗", "#89b4fa"),
    61: ("󰖖", "#74c7ec"), # Rain
    63: ("󰖖", "#74c7ec"),
    65: ("󰖖", "#74c7ec"),
    71: ("󰖘", "#b4befe"), # Snow
    73: ("󰖘", "#b4befe"),
    75: ("󰖘", "#b4befe"),
    80: ("󰖖", "#74c7ec"), # Showers
    81: ("󰖖", "#74c7ec"),
    82: ("󰖖", "#74c7ec"),
    95: ("󰖓", "#f38ba8"), # Thunderstorm
}

def get_weather():
    cache_dir = os.path.expanduser("~/.cache/galaxy3d")
    os.makedirs(cache_dir, exist_ok=True)
    cache_file = os.path.join(cache_dir, "weather.json")

    # Try cache if fresh (< 20 mins)
    if os.path.exists(cache_file) and (os.path.getmtime(cache_file) + 1200 > os.path.getmtime(cache_file)):
        pass

    lat, lon = -6.2, 106.8 # Jakarta fallback
    try:
        req = urllib.request.Request("http://ip-api.com/json", headers={"User-Agent": "curl/7.88.1"})
        with urllib.request.urlopen(req, timeout=3) as resp:
            loc = json.loads(resp.read().decode())
            lat, lon = loc.get("lat", lat), loc.get("lon", lon)
    except Exception:
        pass

    url = (
        f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}"
        "&current=temperature_2m,weather_code,relative_humidity_2m,apparent_temperature,precipitation,wind_speed_10m"
        "&hourly=temperature_2m,weather_code,apparent_temperature,precipitation_probability,relative_humidity_2m,wind_speed_10m"
        "&timezone=auto"
    )

    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=5) as resp:
            data = json.loads(resp.read().decode())
    except Exception as e:
        if os.path.exists(cache_file):
            with open(cache_file, "r") as f:
                return json.load(f)
        return {
            "current": {"temp": "31", "icon": "󰖙", "hex": "#f9e2af"},
            "forecast": [{"wind": "2.5", "humidity": "65", "pop": "10", "feels_like": "33", "hourly": []}]
        }

    curr = data.get("current", {})
    code = curr.get("weather_code", 0)
    icon, hex_color = WEATHER_ICONS.get(code, ("󰖙", "#f9e2af"))
    curr_temp = str(round(curr.get("temperature_2m", 28)))

    hourly_raw = data.get("hourly", {})
    times = hourly_raw.get("time", [])
    temps = hourly_raw.get("temperature_2m", [])
    codes = hourly_raw.get("weather_code", [])

    hourly_list = []
    for i in range(min(8, len(times))):
        t_str = times[i].split("T")[-1][:5] if "T" in times[i] else f"{i:02d}:00"
        h_code = codes[i] if i < len(codes) else 0
        h_icon, h_hex = WEATHER_ICONS.get(h_code, ("󰖙", "#f9e2af"))
        hourly_list.append({
            "time": t_str,
            "temp": str(round(temps[i])) if i < len(temps) else curr_temp,
            "icon": h_icon,
            "hex": h_hex
        })

    wind = str(round(curr.get("wind_speed_10m", 2.0), 1))
    humidity = str(round(curr.get("relative_humidity_2m", 60)))
    feels_like = str(round(curr.get("apparent_temperature", float(curr_temp))))
    pop = "10"
    if hourly_raw.get("precipitation_probability"):
        pop = str(hourly_raw["precipitation_probability"][0])

    res = {
        "current": {
            "temp": curr_temp,
            "icon": icon,
            "hex": hex_color
        },
        "forecast": [{
            "wind": wind,
            "humidity": humidity,
            "pop": pop,
            "feels_like": feels_like,
            "hourly": hourly_list
        }]
    }

    try:
        with open(cache_file, "w") as f:
            json.dump(res, f)
    except Exception:
        pass

    return res

if __name__ == "__main__":
    w = get_weather()
    if len(sys.argv) > 1 and sys.argv[1] == "--current":
        c = w["current"]
        print(f"{c['icon']}\n{c['temp']}°\n{c['hex']}")
    else:
        print(json.dumps(w))
