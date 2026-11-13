import os, glob, json

apps = []
seen = set()
dirs = [
    os.path.expanduser("~/.local/share/applications"),
    "/usr/local/share/applications",
    "/usr/share/applications"
]

for d in dirs:
    if not os.path.exists(d): continue
    for f in glob.glob(os.path.join(d, "*.desktop")):
        try:
            name, icon, exec_cmd, nodisplay = None, "application-x-executable", None, False
            with open(f, "r", encoding="utf-8", errors="ignore") as fp:
                for line in fp:
                    line = line.strip()
                    if line == "[Desktop Entry]": continue
                    if line.startswith("[") and line.endswith("]"): break
                    if line.startswith("Name=") and not name:
                        name = line.split("=", 1)[1].strip()
                    elif line.startswith("Icon=") and icon == "application-x-executable":
                        icon = line.split("=", 1)[1].strip()
                    elif line.startswith("Exec=") and not exec_cmd:
                        exec_cmd = line.split("=", 1)[1].strip()
                    elif line.startswith("NoDisplay=true"):
                        nodisplay = True
            if name and exec_cmd and not nodisplay and name not in seen:
                seen.add(name)
                apps.append({"name": name, "icon": icon, "exec": exec_cmd})
        except Exception:
            pass

apps.sort(key=lambda x: x["name"].lower())
print(json.dumps(apps))
