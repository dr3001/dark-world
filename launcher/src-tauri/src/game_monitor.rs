use crate::logger;
use crate::paths::{find_game_executable, read_local_version};
use crate::tray;
use crate::{emit_state, AppState};
use tauri::{AppHandle, Emitter, Manager};

/// Poll game child process; when it exits, restore launcher window and notify UI.
pub fn start_game_monitor(app: AppHandle) {
    std::thread::spawn(move || {
        loop {
            std::thread::sleep(std::time::Duration::from_millis(500));
            let exited = {
                let state = match app.try_state::<AppState>() {
                    Some(s) => s,
                    None => return,
                };
                let mut guard = match state.game_child.lock() {
                    Ok(g) => g,
                    Err(_) => return,
                };
                let Some(ref mut child) = *guard else {
                    return;
                };
                match child.try_wait() {
                    Ok(Some(_status)) => {
                        *guard = None;
                        true
                    }
                    Ok(None) => false,
                    Err(e) => {
                        logger::log(&format!("Game monitor try_wait error: {e}"));
                        *guard = None;
                        true
                    }
                }
            };
            if exited {
                on_game_exited(&app);
                return;
            }
        }
    });
}

pub fn on_game_exited(app: &AppHandle) {
    tray::set_game_running(app, false);
    tray::show_launcher_window(app);
    let local = read_local_version();
    let can_play = find_game_executable().is_some();
    let mut state = app
        .try_state::<AppState>()
        .and_then(|s| s.last_state.lock().ok().map(|g| g.clone()))
        .unwrap_or_default();
    state.can_play = can_play && state.server_online && !state.update_required;
    state.local_version = local;
    state.message = "Jogo encerrado. Pronto para jogar novamente.".to_string();
    state.progress = -1;
    emit_state(app, state);
    let _ = app.emit("game-exited", ());
    logger::log("Game process exited — launcher restored");
}
