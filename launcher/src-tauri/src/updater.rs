use crate::api::ManifestFile;
use crate::paths::CDN_BASE;
use crate::paths::game_dir;
use sha2::{Digest, Sha256};
use std::fs::File;
use std::io::{copy, Read, Write};
use std::path::{Path, PathBuf};

pub async fn download_file(
    url_path: &str,
    dest: &Path,
    on_progress: impl Fn(u64, u64) + Send + Sync,
) -> Result<(), String> {
    let url = if url_path.starts_with("http") {
        url_path.to_string()
    } else {
        format!("{}{}", CDN_BASE, url_path)
    };
    let client = reqwest::Client::new();
    let resp = client
        .get(&url)
        .send()
        .await
        .map_err(|e| format!("download failed: {e}"))?;
    if !resp.status().is_success() {
        return Err(format!("download HTTP {}", resp.status()));
    }
    let total = resp.content_length().unwrap_or(0);
    let mut stream = resp.bytes_stream();
    use futures_util::StreamExt;
    if let Some(parent) = dest.parent() {
        std::fs::create_dir_all(parent).map_err(|e| e.to_string())?;
    }
    let mut file = File::create(dest).map_err(|e| e.to_string())?;
    let mut downloaded: u64 = 0;
    while let Some(chunk) = stream.next().await {
        let chunk = chunk.map_err(|e| format!("stream error: {e}"))?;
        file.write_all(&chunk).map_err(|e| e.to_string())?;
        downloaded += chunk.len() as u64;
        on_progress(downloaded, total);
    }
    Ok(())
}

pub fn verify_sha256(path: &Path, expected: &str) -> Result<(), String> {
    let mut file = File::open(path).map_err(|e| e.to_string())?;
    let mut hasher = Sha256::new();
    let mut buf = [0u8; 1024 * 1024];
    loop {
        let n = file.read(&mut buf).map_err(|e| e.to_string())?;
        if n == 0 {
            break;
        }
        hasher.update(&buf[..n]);
    }
    let actual = hex::encode(hasher.finalize());
    if actual.to_lowercase() != expected.to_lowercase() {
        return Err(format!(
            "SHA256 mismatch: expected {} got {}",
            &expected[..16.min(expected.len())],
            &actual[..16]
        ));
    }
    Ok(())
}

pub fn apply_package(file: &ManifestFile, archive_path: &Path) -> Result<(), String> {
    let staging = game_dir().with_extension("staging");
    if staging.exists() {
        std::fs::remove_dir_all(&staging).map_err(|e| e.to_string())?;
    }
    std::fs::create_dir_all(&staging).map_err(|e| e.to_string())?;

    match file.package_type.as_str() {
        "zip" => extract_zip(archive_path, &staging)?,
        "tar.gz" | "tgz" => extract_tar_gz(archive_path, &staging)?,
        other => return Err(format!("unsupported package type: {other}")),
    }

    let game = game_dir();
    if game.exists() {
        let backup = game.with_extension("backup");
        let _ = std::fs::remove_dir_all(&backup);
        std::fs::rename(&game, &backup).map_err(|e| e.to_string())?;
    }
    if let Some(parent) = game.parent() {
        std::fs::create_dir_all(parent).map_err(|e| e.to_string())?;
    }
    std::fs::rename(&staging, &game).map_err(|e| e.to_string())?;

    #[cfg(target_os = "macos")]
    clear_xattr(&game)?;

    Ok(())
}

fn extract_zip(archive: &Path, dest: &Path) -> Result<(), String> {
    let file = File::open(archive).map_err(|e| e.to_string())?;
    let mut archive = zip::ZipArchive::new(file).map_err(|e| e.to_string())?;
    for i in 0..archive.len() {
        let mut f = archive.by_index(i).map_err(|e| e.to_string())?;
        let Some(name) = f.enclosed_name() else { continue };
        let outpath = dest.join(name);
        if f.name().ends_with('/') {
            std::fs::create_dir_all(&outpath).map_err(|e| e.to_string())?;
        } else {
            if let Some(p) = outpath.parent() {
                std::fs::create_dir_all(p).map_err(|e| e.to_string())?;
            }
            let mut outfile = File::create(&outpath).map_err(|e| e.to_string())?;
            copy(&mut f, &mut outfile).map_err(|e| e.to_string())?;
        }
    }
    Ok(())
}

fn extract_tar_gz(archive: &Path, dest: &Path) -> Result<(), String> {
    let file = File::open(archive).map_err(|e| e.to_string())?;
    let dec = flate2::read::GzDecoder::new(file);
    let mut tar = tar::Archive::new(dec);
    tar.unpack(dest).map_err(|e| e.to_string())?;
    Ok(())
}

#[cfg(target_os = "macos")]
fn clear_xattr(dir: &Path) -> Result<(), String> {
    use std::process::Command;
    let status = Command::new("xattr")
        .args(["-cr", dir.to_str().unwrap_or("")])
        .status()
        .map_err(|e| e.to_string())?;
    if !status.success() {
        return Err("xattr -cr failed".to_string());
    }
    Ok(())
}

pub fn cache_download_path(name: &str) -> PathBuf {
    game_dir()
        .parent()
        .unwrap_or(Path::new("."))
        .join("cache")
        .join(name)
}
