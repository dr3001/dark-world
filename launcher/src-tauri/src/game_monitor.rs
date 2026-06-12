use crate::logger;
use crate::paths::{find_game_executable, read_local_version};
use crate::tray;
use crate::{emit_state, AppState, LauncherState};
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
    emit_state(
        app,
        LauncherState {
            can_play,
            local_version: local.clone(),
            message: "Jogo encerrado. Pronto para jogar novamente.".to_string(),
            progress: -1,
            ..Default::default()
        },
    );
    let _ = app.emit("game-exited", ());
    logger::log("Game process exited — launcher restored");
}
