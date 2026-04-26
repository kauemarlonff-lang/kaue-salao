# 💅 Lumière Studio — Sistema de Agendamento

Sistema completo de agendamento para salão de beleza com painel administrativo e integração com WhatsApp.

---

## 📁 Estrutura de Arquivos

```
salon/
├── server.js              ← Backend Node.js (API REST)
├── package.json           ← Dependências
├── data/                  ← Criado automaticamente ao iniciar
│   ├── appointments.json  ← Banco de dados dos agendamentos
│   └── admin.json         ← Credenciais do admin (senha hasheada)
└── public/
    ├── index.html         ← Página principal do salão
    ├── admin.html         ← Painel do administrador
    ├── style.css          ← Todos os estilos
    ├── app.js             ← JS da página principal
    └── admin.js           ← JS do painel admin
```

---

## 🚀 Como Rodar

### Pré-requisitos
- [Node.js](https://nodejs.org) versão 16 ou superior instalado

### Passo a Passo

**1. Entre na pasta do projeto:**
```bash
cd salon
```

**2. Instale as dependências:**
```bash
npm install
```

**3. Inicie o servidor:**
```bash
npm start
```

Ou, para desenvolvimento com reinício automático:
```bash
npm run dev
```

**4. Acesse no navegador:**
- 🌐 Site principal: http://localhost:3000
- 🔐 Painel admin: http://localhost:3000/admin.html

---

## 🔐 Credenciais Padrão do Admin

| Campo | Valor |
|-------|-------|
| Usuário | `admin` |
| Senha | `admin123` |

> ⚠️ **Importante:** Altere a senha no painel de Configurações após o primeiro login!

---

## ✨ Funcionalidades

### Site Principal
- ✅ Página de apresentação do salão com serviços
- ✅ Formulário de agendamento com validação completa
- ✅ Seleção visual de horários disponíveis (ocupados aparecem riscados)
- ✅ Prevenção de agendamentos duplicados
- ✅ Botão de confirmação via WhatsApp com mensagem pré-preenchida
- ✅ Design responsivo (mobile-friendly)

### Painel Admin
- ✅ Login seguro com senha hasheada (SHA-256 + salt)
- ✅ Sessão com token aleatório (expira em 8h)
- ✅ Lista de todos os agendamentos
- ✅ Filtro por data e status
- ✅ Estatísticas do dia
- ✅ Alterar status (Confirmado → Concluído / Cancelado)
- ✅ Excluir agendamentos
- ✅ Enviar mensagem WhatsApp para o cliente
- ✅ Configurar número do WhatsApp do salão
- ✅ Alterar senha pelo painel

### Integração WhatsApp
- ✅ Cliente recebe link direto para WhatsApp com mensagem pré-formatada
- ✅ Admin pode enviar mensagem de confirmação para cada cliente
- ✅ Número do salão configurável no painel

---

## 🛡️ Segurança Implementada

| Recurso | Detalhes |
|---------|----------|
| Autenticação | Token aleatório de 32 bytes (hex) por sessão |
| Senhas | SHA-256 com salt fixo (para produção: use bcrypt) |
| Validação | Inputs validados no frontend E no backend |
| Sessão | Expira automaticamente após 8 horas |
| Proteção de rotas | Todas as rotas /admin/* exigem token válido |

---

## 🔧 Personalização

### Trocar nome do salão
Edite `public/index.html` e troque todas as ocorrências de "Lumière Studio".

### Trocar serviços disponíveis
No `public/index.html`, localize a `<select id="service">` e edite as opções.

### Trocar horários de funcionamento
No `server.js`, localize a função `generateSlots()` e ajuste os valores de `h = 8` (abertura) e `h < 19` (fechamento).

### Trocar número do WhatsApp padrão
No painel admin → Configurações → insira o número completo com código do país (ex: `5511999999999`).

---

## 📊 API Endpoints

### Públicos
| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/api/slots?date=YYYY-MM-DD` | Horários disponíveis |
| POST | `/api/appointments` | Criar agendamento |

### Admin (requer Authorization header)
| Método | Rota | Descrição |
|--------|------|-----------|
| POST | `/api/admin/login` | Fazer login |
| POST | `/api/admin/logout` | Encerrar sessão |
| GET | `/api/admin/appointments` | Listar agendamentos |
| PATCH | `/api/admin/appointments/:id` | Atualizar status |
| DELETE | `/api/admin/appointments/:id` | Excluir |
| GET | `/api/admin/settings` | Ver configurações |
| PATCH | `/api/admin/settings` | Salvar configurações |

---

## 🌐 Deploy em Produção

Para colocar online, recomendamos:

1. **[Railway](https://railway.app)** — gratuito, fácil deploy com Node.js
2. **[Render](https://render.com)** — plano free disponível
3. **[Fly.io](https://fly.io)** — opção robusta e gratuita

> 💡 Para produção, considere trocar o JSON por um banco real (SQLite com `better-sqlite3` ou PostgreSQL) e usar `bcrypt` para hashing de senhas.

---

## 📱 Testando no Celular

Com o servidor rodando, descubra o IP da sua máquina:
```bash
# Linux/Mac:
hostname -I

# Windows:
ipconfig
```

Acesse pelo celular: `http://SEU-IP:3000`

---

Feito com 💗 para Lumière Studio
