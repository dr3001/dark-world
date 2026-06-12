mod api;
mod game_monitor;
mod logger;
mod paths;
mod settings;
mod tray;
mod updater;

use api::{
    changelog_fallback, changelog_for_player, fetch_changelog, fetch_manifest, fetch_status,
    fetch_version_policy, pick_game_file, send_telemetry, platform_key, version_lt,
};
use paths::{
    find_game_executable, get_installation_id, read_local_version, write_local_version, game_dir,
};
use serde::Serialize;
use std::process::Child;
use std::sync::{atomic::{AtomicBool, Ordering}, Mutex};
use std::time::Duration;
use tauri::{AppHandle, Emitter, Manager, State};
use tokio::time::timeout;
use updater::{apply_package, cache_download_path, download_file, verify_sha256};

const API_TIMEOUT: Duration = Duration::from_secs(25);

async fn timed_api<F, T>(step: &str, fut: F) -> Result<T, String>
where
    F: std::future::Future<Output = Result<T, String>>,
{
    match timeout(API_TIMEOUT, fut).await {
        Ok(r) => r,
        Err(_) => {
            logger::log_step(step, "TIMEOUT");
            Err(format!("{step} timeout after {}s", API_TIMEOUT.as_secs()))
        }
    }
}

fn api_client() -> Result<reqwest::Client, String> {
    reqwest::Client::builder()
        .connect_timeout(Duration::from_secs(12))
        .timeout(Duration::from_secs(30))
        .build()
        .map_err(|e| e.to_string())
}

#[derive(Default)]
pub(crate) struct AppState {
    bootstrapping: AtomicBool,
    game_child: Mutex<Option<Child>>,
    last_state: Mutex<LauncherState>,
}

#[derive(Clone, Serialize)]
pub(crate) struct LauncherState {
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

pub(crate) fn emit_state(app: &AppHandle, state: LauncherState) {
    if let Some(app_state) = app.try_state::<AppState>() {
        if let Ok(mut last) = app_state.last_state.lock() {
            *last = state.clone();
        }
    }
    tray::update_tray_status(app, state.server_online);
    let _ = app.emit("launcher-state", state);
}

pub(crate) async fn run_bootstrap(app: AppHandle, force_repair: bool) -> Result<(), String> {
    logger::log_step("STARTUP", "bootstrap begin");
    let mut state = LauncherState {
        server_online: false,
        players_online: 0,
        local_version: read_local_version(),
        remote_version: "—".to_string(),
        message: "Iniciando...".to_string(),
        can_play: false,
        progress: -1,
        progress_label: String::new(),
        force_update: false,
        update_required: false,
    };
    emit_state(&app, state.clone());

    logger::log_step("LOAD_CONFIG", "paths and installation id");
    state.message = "Carregando configurações...".to_string();
    emit_state(&app, state.clone());

    let client = api_client()?;
    let inst_id = get_installation_id();
    let plat = platform_key();

    // Never block UI on telemetry
    let telem_client = match api_client() {
        Ok(c) => c,
        Err(_) => client.clone(),
    };
    let telem_id = inst_id.clone();
    let telem_ver = read_local_version();
    tauri::async_runtime::spawn(async move {
        send_telemetry(
            &telem_client,
            "launcher_start",
            plat,
            &telem_ver,
            &telem_id,
            serde_json::json!({}),
        )
        .await;
    });

    logger::log_step("CHECK_SERVER", "fetch /api/launcher/status");
    state.message = "Consultando servidor...".to_string();
    emit_state(&app, state.clone());

    let status = match timed_api("CHECK_SERVER", fetch_status(&client)).await {
        Ok(s) => Some(s),
        Err(e) => {
            logger::log_step("CHECK_SERVER", &format!("failed: {e}"));
            None
        }
    };
    let server_online = status.as_ref().map(|s| s.server == "online").unwrap_or(false);
    state.server_online = server_online;
    state.players_online = status.as_ref().map(|s| s.players_online).unwrap_or(0);
    emit_state(&app, state.clone());

    if !server_online {
        state.message = "Não foi possível conectar ao servidor. Tente Reparar.".to_string();
        emit_state(&app, state);
        logger::log_step("CHECK_SERVER", "server offline or unreachable");
        return Err("server offline".to_string());
    }

    logger::log_step("CHECK_VERSION", "fetch version policy");
    state.message = "Conectando API...".to_string();
    emit_state(&app, state.clone());

    let version_policy = timed_api("CHECK_VERSION", fetch_version_policy(&client))
        .await
        .ok();
    if let Some(ref vp) = version_policy {
        if vp.maintenance_mode {
            state.message = vp.message.clone();
            emit_state(&app, state);
            logger::log_step("CHECK_VERSION", "maintenance mode");
            return Err("maintenance mode".to_string());
        }
    }

    logger::log_step("LOAD_MANIFEST", "fetch manifest.json");
    state.message = "Baixando manifest...".to_string();
    emit_state(&app, state.clone());

    let manifest = timed_api("LOAD_MANIFEST", fetch_manifest(&client)).await?;
    logger::log_step("PARSE_MANIFEST", &format!("game={}", manifest.game_version));
    state.remote_version = manifest.game_version.clone();
    state.force_update = manifest.force_update;
    state.message = "Comparando versões...".to_string();
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
        logger::log_step("CHECK_UPDATE", "download required");
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

        logger::log_step("DOWNLOAD_MANIFEST", &game_file.url);
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

        state.message = "Verificando arquivos...".to_string();
        state.progress = 100;
        emit_state(&app, state.clone());

        verify_sha256(&cache_path, &game_file.sha256).map_err(|e| {
            let _ = app.emit(
                "launcher-state",
                LauncherState {
                    message: "Arquivo corrompido. Use Reparar para baixar novamente.".to_string(),
                    ..state.clone()
                },
            );
            logger::log(&format!("SHA256 verify failed: {e}"));
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

    let updated_local = read_local_version();
    state.local_version = updated_local.clone();
    state.update_required =
        manifest.force_update || version_lt(&updated_local, min_version);

    let play_ok = find_game_executable().is_some()
        && server_online
        && !state.update_required
        && updated_local == manifest.game_version;
    state.can_play = play_ok;
    if play_ok {
        state.message = format!("v{} — Pronto para jogar.", updated_local);
    } else if find_game_executable().is_none() {
        state.message = "Jogo não instalado. Clique Reparar.".to_string();
    }
    logger::log_step("ENABLE_PLAY", &format!("can_play={play_ok} local={updated_local}"));
    logger::log(&format!(
        "Bootstrap complete: can_play={play_ok} local={updated_local} remote={}",
        manifest.game_version
    ));
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
        logger::log_step("STARTUP", "bootstrap already running — skip duplicate invoke");
        return Ok(());
    }
    let result = run_bootstrap(app.clone(), false).await;
    state.bootstrapping.store(false, Ordering::SeqCst);
    if let Err(ref e) = result {
        logger::log(&format!("Bootstrap error: {e}"));
        let friendly = match e.as_str() {
            "server offline" => {
                "Não foi possível conectar ao servidor. Clique Reparar para tentar novamente."
                    .to_string()
            }
            "maintenance mode" => "Servidor em manutenção. Aguarde e tente novamente.".to_string(),
            _ if e.contains("timeout") => format!(
                "Tempo esgotado ({e}). Verifique sua internet e clique Reparar."
            ),
            _ if e.contains("Hash") || e.contains("SHA") => {
                "Arquivo corrompido. Use Reparar para baixar novamente.".to_string()
            }
            _ => format!("Falha na verificação: {e}. Use Reparar."),
        };
        let last = app
            .try_state::<AppState>()
            .and_then(|s| s.last_state.lock().ok().map(|g| g.clone()))
            .unwrap_or_default();
        emit_state(
            &app,
            LauncherState {
                message: friendly,
                server_online: last.server_online,
                players_online: last.players_online,
                local_version: read_local_version(),
                remote_version: last.remote_version,
                can_play: false,
                ..Default::default()
            },
        );
    }
    Ok(())
}

#[tauri::command]
async fn repair_game(app: AppHandle) -> Result<(), String> {
    logger::log("Repair requested");
    run_bootstrap(app, true).await
}

#[tauri::command]
async fn fetch_changelog_cmd() -> Result<String, String> {
    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(15))
        .build()
        .map_err(|e| e.to_string())?;
    match fetch_changelog(&client).await {
        Ok(text) => Ok(changelog_for_player(&text)),
        Err(e) => {
            logger::log(&format!("Changelog fetch failed (using fallback): {e}"));
            Ok(changelog_fallback())
        }
    }
}

#[tauri::command]
fn get_settings() -> Result<serde_json::Value, String> {
    Ok(serde_json::json!({
        "Versão instalada": read_local_version(),
        "Instalação": "Este computador",
    }))
}

pub(crate) fn open_game_folder_internal() -> Result<(), String> {
    let dir = game_dir();
    std::fs::create_dir_all(&dir).map_err(|e| e.to_string())?;
    logger::open_path(&dir)
}

#[tauri::command]
fn open_game_folder() -> Result<(), String> {
    open_game_folder_internal()
}

#[tauri::command]
fn open_logs_folder() -> Result<(), String> {
    logger::open_logs_folder()
}

fn spawn_game_process() -> Result<Child, String> {
    let exe = find_game_executable().ok_or("Executável do jogo não encontrado. Use Reparar.")?;
    #[cfg(target_os = "windows")]
    {
        use std::os::windows::process::CommandExt;
        const CREATE_NO_WINDOW: u32 = 0x08000000;
        std::process::Command::new(&exe)
            .current_dir(exe.parent().unwrap_or(game_dir().as_path()))
            .creation_flags(CREATE_NO_WINDOW)
            .stdin(std::process::Stdio::null())
            .stdout(std::process::Stdio::null())
            .stderr(std::process::Stdio::null())
            .spawn()
            .map_err(|e| format!("spawn failed: {e}"))
    }
    #[cfg(target_os = "macos")]
    {
        std::process::Command::new(&exe)
            .stdin(std::process::Stdio::null())
            .stdout(std::process::Stdio::null())
            .stderr(std::process::Stdio::null())
            .spawn()
            .map_err(|e| format!("spawn failed: {e}"))
    }
    #[cfg(not(any(target_os = "windows", target_os = "macos")))]
    {
        std::process::Command::new(&exe)
            .stdin(std::process::Stdio::null())
            .stdout(std::process::Stdio::null())
            .stderr(std::process::Stdio::null())
            .spawn()
            .map_err(|e| format!("spawn failed: {e}"))
    }
}

#[tauri::command]
fn launch_game(app: AppHandle, state: State<'_, AppState>) -> Result<(), String> {
    tray::hide_launcher_on_play(&app);
    let child = match spawn_game_process() {
        Ok(c) => c,
        Err(e) => {
            tray::show_launcher_window(&app);
            return Err(format!("Não foi possível abrir o jogo. Use Reparar. ({e})"));
        }
    };
    logger::log("Game launched");
    if let Ok(mut guard) = state.game_child.lock() {
        *guard = Some(child);
    }
    tray::set_game_running(&app, true);
    game_monitor::start_game_monitor(app);
    Ok(())
}

pub(crate) fn kill_game_process(state: &AppState) -> Result<(), String> {
    let mut guard = state.game_child.lock().map_err(|e| e.to_string())?;
    if let Some(mut child) = guard.take() {
        let _ = child.kill();
        logger::log("Game process killed");
    }
    Ok(())
}

#[tauri::command]
fn kill_game(app: AppHandle, state: State<'_, AppState>) -> Result<(), String> {
    kill_game_process(&state)?;
    game_monitor::on_game_exited(&app);
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
    logger::init();
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .manage(AppState::default())
        .manage(tray::TrayState::default())
        .setup(|app| {
            if let Some(win) = app.get_webview_window("main") {
                tray::setup_window_close_to_tray(&win);
            }
            tray::setup_tray(app.handle())?;
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            bootstrap,
            repair_game,
            fetch_changelog_cmd,
            launch_game,
            kill_game,
            get_settings,
            open_game_folder,
            open_logs_folder
        ])
        .run(tauri::generate_context!())
        .expect("error running tauri application");
}
