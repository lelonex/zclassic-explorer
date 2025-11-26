# Troubleshooting - Zclassic Explorer

Guida alla risoluzione dei problemi più comuni.

## Problemi di Connessione

### Errore: "Connection refused" su RPC

**Sintomi:** Explorer non si connette al nodo Zclassic

**Diagnosi:**
```bash
# 1. Verifica che zclassicd sia in esecuzione
ps aux | grep zclassicd

# 2. Verifica porta RPC
netstat -tulpn | grep 8023

# 3. Test connessione RPC diretta
curl --user zclassic:password \
  --data-binary '{"jsonrpc":"1.0","id":"test","method":"getinfo","params":[]}' \
  -H 'content-type: text/plain;' \
  http://127.0.0.1:8023/
```

**Soluzioni:**

1. **Nodo non avviato:**
   ```bash
   zclassicd -daemon
   ```

2. **Credenziali errate:**
   ```bash
   # Verifica zclassic.conf
   cat ~/.zclassic/zclassic.conf | grep rpc
   
   # Aggiorna .env con credenziali corrette
   nano .env
   ```

3. **Porta sbagliata:**
   ```bash
   # Default Zclassic: 8023 mainnet, 18023 testnet
   # Verifica in zclassic.conf
   grep rpcport ~/.zclassic/zclassic.conf
   ```

### Errore: "Unauthorized" su RPC

**Causa:** Username/password errati

**Soluzione:**
```bash
# Assicurati che .env corrisponda a zclassic.conf
diff <(grep -E 'rpc(user|password)' ~/.zclassic/zclassic.conf) \
     <(grep -E 'ZCLASSICD_(USERNAME|PASSWORD)' .env)
```

## Problemi di Sincronizzazione

### Nodo non sincronizza

**Diagnosi:**
```bash
zclassic-cli getblockchaininfo

# Verifica:
# - "blocks" dovrebbe aumentare
# - "verificationprogress" dovrebbe avvicinarsi a 1.0
# - "initialblockdownload" dovrebbe essere false quando completo
```

**Soluzioni:**

1. **Peer insufficienti:**
   ```bash
   zclassic-cli getpeerinfo | jq length
   # Dovrebbe essere > 8
   
   # Aggiungi peer manualmente
   zclassic-cli addnode "node_ip:8033" add
   ```

2. **Sync bloccata:**
   ```bash
   zclassic-cli stop
   zclassicd -reindex -daemon
   ```

3. **Corruzione blockchain:**
   ```bash
   zclassic-cli stop
   rm -rf ~/.zclassic/blocks ~/.zclassic/chainstate
   zclassicd -daemon
   # ATTENZIONE: Ri-scarica tutta la blockchain!
   ```

### Explorer mostra dati vecchi

**Causa:** Cache non aggiornata

**Soluzione:**
```elixir
# In IEx console
iex -S mix
iex> Cachex.clear(:app_cache)
{:ok, true}

# Restart explorer
sudo systemctl restart zclassic-explorer
```

## Problemi di Performance

### Explorer lento

**Diagnosi:**
```bash
# 1. Check CPU/Memory
htop

# 2. Check disk I/O
iostat -x 1

# 3. Check network
iftop
```

**Soluzioni:**

1. **High CPU:**
   ```elixir
   # In IEx, identifica processi pesanti
   :observer.start()
   
   # Riduci numero warmers se necessario
   # in lib/zclassic_explorer/application.ex
   ```

2. **High Memory:**
   ```bash
   # Riduci dbcache in zclassic.conf
   nano ~/.zclassic/zclassic.conf
   # dbcache=1024
   
   zclassic-cli stop
   zclassicd -daemon
   ```

3. **Disk I/O alto:**
   ```bash
   # Verifica scritture log
   iotop
   
   # Riduci log level in config/prod.exs
   # level: :warn
   ```

### Query API lente

**Diagnosi:**
```bash
# Check log per query lente
grep "Sent.*[0-9][0-9][0-9][0-9]ms" log/prod.log
```

**Soluzioni:**

1. **RPC timeout:**
   ```elixir
   # In config, aumenta timeout
   config :zclassic_explorer, Zclassicex,
     rpc_timeout: 60_000  # 60 secondi
   ```

2. **Database lento (se usato):**
   ```sql
   -- Ottimizza
   VACUUM ANALYZE;
   REINDEX DATABASE zclassic_explorer_prod;
   
   -- Controlla missing indexes
   SELECT schemaname, tablename, indexdef 
   FROM pg_indexes 
   WHERE schemaname = 'public';
   ```

## Problemi di Compilazione

### Dipendenze Elixir non si compilano

**Errore comune:** `(Mix) Could not compile dependency`

**Soluzioni:**
```bash
# 1. Pulisci tutto
mix deps.clean --all
rm -rf _build deps

# 2. Reinstalla
mix deps.get
mix deps.compile

# 3. Se persiste, forza ricompilazione
mix do deps.clean --all, deps.get, compile --force
```

### Errori Node.js/Webpack

**Soluzioni:**
```bash
cd assets

# 1. Pulisci cache
rm -rf node_modules package-lock.json
npm cache clean --force

# 2. Reinstalla
npm install

# 3. Rebuild
npm run deploy

# 4. Se problema con node-sass:
npm rebuild node-sass
```

### Errore: "openssl-legacy-provider"

**Causa:** Node.js 17+ incompatibilità

**Soluzione:**
```bash
# In assets/package.json
"scripts": {
  "deploy": "NODE_OPTIONS=--openssl-legacy-provider webpack --mode production",
  "watch": "NODE_OPTIONS=--openssl-legacy-provider webpack --mode development --watch"
}
```

## Problemi di Avvio

### Phoenix non si avvia

**Errore:** `(RuntimeError) unable to start endpoint`

**Diagnosi:**
```bash
# Verifica porta disponibile
netstat -tulpn | grep 4000

# Verifica permessi
ls -la /home/zclassic/zclassic-explorer
```

**Soluzioni:**

1. **Porta occupata:**
   ```bash
   # Trova processo
   lsof -i :4000
   
   # Termina o usa porta diversa
   export PORT=4001
   ```

2. **Secret key base mancante:**
   ```bash
   # Genera nuovo
   mix phx.gen.secret
   
   # Aggiungi a .env
   export SECRET_KEY_BASE="generated_key_here"
   source .env
   ```

### Crash all'avvio con indici

**Errore:** `addressindex not enabled`

**Causa:** Indici non abilitati nel nodo

**Soluzione:**
```bash
# Aggiungi a zclassic.conf
nano ~/.zclassic/zclassic.conf
```

```conf
addressindex=1
timestampindex=1
spentindex=1
txindex=1
```

```bash
# Reindex necessario
zclassic-cli stop
zclassicd -reindex -daemon
```

## Problemi di Database

### Errore: "database does not exist"

**Soluzione:**
```bash
# Crea database
MIX_ENV=prod mix ecto.create

# Esegui migrations
MIX_ENV=prod mix ecto.migrate
```

### Migrations fallite

**Soluzione:**
```bash
# Rollback
MIX_ENV=prod mix ecto.rollback

# Ri-esegui
MIX_ENV=prod mix ecto.migrate

# Se persiste, reset (ATTENZIONE: perde dati!)
MIX_ENV=prod mix ecto.drop
MIX_ENV=prod mix ecto.create
MIX_ENV=prod mix ecto.migrate
```

## Problemi di Rete

### Explorer non raggiungibile da internet

**Diagnosi:**
```bash
# 1. Verifica nginx
sudo nginx -t
sudo systemctl status nginx

# 2. Verifica firewall
sudo ufw status

# 3. Test locale
curl -I http://localhost:4000

# 4. Test remoto
curl -I http://your-server-ip
```

**Soluzioni:**

1. **Firewall blocca:**
   ```bash
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   ```

2. **Nginx misconfigured:**
   ```bash
   # Verifica config
   sudo nginx -t
   
   # Riavvia
   sudo systemctl restart nginx
   ```

3. **DNS non configurato:**
   ```bash
   # Verifica DNS
   dig +short zclassicexplorer.com
   # Dovrebbe restituire il tuo IP
   ```

### SSL non funziona

**Diagnosi:**
```bash
# Test certificato
curl -vI https://zclassicexplorer.com

# Verifica certbot
sudo certbot certificates
```

**Soluzioni:**

1. **Certificato scaduto:**
   ```bash
   sudo certbot renew --force-renewal
   sudo systemctl reload nginx
   ```

2. **Certificato non trovato:**
   ```bash
   sudo certbot --nginx -d zclassicexplorer.com
   ```

## Problemi di Logging

### Log troppo grandi

**Soluzione:**
```bash
# Setup log rotation
sudo nano /etc/logrotate.d/zclassic-explorer
```

```
/home/zclassic/zclassic-explorer/log/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
}
```

### Debug log non funzionano

**Soluzione in config/dev.exs:**
```elixir
config :logger, :console,
  level: :debug,  # Cambia da :info a :debug
  format: "$time $metadata[$level] $message\n"
```

## Problemi Specifici

### LiveView non aggiorna

**Causa:** WebSocket non connesso

**Diagnosi:**
```javascript
// In browser console
wscat -c ws://localhost:4000/socket/websocket
```

**Soluzione:**

1. **Nginx config:**
   ```nginx
   location /live {
       proxy_pass http://phoenix;
       proxy_http_version 1.1;
       proxy_set_header Upgrade $http_upgrade;
       proxy_set_header Connection "upgrade";
   }
   ```

2. **Verifica endpoint config:**
   ```elixir
   # config/prod.exs
   config :zclassic_explorer, ZclassicExplorerWeb.Endpoint,
     check_origin: ["//zclassicexplorer.com"]
   ```

### Mempool non si aggiorna

**Diagnosi:**
```bash
# Verifica mempool sul nodo
zclassic-cli getmempoolinfo
```

**Soluzione:**
```elixir
# Restart warmer
# In IEx
iex> Supervisor.restart_child(
  ZclassicExplorer.Supervisor,
  {Cachex, :app_cache}
)
```

## Comandi Utili di Debug

### Elixir/Phoenix

```elixir
# In IEx
:observer.start()                              # GUI monitoring
:sys.get_status(ZclassicExplorerWeb.Endpoint) # Endpoint status
Supervisor.which_children(ZclassicExplorer.Supervisor) # Processi
:erlang.memory()                               # Memory usage
Cachex.stats(:app_cache)                       # Cache stats
```

### System

```bash
# Process monitoring
htop
ps aux | grep beam
ps aux | grep zclassicd

# Network
netstat -tulpn | grep -E '(4000|8023)'
ss -tunlp

# Disk
df -h
du -sh /home/zclassic/.zclassic
iostat -x 1

# Logs
journalctl -u zclassic-explorer -f --since "10 minutes ago"
journalctl -u zclassicd -f
tail -f log/prod.log
```

## Quando Chiedere Aiuto

Se dopo aver provato queste soluzioni il problema persiste:

1. **Raccogli informazioni:**
   ```bash
   # System info
   uname -a
   cat /etc/os-release
   
   # Versions
   elixir --version
   node --version
   zclassic-cli --version
   
   # Logs
   journalctl -u zclassic-explorer -n 100 > explorer.log
   journalctl -u zclassicd -n 100 > node.log
   ```

2. **Crea issue su GitHub:**
   - Descrizione problema
   - Passi per riprodurre
   - Logs rilevanti
   - Info sistema

3. **Community:**
   - Discord/Telegram Zclassic
   - Forum: https://forum.zclassic.org

## Risorse

- [Elixir Forum](https://elixirforum.com)
- [Phoenix Guides](https://hexdocs.pm/phoenix/overview.html)
- [Zclassic GitHub](https://github.com/z-classic/zclassic)
