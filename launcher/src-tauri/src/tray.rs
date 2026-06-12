use crate::logger;
use crate::paths::{read_local_version};
use crate::settings::OnPlayBehavior;
use std::sync::Mutex;
use tauri::{
    menu::{Menu, MenuItem},
    tray::TrayIconBuilder,
    AppHandle, Manager, WebviewWindow,
};

pub struct TrayState {
    pub server_online: Mutex<bool>,
    pub game_running: Mutex<bool>,
}

impl Default for TrayState {
    fn default() -> Self {
        Self {
            server_online: Mutex::new(false),
            game_running: Mutex::new(false),
        }
    }
}

pub fn update_tray_status(app: &AppHandle, online: bool) {
    if let Some(state) = app.try_state::<TrayState>() {
        if let Ok(mut s) = state.server_online.lock() {
            *s = online;
        }
    }
    refresh_tooltip(app);
}

pub fn set_game_running(app: &AppHandle, running: bool) {
    if let Some(state) = app.try_state::<TrayState>() {
        if let Ok(mut s) = state.game_running.lock() {
            *s = running;
        }
    }
    refresh_tooltip(app);
}

fn refresh_tooltip(app: &AppHandle) {
    let online = app
        .try_state::<TrayState>()
        .and_then(|s| s.server_online.lock().ok().map(|v| *v))
        .unwrap_or(false);
    let version = read_local_version();
    let status = if online { "Online" } else { "Offline" };
    let tooltip = format!("Dark World Launcher — {status} — v{version}");
    if let Some(tray) = app.tray_by_id("main-tray") {
        let _ = tray.set_tooltip(Some(tooltip));
    }
}

pub fn show_launcher_window(app: &AppHandle) {
    if let Some(win) = app.get_webview_window("main") {
        let _ = win.unminimize();
        let _ = win.show();
        let _ = win.set_focus();
    }
}

pub fn hide_launcher_on_play(app: &AppHandle, behavior: &OnPlayBehavior) {
    let Some(win) = app.get_webview_window("main") else {
        return;
    };
    match behavior {
        OnPlayBehavior::MinimizeToTray => {
            let _ = win.minimize();
            let _ = win.hide();
        }
        OnPlayBehavior::Hide => {
            let _ = win.hide();
        }
        OnPlayBehavior::Close => {
            let _ = win.close();
        }
    }
}

pub fn setup_tray(app: &AppHandle) -> Result<(), Box<dyn std::error::Error>> {
    let open_i = MenuItem::with_id(app, "open_launcher", "Abrir launcher", true, None::<&str>)?;
    let repair_i = MenuItem::with_id(app, "repair", "Reparar jogo", true, None::<&str>)?;
    let logs_i = MenuItem::with_id(app, "view_logs", "Ver logs", true, None::<&str>)?;
    let folder_i = MenuItem::with_id(app, "open_folder", "Abrir pasta do jogo", true, None::<&str>)?;
    let kill_i = MenuItem::with_id(app, "kill_game", "Fechar jogo", true, None::<&str>)?;
    let quit_i = MenuItem::with_id(app, "quit_launcher", "Sair do launcher", true, None::<&str>)?;

    let menu = Menu::with_items(
        app,
        &[&open_i, &repair_i, &logs_i, &folder_i, &kill_i, &quit_i],
    )?;

    let icon = app
        .default_window_icon()
        .cloned()
        .ok_or("missing default icon")?;

    TrayIconBuilder::with_id("main-tray")
        .icon(icon)
        .menu(&menu)
        .tooltip("Dark World Launcher")
        .on_menu_event(|app, event| {
            match event.id.as_ref() {
                "open_launcher" => show_launcher_window(app),
                "repair" => {
                    let handle = app.clone();
                    tauri::async_runtime::spawn(async move {
                        let _ = crate::run_bootstrap(handle, true).await;
                    });
                }
                "view_logs" => {
                    let _ = logger::open_logs_folder();
                }
                "open_folder" => {
                    let _ = crate::open_game_folder_internal();
                }
                "kill_game" => {
                    if let Some(state) = app.try_state::<crate::AppState>() {
                        let _ = crate::kill_game_process(&state);
                        set_game_running(app, false);
                    }
                }
                "quit_launcher" => {
                    app.exit(0);
                }
                _ => {}
            }
        })
        .build(app)?;

    refresh_tooltip(app);
    Ok(())
}

pub fn setup_window_close_to_tray(window: &WebviewWindow) {
    let win = window.clone();
    window.on_window_event(move |event| {
        if let tauri::WindowEvent::CloseRequested { api, .. } = event {
            api.prevent_close();
            let _ = win.hide();
            logger::log("Launcher minimized to tray on close");
        }
    });
}
