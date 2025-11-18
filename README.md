# 🚀 DevOps Automation Scripts

A curated collection of production-ready automation scripts for server management, web development, and system administration. Each script is designed with reliability, security, and ease of use in mind.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Scripts](#scripts)
- [Quick Start](#quick-start)
- [Usage Guidelines](#usage-guidelines)
- [Contributing](#contributing)
- [License](#license)

---

## 🎯 Overview

This repository contains reusable automation scripts that simplify common DevOps and system administration tasks. All scripts follow best practices for error handling, logging, and user experience.

### Key Features

- ✅ **Production Ready**: Tested and used in production environments
- ✅ **Well Documented**: Comprehensive inline comments and usage examples
- ✅ **Error Handling**: Robust error checking and user-friendly messages
- ✅ **Cross-Platform**: Primarily Linux-focused with Ubuntu/Debian support
- ✅ **Security First**: Implements security best practices

---

## 📦 Scripts

### 🌐 Web Server Scripts

#### Apache to Nginx Reverse Proxy
**Location:** `scripts/web-server/apache-proxy.sh`  
**Purpose:** Automatically creates Nginx reverse proxy configurations for Apache websites with optional SSL support

**Features:**
- 🔒 Automatic SSL certificate generation (Let's Encrypt or self-signed)
- 🌐 Multi-domain and subdomain support
- 🛡️ Security headers implementation
- 📊 Server name conflict detection
- 🔧 aaPanel integration support
- 📝 Comprehensive logging
- 🔄 Auto-renewal setup for Let's Encrypt certificates

**Quick Usage:**
```bash
# HTTP only
sudo ./scripts/web-server/apache-proxy.sh example.com 8080

# With self-signed SSL
sudo ./scripts/web-server/apache-proxy.sh example.com 8080 self

# With Let's Encrypt SSL
sudo ./scripts/web-server/apache-proxy.sh example.com 8080 letsencrypt
```

**See [Usage Guidelines](USAGE.md#apache-to-nginx-reverse-proxy) for detailed documentation.**

---

### 🎨 Frappe Framework Scripts

#### Frappe Development Setup
**Location:** `scripts/frappe/frappe_dev_setup.sh`  
**Purpose:** Streamlined setup script for Frappe Framework development environment

**Features:**
- 🛠️ Installs all system dependencies (Python, Node.js, MySQL, Redis, Nginx, etc.)
- 📦 Node.js 18+ installation and upgrade
- 🧶 Yarn package manager setup via Corepack
- 🗄️ MySQL/MariaDB configuration
- 🔑 SSH key generation and Git configuration
- 🐍 Python virtual environment with frappe-bench
- 🏗️ Interactive bench and site creation
- 🚀 Optional development server startup

**Quick Usage:**
```bash
# Run the setup script
./scripts/frappe/frappe_dev_setup.sh
```

**See [Usage Guidelines](USAGE.md#frappe-development-setup) for detailed documentation.**

#### Frappe Enhanced Setup Wizard
**Location:** `scripts/frappe/frappe_enhanced_setup.sh`  
**Purpose:** Interactive wizard for complete Frappe Framework setup including system dependencies, benches, and sites

**Features:**
- 🛠️ Complete system setup (dependencies, MySQL, SSH/Git, Python venv)
- 🏗️ Bench creation with version selection
- 🌐 Site creation with custom apps
- 🚀 Development and production environment setup
- 🎨 Automatic desk theme installation
- 🔐 SSL certificate configuration
- ⚙️ Supervisor and Nginx auto-configuration

**Quick Usage:**
```bash
# Run the interactive wizard
./scripts/frappe/frappe_enhanced_setup.sh
```

**See [Usage Guidelines](USAGE.md#frappe-enhanced-setup-wizard) for detailed documentation.**

#### Frappe Icon Generator
**Location:** `scripts/frappe/frappe_generate_icons.py`  
**Purpose:** Converts Octicons SVG files to Frappe Framework icons.svg format

**Features:**
- 📦 Processes 24px icons (with and without fill variants)
- 🔄 Automatic symbol ID generation
- 📝 Proper formatting for Frappe compatibility
- ✅ Handles both single-line and multi-line SVGs

**Quick Usage:**
```bash
python3 scripts/frappe/frappe_generate_icons.py /path/to/octicons/icons ./output/icons.svg
```

**See [Usage Guidelines](USAGE.md#frappe-icon-generator) for detailed documentation.**

---

## ⚡ Quick Start

### Prerequisites

- **Operating System:** Ubuntu/Debian Linux (most scripts)
- **Permissions:** Root or sudo access (for system-level scripts)
- **Python:** Python 3.x (for Python scripts)
- **Bash:** Bash 4.0+ (for shell scripts)

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/automation-scripts.git
cd automation-scripts

# Make scripts executable
find scripts/ -type f -name "*.sh" -exec chmod +x {} \;
find scripts/ -type f -name "*.py" -exec chmod +x {} \;
```

### System-Wide Installation (Optional)

```bash
# Install scripts to system PATH
sudo cp scripts/web-server/apache-proxy.sh /usr/local/bin/apache-proxy
sudo cp scripts/frappe/frappe_enhanced_setup.sh /usr/local/bin/frappe-setup
sudo chmod +x /usr/local/bin/apache-proxy /usr/local/bin/frappe-setup

# Now you can use them from anywhere
sudo apache-proxy example.com 8080 letsencrypt
frappe-setup
```

---

## 📖 Usage Guidelines

For detailed usage instructions, examples, and troubleshooting guides, see **[USAGE.md](USAGE.md)**.

---

## 🗂️ Repository Structure

```
automation-scripts/
├── scripts/
│   ├── frappe/
│   │   ├── frappe_dev_setup.sh         # Frappe development setup
│   │   ├── frappe_enhanced_setup.sh    # Frappe setup wizard
│   │   └── frappe_generate_icons.py    # Icon converter
│   └── web-server/
│       └── apache-proxy.sh              # Nginx reverse proxy generator
├── README.md                            # This file
├── USAGE.md                             # Detailed usage guidelines
├── LICENSE                              # MIT License
└── .gitignore                           # Git ignore rules
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- Frappe Framework community
- Nginx and Apache communities
- All contributors and users

---

<div align="center">

**🚀 Automate Everything, Simplify Everything 🚀**

*Made with ❤️ for the DevOps community*

[![GitHub Stars](https://img.shields.io/github/stars/bhushan-dhwaniris/automation-scripts?style=social)](https://github.com/bhushan-dhwaniris/automation-scripts)
[![GitHub Forks](https://img.shields.io/github/forks/bhushan-dhwaniris/automation-scripts?style=social)](https://github.com/bhushan-dhwaniris/automation-scripts)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

</div>
