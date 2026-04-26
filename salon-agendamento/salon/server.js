const express = require('express');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const app = express();
const PORT = 3000;
const DB_FILE = path.join(__dirname, 'data', 'appointments.json');
const ADMIN_FILE = path.join(__dirname, 'data', 'admin.json');

// ─── Middleware ────────────────────────────────────────────────────────────────
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// ─── Helpers ───────────────────────────────────────────────────────────────────
function readDB() {
  if (!fs.existsSync(DB_FILE)) fs.writeFileSync(DB_FILE, JSON.stringify([]));
  return JSON.parse(fs.readFileSync(DB_FILE, 'utf8'));
}

function writeDB(data) {
  fs.writeFileSync(DB_FILE, JSON.stringify(data, null, 2));
}

function hashPassword(password) {
  return crypto.createHash('sha256').update(password + 'salon_salt_2024').digest('hex');
}

function initAdmin() {
  if (!fs.existsSync(ADMIN_FILE)) {
    const admin = {
      username: 'admin',
      password: hashPassword('admin123'),
      salon_phone: '5511999999999'
    };
    fs.writeFileSync(ADMIN_FILE, JSON.stringify(admin, null, 2));
    console.log('Admin criado: usuário=admin, senha=admin123');
  }
}

function getAdmin() {
  return JSON.parse(fs.readFileSync(ADMIN_FILE, 'utf8'));
}

// Simple session store (in production use express-session + Redis)
const sessions = new Map();

function generateToken() {
  return crypto.randomBytes(32).toString('hex');
}

function requireAuth(req, res, next) {
  const token = req.headers['authorization'];
  if (!token || !sessions.has(token)) {
    return res.status(401).json({ error: 'Não autorizado' });
  }
  next();
}

// ─── Public Routes ─────────────────────────────────────────────────────────────

// Get available time slots for a date
app.get('/api/slots', (req, res) => {
  const { date, service } = req.query;
  if (!date) return res.status(400).json({ error: 'Data obrigatória' });

  const allSlots = generateSlots();
  const appointments = readDB();
  const booked = appointments
    .filter(a => a.date === date && a.status !== 'cancelado')
    .map(a => a.time);

  const available = allSlots.map(slot => ({
    time: slot,
    available: !booked.includes(slot)
  }));

  res.json(available);
});

function generateSlots() {
  const slots = [];
  for (let h = 8; h < 19; h++) {
    slots.push(`${String(h).padStart(2,'0')}:00`);
    slots.push(`${String(h).padStart(2,'0')}:30`);
  }
  return slots;
}

// Create appointment
app.post('/api/appointments', (req, res) => {
  const { name, phone, service, date, time } = req.body;

  // Validation
  if (!name || !phone || !service || !date || !time) {
    return res.status(400).json({ error: 'Todos os campos são obrigatórios' });
  }
  if (name.length < 2 || name.length > 100) {
    return res.status(400).json({ error: 'Nome inválido' });
  }
  const phoneClean = phone.replace(/\D/g, '');
  if (phoneClean.length < 10 || phoneClean.length > 11) {
    return res.status(400).json({ error: 'Telefone inválido' });
  }

  // Check duplicate
  const appointments = readDB();
  const conflict = appointments.find(
    a => a.date === date && a.time === time && a.status !== 'cancelado'
  );
  if (conflict) {
    return res.status(409).json({ error: 'Horário já ocupado' });
  }

  const newAppointment = {
    id: crypto.randomUUID(),
    name: name.trim(),
    phone: phoneClean,
    service,
    date,
    time,
    status: 'confirmado',
    createdAt: new Date().toISOString()
  };

  appointments.push(newAppointment);
  writeDB(appointments);

  res.status(201).json({
    success: true,
    appointment: newAppointment,
    message: 'Agendamento realizado com sucesso!'
  });
});

// ─── Admin Routes ──────────────────────────────────────────────────────────────

app.post('/api/admin/login', (req, res) => {
  const { username, password } = req.body;
  const admin = getAdmin();

  if (username !== admin.username || hashPassword(password) !== admin.password) {
    return res.status(401).json({ error: 'Usuário ou senha incorretos' });
  }

  const token = generateToken();
  sessions.set(token, { username, loginAt: Date.now() });

  // Auto-expire sessions after 8 hours
  setTimeout(() => sessions.delete(token), 8 * 60 * 60 * 1000);

  res.json({ token });
});

app.post('/api/admin/logout', requireAuth, (req, res) => {
  sessions.delete(req.headers['authorization']);
  res.json({ success: true });
});

app.get('/api/admin/appointments', requireAuth, (req, res) => {
  const { date, status } = req.query;
  let appointments = readDB();

  if (date) appointments = appointments.filter(a => a.date === date);
  if (status) appointments = appointments.filter(a => a.status === status);

  appointments.sort((a, b) => {
    if (a.date !== b.date) return a.date.localeCompare(b.date);
    return a.time.localeCompare(b.time);
  });

  res.json(appointments);
});

app.patch('/api/admin/appointments/:id', requireAuth, (req, res) => {
  const { id } = req.params;
  const { status } = req.body;

  if (!['confirmado', 'cancelado', 'concluido'].includes(status)) {
    return res.status(400).json({ error: 'Status inválido' });
  }

  const appointments = readDB();
  const idx = appointments.findIndex(a => a.id === id);
  if (idx === -1) return res.status(404).json({ error: 'Agendamento não encontrado' });

  appointments[idx].status = status;
  appointments[idx].updatedAt = new Date().toISOString();
  writeDB(appointments);

  res.json({ success: true, appointment: appointments[idx] });
});

app.delete('/api/admin/appointments/:id', requireAuth, (req, res) => {
  const { id } = req.params;
  let appointments = readDB();
  const idx = appointments.findIndex(a => a.id === id);
  if (idx === -1) return res.status(404).json({ error: 'Agendamento não encontrado' });

  appointments.splice(idx, 1);
  writeDB(appointments);
  res.json({ success: true });
});

app.get('/api/admin/settings', requireAuth, (req, res) => {
  const admin = getAdmin();
  res.json({ salon_phone: admin.salon_phone, username: admin.username });
});

app.patch('/api/admin/settings', requireAuth, (req, res) => {
  const { salon_phone, current_password, new_password } = req.body;
  const admin = getAdmin();

  if (new_password) {
    if (hashPassword(current_password) !== admin.password) {
      return res.status(401).json({ error: 'Senha atual incorreta' });
    }
    admin.password = hashPassword(new_password);
  }

  if (salon_phone) {
    admin.salon_phone = salon_phone.replace(/\D/g, '');
  }

  fs.writeFileSync(ADMIN_FILE, JSON.stringify(admin, null, 2));
  res.json({ success: true });
});

// ─── Catch all ─────────────────────────────────────────────────────────────────
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// ─── Init ──────────────────────────────────────────────────────────────────────
initAdmin();
if (!fs.existsSync(path.join(__dirname, 'data'))) {
  fs.mkdirSync(path.join(__dirname, 'data'));
}

app.listen(PORT, () => {
  console.log(`\n✨ Salão App rodando em http://localhost:${PORT}`);
  console.log(`📋 Admin: http://localhost:${PORT}/admin.html`);
  console.log(`🔑 Login: admin / admin123\n`);
});
