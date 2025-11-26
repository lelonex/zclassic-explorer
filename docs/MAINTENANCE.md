# Manutenzione e Monitoring - Zclassic Explorer

Guida completa per la manutenzione quotidiana e il monitoring del sistema.

## Monitoring Quotidiano

### Check Rapido Sistema

Script giornaliero `~/check_system.sh`:

```bash
#!/bin/bash

echo "=== ZCLASSIC EXPLORER HEALTH CHECK ==="
echo "Timestamp: $(date)"
echo ""

# 1. Check Zclassic Node
echo "1. Zclassic Node Status"
if pgrep -x zclassicd > /dev/null; then
    echo "✓ zclassicd running"
    BLOCKS=$(zclassic-cli getblockcount)
    CONNECTIONS=$(zclassic-cli getconnectioncount)
    MEMPOOL=$(zclassic-cli getmempoolinfo | jq -r '.size')
    echo "  Blocks: $BLOCKS"
    echo "  Connections: $CONNECTIONS"
    echo "  Mempool: $MEMPOOL txs"
else
    echo "✗ zclassicd NOT running - CRITICAL!"
    exit 1
fi

# 2. Check Explorer Process
echo ""
echo "2. Explorer Status"
if pgrep -f "beam.smp.*zclassic_explorer" > /dev/null; then
    echo "✓ Explorer running"
    # Test HTTP response
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:4000)
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✓ HTTP responding ($HTTP_CODE)"
    else
        echo "✗ HTTP error ($HTTP_CODE)"
    fi
else
    echo "✗ Explorer NOT running - CRITICAL!"
    exit 1
fi

# 3. Check Disk Space
echo ""
echo "3. Disk Space"
DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
echo "  Root: ${DISK_USAGE}% used"
if [ "$DISK_USAGE" -gt 90 ]; then
    echo "✗ WARNING: Disk almost full!"
fi

# 4. Check Memory
echo ""
echo "4. Memory Usage"
free -h | grep Mem

# 5. Check Load Average
echo ""
echo "5. System Load"
uptime

echo ""
echo "=== END CHECK ==="
```

### Monitoring Automatico con Prometheus + Grafana (Opzionale)

#### Installazione Prometheus

```bash
# Download Prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.40.0/prometheus-2.40.0.linux-amd64.tar.gz
tar xvfz prometheus-*.tar.gz
cd prometheus-*

# Configurazione prometheus.yml
cat > prometheus.yml << EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'zclassic_explorer'
    static_configs:
      - targets: ['localhost:4000']
  
  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']
EOF

# Avvia Prometheus
./prometheus --config.file=prometheus.yml &
```

## Manutenzione Database (se usato)

### Pulizia e Ottimizzazione

```bash
# Connettiti al database
psql -U zclassic -d zclassic_explorer_prod

# Analizza tabelle
ANALYZE;

# Vacuum per recuperare spazio
VACUUM ANALYZE;

# Reindex se necessario
REINDEX DATABASE zclassic_explorer_prod;
```

### Backup Automatico

Script `~/backup_db.sh`:

```bash
#!/bin/bash

BACKUP_DIR="/backup/zclassic_explorer"
DATE=$(date +%Y%m%d_%H%M%S)
DB_NAME="zclassic_explorer_prod"

# Crea directory backup
mkdir -p $BACKUP_DIR

# Backup
pg_dump $DB_NAME | gzip > "$BACKUP_DIR/db_backup_$DATE.sql.gz"

# Mantieni solo ultimi 7 giorni
find $BACKUP_DIR -name "db_backup_*.sql.gz" -mtime +7 -delete

echo "Backup completato: db_backup_$DATE.sql.gz"
```

Aggiungi a cron:

```bash
# Backup giornaliero alle 2 AM
0 2 * * * /home/zclassic/backup_db.sh >> /var/log/zclassic_backup.log 2>&1
```

## Manutenzione Nodo Zclassic

### Pulizia Log

```bash
# Il debug.log può crescere molto
# Tronca periodicamente (zclassic.conf: shrinkdebugfile=1 fa questo automaticamente)

# Manuale:
zclassic-cli stop
echo "" > ~/.zclassic/debug.log
zclassicd -daemon
```

### Controllo Integrità Blockchain

```bash
# Verifica integrità
zclassic-cli verifychain

# Se ci sono problemi, reindex:
zclassic-cli stop
zclassicd -reindex -daemon
```

## Gestione Log Explorer

### Rotazione Log

Configurazione in `config/prod.exs`:

```elixir
config :logger,
  backends: [{LoggerFileBackend, :info_log}]

config :logger, :info_log,
  path: "log/info.log",
  level: :info,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  rotate: %{max_bytes: 10_485_760, keep: 5}  # 10MB, mantieni 5 file
```

### Analisi Log

```bash
# Errori nelle ultime 24h
grep ERROR log/prod.log | tail -100

# Richieste più lente
grep "Sent.*in [0-9][0-9][0-9]ms" log/prod.log

# Pattern di errori
awk '/ERROR/ {print $NF}' log/prod.log | sort | uniq -c | sort -rn
```

## Performance Tuning

### Monitorare Performance

```bash
# In IEx console
iex -S mix
```

```elixir
# Check processi
:observer.start()

# Memory usage
:erlang.memory()

# Process count
:erlang.system_info(:process_count)

# Cachex stats
Cachex.stats(:app_cache)

# Clear cache se necessario
Cachex.clear(:app_cache)
```

### Ottimizzazione Cache

Se noti problemi di memoria:

```elixir
# In lib/zclassic_explorer/application.ex
# Riduci frequenza warmers o disabilita alcuni

warmers: [
  warmer(module: ZclassicExplorer.Blocks.BlockWarmer, state: {}),
  # Commenta warmers non essenziali
  # warmer(module: ZclassicExplorer.Metrics.MetricsWarmer, state: {}),
]
```

## Aggiornamenti

### Aggiornare Explorer

```bash
# 1. Backup configurazione
cp .env .env.backup
cp -r config config.backup

# 2. Pull updates
git fetch origin
git pull origin main

# 3. Update dependencies
mix deps.get
cd assets && npm install && cd ..

# 4. Recompile
MIX_ENV=prod mix compile
cd assets && npm run deploy && cd ..

# 5. Migrate database (se necessario)
MIX_ENV=prod mix ecto.migrate

# 6. Restart
sudo systemctl restart zclassic-explorer
```

### Aggiornare Nodo Zclassic

```bash
# 1. Backup wallet
zclassic-cli backupwallet /backup/wallet_$(date +%Y%m%d).dat

# 2. Stop node
zclassic-cli stop

# 3. Update binaries
cd ~/zclassic
git pull
./zcutil/build.sh -j$(nproc)

# 4. Restart
zclassicd -daemon

# 5. Verifica
zclassic-cli getinfo
```

## Troubleshooting Comune

### Explorer Non Risponde

```bash
# 1. Check processi
ps aux | grep beam

# 2. Check port
netstat -tulpn | grep 4000

# 3. Check log
tail -f log/prod.log

# 4. Restart
sudo systemctl restart zclassic-explorer
```

### Nodo RPC Non Risponde

```bash
# 1. Test RPC
curl --user zclassic:password \
  --data-binary '{"jsonrpc":"1.0","method":"getinfo"}' \
  -H 'content-type: text/plain;' \
  http://127.0.0.1:8023/

# 2. Check zclassic.conf
cat ~/.zclassic/zclassic.conf | grep rpc

# 3. Restart node
zclassic-cli stop
zclassicd -daemon
```

### High Memory Usage

```bash
# 1. Check top consumers
ps aux --sort=-%mem | head

# 2. Restart explorer con cache ridotta
# Modifica config e restart

# 3. Se è il nodo:
# Riduci dbcache in zclassic.conf
zclassic-cli stop
nano ~/.zclassic/zclassic.conf  # dbcache=1024
zclassicd -daemon
```

### Slow Response Times

```elixir
# In IEx, check processi bloccati
:sys.get_status(ZclassicExplorerWeb.Endpoint)

# Check cache hit rate
Cachex.stats(:app_cache)
# Se hit rate basso, aumenta TTL warmers
```

## Alert Setup

### Email Alerts con Monit

```bash
# Installa monit
sudo apt install monit

# Configura /etc/monit/conf.d/zclassic.conf
sudo nano /etc/monit/conf.d/zclassic.conf
```

```
# Check zclassicd
check process zclassicd with pidfile /home/zclassic/.zclassic/zclassicd.pid
  start program = "/usr/local/bin/zclassicd -daemon"
  stop program = "/usr/local/bin/zclassic-cli stop"
  if failed port 8023 type tcp for 3 cycles then restart
  if 5 restarts within 5 cycles then timeout
  alert your-email@example.com

# Check explorer
check process zclassic_explorer matching "beam.smp.*zclassic_explorer"
  start program = "/bin/systemctl start zclassic-explorer"
  stop program = "/bin/systemctl stop zclassic-explorer"
  if failed port 4000 type tcp for 3 cycles then restart
  alert your-email@example.com
```

```bash
# Abilita e avvia
sudo monit reload
sudo systemctl enable monit
sudo systemctl start monit
```

## Best Practices

### Checklist Settimanale

- [ ] Verificare spazio disco
- [ ] Controllare log per errori
- [ ] Backup database
- [ ] Verificare sincronizzazione nodo
- [ ] Test endpoint API
- [ ] Review performance metrics

### Checklist Mensile

- [ ] Aggiornamenti sicurezza sistema
- [ ] Aggiornare dipendenze explorer
- [ ] Verificare aggiornamenti nodo Zclassic
- [ ] Ottimizzare database
- [ ] Review e cleanup log vecchi
- [ ] Test disaster recovery

### Documentare Incidenti

Mantieni un log degli incidenti in `~/incidents.log`:

```
[2024-01-15 14:30] Explorer down - causa: OOM, fix: restart + aumentato RAM
[2024-01-20 09:15] Nodo disconnesso - causa: firewall, fix: riconfigurato ufw
```

## Risorse Utili

- [Phoenix Deployment](https://hexdocs.pm/phoenix/deployment.html)
- [Elixir Performance](https://www.erlang.org/doc/efficiency_guide/users_guide.html)
- [Zclassic GitHub](https://github.com/z-classic/zclassic)

## Supporto

Per assistenza: https://github.com/yourusername/zclassic-explorer/issues
