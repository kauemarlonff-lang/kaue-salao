/* ─────────────────────────────────────────────────────────────────
   Lumière Studio — Frontend JS
   Handles: booking form, slots, WhatsApp, nav
───────────────────────────────────────────────────────────────── */

// ── State ──────────────────────────────────────────────────────
let selectedTime = '';
let currentAppointment = null;

// ── Utils ──────────────────────────────────────────────────────
function showToast(msg, type = 'info', duration = 3500) {
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
  }, duration);
}

function formatPhone(value) {
  const digits = value.replace(/\D/g, '').slice(0, 11);
  if (digits.length <= 2) return digits;
  if (digits.length <= 7) return `(${digits.slice(0,2)}) ${digits.slice(2)}`;
  if (digits.length <= 11) return `(${digits.slice(0,2)}) ${digits.slice(2,7)}-${digits.slice(7)}`;
  return value;
}

function getTodayString() {
  const d = new Date();
  return d.toISOString().split('T')[0];
}

// ── Hamburger nav ──────────────────────────────────────────────
const hamburger = document.getElementById('hamburger');
const navLinks = document.querySelector('.nav-links');

if (hamburger) {
  hamburger.addEventListener('click', () => {
    navLinks.classList.toggle('open');
    hamburger.textContent = navLinks.classList.contains('open') ? '✕' : '☰';
  });

  navLinks?.querySelectorAll('a').forEach(a => {
    a.addEventListener('click', () => {
      navLinks.classList.remove('open');
      hamburger.textContent = '☰';
    });
  });
}

// ── Date min ───────────────────────────────────────────────────
const dateInput = document.getElementById('date');
if (dateInput) {
  dateInput.min = getTodayString();

  dateInput.addEventListener('change', loadSlots);
}

// Phone mask
const phoneInput = document.getElementById('phone');
if (phoneInput) {
  phoneInput.addEventListener('input', e => {
    e.target.value = formatPhone(e.target.value);
  });
}

// ── Load slots ─────────────────────────────────────────────────
async function loadSlots() {
  const date = document.getElementById('date').value;
  const service = document.getElementById('service').value;
  const container = document.getElementById('slotsContainer');

  if (!date) return;

  container.innerHTML = '<span class="slots-loading">Carregando horários...</span>';
  selectedTime = '';
  document.getElementById('selectedTime').value = '';

  try {
    const res = await fetch(`/api/slots?date=${date}&service=${encodeURIComponent(service)}`);
    const slots = await res.json();

    if (!slots.length) {
      container.innerHTML = '<p class="slots-hint">Nenhum horário disponível.</p>';
      return;
    }

    container.innerHTML = '';
    slots.forEach(slot => {
      const btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'slot-btn';
      btn.textContent = slot.time;
      if (!slot.available) {
        btn.disabled = true;
        btn.title = 'Horário ocupado';
      } else {
        btn.addEventListener('click', () => selectSlot(btn, slot.time));
      }
      container.appendChild(btn);
    });
  } catch (err) {
    container.innerHTML = '<p class="slots-hint" style="color:#c0392b">Erro ao carregar horários. Tente novamente.</p>';
  }
}

document.getElementById('service')?.addEventListener('change', () => {
  if (document.getElementById('date').value) loadSlots();
});

function selectSlot(btn, time) {
  document.querySelectorAll('.slot-btn').forEach(b => b.classList.remove('selected'));
  btn.classList.add('selected');
  selectedTime = time;
  document.getElementById('selectedTime').value = time;
  document.getElementById('timeError').textContent = '';
}

// ── Form Validation ────────────────────────────────────────────
function validateForm() {
  let valid = true;

  const name = document.getElementById('name').value.trim();
  const phone = document.getElementById('phone').value.replace(/\D/g, '');
  const service = document.getElementById('service').value;
  const date = document.getElementById('date').value;

  const setError = (id, msg) => {
    document.getElementById(id).textContent = msg;
    if (msg) valid = false;
  };

  setError('nameError', name.length < 2 ? 'Nome deve ter pelo menos 2 caracteres.' : '');
  setError('phoneError', phone.length < 10 || phone.length > 11 ? 'Telefone inválido. Ex: (11) 99999-9999' : '');
  setError('serviceError', !service ? 'Selecione um serviço.' : '');
  setError('dateError', !date ? 'Selecione uma data.' : '');
  setError('timeError', !selectedTime ? 'Selecione um horário.' : '');

  return valid;
}

// ── Form Submit ─────────────────────────────────────────────────
document.getElementById('bookingForm')?.addEventListener('submit', async (e) => {
  e.preventDefault();
  if (!validateForm()) return;

  const submitBtn = document.getElementById('submitBtn');
  submitBtn.disabled = true;
  submitBtn.innerHTML = '<span>Aguarde...</span>';

  const body = {
    name: document.getElementById('name').value.trim(),
    phone: document.getElementById('phone').value,
    service: document.getElementById('service').value,
    date: document.getElementById('date').value,
    time: selectedTime
  };

  try {
    const res = await fetch('/api/appointments', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    });

    const data = await res.json();

    if (!res.ok) {
      showToast(data.error || 'Erro ao agendar.', 'error');
      submitBtn.disabled = false;
      submitBtn.innerHTML = '<span>Confirmar Agendamento</span>';
      if (res.status === 409) loadSlots(); // reload slots if conflict
      return;
    }

    currentAppointment = data.appointment;
    showSuccess(data.appointment);

  } catch (err) {
    showToast('Erro de conexão. Verifique se o servidor está rodando.', 'error');
    submitBtn.disabled = false;
    submitBtn.innerHTML = '<span>Confirmar Agendamento</span>';
  }
});

function showSuccess(apt) {
  document.getElementById('bookingForm').style.display = 'none';
  const successEl = document.getElementById('bookingSuccess');
  successEl.style.display = 'block';

  const dateFormatted = new Date(apt.date + 'T12:00:00').toLocaleDateString('pt-BR', {
    weekday: 'long', day: 'numeric', month: 'long', year: 'numeric'
  });

  document.getElementById('successDetails').innerHTML =
    `<strong>${apt.name}</strong>, seu agendamento foi confirmado!<br/>
     📋 ${apt.service}<br/>
     📅 ${dateFormatted}<br/>
     🕐 ${apt.time}`;

  // Setup WhatsApp button
  document.getElementById('whatsappBtn').onclick = () => sendWhatsApp(apt);
}

function sendWhatsApp(apt) {
  const dateFormatted = new Date(apt.date + 'T12:00:00').toLocaleDateString('pt-BR', {
    weekday: 'long', day: 'numeric', month: 'long'
  });

  const msg = encodeURIComponent(
    `Olá! Gostaria de confirmar meu agendamento no *Lumière Studio* 💆‍♀️\n\n` +
    `👤 *Nome:* ${apt.name}\n` +
    `✂️ *Serviço:* ${apt.service}\n` +
    `📅 *Data:* ${dateFormatted}\n` +
    `🕐 *Horário:* ${apt.time}\n\n` +
    `Aguardo a confirmação. Obrigada! 🌸`
  );

  // Try to get salon phone from settings; fallback to default
  fetch('/api/admin/settings').then(r => r.json()).then(s => {
    const phone = s.salon_phone || '5511999999999';
    window.open(`https://wa.me/${phone}?text=${msg}`, '_blank');
  }).catch(() => {
    window.open(`https://wa.me/5511999999999?text=${msg}`, '_blank');
  });
}

function resetForm() {
  currentAppointment = null;
  selectedTime = '';
  document.getElementById('bookingForm').reset();
  document.getElementById('bookingForm').style.display = 'block';
  document.getElementById('bookingSuccess').style.display = 'none';
  document.getElementById('submitBtn').disabled = false;
  document.getElementById('submitBtn').innerHTML = '<span>Confirmar Agendamento</span>';
  document.getElementById('slotsContainer').innerHTML = '<p class="slots-hint">Selecione uma data e serviço para ver os horários disponíveis.</p>';
  ['nameError','phoneError','serviceError','dateError','timeError'].forEach(id => {
    document.getElementById(id).textContent = '';
  });
}

// Make accessible globally
window.resetForm = resetForm;
