# Zclassic Explorer Documentation

Complete documentation index for the project.

## 📚 Documentation Overview

This directory contains all necessary documentation to install, configure, deploy and maintain Zclassic Explorer.

## 📖 Available Documents

### 1. [INSTALLATION.md](INSTALLATION.md) - Installation Guide
**For:** Developers installing for the first time  
**Content:**
- System prerequisites
- Zclassic daemon installation
- Explorer installation
- Initial configuration
- First startup
- Installation verification

### 2. [NODE_SETUP.md](NODE_SETUP.md) - Zclassic Node Configuration
**For:** Operators configuring the node  
**Content:**
- Basic zclassicd configuration
- Advanced options
- Indexes for Explorer (MANDATORY)
- Performance tuning
- RPC security
- Node monitoring

### 3. [API.md](API.md) - API Documentation
**For:** Developers integrating with Explorer  
**Content:**
- Complete REST endpoints
- Request/response format
- Usage examples
- WebSocket API
- Rate limiting
- Error codes

### 4. [DEPLOYMENT.md](DEPLOYMENT.md) - Production Deployment
**For:** DevOps deploying to production  
**Content:**
- Production server setup
- Nginx configurations
- SSL/TLS with Let's Encrypt
- Systemd services
- Backup strategy
- Performance tuning
- Disaster recovery

### 5. [MAINTENANCE.md](MAINTENANCE.md) - Maintenance and Monitoring
**For:** Operators for daily maintenance  
**Content:**
- Daily system checks
- Monitoring setup
- Log management
- Updates
- Best practices
- Alert configuration

### 6. [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Problem Resolution
**For:** Everyone, to solve common issues  
**Content:**
- Connection problems
- Synchronization issues
- Performance issues
- Compilation errors
- Debug utilities

## 🚀 Quick Start

### For Developers (Local Environment)

```bash
# 1. Read prerequisites
cat docs/INSTALLATION.md | grep -A 20 "Prerequisites"

# 2. Install and configure node
# Follow: docs/NODE_SETUP.md

# 3. Install explorer
git clone https://github.com/lelonex/zclassic-explorer.git
cd zclassic-explorer
mix deps.get
cd assets && npm install && cd ..

# 4. Configure
cp .env.example .env
# Edit .env

# 5. Start
source .env
mix phx.server
```

### For Production

```bash
# Read DEPLOYMENT.md completely before starting!
# THEN follow step-by-step:

# 1. Server preparation (DEPLOYMENT.md "Server Preparation")
# 2. Component installation (DEPLOYMENT.md "Production Installation")
# 3. Nginx and SSL configuration (DEPLOYMENT.md "Nginx Reverse Proxy")
# 4. Monitoring setup (MAINTENANCE.md "Production Monitoring")
# 5. Backup configuration (DEPLOYMENT.md "Backup Strategy")
```

## 🔍 How to Use This Documentation

### Scenario: First Installation

1. ✅ Read **INSTALLATION.md** completely
2. ✅ Follow **NODE_SETUP.md** to configure zclassicd
3. ✅ Verify indexes are enabled (CRITICAL!)
4. ✅ Complete installation with INSTALLATION.md
5. ✅ If problems, consult **TROUBLESHOOTING.md**

### Scenario: Production Deploy

1. ✅ First complete local installation (see above)
2. ✅ Read **DEPLOYMENT.md** completely
3. ✅ Prepare checklist from "Go-Live Checklist" section
4. ✅ Execute deploy following step-by-step
5. ✅ Setup monitoring from **MAINTENANCE.md**
6. ✅ Test everything before go-live

### Scenario: API Integration

1. ✅ Read **API.md**
2. ✅ Identify required endpoints
3. ✅ Test with curl/Postman
4. ✅ Implement in your code
5. ✅ Consider rate limiting

### Scenario: Production Problem

1. ✅ Identify symptoms
2. ✅ Search in **TROUBLESHOOTING.md**
3. ✅ Collect logs (commands in TROUBLESHOOTING)
4. ✅ Apply suggested solution
5. ✅ If persists, open GitHub issue with collected info

## 🛠 Tools and Utilities

### Useful Scripts Included

```
scripts/
├── convert_to_zclassic.sh  # Conversion from Zcash (ALREADY EXECUTED)
└── (other scripts to create)
```

### Quick Commands

```bash
# Complete health check
~/check_system.sh  # See MAINTENANCE.md

# Restart everything
sudo systemctl restart zclassicd
sudo systemctl restart zclassic-explorer

# Real-time logs
journalctl -u zclassic-explorer -f

# Verify node sync
zclassic-cli getblockchaininfo | grep -E "blocks|verificationprogress"

# Test RPC
curl --user zclassic:password --data-binary \
  '{"jsonrpc":"1.0","method":"getinfo","params":[]}' \
  -H 'content-type: text/plain;' http://127.0.0.1:8023/
```

## 📊 Project Structure

```
zclassic-explorer/
├── assets/              # Frontend (JS, CSS)
├── config/              # Configurations
│   ├── config.exs      # Base config
│   ├── dev.exs         # Development
│   ├── prod.exs        # Production
│   └── releases.exs    # Release config
├── docs/               # ← YOU ARE HERE
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

## 🔗 Useful Links

### External Documentation

- **Elixir**: https://elixir-lang.org/docs.html
- **Phoenix Framework**: https://hexdocs.pm/phoenix/overview.html
- **Zclassic**: https://github.com/z-classic/zclassic
- **Nginx**: https://nginx.org/en/docs/

### Community

- **GitHub Issues**: https://github.com/lelonex/zclassic-explorer/issues
- **Zclassic Forum**: https://forum.zclassic.org

## ❓ FAQ

### Q: Do I need to use PostgreSQL?
**A:** No, it's optional. The explorer can work with in-memory cache only.

### Q: How long does initial sync take?
**A:** Depends on hardware and connection. Generally 6-24 hours for complete mainnet.

### Q: Can I use a remote node?
**A:** Yes, but not recommended. Configure RPC over SSL and appropriate firewall.

### Q: How do I update the explorer?
**A:** See MAINTENANCE.md "Updates" section.

### Q: Are indexes really mandatory?
**A:** YES! Without indexes the explorer cannot function. See NODE_SETUP.md.

### Q: Can I run on Raspberry Pi?
**A:** Theoretically yes, but sync will be very slow. Minimum RPi 4 with 8GB RAM.

### Q: How do I contribute to the project?
**A:** Fork, modify, test, Pull Request. See README.md "Contributing" section.

## 📝 Glossary

- **RPC**: Remote Procedure Call - interface to communicate with zclassicd
- **Mempool**: Memory pool - unconfirmed transactions
- **UTXO**: Unspent Transaction Output - unspent outputs
- **LiveView**: Phoenix technology for real-time updates
- **Warmer**: Process that pre-loads cache
- **Mix**: Build tool for Elixir
- **OTP**: Open Telecom Platform - Erlang framework

## 🆘 Support

### Order to Get Help

1. **Search this documentation** - Answer is probably here
2. **Check TROUBLESHOOTING.md** - Common problems solved
3. **Search existing issues** - Someone else might have had the problem
4. **Ask in community** - Forum/Discord
5. **Open new issue** - With all required info

### Info to Include in Issue

```bash
# Collect this info
elixir --version
node --version
zclassic-cli getinfo
cat /etc/os-release
journalctl -u zclassic-explorer -n 50
journalctl -u zclassicd -n 50
```

## 🎯 Best Practices

### Development

- ✅ Always use `source .env` before starting
- ✅ Test locally before commit
- ✅ Follow Elixir style guide: `mix format`
- ✅ Write tests for new features

### Production

- ✅ **NEVER** commit credentials
- ✅ Regular backups (automated)
- ✅ Active monitoring 24/7
- ✅ Keep dependencies updated
- ✅ Review security advisories

### Operations

- ✅ Document every change
- ✅ Test on staging before production
- ✅ Keep runbook updated
- ✅ Plan for disaster recovery

## 📅 Recommended Maintenance

### Daily
- Check system health
- Review error logs
- Verify sync status

### Weekly
- Review performance metrics
- Check disk space
- Verify backups

### Monthly
- Update dependencies
- Security patches
- Performance optimization
- Documentation review

## 📜 Changelog

Documentation is updated with code. See:
- Git commits for changes
- GitHub Releases for versions
- CHANGELOG.md in root (if present)

## 🤝 Contributing to Documentation

Improvements welcome!

```bash
# 1. Fork repo
# 2. Edit docs/
# 3. Test that examples work
# 4. Pull Request with clear description
```

---

**Last updated:** 2024  
**Maintainer:** Zclassic Community  
**License:** Apache 2.0

For questions: https://github.com/lelonex/zclassic-explorer/issues
