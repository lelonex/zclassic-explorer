# Zclassic Explorer

A modern and comprehensive blockchain explorer for Zclassic (ZCL), built with Phoenix Framework and Elixir.

## 🌟 Features

- **Real-time Blockchain Exploration**: View blocks, transactions and addresses
- **Mempool Monitoring**: Monitor unconfirmed transactions in real-time
- **Network Statistics**: Live network stats including hashrate, difficulty and connected nodes
- **Address Tracking**: Track balance and transactions for transparent and shielded addresses
- **Responsive UI**: Modern, dark-mode enabled interface optimized for desktop and mobile
- **Real-time Updates**: Live updates via Phoenix LiveView WebSockets
- **Payment Disclosure**: Support for payment disclosure verification
- **Viewing Key Support**: Decrypt shielded transaction details with viewing keys
- **Market Analysis**: Dedicated market page with TradingView advanced chart widget
- **Price Ticker**: Real-time ZCL price display with 24h change indicator
- **Dark/Light Theme**: Toggle between dark and light themes with persistent storage
- **Professional Branding**: Updated logo and favicon from Zclassic official sources
- **Extended Search**: Wide search bar for efficient block/transaction/address lookup

## 📋 Requirements

### System Requirements
- **Elixir**: >= 1.14.0
- **Erlang/OTP**: >= 24.0
- **Node.js**: >= 14.x (for asset compilation)
- **PostgreSQL**: >= 12 (optional, for caching)
- **Zclassic Daemon (zclassicd)**: >= 2.1.1

### System Packages
```bash
# Ubuntu/Debian
sudo apt-get install -y erlang-os-mon inotify-tools imagemagick

# Arch Linux
sudo pacman -S erlang inotify-tools imagemagick
```

## 📦 Dependencies

### Elixir/Phoenix Dependencies
- **phoenix** (~> 1.6) - Web framework
- **phoenix_live_view** (~> 0.17.9) - Real-time UI updates
- **phoenix_html** (~> 3.2) - HTML rendering
- **plug_cowboy** (~> 2.0) - HTTP server
- **jason** (~> 1.0) - JSON encoding/decoding
- **httpoison** (~> 1.8) - HTTP client for RPC calls
- **cachex** (~> 3.3) - In-memory caching
- **timex** (~> 3.0) - Date/time manipulation
- **phoenix_live_dashboard** (~> 0.6.5) - Monitoring dashboard
- **telemetry_metrics** (~> 0.6.1) - Performance metrics
- **eqrcode** (~> 0.1.8) - QR code generation
- **sizeable** (~> 1.0) - Human-readable file sizes

### Frontend Dependencies
- **webpack** (4.46.0) - Asset bundling
- **postcss** - CSS processing
- **tailwindcss** - Utility-first CSS framework
- **@fontsource/inter** - Inter font family

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

## ✨ Recent Improvements

### UI/UX Enhancements
- **Homepage Optimization**: Fixed and styled Recent Blocks and Recent Transactions tables with proper caching
- **Navigation Improvements**: Extended search bar (max-width 4xl), improved menu responsiveness
- **Header Refinement**: Added professional Zclassic logo from official sources, positioned theme toggle on the right
- **Footer Enhancement**: Replaced generic icon with Zclassic logo for Official Website link
- **Mobile Responsiveness**: Fixed mobile menu closing behavior on navigation

### New Features
- **Market Analysis Page** (`/market`): Dedicated page with TradingView advanced chart widget showing CRYPTO:ZCLUSD
- **Price Badge Enhancement**: Made clickable to navigate to market page, displays real-time price with 24h change indicator
- **Theme Toggle**: Persistent dark/light mode toggle with localStorage support

### Technical Improvements
- **Cache Warmers**: Enabled 15-second interval warmers for blocks, transactions, and network metrics
- **Map-based Data Flow**: Converted all template field accesses to map notation for reliability
- **External Asset Loading**: Logo and favicon loaded from https://zclassic.org for consistency
- **Template Fixes**: Corrected HEEX syntax in root template for proper compilation

## 📖 Documentation

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
