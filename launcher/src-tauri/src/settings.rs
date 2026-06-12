use serde::{Deserialize, Serialize};
use std::fs;
use std::path::PathBuf;

#[derive(Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum OnPlayBehavior {
    MinimizeToTray,
    Hide,
    Close,
}

impl Default for OnPlayBehavior {
    fn default() -> Self {
        Self::MinimizeToTray
    }
}

#[derive(Clone, Serialize, Deserialize)]
pub struct LauncherSettings {
    #[serde(default)]
    pub on_play: OnPlayBehavior,
}

impl Default for LauncherSettings {
    fn default() -> Self {
        Self {
            on_play: OnPlayBehavior::default(),
        }
    }
}

pub fn settings_path() -> PathBuf {
    let base = if cfg!(target_os = "windows") {
        dirs::data_local_dir().unwrap_or_else(|| PathBuf::from("."))
    } else {
        dirs::data_dir().unwrap_or_else(|| PathBuf::from("."))
    };
    base.join("DarkWorld").join("launcher").join("settings.json")
}

pub fn load_settings() -> LauncherSettings {
    let path = settings_path();
    if !path.exists() {
        return LauncherSettings::default();
    }
    fs::read_to_string(&path)
        .ok()
        .and_then(|s| serde_json::from_str(&s).ok())
        .unwrap_or_default()
}

pub fn save_settings(settings: &LauncherSettings) -> Result<(), String> {
    let path = settings_path();
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent).map_err(|e| e.to_string())?;
    }
    fs::write(&path, serde_json::to_string_pretty(settings).map_err(|e| e.to_string())?)
        .map_err(|e| e.to_string())
}
