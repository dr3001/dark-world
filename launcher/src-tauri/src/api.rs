use crate::paths::{API_BASE, CDN_BASE};
use serde::{Deserialize, Serialize};
use serde_json::Value;

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct ManifestFile {
    pub path: String,
    pub url: String,
    pub size: u64,
    pub sha256: String,
    pub platform: String,
    pub role: String,
    pub package_type: String,
    #[serde(default)]
    pub required: bool,
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct Manifest {
    pub game_version: String,
    pub launcher_version: String,
    #[serde(default)]
    pub force_update: bool,
    pub files: Vec<ManifestFile>,
}

#[derive(Debug, Deserialize)]
pub struct ServerStatus {
    pub server: String,
    pub players_online: i64,
    pub game_version: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct VersionPolicy {
    pub backend_current_version: String,
    pub minimum_client_version: String,
    pub minimum_launcher_version: String,
    pub maintenance_mode: bool,
    pub login_allowed: bool,
    pub message: String,
}

pub async fn fetch_status(client: &reqwest::Client) -> Result<ServerStatus, String> {
    let url = format!("{}/api/launcher/status", API_BASE);
    let resp = client
        .get(&url)
        .send()
        .await
        .map_err(|e| format!("status request failed: {e}"))?;
    if !resp.status().is_success() {
        return Err(format!("status HTTP {}", resp.status()));
    }
    resp.json()
        .await
        .map_err(|e| format!("status parse failed: {e}"))
}

pub async fn fetch_manifest(client: &reqwest::Client) -> Result<Manifest, String> {
    let url = format!("{}/downloads/launcher/manifest.json", CDN_BASE);
    let resp = client
        .get(&url)
        .send()
        .await
        .map_err(|e| format!("manifest request failed: {e}"))?;
    if !resp.status().is_success() {
        return Err(format!("manifest HTTP {}", resp.status()));
    }
    resp.json()
        .await
        .map_err(|e| format!("manifest parse failed: {e}"))
}

pub async fn fetch_version_policy(client: &reqwest::Client) -> Result<VersionPolicy, String> {
    let url = format!("{}/api/launcher/version", API_BASE);
    let resp = client
        .get(&url)
        .send()
        .await
        .map_err(|e| format!("version policy failed: {e}"))?;
    if !resp.status().is_success() {
        return Err(format!("version HTTP {}", resp.status()));
    }
    resp.json()
        .await
        .map_err(|e| format!("version parse failed: {e}"))
}

pub fn version_lt(a: &str, b: &str) -> bool {
    let parse = |s: &str| -> Vec<u32> {
        s.split('.')
            .filter_map(|p| p.parse().ok())
            .collect()
    };
    let mut va = parse(a);
    let mut vb = parse(b);
    while va.len() < vb.len() {
        va.push(0);
    }
    while vb.len() < va.len() {
        vb.push(0);
    }
    va < vb
}

pub async fn fetch_changelog(client: &reqwest::Client) -> Result<String, String> {
    let url = format!("{}/downloads/CHANGELOG.md", CDN_BASE);
    let resp = client
        .get(&url)
        .send()
        .await
        .map_err(|e| format!("changelog failed: {e}"))?;
    resp.text()
        .await
        .map_err(|e| format!("changelog read failed: {e}"))
}

pub async fn send_telemetry(
    client: &reqwest::Client,
    action: &str,
    platform: &str,
    version: &str,
    installation_id: &str,
    extra: Value,
) {
    let url = format!("{}/api/launcher/update-report", API_BASE);
    let body = serde_json::json!({
        "action": action,
        "platform": platform,
        "version": version,
        "installation_id": installation_id,
        "status": "ok",
        "details": extra
    });
    let _ = client.post(&url).json(&body).send().await;
}

pub fn platform_key() -> &'static str {
    if cfg!(target_os = "windows") {
        "windows"
    } else if cfg!(target_os = "macos") {
        "macos"
    } else {
        "linux"
    }
}

pub fn pick_game_file(manifest: &Manifest) -> Option<ManifestFile> {
    let plat = platform_key();
    manifest
        .files
        .iter()
        .find(|f| f.platform == plat && f.role == "game")
        .cloned()
}
