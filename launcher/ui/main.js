const { invoke } = window.__TAURI__.core;
const { listen } = window.__TAURI__.event;

const els = {
  serverStatus: document.getElementById("serverStatus"),
  playersOnline: document.getElementById("playersOnline"),
  localVersion: document.getElementById("localVersion"),
  remoteVersion: document.getElementById("remoteVersion"),
  message: document.getElementById("message"),
  progressWrap: document.getElementById("progressWrap"),
  progressFill: document.getElementById("progressFill"),
  progressText: document.getElementById("progressText"),
  changelog: document.getElementById("changelog"),
  playBtn: document.getElementById("playBtn"),
  repairBtn: document.getElementById("repairBtn"),
  settingsBtn: document.getElementById("settingsBtn"),
  settingsDialog: document.getElementById("settingsDialog"),
  settingsList: document.getElementById("settingsList"),
  openFolderBtn: document.getElementById("openFolderBtn"),
  closeSettingsBtn: document.getElementById("closeSettingsBtn"),
};

function setProgress(pct, text) {
  els.progressWrap.hidden = false;
  els.progressFill.style.width = `${pct}%`;
  els.progressText.textContent = text || `${pct}%`;
}

function applyState(s) {
  els.serverStatus.textContent = s.server_online ? "ONLINE" : "OFFLINE";
  els.serverStatus.style.color = s.server_online ? "#88cc88" : "#f44";
  els.playersOnline.textContent = String(s.players_online ?? 0);
  els.localVersion.textContent = s.local_version || "—";
  els.remoteVersion.textContent = s.remote_version || "—";
  els.message.textContent = s.message || "";
  els.message.classList.toggle("update-required", Boolean(s.update_required));
  els.playBtn.disabled = !s.can_play;
  if (s.progress >= 0) setProgress(s.progress, s.progress_label);
  else els.progressWrap.hidden = true;
}

listen("launcher-state", (e) => applyState(e.payload));

els.playBtn.addEventListener("click", async () => {
  els.playBtn.disabled = true;
  els.message.textContent = "Abrindo jogo...";
  try {
    await invoke("launch_game");
    els.message.textContent = "Jogo em execução. Launcher na bandeja.";
  } catch (err) {
    els.message.textContent = "Erro ao abrir jogo: " + err;
    els.playBtn.disabled = false;
  }
});

els.repairBtn.addEventListener("click", async () => {
  els.repairBtn.disabled = true;
  els.playBtn.disabled = true;
  try {
    await invoke("repair_game");
  } catch (err) {
    els.message.textContent = "Reparo falhou: " + err;
  }
  els.repairBtn.disabled = false;
});

els.settingsBtn.addEventListener("click", async () => {
  try {
    const s = await invoke("get_settings");
    els.settingsList.innerHTML = Object.entries(s)
      .map(([k, v]) => `<dt>${k}</dt><dd>${v}</dd>`)
      .join("");
    els.settingsDialog.showModal();
  } catch (err) {
    els.message.textContent = "Configurações indisponíveis: " + err;
  }
});

els.openFolderBtn.addEventListener("click", async () => {
  try {
    await invoke("open_game_folder");
  } catch (err) {
    els.message.textContent = "Erro ao abrir pasta: " + err;
  }
});

els.closeSettingsBtn.addEventListener("click", () => els.settingsDialog.close());

(async () => {
  try {
    const cl = await invoke("fetch_changelog");
    els.changelog.textContent = cl || "Sem changelog.";
  } catch {
    els.changelog.textContent = "Changelog indisponível.";
  }
  try {
    await invoke("bootstrap");
  } catch (err) {
    els.message.textContent = "Erro: " + err;
  }
})();
