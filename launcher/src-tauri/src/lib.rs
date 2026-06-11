mod api;
mod paths;
mod updater;

use api::{
    fetch_changelog, fetch_manifest, fetch_status, fetch_version_policy, pick_game_file,
    send_telemetry, platform_key, version_lt,
};
use paths::{
    find_game_executable, get_installation_id, read_local_version, write_local_version, game_dir,
};
use serde::Serialize;
use std::sync::atomic::{AtomicBool, Ordering};
use tauri::{AppHandle, Emitter, State};
use updater::{apply_package, cache_download_path, download_file, verify_sha256};

#[derive(Default)]
struct AppState {
    bootstrapping: AtomicBool,
}

#[derive(Clone, Serialize)]
struct LauncherState {
    server_online: bool,
    players_online: i64,
    local_version: String,
    remote_version: String,
    message: String,
    can_play: bool,
    progress: i32,
    progress_label: String,
    force_update: bool,
    update_required: bool,
}

fn emit_state(app: &AppHandle, state: LauncherState) {
    let _ = app.emit("launcher-state", state);
}

async fn run_bootstrap(app: AppHandle, force_repair: bool) -> Result<(), String> {
    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(120))
        .build()
        .map_err(|e| e.to_string())?;

    let inst_id = get_installation_id();
    let plat = platform_key();
    send_telemetry(
        &client,
        "launcher_start",
        plat,
        &read_local_version(),
        &inst_id,
        serde_json::json!({}),
    )
    .await;

    let mut state = LauncherState {
        server_online: false,
        players_online: 0,
        local_version: read_local_version(),
        remote_version: "—".to_string(),
        message: "Verificando servidor...".to_string(),
        can_play: false,
        progress: -1,
        progress_label: String::new(),
        force_update: false,
        update_required: false,
    };
    emit_state(&app, state.clone());

    let status = fetch_status(&client).await;
    let server_online = status.as_ref().map(|s| s.server == "online").unwrap_or(false);
    state.server_online = server_online;
    state.players_online = status.as_ref().map(|s| s.players_online).unwrap_or(0);
    if !server_online {
        state.message = "Servidor offline ou indisponível.".to_string();
        emit_state(&app, state);
        send_telemetry(
            &client,
            "server_offline",
            plat,
            &read_local_version(),
            &inst_id,
            serde_json::json!({}),
        )
        .await;
        return Err("server offline".to_string());
    }

    state.message = "Consultando manifest...".to_string();
    emit_state(&app, state.clone());

    let version_policy = fetch_version_policy(&client).await.ok();
    if let Some(ref vp) = version_policy {
        if vp.maintenance_mode {
            state.message = vp.message.clone();
            emit_state(&app, state);
            return Err("maintenance mode".to_string());
        }
    }

    let manifest = fetch_manifest(&client).await?;
    state.remote_version = manifest.game_version.clone();
    state.force_update = manifest.force_update;
    emit_state(&app, state.clone());

    let local = read_local_version();
    let min_version = version_policy
        .as_ref()
        .map(|v| v.minimum_client_version.as_str())
        .unwrap_or(manifest.game_version.as_str());
    let below_minimum = version_lt(&local, min_version);
    state.update_required = manifest.force_update || below_minimum;
    if state.update_required && !force_repair {
        state.message = format!(
            "Atualização obrigatória: v{} → v{}",
            local, manifest.game_version
        );
        state.can_play = false;
        emit_state(&app, state.clone());
    }

    let needs_update = force_repair
        || local != manifest.game_version
        || find_game_executable().is_none()
        || below_minimum
        || (manifest.force_update && local != manifest.game_version);

    if needs_update {
        let game_file = pick_game_file(&manifest).ok_or("Nenhum pacote de jogo para esta plataforma")?;
        state.message = format!("Baixando v{}...", manifest.game_version);
        state.progress = 0;
        state.progress_label = "0%".to_string();
        emit_state(&app, state.clone());

        send_telemetry(
            &client,
            "update_download_start",
            plat,
            &local,
            &inst_id,
            serde_json::json!({"remote": manifest.game_version}),
        )
        .await;

        let cache_path = cache_download_path(&game_file.path);
        let app_emit = app.clone();
        let base_state = state.clone();
        download_file(&game_file.url, &cache_path, move |done, total| {
            let pct = if total > 0 {
                ((done as f64 / total as f64) * 100.0) as i32
            } else {
                0
            };
            let mut s = base_state.clone();
            s.progress = pct;
            s.progress_label = format!("{}%", pct);
            s.message = format!("Baixando... {}%", pct);
            emit_state(&app_emit, s);
        })
        .await?;

        state.message = "Validando SHA256...".to_string();
        state.progress = 100;
        emit_state(&app, state.clone());

        verify_sha256(&cache_path, &game_file.sha256).map_err(|e| {
            let _ = app.emit(
                "launcher-state",
                LauncherState {
                    message: format!("Hash inválido: {e}"),
                    ..state.clone()
                },
            );
            e
        })?;

        state.message = "Aplicando atualização...".to_string();
        emit_state(&app, state.clone());

        apply_package(&game_file, &cache_path)?;
        write_local_version(&manifest.game_version, &manifest.launcher_version);

        send_telemetry(
            &client,
            "update_applied",
            plat,
            &manifest.game_version,
            &inst_id,
            serde_json::json!({}),
        )
        .await;

        state.local_version = manifest.game_version.clone();
        state.message = format!("v{} instalado.", manifest.game_version);
        state.progress = -1;
    } else {
        state.message = format!("v{} — Pronto.", local);
    }

    let play_ok = find_game_executable().is_some()
        && server_online
        && !state.update_required
        && read_local_version() == manifest.game_version;
    state.can_play = play_ok;
    emit_state(&app, state);
    Ok(())
}

#[tauri::command]
async fn bootstrap(app: AppHandle, state: State<'_, AppState>) -> Result<(), String> {
    if state
        .bootstrapping
        .compare_exchange(false, true, Ordering::SeqCst, Ordering::SeqCst)
        .is_err()
    {
        return Ok(());
    }
    let result = run_bootstrap(app.clone(), false).await;
    state.bootstrapping.store(false, Ordering::SeqCst);
    if let Err(ref e) = result {
        emit_state(
            &app,
            LauncherState {
                message: format!("Erro: {e}"),
                can_play: find_game_executable().is_some(),
                local_version: read_local_version(),
                ..Default::default()
            },
        );
    }
    Ok(())
}

#[tauri::command]
async fn repair_game(app: AppHandle) -> Result<(), String> {
    run_bootstrap(app, true).await
}

#[tauri::command]
async fn fetch_changelog_cmd() -> Result<String, String> {
    let client = reqwest::Client::new();
    fetch_changelog(&client).await
}

#[tauri::command]
fn get_settings() -> Result<serde_json::Value, String> {
    Ok(serde_json::json!({
        "game_dir": paths::game_dir().to_string_lossy(),
        "installation_id": get_installation_id(),
        "local_version": read_local_version(),
        "api_base": paths::API_BASE,
        "cdn_base": paths::CDN_BASE,
    }))
}

#[tauri::command]
fn open_game_folder() -> Result<(), String> {
    let dir = game_dir();
    std::fs::create_dir_all(&dir).map_err(|e| e.to_string())?;
    #[cfg(target_os = "windows")]
    {
        std::process::Command::new("explorer")
            .arg(dir)
            .spawn()
            .map_err(|e| e.to_string())?;
    }
    #[cfg(target_os = "macos")]
    {
        std::process::Command::new("open")
            .arg(dir)
            .spawn()
            .map_err(|e| e.to_string())?;
    }
    #[cfg(not(any(target_os = "windows", target_os = "macos")))]
    {
        std::process::Command::new("xdg-open")
            .arg(dir)
            .spawn()
            .map_err(|e| e.to_string())?;
    }
    Ok(())
}

#[tauri::command]
fn launch_game() -> Result<(), String> {
    let exe = find_game_executable().ok_or("Executável do jogo não encontrado. Use Reparar.")?;
    #[cfg(target_os = "windows")]
    {
        std::process::Command::new(&exe)
            .current_dir(exe.parent().unwrap_or(game_dir().as_path()))
            .spawn()
            .map_err(|e| format!("spawn failed: {e}"))?;
    }
    #[cfg(target_os = "macos")]
    {
        std::process::Command::new(&exe)
            .spawn()
            .map_err(|e| format!("spawn failed: {e}"))?;
    }
    #[cfg(not(any(target_os = "windows", target_os = "macos")))]
    {
        std::process::Command::new(&exe)
            .spawn()
            .map_err(|e| format!("spawn failed: {e}"))?;
    }
    Ok(())
}

impl Default for LauncherState {
    fn default() -> Self {
        Self {
            server_online: false,
            players_online: 0,
            local_version: "0.0.0".to_string(),
            remote_version: "—".to_string(),
            message: String::new(),
            can_play: false,
            progress: -1,
            progress_label: String::new(),
            force_update: false,
            update_required: false,
        }
    }
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .manage(AppState::default())
        .invoke_handler(tauri::generate_handler![
            bootstrap,
            repair_game,
            fetch_changelog_cmd,
            launch_game,
            get_settings,
            open_game_folder
        ])
        .run(tauri::generate_context!())
        .expect("error running tauri application");
}
