# Deployment in Produzione - Zclassic Explorer

Guida completa per il deployment dell'explorer in ambiente di produzione.

## Preparazione Server

### Requisiti Hardware Produzione

- **CPU**: 4+ cores (8+ raccomandato)
- **RAM**: 16GB minimo, 32GB raccomandato
- **Storage**: 100GB+ SSD
- **Network**: 100Mbps+, IP statico

### Setup Iniziale Server

```bash
# Update sistema
sudo apt update && sudo apt upgrade -y

# Installa dependencies
sudo apt install -y build-essential git curl wget \
  postgresql postgresql-contrib nginx certbot \
  python3-certbot-nginx fail2ban ufw htop

# Crea utente dedicato
sudo adduser zclassic
sudo usermod -aG sudo zclassic
su - zclassic
```

### Sicurezza Base

```bash
# Firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8033/tcp  # Zclassic P2P
sudo ufw enable

# Fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Disable root SSH
sudo nano /etc/ssh/sshd_config
# PermitRootLogin no
# PasswordAuthentication no  # Solo key-based auth
sudo systemctl restart sshd
```

## Installazione Produzione

### 1. Installa Zclassic Node

```bash
# Come utente zclassic
cd ~
git clone https://github.com/z-classic/zclassic.git
cd zclassic
./zcutil/build.sh -j$(nproc)

# Copia binari
sudo cp src/zclassicd src/zclassic-cli /usr/local/bin/

# Configura
mkdir -p ~/.zclassic
nano ~/.zclassic/zclassic.conf
```

Configurazione produzione `zclassic.conf`:

```conf
server=1
daemon=1
listen=1
addressindex=1
timestampindex=1
spentindex=1
txindex=1
rpcuser=zclassic_prod
rpcpassword=$(openssl rand -base64 32)
rpcport=8023
rpcallowip=127.0.0.1
maxconnections=250
dbcache=4096
par=4
maxmempool=500
```

### 2. Systemd per Zclassicd

```bash
sudo nano /etc/systemd/system/zclassicd.service
```

```ini
[Unit]
Description=Zclassic Daemon
After=network.target

[Service]
Type=forking
User=zclassic
Group=zclassic
ExecStart=/usr/local/bin/zclassicd -daemon
ExecStop=/usr/local/bin/zclassic-cli stop
Restart=on-failure
RestartSec=60
TimeoutStopSec=300
KillMode=process

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable zclassicd
sudo systemctl start zclassicd
```

### 3. Installa Explorer

```bash
cd /home/zclassic
git clone https://github.com/yourusername/zclassic-explorer.git
cd zclassic-explorer

# Dependencies
mix local.hex --force
mix local.rebar --force
mix deps.get --only prod
MIX_ENV=prod mix compile

cd assets
npm install
npm run deploy
cd ..

# Digest assets
MIX_ENV=prod mix phx.digest
```

### 4. Configurazione Produzione

```bash
# Crea .env per produzione
nano /home/zclassic/zclassic-explorer/.env.prod
```

```bash
export MIX_ENV=prod
export SECRET_KEY_BASE=$(mix phx.gen.secret)
export EXPLORER_HOSTNAME=zclassicexplorer.com
export EXPLORER_SCHEME=https
export EXPLORER_PORT=443
export ZCLASSIC_NETWORK=mainnet
export ZCLASSICD_HOSTNAME=127.0.0.1
export ZCLASSICD_PORT=8023
export ZCLASSICD_USERNAME=zclassic_prod
export ZCLASSICD_PASSWORD=your_password_here
export PORT=4000
```

### 5. Systemd per Explorer

```bash
sudo nano /etc/systemd/system/zclassic-explorer.service
```

```ini
[Unit]
Description=Zclassic Explorer
After=network.target zclassicd.service
Requires=zclassicd.service

[Service]
Type=simple
User=zclassic
Group=zclassic
WorkingDirectory=/home/zclassic/zclassic-explorer
EnvironmentFile=/home/zclassic/zclassic-explorer/.env.prod
ExecStart=/usr/bin/mix phx.server
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=zclassic-explorer

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable zclassic-explorer
sudo systemctl start zclassic-explorer
```

## Nginx Reverse Proxy

### Configurazione Base

```bash
sudo nano /etc/nginx/sites-available/zclassic-explorer
```

```nginx
upstream phoenix {
    server 127.0.0.1:4000;
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name zclassicexplorer.com www.zclassicexplorer.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name zclassicexplorer.com www.zclassicexplorer.com;

    # SSL certificates (configurati dopo certbot)
    ssl_certificate /etc/letsencrypt/live/zclassicexplorer.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/zclassicexplorer.com/privkey.pem;

    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # Gzip
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/javascript application/json;

    # Static files
    location ~ ^/(css|js|images|fonts)/ {
        root /home/zclassic/zclassic-explorer/priv/static;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Phoenix app
    location / {
        proxy_pass http://phoenix;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # WebSocket for LiveView
    location /live {
        proxy_pass http://phoenix;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_read_timeout 86400;
    }

    # Health check
    location /health {
        access_log off;
        return 200 "OK\n";
        add_header Content-Type text/plain;
    }
}
```

```bash
# Abilita configurazione
sudo ln -s /etc/nginx/sites-available/zclassic-explorer /etc/nginx/sites-enabled/

# Test configurazione
sudo nginx -t

# Restart nginx
sudo systemctl restart nginx
```

## SSL con Let's Encrypt

```bash
# Ottieni certificato
sudo certbot --nginx -d zclassicexplorer.com -d www.zclassicexplorer.com

# Auto-renewal è già configurato, test:
sudo certbot renew --dry-run
```

## Database Produzione (Opzionale)

Se usi PostgreSQL:

```bash
# Setup PostgreSQL
sudo -u postgres psql << EOF
CREATE USER zclassic_prod WITH PASSWORD 'secure_password';
CREATE DATABASE zclassic_explorer_prod OWNER zclassic_prod;
GRANT ALL PRIVILEGES ON DATABASE zclassic_explorer_prod TO zclassic_prod;
EOF

# In .env.prod
export DATABASE_URL="postgresql://zclassic_prod:secure_password@localhost/zclassic_explorer_prod"

# Migrate
MIX_ENV=prod mix ecto.create
MIX_ENV=prod mix ecto.migrate
```

## Monitoring Produzione

### Logging Centralizzato

```bash
# Tutti i log vanno in journald
journalctl -u zclassic-explorer -f
journalctl -u zclassicd -f

# Per salvare in file
sudo nano /etc/systemd/journald.conf
# Storage=persistent
# MaxRetentionSec=7day
sudo systemctl restart systemd-journald
```

### Monit per Auto-restart

```bash
sudo apt install monit
sudo nano /etc/monit/monitrc
```

```
set daemon 120
set log /var/log/monit.log

check process zclassicd with pidfile /home/zclassic/.zclassic/zclassicd.pid
  start program = "/bin/systemctl start zclassicd"
  stop program = "/bin/systemctl stop zclassicd"
  if failed port 8023 type tcp for 3 cycles then restart
  if 5 restarts within 5 cycles then timeout

check process zclassic_explorer matching "beam.smp.*zclassic_explorer"
  start program = "/bin/systemctl start zclassic-explorer"
  stop program = "/bin/systemctl stop zclassic-explorer"
  if failed port 4000 type tcp for 3 cycles then restart

check host zclassic_web with address zclassicexplorer.com
  if failed port 443 protocol https for 3 cycles then alert
```

## Backup Strategy

### Script Backup Automatico

```bash
nano ~/backup.sh
```

```bash
#!/bin/bash
BACKUP_DIR="/backup/zclassic"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup configurazione
tar -czf $BACKUP_DIR/config_$DATE.tar.gz \
  /home/zclassic/zclassic-explorer/.env.prod \
  /home/zclassic/zclassic-explorer/config/ \
  /home/zclassic/.zclassic/zclassic.conf \
  /etc/nginx/sites-available/zclassic-explorer

# Backup database se presente
if [ -n "$DATABASE_URL" ]; then
  pg_dump zclassic_explorer_prod | gzip > $BACKUP_DIR/db_$DATE.sql.gz
fi

# Cleanup old backups (>30 giorni)
find $BACKUP_DIR -mtime +30 -delete

# Upload to remote (opzionale)
# rsync -avz $BACKUP_DIR/ user@backup-server:/backups/zclassic/
```

```bash
chmod +x ~/backup.sh

# Cron per backup giornaliero
crontab -e
# 0 3 * * * /home/zclassic/backup.sh >> /var/log/backup.log 2>&1
```

## Performance Tuning

### Kernel Parameters

```bash
sudo nano /etc/sysctl.conf
```

```
# Network performance
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216

# File descriptors
fs.file-max=65536

# Swap
vm.swappiness=10
```

```bash
sudo sysctl -p
```

### Limits

```bash
sudo nano /etc/security/limits.conf
```

```
zclassic soft nofile 65536
zclassic hard nofile 65536
```

## Zero-Downtime Deployment

Per aggiornamenti senza downtime:

```bash
# Script deploy.sh
#!/bin/bash
cd /home/zclassic/zclassic-explorer

# Pull updates
git pull origin main

# Update deps
mix deps.get --only prod
cd assets && npm install && cd ..

# Compile
MIX_ENV=prod mix compile
cd assets && npm run deploy && cd ..
MIX_ENV=prod mix phx.digest

# Hot reload (se configurato) oppure restart
sudo systemctl reload zclassic-explorer
# O: sudo systemctl restart zclassic-explorer
```

## Disaster Recovery

### Ripristino Completo

```bash
# 1. Reinstalla OS
# 2. Setup utente zclassic
# 3. Installa software base
# 4. Ripristina backup
cd /backup/zclassic
tar -xzf config_latest.tar.gz -C /

# 5. Reinstalla zclassic node
# 6. Avvia servizi
sudo systemctl start zclassicd
sudo systemctl start zclassic-explorer

# 7. Ripristina DB se presente
gunzip < db_latest.sql.gz | psql zclassic_explorer_prod
```

## Checklist Go-Live

Prima del lancio pubblico:

- [ ] SSL configurato e funzionante
- [ ] Firewall configurato
- [ ] Monitoring attivo
- [ ] Backup automatici configurati
- [ ] Limiti rate configurati
- [ ] Log rotation configurato
- [ ] Test load con tool come `wrk` o `ab`
- [ ] DNS configurato correttamente
- [ ] Health check funzionanti
- [ ] Documentazione completa per team

## Post-Launch

- Monitor attentamente primi giorni
- Verifica metriche performance
- Configura alert per downtime
- Prepara runbook per incidenti comuni

## Risorse

- [Phoenix Deployment Guide](https://hexdocs.pm/phoenix/deployment.html)
- [Nginx Performance](https://www.nginx.com/blog/tuning-nginx/)
- [Let's Encrypt](https://letsencrypt.org/getting-started/)
