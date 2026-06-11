use std::path::{Path, PathBuf};

pub const API_BASE: &str = "https://dark.zorionlabs.net/dw-api";
pub const CDN_BASE: &str = "https://dark.zorionlabs.net";

pub fn game_dir() -> PathBuf {
    if cfg!(target_os = "windows") {
        dirs::data_local_dir()
            .unwrap_or_else(|| PathBuf::from("."))
            .join("DarkWorld")
            .join("game")
    } else {
        dirs::data_dir()
            .unwrap_or_else(|| PathBuf::from("."))
            .join("DarkWorld")
            .join("game")
    }
}

pub fn version_file() -> PathBuf {
    game_dir().join("version.json")
}

pub fn installation_id_path() -> PathBuf {
    game_dir()
        .parent()
        .unwrap_or(Path::new("."))
        .join("installation_id")
}

pub fn read_local_version() -> String {
    let p = version_file();
    if !p.exists() {
        return "0.0.0".to_string();
    }
    let Ok(data) = std::fs::read_to_string(&p) else {
        return "0.0.0".to_string();
    };
    let Ok(v) = serde_json::from_str::<serde_json::Value>(&data) else {
        return "0.0.0".to_string();
    };
    v.get("game_version")
        .and_then(|x| x.as_str())
        .unwrap_or("0.0.0")
        .to_string()
}

pub fn write_local_version(game_version: &str, launcher_version: &str) {
    let dir = game_dir();
    let _ = std::fs::create_dir_all(&dir);
    let payload = serde_json::json!({
        "game_version": game_version,
        "launcher_version": launcher_version,
        "updated_at": chrono_now()
    });
    let _ = std::fs::write(version_file(), payload.to_string());
}

fn chrono_now() -> String {
    use std::time::{SystemTime, UNIX_EPOCH};
    let d = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default();
    format!("{}", d.as_secs())
}

pub fn get_installation_id() -> String {
    let p = installation_id_path();
    if p.exists() {
        if let Ok(s) = std::fs::read_to_string(&p) {
            let t = s.trim().to_string();
            if !t.is_empty() {
                return t;
            }
        }
    }
    let id = uuid::Uuid::new_v4().to_string();
    if let Some(parent) = p.parent() {
        let _ = std::fs::create_dir_all(parent);
    }
    let _ = std::fs::write(&p, &id);
    id
}

pub fn find_game_executable() -> Option<PathBuf> {
    let base = game_dir();
    #[cfg(target_os = "windows")]
    {
        let candidates = [
            base.join("windows").join("DarkWorld.exe"),
            base.join("DarkWorld.exe"),
        ];
        for c in candidates {
            if c.exists() {
                return Some(c);
            }
        }
    }
    #[cfg(target_os = "macos")]
    {
        let candidates = [
            base.join("DarkWorld.app"),
            base.join("Dark World.app"),
        ];
        for app in candidates {
            let exe = app.join("Contents").join("MacOS").join("Dark World");
            if exe.exists() {
                return Some(exe);
            }
            let exe2 = app.join("Contents").join("MacOS").join("DarkWorld");
            if exe2.exists() {
                return Some(exe2);
            }
        }
        // walk for .app
        if let Ok(entries) = std::fs::read_dir(&base) {
            for e in entries.flatten() {
                let p = e.path();
                if p.extension().and_then(|s| s.to_str()) == Some("app") {
                    if let Some(exe) = find_macos_exe(&p) {
                        return Some(exe);
                    }
                }
            }
        }
    }
    None
}

#[cfg(target_os = "macos")]
fn find_macos_exe(app: &Path) -> Option<PathBuf> {
    let macos_dir = app.join("Contents").join("MacOS");
    if let Ok(entries) = std::fs::read_dir(macos_dir) {
        for e in entries.flatten() {
            let p = e.path();
            if p.is_file() {
                return Some(p);
            }
        }
    }
    None
}

#[cfg(not(target_os = "macos"))]
fn find_macos_exe(_app: &Path) -> Option<PathBuf> {
    None
}
