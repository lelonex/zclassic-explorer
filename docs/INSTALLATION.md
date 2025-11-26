# Guida all'Installazione di Zclassic Explorer

Questa guida ti accompagnerà passo-passo nell'installazione completa di Zclassic Explorer.

## Indice

1. [Prerequisiti](#prerequisiti)
2. [Installazione Zclassic Daemon](#installazione-zclassic-daemon)
3. [Installazione Explorer](#installazione-explorer)
4. [Configurazione](#configurazione)
5. [Primo Avvio](#primo-avvio)
6. [Verifica Installazione](#verifica-installazione)

## Prerequisiti

### Sistema Operativo

Questa guida assume che stai usando Ubuntu/Debian. Per altri sistemi operativi, adatta i comandi di conseguenza.

```bash
# Aggiorna il sistema
sudo apt update && sudo apt upgrade -y
```

### Installazione Elixir e Erlang

```bash
# Aggiungi repository Erlang Solutions
wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb
sudo dpkg -i erlang-solutions_2.0_all.deb
sudo apt update

# Installa Erlang e Elixir
sudo apt install -y esl-erlang elixir

# Verifica installazione
elixir --version
# Dovresti vedere: Elixir 1.x.x (compiled with Erlang/OTP 2x)
```

### Installazione Node.js

```bash
# Installa Node.js 16.x
curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt install -y nodejs

# Verifica installazione
node --version  # v16.x.x
npm --version   # 8.x.x
```

### Installazione PostgreSQL (Opzionale)

Se prevedi di usare un database per caching o storage addizionale:

```bash
# Installa PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# Avvia il servizio
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Crea utente e database
sudo -u postgres psql << EOF
CREATE USER zclassic WITH PASSWORD 'your_password';
CREATE DATABASE zclassic_explorer_dev OWNER zclassic;
CREATE DATABASE zclassic_explorer_test OWNER zclassic;
CREATE DATABASE zclassic_explorer_prod OWNER zclassic;
GRANT ALL PRIVILEGES ON DATABASE zclassic_explorer_dev TO zclassic;
GRANT ALL PRIVILEGES ON DATABASE zclassic_explorer_test TO zclassic;
GRANT ALL PRIVILEGES ON DATABASE zclassic_explorer_prod TO zclassic;
EOF
```

## Installazione Zclassic Daemon

### Opzione 1: Compilazione da Sorgente

```bash
# Installa dipendenze di build
sudo apt install -y build-essential pkg-config libc6-dev m4 g++-multilib \
    autoconf libtool ncurses-dev unzip git python3 python3-zmq zlib1g-dev \
    wget curl bsdmainutils automake

# Clona il repository Zclassic
cd ~
git clone https://github.com/z-classic/zclassic.git
cd zclassic

# Compila
./zcutil/build.sh -j$(nproc)

# Questo processo può richiedere 30-60 minuti
```

### Opzione 2: Binari Pre-compilati

```bash
# Scarica l'ultima release
cd ~
wget https://github.com/z-classic/zclassic/releases/download/vX.X.X/zclassic-X.X.X-linux.tar.gz

# Estrai
tar -xzvf zclassic-X.X.X-linux.tar.gz

# Sposta i binari
sudo mv zclassic*/bin/* /usr/local/bin/

# Verifica installazione
zclassicd --version
```

### Configurazione Zclassic Daemon

```bash
# Crea directory per i dati
mkdir -p ~/.zclassic

# Crea file di configurazione
cat > ~/.zclassic/zclassic.conf << EOF
# Server Configuration
server=1
daemon=1
listen=1

# RPC Configuration
rpcuser=zclassic
rpcpassword=$(openssl rand -base64 32)
rpcport=8023
rpcallowip=127.0.0.1

# Network Configuration
maxconnections=125

# Enable Address Index (REQUIRED for Explorer)
addressindex=1
timestampindex=1
spentindex=1
txindex=1

# ZMQ Notifications (Optional but recommended)
zmqpubrawblock=tcp://127.0.0.1:28332
zmqpubrawtx=tcp://127.0.0.1:28333

# Memory Pool Configuration
maxmempool=300

# Network (mainnet is default, for testnet add: testnet=1)
# testnet=1

# Performance Tuning
dbcache=2048
maxorphantx=100
maxmempool=300
EOF

# IMPORTANTE: Annota username e password generati!
echo "=== CREDENZIALI RPC ==="
echo "Username: zclassic"
echo "Password: $(grep rpcpassword ~/.zclassic/zclassic.conf | cut -d'=' -f2)"
echo "======================="
```

### Avvio Zclassic Daemon

```bash
# Avvia il daemon
zclassicd -daemon

# Verifica che sia in esecuzione
zclassic-cli getinfo

# Controlla lo stato di sincronizzazione
zclassic-cli getblockchaininfo
```

**NOTA IMPORTANTE**: La sincronizzazione iniziale della blockchain può richiedere diverse ore o giorni, a seconda della velocità della connessione e dell'hardware. L'explorer NON funzionerà correttamente finché il nodo non è completamente sincronizzato.

Monitorare la sincronizzazione:

```bash
# Script per monitorare il progresso
watch -n 60 'zclassic-cli getblockchaininfo | grep -E "blocks|headers|verificationprogress"'
```

## Installazione Explorer

### Clonare il Repository

```bash
# Vai nella directory home o dove preferisci installare
cd ~

# Clona il repository
git clone https://github.com/yourusername/zclassic-explorer.git
cd zclassic-explorer
```

### Installare Hex e Rebar

```bash
# Installa Hex (package manager per Elixir)
mix local.hex --force

# Installa Rebar (build tool)
mix local.rebar --force
```

### Installare Dipendenze Elixir

```bash
# Installa le dipendenze
mix deps.get

# Compila le dipendenze
mix deps.compile
```

### Installare Dipendenze Node.js

```bash
# Entra nella directory assets
cd assets

# Installa dipendenze npm
npm install

# Torna alla root del progetto
cd ..
```

## Configurazione

### Creare File di Ambiente

```bash
# Copia il file di esempio
cp .env.example .env

# Genera un secret key base
SECRET_KEY=$(mix phx.gen.secret)

# Modifica il file .env
nano .env
```

### Configurazione .env

Modifica il file `.env` con i seguenti valori:

```bash
# ====================================
# PHOENIX / EXPLORER CONFIGURATION
# ====================================

# Secret Key Base (generato con mix phx.gen.secret)
export SECRET_KEY_BASE="your_generated_secret_key_here"

# Explorer Hostname
export EXPLORER_HOSTNAME="localhost"
export EXPLORER_SCHEME="http"
export EXPLORER_PORT="4000"

# Network Type (mainnet or testnet)
export ZCLASSIC_NETWORK="mainnet"

# ====================================
# ZCLASSIC NODE RPC CONFIGURATION
# ====================================

# RPC Connection (deve corrispondere a zclassic.conf)
export ZCLASSICD_HOSTNAME="127.0.0.1"
export ZCLASSICD_PORT="8023"
export ZCLASSICD_USERNAME="zclassic"
export ZCLASSICD_PASSWORD="your_rpc_password_from_zclassic_conf"

# ====================================
# OPTIONAL: DOCKER CONFIGURATION
# ====================================

# Docker resources for viewing keys
export VK_CPUS="0.3"
export VK_MEM="1024M"
export VK_RUNNER_IMAGE="zclassic/vkrunner"

# ====================================
# OPTIONAL: DATABASE CONFIGURATION
# ====================================

# Se usi PostgreSQL, decommentare e configurare:
# export DATABASE_URL="postgresql://zclassic:password@localhost/zclassic_explorer_dev"
```

### Configurazione Sviluppo (config/dev.exs)

Il file `config/dev.exs` è già configurato, ma verifica che le impostazioni corrispondano:

```bash
# Visualizza configurazione corrente
cat config/dev.exs | grep -A 10 "config :zclassic_explorer, Zclassicex"
```

## Primo Avvio

### Compilare l'Applicazione

```bash
# Compila l'applicazione
MIX_ENV=dev mix compile
```

### Compilare Assets Frontend

```bash
# Entra nella directory assets
cd assets

# Build per sviluppo
npm run deploy

# Torna alla root
cd ..
```

### Avviare il Server

```bash
# Carica le variabili d'ambiente
source .env

# Avvia il server Phoenix
mix phx.server
```

Se tutto è configurato correttamente, dovresti vedere:

```
[info] Running ZclassicExplorerWeb.Endpoint with cowboy 2.9.0 at 0.0.0.0:4000 (http)
[info] Access ZclassicExplorerWeb.Endpoint at http://localhost:4000
[info] Zclassicex RPC client started - connecting to 127.0.0.1:8023
```

### Modalità Interattiva (Consigliata per Debug)

```bash
# Avvia in modalità interattiva
iex -S mix phx.server
```

Questo ti permetterà di eseguire comandi Elixir mentre il server è in esecuzione:

```elixir
# Test connessione RPC
iex> Zclassicex.getinfo()
{:ok, %{"version" => 1000000, ...}}

# Verifica cache
iex> Cachex.stats(:app_cache)

# Lista processi attivi
iex> Supervisor.which_children(ZclassicExplorer.Supervisor)
```

## Verifica Installazione

### Test Browser

1. Apri il browser su: `http://localhost:4000`
2. Dovresti vedere la homepage dell'explorer
3. Verifica che vengano mostrati i blocchi recenti
4. Clicca su un blocco per vederne i dettagli

### Test API

```bash
# Test blockchain info
curl http://localhost:4000/api/blockchain/info | jq

# Test blocchi recenti
curl http://localhost:4000/api/blocks | jq

# Test mempool
curl http://localhost:4000/api/mempool/info | jq
```

### Test RPC Diretto

```bash
# Da terminale separato
iex -S mix

# Nel prompt IEx:
Zclassicex.getblockcount()
# Dovrebbe restituire: {:ok, numero_blocco}

Zclassicex.getnetworkinfo()
# Dovrebbe restituire info sulla rete
```

### Log di Debug

Monitora i log per eventuali errori:

```bash
# In un terminale separato
tail -f log/dev.log
```

## Troubleshooting Installazione

### Problema: "Connection refused" su RPC

```bash
# Verifica che zclassicd sia in esecuzione
ps aux | grep zclassicd

# Verifica la porta RPC
netstat -tulpn | grep 8023

# Test connessione RPC
curl --user zclassic:password --data-binary '{"jsonrpc":"1.0","id":"test","method":"getinfo","params":[]}' -H 'content-type: text/plain;' http://127.0.0.1:8023/
```

### Problema: Dipendenze Elixir non si compilano

```bash
# Pulisci e ricompila
mix deps.clean --all
rm -rf _build
mix deps.get
mix compile
```

### Problema: Errori Node.js/NPM

```bash
# Pulisci cache npm
cd assets
rm -rf node_modules package-lock.json
npm cache clean --force
npm install
cd ..
```

### Problema: Nodo non sincronizzato

L'explorer mostra dati solo dopo la completa sincronizzazione:

```bash
# Controlla progresso
zclassic-cli getblockchaininfo | grep "verificationprogress"

# Se è < 0.999999, il nodo sta ancora sincronizzando
# Attendi il completamento prima di usare l'explorer
```

### Problema: "Secret key base is missing"

```bash
# Genera nuovo secret
mix phx.gen.secret

# Aggiorna .env
export SECRET_KEY_BASE="nuovo_secret_generato"
source .env
```

## Prossimi Passi

Una volta completata l'installazione:

1. Leggi la [Guida al Deployment](DEPLOYMENT.md) per la produzione
2. Consulta la [Documentazione API](API.md) per le integrazioni
3. Vedi [Manutenzione](MAINTENANCE.md) per il monitoring

## Supporto

Per problemi o domande:
- GitHub Issues: https://github.com/yourusername/zclassic-explorer/issues
- Community: https://forum.zclassic.org
