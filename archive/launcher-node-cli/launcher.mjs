#!/usr/bin/env node
/**
 * Dark World Launcher — Node.js (publishable MVP)
 */
import { createHash } from 'crypto';
import { spawn, execSync } from 'child_process';
import { createReadStream, existsSync, mkdirSync, readFileSync, rmSync, writeFileSync, readdirSync, statSync, renameSync } from 'fs';
import { join, dirname } from 'path';
import { homedir, platform } from 'os';
import { pipeline } from 'stream/promises';
import { createGunzip } from 'zlib';
import tar from 'tar';
import unzipper from 'unzipper';

const API_BASE = 'https://dark.zorionlabs.net/dw-api';
const CDN_BASE = 'https://dark.zorionlabs.net';

const BASE = platform() === 'win32'
  ? join(process.env.LOCALAPPDATA || homedir(), 'DarkWorld')
  : platform() === 'darwin'
    ? join(homedir(), 'Library', 'Application Support', 'DarkWorld')
    : join(homedir(), '.darkworld');

const GAME_DIR = join(BASE, 'game');
const CACHE_DIR = join(BASE, 'cache');
const VERSION_FILE = join(GAME_DIR, 'version.json');
const INST_ID_FILE = join(BASE, 'installation_id');

function log(msg) { console.log(`[Launcher] ${msg}`); }

function getInstallationId() {
  if (existsSync(INST_ID_FILE)) return readFileSync(INST_ID_FILE, 'utf8').trim();
  mkdirSync(BASE, { recursive: true });
  const id = `DW-${Date.now()}-${Math.random().toString(36).slice(2, 10)}`;
  writeFileSync(INST_ID_FILE, id);
  return id;
}

function readLocalVersion() {
  if (!existsSync(VERSION_FILE)) return '0.0.0';
  try {
    return JSON.parse(readFileSync(VERSION_FILE, 'utf8')).game_version || '0.0.0';
  } catch { return '0.0.0'; }
}

function writeLocalVersion(gameVersion, launcherVersion) {
  mkdirSync(GAME_DIR, { recursive: true });
  writeFileSync(VERSION_FILE, JSON.stringify({
    game_version: gameVersion,
    launcher_version: launcherVersion,
    updated_at: new Date().toISOString(),
  }, null, 2));
}

async function telemetry(action, version, extra = {}) {
  try {
    await fetch(`${API_BASE}/api/launcher/update-report`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        action, platform: platform(), version,
        installation_id: getInstallationId(), status: 'ok', details: extra,
      }),
    });
  } catch {}
}

async function fetchJson(url) {
  const r = await fetch(url);
  if (!r.ok) throw new Error(`HTTP ${r.status} for ${url}`);
  return r.json();
}

function sha256File(path) {
  return new Promise((resolve, reject) => {
    const hash = createHash('sha256');
    const rs = createReadStream(path);
    rs.on('data', d => hash.update(d));
    rs.on('end', () => resolve(hash.digest('hex')));
    rs.on('error', reject);
  });
}

function pickGameFile(manifest) {
  const plat = platform() === 'win32' ? 'windows' : platform() === 'darwin' ? 'macos' : 'linux';
  return manifest.files?.find(f => f.platform === plat && f.role === 'game');
}

async function downloadFile(urlPath, dest) {
  const url = urlPath.startsWith('http') ? urlPath : `${CDN_BASE}${urlPath}`;
  mkdirSync(dirname(dest), { recursive: true });
  const r = await fetch(url);
  if (!r.ok) throw new Error(`Download failed HTTP ${r.status}`);
  const buf = Buffer.from(await r.arrayBuffer());
  writeFileSync(dest, buf);
  log(`Downloaded ${(buf.length / 1024 / 1024).toFixed(1)}MB`);
}

async function extractPackage(file, archivePath) {
  const staging = `${GAME_DIR}.staging`;
  if (existsSync(staging)) rmSync(staging, { recursive: true, force: true });
  mkdirSync(staging, { recursive: true });

  if (file.package_type === 'zip') {
    await pipeline(createReadStream(archivePath), unzipper.Extract({ path: staging }));
  } else if (file.package_type === 'tar.gz') {
    await pipeline(createReadStream(archivePath), createGunzip(), tar.x({ cwd: staging }));
  } else {
    throw new Error(`Unsupported package: ${file.package_type}`);
  }

  if (existsSync(GAME_DIR)) rmSync(GAME_DIR, { recursive: true, force: true });
  mkdirSync(dirname(GAME_DIR), { recursive: true });
  renameSync(staging, GAME_DIR);

  if (platform() === 'darwin') {
    try {
      for (const name of readdirSync(GAME_DIR)) {
        if (name.endsWith('.app')) execSync(`xattr -cr "${join(GAME_DIR, name)}"`, { stdio: 'ignore' });
      }
    } catch {}
  }
}

function findGameExe() {
  if (platform() === 'win32') {
    for (const p of [join(GAME_DIR, 'windows', 'DarkWorld.exe'), join(GAME_DIR, 'DarkWorld.exe')]) {
      if (existsSync(p)) return p;
    }
  }
  if (platform() === 'darwin' && existsSync(GAME_DIR)) {
    for (const name of readdirSync(GAME_DIR)) {
      if (!name.endsWith('.app')) continue;
      const macos = join(GAME_DIR, name, 'Contents', 'MacOS');
      if (!existsSync(macos)) continue;
      for (const bin of readdirSync(macos)) {
        const p = join(macos, bin);
        if (statSync(p).isFile()) return p;
      }
    }
  }
  return null;
}

function launchGame(exe) {
  log(`Launching ${exe}`);
  spawn(exe, [], { detached: true, stdio: 'ignore', cwd: dirname(exe) }).unref();
}

async function run(forceRepair = false) {
  await telemetry('launcher_start', readLocalVersion());
  log('Checking server...');
  const status = await fetchJson(`${API_BASE}/api/launcher/status`);
  if (status.server !== 'online') throw new Error('Server offline');

  log('Fetching manifest...');
  const manifest = await fetchJson(`${CDN_BASE}/downloads/launcher/manifest.json`);
  const local = readLocalVersion();
  const remote = manifest.game_version;
  log(`Local: ${local}  Remote: ${remote}  Players: ${status.players_online ?? 0}`);

  if (forceRepair || local !== remote || !findGameExe()) {
    const gameFile = pickGameFile(manifest);
    if (!gameFile) throw new Error('No game package for this platform');
    await telemetry('update_download_start', local, { remote });
    const cachePath = join(CACHE_DIR, gameFile.path);
    await downloadFile(gameFile.url, cachePath);
    const hash = await sha256File(cachePath);
    if (hash.toLowerCase() !== gameFile.sha256.toLowerCase()) {
      await telemetry('hash_validation_failed', local);
      throw new Error(`SHA256 mismatch`);
    }
    log('Applying update...');
    await extractPackage(gameFile, cachePath);
    writeLocalVersion(remote, manifest.launcher_version || '1.0.0');
    await telemetry('update_applied', remote);
    log(`Updated to v${remote}`);
  } else {
    log('Game up to date.');
    await telemetry('version_checked', local, { remote });
  }

  const exe = findGameExe();
  if (!exe) throw new Error('Game executable not found');
  await telemetry('game_launch', remote);
  launchGame(exe);
}

run(process.argv.includes('--repair')).catch(async e => {
  console.error('[Launcher] ERROR:', e.message);
  await telemetry('version_check_failed', readLocalVersion(), { error: e.message });
  process.exit(1);
});
