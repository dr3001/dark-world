use std::fs::{self, OpenOptions};
use std::io::Write;
use std::path::PathBuf;
use std::sync::Mutex;

static LOG_MUTEX: Mutex<()> = Mutex::new(());

const MAX_LOG_BYTES: u64 = 5 * 1024 * 1024;

pub fn logs_dir() -> PathBuf {
    let base = if cfg!(target_os = "windows") {
        dirs::data_local_dir().unwrap_or_else(|| PathBuf::from("."))
    } else {
        dirs::data_dir().unwrap_or_else(|| PathBuf::from("."))
    };
    base.join("DarkWorld").join("logs").join("launcher")
}

fn log_file_path() -> PathBuf {
    logs_dir().join("launcher.log")
}

fn rotate_if_needed(path: &PathBuf) {
    if let Ok(meta) = fs::metadata(path) {
        if meta.len() >= MAX_LOG_BYTES {
            let rotated = logs_dir().join(format!(
                "launcher.{}.log.gz",
                std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)
                    .map(|d| d.as_secs())
                    .unwrap_or(0)
            ));
            if let Ok(data) = fs::read(path) {
                if let Ok(file) = fs::File::create(&rotated) {
                    let mut enc =
                        flate2::write::GzEncoder::new(file, flate2::Compression::default());
                    let _ = enc.write_all(&data);
                    let _ = enc.finish();
                }
            }
            let _ = fs::remove_file(path);
        }
    }
}

pub fn init() {
    let _ = fs::create_dir_all(logs_dir());
    log("Launcher logging initialized");
}

pub fn log(message: &str) {
    let _guard = LOG_MUTEX.lock().ok();
    let path = log_file_path();
    let _ = fs::create_dir_all(logs_dir());
    rotate_if_needed(&path);
    if let Ok(mut f) = OpenOptions::new()
        .create(true)
        .append(true)
        .open(&path)
    {
        let ts = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map(|d| d.as_secs())
            .unwrap_or(0);
        let _ = writeln!(f, "[{ts}] {message}");
    }
}

pub fn open_logs_folder() -> Result<(), String> {
    let dir = logs_dir();
    fs::create_dir_all(&dir).map_err(|e| e.to_string())?;
    open_path(&dir)
}

pub fn open_path(path: &std::path::Path) -> Result<(), String> {
    #[cfg(target_os = "windows")]
    {
        std::process::Command::new("explorer")
            .arg(path)
            .spawn()
            .map_err(|e| e.to_string())?;
    }
    #[cfg(target_os = "macos")]
    {
        std::process::Command::new("open")
            .arg(path)
            .spawn()
            .map_err(|e| e.to_string())?;
    }
    #[cfg(not(any(target_os = "windows", target_os = "macos")))]
    {
        std::process::Command::new("xdg-open")
            .arg(path)
            .spawn()
            .map_err(|e| e.to_string())?;
    }
    Ok(())
}
