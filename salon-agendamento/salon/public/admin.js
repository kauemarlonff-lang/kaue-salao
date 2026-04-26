/* ─────────────────────────────────────────────────────────────────
   Lumière Studio — Admin JS
───────────────────────────────────────────────────────────────── */

let authToken = sessionStorage.getItem('salon_token') || '';

// ── Login ──────────────────────────────────────────────────────
document.getElementById('loginBtn').addEventListener('click', login);
document.getElementById('loginPass').addEventListener('keydown', e => {
  if (e.key === 'Enter') login();
});

async function login() {
  const username = document.getElementById('loginUser').value.trim();
  const password = document.getElementById('loginPass').value;
  const btn = document.getElementById('loginBtn');
  const errEl = document.getElementById('loginError');

  if (!username || !password) {
    errEl.textContent = 'Preencha usuário e senha.';
    return;
  }

  btn.disabled = true;
  btn.innerHTML = '<span>Entrando...</span>';
  errEl.textContent = '';

  try {
    const res = await fetch('/api/admin/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username, password })
    });

    const data = await res.json();

    if (!res.ok) {
      errEl.textContent = data.error || 'Erro ao fazer login.';
      btn.disabled = false;
      btn.innerHTML = '<span>Entrar</span>';
      return;
    }

    authToken = data.token;
    sessionStorage.setItem('salon_token', authToken);
    showPanel();

  } catch (err) {
    errEl.textContent = 'Erro de conexão com o servidor.';
    btn.disabled = false;
    btn.innerHTML = '<span>Entrar</span>';
  }
}

// ── Logout ─────────────────────────────────────────────────────
document.getElementById('logoutBtn').addEventListener('click', async () => {
  await fetch('/api/admin/logout', {
    method: 'POST',
    headers: { 'Authorization': authToken }
  }).catch(() => {});

  authToken = '';
  sessionStorage.removeItem('salon_token');
  document.getElementById('adminPanel').style.display = 'none';
  document.getElementById('loginView').style.display = 'flex';
  document.getElementById('loginPass').value = '';
});

// ── Show panel ─────────────────────────────────────────────────
function showPanel() {
  document.getElementById('loginView').style.display = 'none';
  document.getElementById('adminPanel').style.display = 'block';

  // Set today as default filter
  const today = new Date().toISOString().split('T')[0];
  document.getElementById('filterDate').value = today;

  loadAppointments();
  loadSettings();
}

// Auto-login if token in session
if (authToken) {
  // Verify token is still valid
  fetch('/api/admin/appointments', {
    headers: { 'Authorization': authToken }
  }).then(res => {
    if (res.ok) showPanel();
    else {
      sessionStorage.removeItem('salon_token');
      authToken = '';
    }
  }).catch(() => {});
}

// ── Load appointments ──────────────────────────────────────────
async function loadAppointments() {
  const date = document.getElementById('filterDate').value;
  const status = document.getElementById('filterStatus').value;

  let url = '/api/admin/appointments?';
  if (date) url += `date=${date}&`;
  if (status) url += `status=${status}`;

  try {
    const res = await fetch(url, {
      headers: { 'Authorization': authToken }
    });

    if (res.status === 401) {
      showToast('Sessão expirada. Faça login novamente.', 'error');
      sessionStorage.removeItem('salon_token');
      location.reload();
      return;
    }

    const appointments = await res.json();
    renderAppointments(appointments);
    updateStats(appointments);

  } catch (err) {
    document.getElementById('appointmentsContainer').innerHTML =
      '<p class="empty-state" style="color:#c0392b">Erro ao carregar. Verifique a conexão.</p>';
  }
}

function updateStats(appointments) {
  document.getElementById('statTotal').textContent = appointments.length;
  document.getElementById('statConfirmado').textContent =
    appointments.filter(a => a.status === 'confirmado').length;
  document.getElementById('statCancelado').textContent =
    appointments.filter(a => a.status === 'cancelado').length;
}

function renderAppointments(appointments) {
  const container = document.getElementById('appointmentsContainer');

  if (!appointments.length) {
    container.innerHTML = '<p class="empty-state">Nenhum agendamento encontrado para os filtros selecionados.</p>';
    return;
  }

  const formatDate = (d) => new Date(d + 'T12:00:00').toLocaleDateString('pt-BR', {
    day: '2-digit', month: '2-digit', year: 'numeric'
  });

  const formatPhone = (p) => p.length === 11
    ? `(${p.slice(0,2)}) ${p.slice(2,7)}-${p.slice(7)}`
    : `(${p.slice(0,2)}) ${p.slice(2,6)}-${p.slice(6)}`;

  const rows = appointments.map(a => `
    <tr id="row-${a.id}">
      <td>${formatDate(a.date)}</td>
      <td><strong>${a.time}</strong></td>
      <td>${escHtml(a.name)}</td>
      <td>${formatPhone(a.phone)}</td>
      <td>${escHtml(a.service)}</td>
      <td><span class="status-badge status-${a.status}">${a.status}</span></td>
      <td>
        <div class="action-btns">
          ${a.status !== 'concluido' ? `<button class="btn-action" onclick="updateStatus('${a.id}','concluido')" title="Marcar concluído">✓</button>` : ''}
          ${a.status === 'confirmado' ? `<button class="btn-action" onclick="updateStatus('${a.id}','cancelado')" title="Cancelar">✕</button>` : ''}
          <button class="btn-action" onclick="sendWhatsApp('${a.phone}','${escAttr(a.name)}','${escAttr(a.service)}','${a.date}','${a.time}')" title="WhatsApp">💬</button>
          <button class="btn-action danger" onclick="deleteAppointment('${a.id}')" title="Excluir">🗑</button>
        </div>
      </td>
    </tr>
  `).join('');

  container.innerHTML = `
    <table class="appointments-table">
      <thead>
        <tr>
          <th>Data</th>
          <th>Hora</th>
          <th>Cliente</th>
          <th>WhatsApp</th>
          <th>Serviço</th>
          <th>Status</th>
          <th>Ações</th>
        </tr>
      </thead>
      <tbody>${rows}</tbody>
    </table>
  `;
}

function escHtml(str) {
  return String(str).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
}

function escAttr(str) {
  return String(str).replace(/'/g, "\\'");
}

// ── Update status ──────────────────────────────────────────────
async function updateStatus(id, status) {
  try {
    const res = await fetch(`/api/admin/appointments/${id}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': authToken
      },
      body: JSON.stringify({ status })
    });

    if (res.ok) {
      showToast(`Status atualizado: ${status}`, 'success');
      loadAppointments();
    } else {
      showToast('Erro ao atualizar.', 'error');
    }
  } catch { showToast('Erro de conexão.', 'error'); }
}

// ── Delete ─────────────────────────────────────────────────────
async function deleteAppointment(id) {
  if (!confirm('Excluir este agendamento permanentemente?')) return;

  try {
    const res = await fetch(`/api/admin/appointments/${id}`, {
      method: 'DELETE',
      headers: { 'Authorization': authToken }
    });

    if (res.ok) {
      showToast('Agendamento excluído.', 'success');
      loadAppointments();
    } else {
      showToast('Erro ao excluir.', 'error');
    }
  } catch { showToast('Erro de conexão.', 'error'); }
}

// ── WhatsApp from admin ────────────────────────────────────────
function sendWhatsApp(phone, name, service, date, time) {
  const dateFormatted = new Date(date + 'T12:00:00').toLocaleDateString('pt-BR', {
    weekday: 'long', day: 'numeric', month: 'long'
  });

  const msg = encodeURIComponent(
    `Olá, *${name}*! 👋\n\n` +
    `Confirmando seu agendamento no *Lumière Studio*:\n\n` +
    `✂️ *Serviço:* ${service}\n` +
    `📅 *Data:* ${dateFormatted}\n` +
    `🕐 *Horário:* ${time}\n\n` +
    `Caso precise remarcar, entre em contato. Até lá! 🌸`
  );

  window.open(`https://wa.me/${phone}?text=${msg}`, '_blank');
}

// ── Filters ────────────────────────────────────────────────────
function clearFilters() {
  document.getElementById('filterDate').value = '';
  document.getElementById('filterStatus').value = '';
  loadAppointments();
}

// ── Settings ───────────────────────────────────────────────────
async function loadSettings() {
  try {
    const res = await fetch('/api/admin/settings', {
      headers: { 'Authorization': authToken }
    });
    const data = await res.json();
    document.getElementById('salonPhone').value = data.salon_phone || '';
  } catch {}
}

async function saveSettings() {
  const salon_phone = document.getElementById('salonPhone').value.trim();
  const current_password = document.getElementById('currentPass').value;
  const new_password = document.getElementById('newPass').value;
  const errEl = document.getElementById('settingsError');
  errEl.textContent = '';

  const body = { salon_phone };
  if (new_password) {
    if (!current_password) {
      errEl.textContent = 'Informe a senha atual para alterar.';
      return;
    }
    if (new_password.length < 6) {
      errEl.textContent = 'Nova senha deve ter pelo menos 6 caracteres.';
      return;
    }
    body.current_password = current_password;
    body.new_password = new_password;
  }

  try {
    const res = await fetch('/api/admin/settings', {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': authToken
      },
      body: JSON.stringify(body)
    });

    const data = await res.json();

    if (!res.ok) {
      errEl.textContent = data.error;
      return;
    }

    showToast('Configurações salvas!', 'success');
    document.getElementById('currentPass').value = '';
    document.getElementById('newPass').value = '';

  } catch { showToast('Erro de conexão.', 'error'); }
}

// ── Tab switch ─────────────────────────────────────────────────
function switchTab(tab) {
  document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
  document.querySelector(`[data-tab="${tab}"]`).classList.add('active');

  document.getElementById('tabAppointments').style.display = tab === 'appointments' ? 'block' : 'none';
  document.getElementById('tabSettings').style.display = tab === 'settings' ? 'block' : 'none';
}

// ── Toast ──────────────────────────────────────────────────────
function showToast(msg, type = 'info') {
  const existing = document.querySelector('.toast');
  if (existing) existing.remove();

  const toast = document.createElement('div');
  toast.className = `toast ${type}`;
  toast.textContent = msg;
  document.body.appendChild(toast);

  setTimeout(() => {
    toast.style.opacity = '0';
    toast.style.transition = 'opacity .3s';
    setTimeout(() => toast.remove(), 300);
  }, 3000);
}

// Make functions global for inline onclick
Object.assign(window, {
  loadAppointments, clearFilters, switchTab,
  updateStatus, deleteAppointment, sendWhatsApp, saveSettings
});
