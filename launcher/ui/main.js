const els = {
  serverStatus: document.getElementById("serverStatus"),
  playersOnline: document.getElementById("playersOnline"),
  gameVersion: document.getElementById("gameVersion"),
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
  closeSettingsBtn: document.getElementById("closeSettingsBtn"),
};

function setProgress(pct, text) {
  els.progressWrap.hidden = false;
  els.progressFill.style.width = `${pct}%`;
  els.progressText.textContent = text || `${pct}%`;
}

function applyState(s) {
  if (!s) return;
  els.serverStatus.textContent = s.server_online ? "Online" : "Offline";
  els.serverStatus.classList.toggle("online", Boolean(s.server_online));
  els.serverStatus.classList.toggle("offline", !s.server_online);
  const players = s.players_online ?? 0;
  els.playersOnline.textContent =
    players === 1 ? "1 jogador" : `${players} jogadores`;
  els.gameVersion.textContent = s.local_version || "—";
  els.message.textContent = s.message || "";
  els.message.classList.toggle("update-required", Boolean(s.update_required));
  els.playBtn.disabled = !s.can_play;
  if (s.progress >= 0) setProgress(s.progress, s.progress_label);
  else els.progressWrap.hidden = true;
}

async function waitForTauri(maxMs = 10000) {
  const start = Date.now();
  while (!window.__TAURI__?.core?.invoke) {
    if (Date.now() - start > maxMs) {
      throw new Error("Runtime Tauri indisponível");
    }
    await new Promise((r) => setTimeout(r, 50));
  }
  return window.__TAURI__;
}

async function main() {
  try {
    const tauri = await waitForTauri();
    const { invoke } = tauri.core;
    const { listen } = tauri.event;

    await listen("launcher-state", (e) => applyState(e.payload));
    await listen("game-exited", () => {
      els.message.textContent = "Jogo encerrado. Pronto para jogar novamente.";
      els.playBtn.disabled = false;
    });

    els.playBtn.addEventListener("click", async () => {
      els.playBtn.disabled = true;
      els.message.textContent = "Abrindo jogo...";
      try {
        await invoke("launch_game");
        els.message.textContent = "Jogo em execução. Launcher na bandeja.";
      } catch (err) {
        els.message.textContent = String(err);
        els.playBtn.disabled = false;
      }
    });

    els.repairBtn.addEventListener("click", async () => {
      els.repairBtn.disabled = true;
      els.playBtn.disabled = true;
      try {
        const s = await invoke("repair_game");
        applyState(s);
      } catch {
        els.message.textContent = "Reparo falhou. Tente novamente.";
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
      } catch {
        els.message.textContent = "Configurações temporariamente indisponíveis.";
      }
    });

    els.closeSettingsBtn.addEventListener("click", () =>
      els.settingsDialog.close()
    );

    invoke("fetch_changelog")
      .then((cl) => {
        els.changelog.textContent = cl || "Sem novidades publicadas.";
      })
      .catch(() => {
        els.changelog.textContent = "Sem novidades publicadas.";
      });

    const finalState = await invoke("bootstrap");
    applyState(finalState);
  } catch (err) {
    els.serverStatus.textContent = "Offline";
    els.message.textContent =
      "Falha ao iniciar o launcher. Clique Reparar ou reinstale.";
    console.error(err);
  }
}

main();
