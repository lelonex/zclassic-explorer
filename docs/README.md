# Documentazione Zclassic Explorer

Indice completo della documentazione del progetto.

## 📚 Panoramica Documentazione

Questa directory contiene tutta la documentazione necessaria per installare, configurare, deployare e mantenere Zclassic Explorer.

## 📖 Documenti Disponibili

### 1. [INSTALLATION.md](INSTALLATION.md) - Guida all'Installazione
**Per chi:** Sviluppatori che installano per la prima volta  
**Contenuto:**
- Prerequisiti sistema
- Installazione Zclassic daemon
- Installazione Explorer
- Configurazione iniziale
- Primo avvio
- Verifica installazione

### 2. [NODE_SETUP.md](NODE_SETUP.md) - Configurazione Nodo Zclassic
**Per chi:** Operatori che configurano il nodo  
**Contenuto:**
- Configurazione base zclassicd
- Opzioni avanzate
- Indici per l'Explorer (OBBLIGATORIO)
- Performance tuning
- Sicurezza RPC
- Monitoring del nodo

### 3. [API.md](API.md) - Documentazione API
**Per chi:** Sviluppatori che integrano con l'Explorer  
**Contenuto:**
- Endpoints REST completi
- Formato request/response
- Esempi di utilizzo
- WebSocket API
- Rate limiting
- Codici errore

### 4. [DEPLOYMENT.md](DEPLOYMENT.md) - Deployment Produzione
**Per chi:** DevOps che deployano in produzione  
**Contenuto:**
- Setup server produzione
- Configurazioni Nginx
- SSL/TLS con Let's Encrypt
- Systemd services
- Backup strategy
- Performance tuning
- Disaster recovery

### 5. [MAINTENANCE.md](MAINTENANCE.md) - Manutenzione e Monitoring
**Per chi:** Operatori per manutenzione quotidiana  
**Contenuto:**
- Check system giornalieri
- Monitoring setup
- Log management
- Aggiornamenti
- Best practices
- Alert configuration

### 6. [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Risoluzione Problemi
**Per chi:** Tutti, per risolvere problemi comuni  
**Contenuto:**
- Problemi di connessione
- Problemi di sincronizzazione
- Performance issues
- Errori di compilazione
- Debug utilities

## 🚀 Quick Start

### Per Sviluppatori (Ambiente Locale)

```bash
# 1. Leggi prerequisiti
cat docs/INSTALLATION.md | grep -A 20 "Prerequisiti"

# 2. Installa e configura nodo
# Segui: docs/NODE_SETUP.md

# 3. Installa explorer
git clone https://github.com/yourusername/zclassic-explorer.git
cd zclassic-explorer
mix deps.get
cd assets && npm install && cd ..

# 4. Configura
cp .env.example .env
# Modifica .env

# 5. Avvia
source .env
mix phx.server
```

### Per Produzione

```bash
# Leggi DEPLOYMENT.md completamente prima di iniziare!
# POI segui step-by-step:

# 1. Preparazione server (DEPLOYMENT.md sezione "Preparazione Server")
# 2. Installazione componenti (DEPLOYMENT.md sezione "Installazione Produzione")
# 3. Configurazione Nginx e SSL (DEPLOYMENT.md sezione "Nginx Reverse Proxy")
# 4. Setup monitoring (MAINTENANCE.md sezione "Monitoring Produzione")
# 5. Configurazione backup (DEPLOYMENT.md sezione "Backup Strategy")
```

## 🔍 Come Usare Questa Documentazione

### Scenario: Prima Installazione

1. ✅ Leggi **INSTALLATION.md** completamente
2. ✅ Segui **NODE_SETUP.md** per configurare zclassicd
3. ✅ Verifica che gli indici siano abilitati (CRITICI!)
4. ✅ Completa installazione con INSTALLATION.md
5. ✅ Se problemi, consulta **TROUBLESHOOTING.md**

### Scenario: Deploy in Produzione

1. ✅ Prima completa installazione locale (vedi sopra)
2. ✅ Leggi **DEPLOYMENT.md** completamente
3. ✅ Prepara checklist dalla sezione "Checklist Go-Live"
4. ✅ Esegui deploy seguendo step-by-step
5. ✅ Setup monitoring da **MAINTENANCE.md**
6. ✅ Testa tutto prima di go-live

### Scenario: Integrazione API

1. ✅ Leggi **API.md**
2. ✅ Identifica endpoints necessari
3. ✅ Testa con curl/Postman
4. ✅ Implementa nel tuo codice
5. ✅ Considera rate limiting

### Scenario: Problema in Produzione

1. ✅ Identifica sintomi
2. ✅ Cerca in **TROUBLESHOOTING.md**
3. ✅ Raccogli log (comandi in TROUBLESHOOTING)
4. ✅ Applica soluzione suggerita
5. ✅ Se persiste, apri issue GitHub con info raccolte

## 🛠 Strumenti e Utility

### Script Utili Inclusi

```
scripts/
├── convert_to_zclassic.sh  # Conversione da Zcash (GIÀ ESEGUITO)
└── (altri script da creare)
```

### Comandi Rapidi

```bash
# Health check completo
~/check_system.sh  # Vedi MAINTENANCE.md

# Restart tutto
sudo systemctl restart zclassicd
sudo systemctl restart zclassic-explorer

# Logs in tempo reale
journalctl -u zclassic-explorer -f

# Verifica sync nodo
zclassic-cli getblockchaininfo | grep -E "blocks|verificationprogress"

# Test RPC
curl --user zclassic:password --data-binary \
  '{"jsonrpc":"1.0","method":"getinfo","params":[]}' \
  -H 'content-type: text/plain;' http://127.0.0.1:8023/
```

## 📊 Struttura Progetto

```
zclassic-explorer/
├── assets/              # Frontend (JS, CSS)
├── config/              # Configurazioni
│   ├── config.exs      # Base config
│   ├── dev.exs         # Development
│   ├── prod.exs        # Production
│   └── releases.exs    # Release config
├── docs/               # ← SEI QUI
│   ├── INSTALLATION.md
│   ├── NODE_SETUP.md
│   ├── API.md
│   ├── DEPLOYMENT.md
│   ├── MAINTENANCE.md
│   └── TROUBLESHOOTING.md
├── lib/
│   ├── zclassicex.ex          # RPC Client
│   ├── zclassic_explorer/     # Business logic
│   └── zclassic_explorer_web/ # Web interface
├── priv/               # Static files
├── scripts/            # Utility scripts
├── test/               # Tests
├── .env.example        # Environment template
├── mix.exs             # Dependencies
└── README.md           # Main readme
```

## 🔗 Link Utili

### Documentazione Esterna

- **Elixir**: https://elixir-lang.org/docs.html
- **Phoenix Framework**: https://hexdocs.pm/phoenix/overview.html
- **Zclassic**: https://github.com/z-classic/zclassic
- **Nginx**: https://nginx.org/en/docs/

### Community

- **GitHub Issues**: https://github.com/yourusername/zclassic-explorer/issues
- **Zclassic Forum**: https://forum.zclassic.org
- **Zclassic Discord**: [link se disponibile]

## ❓ FAQ

### Q: Devo usare PostgreSQL?
**A:** No, è opzionale. L'explorer può funzionare solo con cache in-memory.

### Q: Quanto tempo impiega la sincronizzazione iniziale?
**A:** Dipende da hardware e connessione. Generalmente 6-24 ore per mainnet completo.

### Q: Posso usare un nodo remoto?
**A:** Sì, ma non raccomandato. Configura RPC su SSL e firewall appropriato.

### Q: Come aggiorno l'explorer?
**A:** Vedi MAINTENANCE.md sezione "Aggiornamenti".

### Q: Gli indici sono davvero obbligatori?
**A:** SÌ! Senza indici l'explorer non può funzionare. Vedi NODE_SETUP.md.

### Q: Posso eseguire su Raspberry Pi?
**A:** Teoricamente sì, ma la sincronizzazione sarà molto lenta. Minimo RPi 4 con 8GB RAM.

### Q: Come contribuisco al progetto?
**A:** Fork, modifica, test, Pull Request. Vedi README.md sezione "Contributing".

## 📝 Glossario

- **RPC**: Remote Procedure Call - interfaccia per comunicare con zclassicd
- **Mempool**: Memory pool - transazioni non ancora confermate
- **UTXO**: Unspent Transaction Output - output non spesi
- **LiveView**: Tecnologia Phoenix per aggiornamenti real-time
- **Warmer**: Processo che pre-carica cache
- **Mix**: Build tool per Elixir
- **OTP**: Open Telecom Platform - framework Erlang

## 🆘 Supporto

### Ordine per Ottenere Aiuto

1. **Cerca in questa documentazione** - Probabilmente la risposta c'è
2. **Controlla TROUBLESHOOTING.md** - Problemi comuni risolti
3. **Cerca issue esistenti** - Qualcun altro potrebbe aver avuto il problema
4. **Chiedi nella community** - Forum/Discord
5. **Apri nuovo issue** - Con tutte le info richieste

### Info da Includere in Issue

```bash
# Raccogli queste info
elixir --version
node --version
zclassic-cli getinfo
cat /etc/os-release
journalctl -u zclassic-explorer -n 50
journalctl -u zclassicd -n 50
```

## 🎯 Best Practices

### Sviluppo

- ✅ Usa sempre `source .env` prima di avviare
- ✅ Test localmente prima di commit
- ✅ Segui style guide Elixir: `mix format`
- ✅ Scrivi test per nuove feature

### Produzione

- ✅ **MAI** committare credenziali
- ✅ Backup regolari (automatizzati)
- ✅ Monitoring attivo 24/7
- ✅ Keep dependencies updated
- ✅ Review security advisories

### Operazioni

- ✅ Documenta ogni modifica
- ✅ Test su staging prima di produzione
- ✅ Mantieni runbook aggiornato
- ✅ Plan for disaster recovery

## 📅 Manutenzione Consigliata

### Giornaliera
- Check health system
- Review log errors
- Verify sync status

### Settimanale
- Review performance metrics
- Check disk space
- Verify backups

### Mensile
- Update dependencies
- Security patches
- Performance optimization
- Documentation review

## 📜 Changelog

La documentazione viene aggiornata con il codice. Vedi:
- Git commits per modifiche
- GitHub Releases per versioni
- CHANGELOG.md nel root (se presente)

## 🤝 Contribuire alla Documentazione

Miglioramenti benvenuti!

```bash
# 1. Fork repo
# 2. Modifica docs/
# 3. Test che esempi funzionino
# 4. Pull Request con descrizione chiara
```

---

**Ultimo aggiornamento:** 2024  
**Maintainer:** Zclassic Community  
**Licenza:** Apache 2.0

Per domande: https://github.com/yourusername/zclassic-explorer/issues
