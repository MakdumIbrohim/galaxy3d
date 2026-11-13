mod common;
mod apps;
mod weather;

fn main() {
    let args: Vec<String> = std::env::args().collect();
    if args.len() < 2 {
        eprintln!("Usage: galaxy3d-helper [apps|weather [--current]]");
        std::process::exit(1);
    }

    match args[1].as_str() {
        "apps" => apps::fetch_apps(),
        "weather" => {
            let current_only = args.len() > 2 && args[2] == "--current";
            weather::fetch_weather(current_only);
        }
        cmd => {
            eprintln!("Unknown command: {}", cmd);
            std::process::exit(1);
        }
    }
}
