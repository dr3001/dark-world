#!/usr/bin/env node
// Dark World Super Launcher v1.0.0
// Checks manifest, downloads updates, validates SHA256, launches game

const https = require("https");
const http = require("http");
const fs = require("fs");
const path = require("path");
const crypto = require("crypto");
const { execSync, spawn } = require("child_process");
const os = require("os");

const API_HOST = "5.78.142.138";
const API_PORT = 9000;
const API_BASE = `http://${API_HOST}:${API_PORT}`;
const MANIFEST_URL = `https://dark.zorionlabs.net/downloads/launcher/manifest.json`;

const GAME_DIR = path.join(os.homedir(), ".darkworld", "game");
const LOG_DIR = path.join(os.homedir(), ".darkworld", "logs");
const CACHE_DIR = path.join(os.homedir(), ".darkworld", "cache");
const VERSION_FILE = path.join(GAME_DIR, "version.json");

const PLATFORM = process.platform === "win32" ? "windows" : "macos";
const LOCAL_VERSION = "5.0.1";

function log(msg) {
  const ts = new Date().toISOString();
  const line = `[${ts}] ${msg}`;
  console.log(line);
  fs.mkdirSync(LOG_DIR, { recursive: true });
  fs.appendFileSync(path.join(LOG_DIR, "launcher.log"), line + "\n");
}

function fetchJSON(url) {
  return new Promise((resolve, reject) => {
    const client = url.startsWith("https") ? https : http;
    client.get(url, (res) => {
      let data = "";
      res.on("data", (c) => (data += c));
      res.on("end", () => {
        try { resolve(JSON.parse(data)); } catch (e) { reject(e); }
      });
    }).on("error", reject);
  });
}

function downloadFile(url, dest) {
  return new Promise((resolve, reject) => {
    const client = url.startsWith("https") ? https : http;
    const file = fs.createWriteStream(dest);
    client.get(url, (res) => {
      if (res.statusCode >= 400) { reject(new Error(`HTTP ${res.statusCode}`)); return; }
      let downloaded = 0;
      const total = parseInt(res.headers["content-length"] || "0");
      res.on("data", (c) => { downloaded += c.length; file.write(c); });
      res.on("end", () => { file.end(); resolve({ size: downloaded }); });
    }).on("error", reject);
  });
}

function sha256File(filePath) {
  return crypto.createHash("sha256").update(fs.readFileSync(filePath)).digest("hex");
}

function launchGame() {
  const exe = PLATFORM === "windows"
    ? path.join(GAME_DIR, "DarkWorld.exe")
    : path.join(GAME_DIR, "DarkWorld.app", "Contents", "MacOS", "Dark World");
  if (!fs.existsSync(exe)) { log("ERROR: Game not found at " + exe); return; }
  log("Launching: " + exe);
  if (PLATFORM === "macos") {
    spawn("open", [path.join(GAME_DIR, "DarkWorld.app")], { detached: true, stdio: "ignore" }).unref();
  } else {
    spawn(exe, [], { detached: true, stdio: "ignore" }).unref();
  }
  log("Game launched");
}

function localVersion() {
  try {
    return JSON.parse(fs.readFileSync(VERSION_FILE, "utf8")).game_version || "0";
  } catch { return "0"; }
}

async function main() {
  console.log("============================================");
  console.log("  DARK WORLD LAUNCHER v1.0.0");
  console.log("============================================");
  
  fs.mkdirSync(GAME_DIR, { recursive: true });
  fs.mkdirSync(CACHE_DIR, { recursive: true });
  
  // 1. Server status
  log("[1/4] Checking server status...");
  try {
    const health = await fetchJSON(API_BASE + "/health");
    console.log("  Server: " + health.version + " — " + health.modules.length + " modules");
  } catch (e) {
    log("WARN: Cannot reach server. Offline mode.");
  }
  
  // 2. Manifest check
  log("[2/4] Checking for updates...");
  let manifest;
  try {
    manifest = await fetchJSON(MANIFEST_URL);
  } catch (e) {
    log("WARN: Cannot fetch manifest. Using local version.");
    launchGame();
    return;
  }
  
  const remoteVer = manifest.game_version || "0";
  const localVer = localVersion();
  console.log(`  Local: v${localVer}  Remote: v${remoteVer}`);
  
  if (remoteVer === localVer) {
    console.log("  Game is up to date.");
    log("[3/4] Skipping update.");
  } else {
    log("[3/4] Downloading update...");
    const file = manifest.files.find(f => f.platform === PLATFORM && f.required);
    if (!file) { log("ERROR: No download for platform " + PLATFORM); return; }
    
    const url = "https://dark.zorionlabs.net" + file.url;
    const dest = path.join(CACHE_DIR, file.path);
    console.log(`  Downloading: ${file.url} (${(file.size / 1024 / 1024).toFixed(0)}MB)`);
    await downloadFile(url, dest);
    
    log("[4/4] Verifying SHA256...");
    const hash = sha256File(dest);
    if (hash !== file.sha256) {
      log(`ERROR: SHA256 mismatch! Expected ${file.sha256.substring(0,16)} Got ${hash.substring(0,16)}`);
      fs.unlinkSync(dest);
      return;
    }
    console.log("  SHA256 verified.");
    
    // Extract if tgz
    if (file.path.endsWith(".tar.gz")) {
      console.log("  Extracting...");
      execSync(`tar xzf "${dest}" -C "${GAME_DIR}"`, { stdio: "pipe" });
    } else {
      fs.copyFileSync(dest, path.join(GAME_DIR, file.path));
    }
    
    fs.writeFileSync(VERSION_FILE, JSON.stringify({ game_version: remoteVer, platform: PLATFORM, updated_at: new Date().toISOString() }));
    console.log("  Update complete.");
  }
  
  launchGame();
}

main().catch((e) => { log("FATAL: " + e.message); process.exit(1); });
