# Configurazione Nodo Zclassic

Guida dettagliata alla configurazione ottimale di zclassicd per l'utilizzo con l'Explorer.

## Indice

1. [Configurazione Base](#configurazione-base)
2. [Opzioni Avanzate](#opzioni-avanzate)
3. [Indici per l'Explorer](#indici-per-lexplorer)
4. [Performance Tuning](#performance-tuning)
5. [Sicurezza](#sicurezza)
6. [Monitoring](#monitoring)

## Configurazione Base

### File zclassic.conf

Posizione del file: `~/.zclassic/zclassic.conf`

```conf
##
## Configurazione Base Zclassic Node per Explorer
##

# ============================================
# SERVER CONFIGURATION
# ============================================

# Abilita modalità server
server=1

# Esegui come daemon in background
daemon=1

# Ascolta connessioni in entrata
listen=1

# ============================================
# RPC CONFIGURATION
# ============================================

# Abilita server RPC
rpcservertimeout=300

# Credenziali RPC (CAMBIARE!)
rpcuser=zclassic
rpcpassword=CAMBIA_QUESTA_PASSWORD_ORA

# Porta RPC (default per Zclassic mainnet)
rpcport=8023

# Permetti connessioni solo da localhost
rpcallowip=127.0.0.1

# Per connessioni remote (NON RACCOMANDATO senza SSL/VPN):
# rpcallowip=192.168.1.0/24

# Numero massimo di connessioni RPC simultanee
rpcthreads=4

# ============================================
# NETWORK CONFIGURATION
# ============================================

# Numero massimo di connessioni peer
maxconnections=125

# Porta per connessioni P2P (default: 8033 per mainnet)
port=8033

# ============================================
# ADDRESS INDEXING (REQUIRED FOR EXPLORER!)
# ============================================

# IMPORTANTE: Questi indici sono OBBLIGATORI per l'explorer
# Abilitarli richiede re-sync completa se non erano attivi

# Indice degli indirizzi
addressindex=1

# Indice dei timestamp
timestampindex=1

# Indice delle spese (spent outputs)
spentindex=1

# Indice completo delle transazioni
txindex=1

# ============================================
# ZMQ NOTIFICATIONS (OPTIONAL)
# ============================================

# Notifiche real-time per nuovi blocchi e transazioni
# Utile per aggiornamenti live nell'explorer

zmqpubrawblock=tcp://127.0.0.1:28332
zmqpubrawtx=tcp://127.0.0.1:28333
zmqpubhashtx=tcp://127.0.0.1:28334
zmqpubhashblock=tcp://127.0.0.1:28335

# ============================================
# MEMORY POOL CONFIGURATION
# ============================================

# Dimensione massima mempool (MB)
maxmempool=300

# Transazioni orfane massime in cache
maxorphantx=100

# Minimo fee rate per transazioni (ZCL/kB)
minrelaytxfee=0.00001

# ============================================
# PERFORMANCE TUNING
# ============================================

# Cache database (MB) - aumentare per migliori performance
# Raccomandato: 25% della RAM disponibile
dbcache=2048

# Numero di thread per verifica script
par=4

# ============================================
# LOGGING
# ============================================

# Debug log categorie (0=off, 1=on)
debug=0

# Categorie specifiche (se debug=1):
# debug=net
# debug=rpc
# debug=mempool

# Shrink debug log on startup
shrinkdebugfile=1

# ============================================
# TESTNET (se necessario)
# ============================================

# Decommenta per usare testnet invece di mainnet
# testnet=1

# ============================================
# MINING (se applicabile)
# ============================================

# gen=1
# genproclimit=1
```

## Opzioni Avanzate

### Configurazione per Hardware Potente

Se hai un server dedicato con risorse abbondanti:

```conf
# Cache molto grande (8GB RAM disponibile)
dbcache=6144

# Più thread per verifica
par=8

# Più connessioni
maxconnections=250

# Mempool più grande
maxmempool=500

# Buffer più grandi
maxsendbuffer=10000
maxreceivebuffer=10000
```

### Configurazione per Hardware Limitato

Per VPS o macchine con poca RAM:

```conf
# Cache ridotta (2GB RAM disponibile)
dbcache=512

# Meno thread
par=2

# Meno connessioni
maxconnections=50

# Mempool ridotta
maxmempool=100
```

## Indici per l'Explorer

### Perché sono Necessari

Gli indici sono CRITICI per il funzionamento dell'explorer:

- `addressindex=1`: Permette ricerche per indirizzo
- `timestampindex=1`: Permette ricerche temporali
- `spentindex=1`: Traccia output spesi
- `txindex=1`: Indice completo transazioni

### Abilitazione Indici su Nodo Esistente

Se hai un nodo già sincronizzato SENZA questi indici:

```bash
# 1. Ferma il nodo
zclassic-cli stop

# 2. Aggiungi gli indici a zclassic.conf
nano ~/.zclassic/zclassic.conf
# Aggiungi le 4 righe addressindex, timestampindex, spentindex, txindex

# 3. Riavvia con reindex
zclassicd -reindex

# ATTENZIONE: -reindex richiederà diverse ore!
# Monitora il progresso:
tail -f ~/.zclassic/debug.log
```

### Verifica Indici Attivi

```bash
# Controlla che gli indici siano abilitati
zclassic-cli getblockchaininfo | grep -i index

# Test address index
zclassic-cli getaddressbalance '{"addresses": ["t1YourAddressHere"]}'

# Se l'ultimo comando funziona, gli indici sono attivi
```

## Performance Tuning

### Ottimizzazione Disco

```bash
# Se usi SSD, abilita TRIM
sudo fstrim -v /

# Per HDD, aumenta readahead
sudo blockdev --setra 8192 /dev/sda

# Verifica I/O scheduler (deadline è migliore per database)
cat /sys/block/sda/queue/scheduler
echo deadline | sudo tee /sys/block/sda/queue/scheduler
```

### Ottimizzazione Rete

```conf
# In zclassic.conf - aumenta buffer di rete
maxsendbuffer=10000
maxreceivebuffer=10000

# Priorità massima per connessioni
maxuploadtarget=0
```

### Ottimizzazione Memoria

```bash
# Aumenta limiti file aperti
ulimit -n 10000

# Per rendere permanente, aggiungi a /etc/security/limits.conf:
# zclassic soft nofile 10000
# zclassic hard nofile 10000

# Aumenta memory map
sudo sysctl -w vm.max_map_count=262144
# Rendere permanente in /etc/sysctl.conf:
# vm.max_map_count=262144
```

## Sicurezza

### RPC Security

```conf
# SEMPRE usare password forte
rpcpassword=$(openssl rand -base64 32)

# Limitare IP autorizzati
rpcallowip=127.0.0.1

# Considerare RPC su socket Unix invece di TCP:
# rpcconnect=/var/run/zclassic/zclassicd.sock
```

### Firewall

```bash
# Permetti solo P2P port pubblicamente
sudo ufw allow 8033/tcp comment 'Zclassic P2P'

# RPC solo da localhost (già limitato da rpcallowip)
sudo ufw deny 8023/tcp

# Abilita firewall
sudo ufw enable
```

### SSL per RPC (Advanced)

Per connessioni RPC remote sicure:

```bash
# Genera certificati
openssl req -newkey rsa:2048 -nodes -keyout zclassic.key -x509 -days 365 -out zclassic.cert

# Copia in directory zclassic
cp zclassic.{key,cert} ~/.zclassic/

# Aggiungi a zclassic.conf:
# rpcssl=1
# rpcsslcertificatechainfile=/home/user/.zclassic/zclassic.cert
# rpcsslprivatekeyfile=/home/user/.zclassic/zclassic.key
```

## Monitoring

### Script di Monitoraggio

Crea `~/monitor_zclassic.sh`:

```bash
#!/bin/bash

# Colori
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "========================================="
echo "  Zclassic Node Monitor"
echo "========================================="

# Check se il processo è attivo
if pgrep -x zclassicd > /dev/null; then
    echo -e "${GREEN}✓${NC} Daemon is running"
else
    echo -e "${RED}✗${NC} Daemon is NOT running"
    exit 1
fi

# Blockchain info
INFO=$(zclassic-cli getblockchaininfo 2>/dev/null)
if [ $? -eq 0 ]; then
    BLOCKS=$(echo $INFO | jq -r '.blocks')
    HEADERS=$(echo $INFO | jq -r '.headers')
    PROGRESS=$(echo $INFO | jq -r '.verificationprogress')
    SIZE=$(echo $INFO | jq -r '.size_on_disk')
    
    echo -e "${GREEN}✓${NC} RPC connection OK"
    echo ""
    echo "Blocks: $BLOCKS / $HEADERS"
    echo "Sync Progress: $(echo "$PROGRESS * 100" | bc -l | cut -c1-5)%"
    echo "Chain Size: $((SIZE / 1024 / 1024 / 1024)) GB"
else
    echo -e "${RED}✗${NC} Cannot connect to RPC"
    exit 1
fi

# Network info
NET=$(zclassic-cli getnetworkinfo 2>/dev/null)
if [ $? -eq 0 ]; then
    CONNS=$(echo $NET | jq -r '.connections')
    VERSION=$(echo $NET | jq -r '.subversion')
    
    echo "Connections: $CONNS"
    echo "Version: $VERSION"
fi

# Mempool
MEMPOOL=$(zclassic-cli getmempoolinfo 2>/dev/null)
if [ $? -eq 0 ]; then
    SIZE=$(echo $MEMPOOL | jq -r '.size')
    BYTES=$(echo $MEMPOOL | jq -r '.bytes')
    
    echo "Mempool: $SIZE txs ($((BYTES / 1024)) KB)"
fi

echo "========================================="
```

Rendilo eseguibile:

```bash
chmod +x ~/monitor_zclassic.sh

# Esegui
~/monitor_zclassic.sh
```

### Cron Job per Monitoring

```bash
# Aggiungi a crontab
crontab -e

# Controlla ogni 5 minuti e logga
*/5 * * * * ~/monitor_zclassic.sh >> ~/zclassic_monitor.log 2>&1
```

### Systemd Service

Crea `/etc/systemd/system/zclassicd.service`:

```ini
[Unit]
Description=Zclassic Daemon
After=network.target

[Service]
Type=forking
User=zclassic
Group=zclassic
ExecStart=/usr/local/bin/zclassicd -daemon -conf=/home/zclassic/.zclassic/zclassic.conf -datadir=/home/zclassic/.zclassic
ExecStop=/usr/local/bin/zclassic-cli -conf=/home/zclassic/.zclassic/zclassic.conf -datadir=/home/zclassic/.zclassic stop
Restart=on-failure
RestartSec=60
TimeoutStopSec=300

[Install]
WantedBy=multi-user.target
```

Abilita e avvia:

```bash
sudo systemctl daemon-reload
sudo systemctl enable zclassicd
sudo systemctl start zclassicd
sudo systemctl status zclassicd
```

## Backup

### Backup Blockchain (Non Raccomandato)

La blockchain è grande e può essere re-sincronizzata. Backup solo se necessario:

```bash
# Ferma il nodo
zclassic-cli stop

# Backup
tar -czf zclassic_backup_$(date +%Y%m%d).tar.gz ~/.zclassic/

# Riavvia
zclassicd -daemon
```

### Backup Wallet (IMPORTANTE!)

```bash
# Backup del wallet (SE PRESENTE)
zclassic-cli backupwallet /path/to/backup/wallet_backup_$(date +%Y%m%d).dat

# Copia anche la chiave privata
cp ~/.zclassic/wallet.dat /secure/location/
```

## Troubleshooting

### Nodo non si Avvia

```bash
# Controlla log
tail -n 100 ~/.zclassic/debug.log

# Verifica file lock
rm ~/.zclassic/.lock

# Riavvia
zclassicd -daemon
```

### Sync Bloccata

```bash
# Ferma
zclassic-cli stop

# Reindex
zclassicd -reindex -daemon

# O re-sync completa
rm -rf ~/.zclassic/blocks ~/.zclassic/chainstate
zclassicd -daemon
```

### RPC Timeout

```conf
# Aumenta timeout in zclassic.conf
rpcservertimeout=600
```

## Risorse

- [Zclassic GitHub](https://github.com/z-classic/zclassic)
- [Bitcoin RPC API](https://developer.bitcoin.org/reference/rpc/) - Molti comandi sono compatibili
- [Community Forum](https://forum.zclassic.org)
