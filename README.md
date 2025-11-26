# Zclassic Explorer

Un blockchain explorer moderno e completo per Zclassic (ZCL), costruito con Phoenix Framework ed Elixir.

## 🌟 Caratteristiche

- **Esplorazione Blockchain in tempo reale**: Visualizza blocchi, transazioni e indirizzi
- **Mempool monitoring**: Monitora le transazioni non confermate
- **Network statistics**: Statistiche della rete inclusi hashrate, difficoltà e nodi connessi
- **Address tracking**: Traccia balance e transazioni per indirizzi trasparenti e shielded
- **Responsive UI**: Interfaccia ottimizzata per desktop e mobile
- **Real-time updates**: Aggiornamenti live tramite Phoenix LiveView
- **API RESTful**: API per integrazioni esterne

## 📋 Requisiti

- **Elixir**: >= 1.7
- **Erlang/OTP**: >= 22
- **Node.js**: >= 14.x
- **PostgreSQL**: >= 12 (opzionale)
- **Zclassic Daemon (zclassicd)**: Ultima versione

## 🚀 Installazione Rapida

```bash
# 1. Clona il repository
git clone https://github.com/yourusername/zclassic-explorer.git
cd zclassic-explorer

# 2. Installa dipendenze
mix deps.get
cd assets && npm install && cd ..

# 3. Configura variabili d'ambiente
cp .env.example .env
# Modifica .env con le tue impostazioni

# 4. Avvia l'explorer
source .env
mix phx.server
```

Visita [`localhost:4000`](http://localhost:4000)

## 📚 Documentazione Completa

- [Guida all'Installazione](docs/INSTALLATION.md) - Installazione dettagliata e configurazione
- [Configurazione Nodo Zclassic](docs/NODE_SETUP.md) - Setup del nodo zclassicd
- [API Reference](docs/API.md) - Documentazione completa delle API
- [Deployment](docs/DEPLOYMENT.md) - Deploy in produzione
- [Manutenzione](docs/MAINTENANCE.md) - Manutenzione e monitoring
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Risoluzione problemi comuni

## 🔧 Configurazione Base

Configura il file `.env`:

```bash
# RPC Zclassic Node
export ZCLASSICD_HOSTNAME=127.0.0.1
export ZCLASSICD_PORT=8023
export ZCLASSICD_USERNAME=zclassic
export ZCLASSICD_PASSWORD=changeme
export ZCLASSIC_NETWORK=mainnet

# Explorer Settings
export EXPLORER_HOSTNAME=localhost
export EXPLORER_PORT=4000
export SECRET_KEY_BASE=$(mix phx.gen.secret)
```

## 🐳 Docker

```bash
# Con Docker Compose
docker-compose up -d
```

## 🔍 API Examples

```bash
# Blockchain info
curl http://localhost:4000/api/blockchain/info

# Get block
curl http://localhost:4000/api/block/00000...

# Get transaction
curl http://localhost:4000/api/tx/abc123...

# Address balance
curl http://localhost:4000/api/address/t1.../balance
```

## 🛠 Sviluppo

```bash
# Test
mix test

# Format
mix format

# Code analysis
mix credo
```

## 📄 Licenza

Apache License 2.0

## 🙏 Credits

Basato sul lavoro di Nighthawk Apps per Zcash Explorer.
Adattato per Zclassic dalla community.

---

Made with ❤️ for the Zclassic Community
