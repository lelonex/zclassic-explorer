# Zclassic Explorer

A modern and comprehensive blockchain explorer for Zclassic (ZCL), built with Phoenix Framework and Elixir.

## 🌟 Features

- **Real-time Blockchain Exploration**: View blocks, transactions and addresses
- **Mempool Monitoring**: Monitor unconfirmed transactions
- **Network Statistics**: Network stats including hashrate, difficulty and connected nodes
- **Address Tracking**: Track balance and transactions for transparent and shielded addresses
- **Responsive UI**: Optimized interface for desktop and mobile
- **Real-time Updates**: Live updates via Phoenix LiveView
- **RESTful API**: API for external integrations

## 📋 Requirements

- **Elixir**: >= 1.7
- **Erlang/OTP**: >= 22
- **Node.js**: >= 14.x
- **PostgreSQL**: >= 12 (optional)
- **Zclassic Daemon (zclassicd)**: Latest version

## 🚀 Quick Installation

```bash
# 1. Clone repository
git clone https://github.com/lelonex/zclassic-explorer.git
cd zclassic-explorer

# 2. Install dependencies
mix deps.get
cd assets && npm install && cd ..

# 3. Configure environment variables
cp .env.example .env
# Edit .env with your settings

# 4. Start explorer
source .env
mix phx.server
```

Visit [`localhost:4000`](http://localhost:4000)

## 📚 Complete Documentation

- [Installation Guide](docs/INSTALLATION.md) - Detailed installation and configuration
- [Zclassic Node Setup](docs/NODE_SETUP.md) - Setup zclassicd node
- [API Reference](docs/API.md) - Complete API documentation
- [Deployment](docs/DEPLOYMENT.md) - Production deployment
- [Maintenance](docs/MAINTENANCE.md) - Maintenance and monitoring
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues resolution

## 🔧 Basic Configuration

Configure the `.env` file:

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
# With Docker Compose
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

## 🛠 Development

```bash
# Tests
mix test

# Format
mix format

# Code analysis
mix credo
```

## 📄 License

Apache License 2.0

## 🙏 Credits

Based on original work by Nighthawk Apps for Zcash Explorer.
Adapted for Zclassic by the community.

---

Made with ❤️ for the Zclassic Community
