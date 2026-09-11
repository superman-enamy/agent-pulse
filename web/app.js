let currentConfig = {};

// Tab Navigation
document.querySelectorAll('.tab-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
    document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
    btn.classList.add('active');
    const tabId = btn.getAttribute('data-tab');
    document.getElementById(`tab-${tabId}`).classList.add('active');
  });
});

// Slider display listeners
document.getElementById('tts_rate').addEventListener('input', (e) => {
  document.getElementById('rate-val').innerText = `${e.target.value}x`;
});

document.getElementById('tts_pitch').addEventListener('input', (e) => {
  document.getElementById('pitch-val').innerText = `${e.target.value}x`;
});

// Load Config from Server
async function loadConfig() {
  try {
    const res = await fetch('/api/config');
    currentConfig = await res.json();
    populateForm(currentConfig);
  } catch (err) {
    showStatus('Failed to load settings', false);
  }
}

// Populate UI Elements with Config Values
function populateForm(cfg) {
  // Automation & DND
  document.getElementById('smart_dnd_enabled').checked = cfg.smart_dnd?.enabled ?? true;
  document.getElementById('smart_dnd_toast').checked = cfg.smart_dnd?.silent_toast_in_termux ?? true;
  document.getElementById('auto_open_permission').checked = cfg.automation?.auto_open_on_permission ?? true;
  document.getElementById('auto_open_complete').checked = cfg.automation?.auto_open_on_complete ?? false;

  // Voice TTS
  document.getElementById('tts_enabled').checked = cfg.tts?.enabled ?? true;
  const rate = cfg.tts?.rate ?? 1.0;
  document.getElementById('tts_rate').value = rate;
  document.getElementById('rate-val').innerText = `${rate}x`;

  const pitch = cfg.tts?.pitch ?? 1.0;
  document.getElementById('tts_pitch').value = pitch;
  document.getElementById('pitch-val').innerText = `${pitch}x`;

  document.getElementById('tts_permission_text').value = cfg.tts?.permission_text ?? '';
  document.getElementById('tts_complete_text').value = cfg.tts?.complete_text ?? '';
  document.getElementById('tts_error_text').value = cfg.tts?.error_text ?? '';

  // Notifications
  document.getElementById('notif_sound').checked = cfg.notification?.sound ?? true;
  document.getElementById('notif_vibrate').checked = cfg.notification?.vibrate ?? true;
  document.getElementById('notif_led').checked = cfg.notification?.led ?? true;
  document.getElementById('notif_terminal_banner').checked = cfg.notification?.terminal_banner ?? true;

  document.getElementById('tpl_title_complete').value = cfg.templates?.title_complete ?? '';
  document.getElementById('tpl_title_permission').value = cfg.templates?.title_permission ?? '';
  document.getElementById('tpl_title_error').value = cfg.templates?.title_error ?? '';
}

// Gather UI Elements back into Config Object
function serializeForm() {
  return {
    ...currentConfig,
    automation: {
      ...currentConfig.automation,
      auto_open_on_permission: document.getElementById('auto_open_permission').checked,
      auto_open_on_complete: document.getElementById('auto_open_complete').checked,
      only_open_when_background: true
    },
    smart_dnd: {
      enabled: document.getElementById('smart_dnd_enabled').checked,
      silent_toast_in_termux: document.getElementById('smart_dnd_toast').checked
    },
    tts: {
      enabled: document.getElementById('tts_enabled').checked,
      rate: parseFloat(document.getElementById('tts_rate').value),
      pitch: parseFloat(document.getElementById('tts_pitch').value),
      permission_text: document.getElementById('tts_permission_text').value,
      complete_text: document.getElementById('tts_complete_text').value,
      error_text: document.getElementById('tts_error_text').value
    },
    notification: {
      ...currentConfig.notification,
      sound: document.getElementById('notif_sound').checked,
      vibrate: document.getElementById('notif_vibrate').checked,
      led: document.getElementById('notif_led').checked,
      terminal_banner: document.getElementById('notif_terminal_banner').checked
    },
    templates: {
      title_complete: document.getElementById('tpl_title_complete').value,
      title_permission: document.getElementById('tpl_title_permission').value,
      title_error: document.getElementById('tpl_title_error').value
    }
  };
}

// Save Config to Server
async function saveConfig() {
  const updated = serializeForm();
  showStatus('Saving...', null);
  try {
    const res = await fetch('/api/config', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(updated)
    });
    if (res.ok) {
      currentConfig = updated;
      showStatus('Settings saved successfully! ✅', true);
    } else {
      showStatus('Error saving settings', false);
    }
  } catch (err) {
    showStatus('Failed to connect to server', false);
  }
}

function showStatus(text, success) {
  const el = document.getElementById('save-status');
  el.innerText = text;
  if (success === true) {
    el.className = 'save-status saved';
  } else if (success === false) {
    el.className = 'save-status error';
  } else {
    el.className = 'save-status';
  }
}

document.getElementById('btn-save').addEventListener('click', saveConfig);

// Status Poller (Foreground check)
async function updateStatus() {
  try {
    const res = await fetch('/api/status');
    const data = await res.json();
    const badge = document.getElementById('fg-badge');
    const txt = document.getElementById('fg-text');
    if (data.foreground_state === 'foreground') {
      txt.innerText = 'Hub: Online';
      badge.style.borderColor = 'rgba(46, 160, 67, 0.4)';
      badge.style.color = '#2ea043';
    } else {
      txt.innerText = 'Hub: Online';
      badge.style.borderColor = 'rgba(210, 153, 34, 0.4)';
      badge.style.color = '#d29922';
    }
  } catch (e) {}
}

// Logs Loader
async function loadLogs() {
  try {
    const res = await fetch('/api/logs');
    const data = await res.json();
    const container = document.getElementById('log-viewer');
    if (data.logs && data.logs.length > 0) {
      container.innerHTML = data.logs.map(l => `<div class="log-entry">${escapeHtml(l)}</div>`).reverse().join('');
    } else {
      container.innerHTML = '<div class="log-empty">No activity recorded yet</div>';
    }
  } catch (e) {}
}

function escapeHtml(str) {
  return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

document.getElementById('btn-refresh-logs').addEventListener('click', loadLogs);

// Live Test Buttons
document.getElementById('btn-test-voice').addEventListener('click', async () => {
  const text = document.getElementById('tts_complete_text').value || "Agent pulse voice test";
  await fetch('/api/test/voice', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ text })
  });
});

document.getElementById('btn-test-notif-complete').addEventListener('click', async () => {
  await fetch('/api/test/notification', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      title: document.getElementById('tpl_title_complete').value || "Agent Pulse - Completed",
      content: "Testing task completion alert from web portal!"
    })
  });
});

document.getElementById('btn-test-notif-perm').addEventListener('click', async () => {
  await fetch('/api/test/notification', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      title: document.getElementById('tpl_title_permission').value || "Agent Pulse - Permission",
      content: "Testing waiting for user permission alert!"
    })
  });
});

document.getElementById('btn-test-open').addEventListener('click', async () => {
  await fetch('/api/test/open', { method: 'POST' });
});

// Initialization
loadConfig();
updateStatus();
loadLogs();
setInterval(updateStatus, 5000);
