# 📖 Usage Guidelines

Comprehensive usage documentation for all scripts in this repository.

---

## Table of Contents

- [Apache to Nginx Reverse Proxy](#apache-to-nginx-reverse-proxy)
- [Frappe Development Setup](#frappe-development-setup)
- [Frappe Enhanced Setup Wizard](#frappe-enhanced-setup-wizard)
- [Frappe Icon Generator](#frappe-icon-generator)

---

## 🌐 Apache to Nginx Reverse Proxy

**Script:** `scripts/web-server/apache-proxy.sh`  
**Category:** Web Server Configuration  
**Requires:** Root/sudo access

### Description

Automatically creates Nginx reverse proxy configurations for Apache websites. This script is particularly useful for:
- Running multiple web applications on different ports
- Integrating aaPanel Apache sites with Nginx
- SSL termination at the Nginx level
- Load balancing preparation

### Prerequisites

- Ubuntu/Debian Linux
- Nginx installed (`sudo apt install nginx`)
- Apache2 installed and running
- Root or sudo access
- Domain DNS configured (for Let's Encrypt SSL)

### Basic Usage

```bash
# HTTP only (no SSL)
sudo ./scripts/web-server/apache-proxy.sh example.com 8080

# With self-signed SSL certificate
sudo ./scripts/web-server/apache-proxy.sh example.com 8080 self

# With Let's Encrypt SSL certificate
sudo ./scripts/web-server/apache-proxy.sh example.com 8080 letsencrypt
```

### Parameters

| Parameter | Description | Required | Default |
|-----------|-------------|----------|---------|
| `domain` | Domain name (e.g., example.com) | Yes | - |
| `apache_port` | Port where Apache is running | No | 8080 |
| `ssl_type` | SSL type: `self`, `letsencrypt`, or omit for no SSL | No | none |

### Examples

#### Example 1: Basic HTTP Proxy
```bash
sudo ./scripts/web-server/apache-proxy.sh mysite.com 8080
```
Creates an HTTP-only reverse proxy forwarding `mysite.com` to Apache on port 8080.

#### Example 2: Multiple Subdomains
```bash
sudo ./scripts/web-server/apache-proxy.sh app.company.com 8080 letsencrypt
sudo ./scripts/web-server/apache-proxy.sh blog.company.com 8081 letsencrypt
sudo ./scripts/web-server/apache-proxy.sh shop.company.com 8082 letsencrypt
```
Sets up multiple subdomains, each proxying to different Apache ports.

#### Example 3: Development Environment
```bash
sudo ./scripts/web-server/apache-proxy.sh dev.local 8080
sudo ./scripts/web-server/apache-proxy.sh staging.local 8081
```
Local development setup without SSL.

### Configuration Files

After running the script, the following files are created:

- **Nginx Config:** `/etc/nginx/sites-available/[domain]`
- **Symlink:** `/etc/nginx/sites-enabled/[domain]`
- **SSL Certificates:**
  - Let's Encrypt: `/etc/letsencrypt/live/[domain]/`
  - Self-signed: `/etc/ssl/certs/[domain].crt` and `/etc/ssl/private/[domain].key`
- **Log Files:**
  - Access: `/var/log/nginx/[domain].access.log`
  - Error: `/var/log/nginx/[domain].error.log`
  - SSL Access: `/var/log/nginx/[domain].ssl.access.log` (if SSL enabled)

### Features

#### SSL Support
- **Let's Encrypt:** Automatic certificate generation and renewal
- **Self-signed:** Quick SSL for development/testing
- **Auto-renewal:** Cron job automatically renews Let's Encrypt certificates

#### Security Headers
The script automatically adds:
- `X-Frame-Options: SAMEORIGIN`
- `X-XSS-Protection: 1; mode=block`
- `X-Content-Type-Options: nosniff`
- `Strict-Transport-Security` (for HTTPS)
- `Referrer-Policy: no-referrer-when-downgrade`

#### Performance Optimization
- Optimized proxy buffering
- Static file caching (1 year)
- WebSocket support
- Connection timeouts configured

### Troubleshooting

#### Check Nginx Configuration
```bash
sudo nginx -t
```

#### View Logs
```bash
# Access logs
sudo tail -f /var/log/nginx/[domain].access.log

# Error logs
sudo tail -f /var/log/nginx/[domain].error.log
```

#### Test Backend Connection
```bash
# Test Apache backend directly
curl -I http://127.0.0.1:8080

# Test through proxy
curl -I http://your-domain.com
```

#### Disable Site
```bash
sudo rm /etc/nginx/sites-enabled/[domain]
sudo nginx -s reload
```

#### Edit Configuration
```bash
sudo nano /etc/nginx/sites-available/[domain]
sudo nginx -t
sudo systemctl reload nginx
```

#### Common Issues

**Issue:** "Apache doesn't seem to be running on port X"
- **Solution:** Ensure Apache is running and configured for the specified port
- Check: `sudo netstat -tulpn | grep :8080`

**Issue:** "DNS doesn't point to this server" (Let's Encrypt)
- **Solution:** Configure DNS A record pointing to server IP before running script
- Check: `dig +short your-domain.com`

**Issue:** "Nginx configuration test failed"
- **Solution:** Check the error message from `nginx -t`
- Common causes: Port conflicts, syntax errors, missing directories

**Issue:** "502 Bad Gateway"
- **Solution:** Verify Apache is running on the specified port
- Check Apache logs: `sudo tail -f /var/log/apache2/error.log`

---

## 🎨 Frappe Development Setup

**Script:** `scripts/frappe/frappe_dev_setup.sh`  
**Category:** Frappe Framework  
**Requires:** User-level access (not root), sudo privileges

### Description

Streamlined setup script for Frappe Framework development environment. Automatically installs all required system dependencies, configures development tools, and optionally creates a development bench and site. Perfect for quickly setting up a new Frappe development environment.

### Prerequisites

- Ubuntu/Debian Linux
- User account with sudo privileges
- Internet connection
- At least 4GB RAM recommended
- 20GB+ free disk space

### Basic Usage

```bash
# Run the setup script
./scripts/frappe/frappe_dev_setup.sh
```

The script runs interactively and will:
1. Install all system dependencies
2. Set up Node.js, Yarn, MySQL
3. Configure SSH and Git
4. Create Python virtual environment
5. Optionally create a development bench and site
6. Optionally start the development server

### What Gets Installed

#### System Packages
- Python 3 development tools (python3-dev, python3-pip, python3-venv)
- Build essentials (gcc, build-essential)
- Git and curl
- Redis server
- MySQL/MariaDB server and client
- Nginx web server
- Supervisor process manager
- Certbot for SSL certificates
- wkhtmltopdf for PDF generation
- libffi-dev and other development libraries

#### Development Tools
- **Node.js 18+**: Installed or upgraded if needed
- **Yarn**: Installed via Corepack
- **Python Virtual Environment**: Created at `~/frappe/venv`
- **frappe-bench**: Installed in the virtual environment

### Interactive Flow

#### Step 1: System Dependencies
The script automatically installs all required system packages. You'll be prompted for your sudo password.

#### Step 2: Node.js Setup
- Checks if Node.js is installed
- If not installed or version < 18, installs/upgrades to Node.js 18+
- Uses NodeSource repository for installation

#### Step 3: Yarn Installation
- Enables Corepack
- Installs Yarn via Corepack

#### Step 4: MySQL Configuration
- Enables and starts MariaDB service
- Runs `mysql_secure_installation` if MySQL root password is not set

#### Step 5: SSH and Git Setup
- Generates SSH key if it doesn't exist (`~/.ssh/id_rsa`)
- Displays public SSH key for GitHub/GitLab setup
- Prompts for Git username and email if not configured

#### Step 6: Python Virtual Environment
- Creates virtual environment at `~/frappe/venv`
- Upgrades pip and wheel
- Installs frappe-bench

#### Step 7: Bench Creation (Optional)
After base setup, you'll be prompted:
```bash
Create dev bench now? (y/n):
```

If yes:
- **Bench name**: Default is `dev-bench` (customizable)
- **Frappe version**: Default is `develop` (customizable)
- Bench will be created at `~/frappe/[bench-name]`

#### Step 8: Site Creation (Optional)
If bench is created, you'll be prompted:
```bash
Create default site site1.local? (y/n):
```

If yes:
- **Site name**: Default is `site1.local` (customizable)
- Site will be created in the bench

#### Step 9: Start Development Server (Optional)
After site creation, you'll be prompted:
```bash
Start bench start now? (y/n):
```

If yes, the development server starts immediately. Otherwise, you'll get instructions to start it later.

### Configuration Locations

- **Frappe Home:** `~/frappe/`
- **Virtual Environment:** `~/frappe/venv/`
- **Benches:** `~/frappe/[bench-name]/`
- **Sites:** `~/frappe/[bench-name]/sites/[site-name]/`

### Examples

#### Example 1: Complete Setup with Defaults
```bash
./scripts/frappe/frappe_dev_setup.sh
# Answer 'y' to all prompts
# Creates: dev-bench with site1.local
```

#### Example 2: Base Setup Only
```bash
./scripts/frappe/frappe_dev_setup.sh
# Answer 'n' to bench creation
# Only installs system dependencies
```

#### Example 3: Custom Bench and Site
```bash
./scripts/frappe/frappe_dev_setup.sh
# Bench name: my-project
# Frappe version: version-15
# Site name: myproject.local
```

### Manual Bench Operations

After running the script, you can manually:

#### Create Additional Benches
```bash
source ~/frappe/venv/bin/activate
cd ~/frappe
bench init --frappe-branch version-15 my-other-bench
```

#### Create Additional Sites
```bash
cd ~/frappe/[bench-name]
bench new-site newsite.local
```

#### Start Development Server
```bash
cd ~/frappe/[bench-name]
bench start
```

#### Access Development Site
- Open browser: `http://site1.local:8000`
- Login with Administrator credentials set during site creation

### Features

#### Error Handling
- Script uses `set -euo pipefail` for strict error handling
- Traps errors and displays friendly error messages
- Prevents running as root user

#### Safety Checks
- Checks if Node.js version is sufficient
- Skips installation if tools already exist
- Prevents overwriting existing benches and sites
- Validates bench exists before creating sites

#### User Experience
- Color-coded output (green for success, yellow for warnings, red for errors)
- Clear progress indicators with emojis
- Helpful error messages with line numbers
- Non-interactive prompts with sensible defaults

### Troubleshooting

#### Script Fails with "Don't run this script as root"
**Solution:** Run as a regular user with sudo privileges. The script will prompt for sudo password when needed.

#### MySQL Installation Fails
```bash
# Check if MySQL is already running
sudo systemctl status mariadb

# Try manual installation
sudo apt update
sudo apt install -y mariadb-server mariadb-client
```

#### Node.js Installation Issues
```bash
# Check current Node.js version
node -v

# Manual Node.js 18 installation
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
```

#### Virtual Environment Issues
```bash
# Activate virtual environment manually
source ~/frappe/venv/bin/activate

# Reinstall frappe-bench
pip install --upgrade frappe-bench
```

#### Bench Creation Fails
- Ensure virtual environment is activated
- Check internet connection (bench downloads from GitHub)
- Verify Git is configured: `git config --global user.name` and `git config --global user.email`

#### Site Creation Fails
- Verify MySQL is running: `sudo systemctl status mariadb`
- Check MySQL credentials
- Ensure bench exists before creating site
- Check bench logs: `tail -f ~/frappe/[bench-name]/logs/web.log`

#### Development Server Won't Start
```bash
# Check if ports are in use
sudo netstat -tulpn | grep -E ':(8000|9000|6787)'

# Check bench status
cd ~/frappe/[bench-name]
bench doctor

# View logs
tail -f ~/frappe/[bench-name]/logs/web.log
```

### Differences from Enhanced Setup

| Feature | Dev Setup | Enhanced Setup |
|---------|-----------|----------------|
| **Purpose** | Quick dev environment | Complete production setup |
| **Complexity** | Simple, streamlined | Full-featured wizard |
| **SSL Setup** | ❌ No | ✅ Yes |
| **Supervisor Config** | ❌ No | ✅ Yes |
| **Production Config** | ❌ No | ✅ Yes |
| **Custom Apps** | ❌ No | ✅ Yes |
| **Theme Installation** | ❌ No | ✅ Yes |
| **Use Case** | Development only | Development + Production |

### Tips

- **First Time Setup**: Run the script and answer 'y' to all prompts for a complete setup
- **Existing Environment**: Answer 'n' to bench creation if you just need to update dependencies
- **Multiple Benches**: Run the script multiple times or create benches manually after initial setup
- **Version Control**: The script sets up Git, but you'll need to add your SSH key to GitHub/GitLab
- **Development Workflow**: After setup, use `bench start` in your bench directory to start development

---

## 🎨 Frappe Enhanced Setup Wizard

**Script:** `scripts/frappe/frappe_enhanced_setup.sh`  
**Category:** Frappe Framework  
**Requires:** User-level access (not root)

### Description

Interactive wizard for complete Frappe Framework setup. Handles everything from system dependencies to production deployment.

### Prerequisites

- Ubuntu/Debian Linux
- User account with sudo privileges
- Internet connection
- At least 4GB RAM recommended
- 20GB+ free disk space

### Basic Usage

```bash
# Run the interactive wizard
./scripts/frappe/frappe_enhanced_setup.sh
```

The script provides an interactive menu with the following options:

1. **Complete Setup** - Installs all system dependencies
2. **Create Bench** - Creates a new Frappe bench
3. **Create Site** - Creates a new site in an existing bench
4. **Exit** - Exit the wizard

### Menu Options Explained

#### Option 1: Complete Setup

Installs and configures:
- System packages (Python, Node.js, MySQL, Redis, etc.)
- Node.js 18+ (if not installed or outdated)
- Yarn package manager
- MySQL/MariaDB server
- SSH keys and Git configuration
- Python virtual environment with frappe-bench

**Example:**
```bash
# Select option 1 from menu
# Script will automatically install all dependencies
```

#### Option 2: Create Bench

Creates a new Frappe bench with:
- Custom bench name
- Frappe version selection (default: version-15)
- Validation for existing benches

**Example:**
```bash
# Select option 2 from menu
# Enter bench name: my-bench
# Enter Frappe version [version-15]: version-14
# Bench created at: ~/frappe_portable/my-bench
```

#### Option 3: Create Site

Creates a new site with:
- Bench selection
- Site name (domain)
- MySQL credentials
- Administrator password
- Optional custom app creation
- Optional Git repository setup
- Environment setup (Development or Production)

**Example:**
```bash
# Select option 3 from menu
# Enter bench name: my-bench
# Enter site name: mysite.local
# Enter MySQL root username [root]: root
# Enter MySQL root password: [hidden]
# Enter site administrator password: [hidden]
# Create custom app? (y/n): y
# Enter app name: myapp
# Enter Git repo URL: https://github.com/user/myapp.git
# Choose environment [1-2]: 1
```

### Environment Setup

#### Development Environment

When you select Development:
- Provides commands to start development server
- Option to start server immediately
- No production configurations

**Commands provided:**
```bash
bench start                    # Start all services
bench --site mysite.local serve  # Serve specific site
```

#### Production Environment

When you select Production:
- Configures Supervisor for process management
- Sets up Nginx configuration
- Configures assets and permissions
- Optional SSL certificate setup
- Sets proper file permissions

**Management commands:**
```bash
sudo supervisorctl restart all    # Restart services
sudo systemctl reload nginx      # Reload nginx
bench migrate                     # Run migrations
```

### Configuration Locations

- **Frappe Home:** `~/frappe_portable/`
- **Virtual Environment:** `~/frappe_portable/venv/`
- **Benches:** `~/frappe_portable/[bench-name]/`
- **Sites:** `~/frappe_portable/[bench-name]/sites/[site-name]/`
- **Supervisor Config:** `~/frappe_portable/[bench-name]/config/supervisor.conf`
- **Nginx Config:** `~/frappe_portable/[bench-name]/config/nginx.conf`

### Features

#### Automatic Installations
- Frappe Desk Theme (custom theme)
- Custom apps (optional)
- Git repository initialization (optional)

#### SSL Setup
- Let's Encrypt certificate generation
- Domain validation
- DNS multitenant configuration
- Automatic HTTPS redirect

#### Production Optimizations
- Asset optimization and caching
- Proper file permissions
- Nginx performance tuning
- Supervisor process management

### Troubleshooting

#### Virtual Environment Issues
```bash
# Activate virtual environment manually
source ~/frappe_portable/venv/bin/activate
```

#### Bench Not Found
```bash
# List all benches
ls ~/frappe_portable/

# Navigate to bench
cd ~/frappe_portable/[bench-name]
```

#### Site Creation Fails
- Verify MySQL is running: `sudo systemctl status mariadb`
- Check MySQL credentials
- Ensure bench exists before creating site

#### Production Setup Issues

**Nginx not working:**
```bash
# Check nginx config
sudo nginx -t

# Check supervisor
sudo supervisorctl status

# View logs
tail -f ~/frappe_portable/[bench-name]/logs/web.log
```

**Assets not loading:**
```bash
cd ~/frappe_portable/[bench-name]
bench build --app frappe
bench --site [site-name] clear-cache
```

#### Common Issues

**Issue:** "Don't run this script as root"
- **Solution:** Run as regular user with sudo privileges
- The script will prompt for sudo when needed

**Issue:** "Bench already exists"
- **Solution:** Choose a different name or remove existing bench
- Remove: `rm -rf ~/frappe_portable/[bench-name]`

**Issue:** "MySQL connection failed"
- **Solution:** Ensure MySQL is running and credentials are correct
- Start MySQL: `sudo systemctl start mariadb`

---

## 🎨 Frappe Icon Generator

**Script:** `scripts/frappe/frappe_generate_icons.py`  
**Category:** Frappe Framework  
**Requires:** Python 3.x

### Description

Converts Octicons SVG files to Frappe Framework's icons.svg format. Processes 24px icons (including fill variants) and generates properly formatted symbol definitions.

### Prerequisites

- Python 3.x
- Octicons SVG files (24px variants)
- Write permissions for output directory

### Basic Usage

```bash
python3 scripts/frappe/frappe_generate_icons.py <input_directory> <output_file>
```

### Parameters

| Parameter | Description | Required |
|-----------|-------------|----------|
| `input_directory` | Path to directory containing Octicons SVG files | Yes |
| `output_file` | Path to output icons.svg file | Yes |

### Examples

#### Example 1: Basic Conversion
```bash
python3 scripts/frappe/frappe_generate_icons.py \
  /path/to/octicons/icons \
  ./frappe/public/icons/octicons/icons.svg
```

#### Example 2: Custom Output Location
```bash
python3 scripts/frappe/frappe_generate_icons.py \
  ~/Downloads/octicons-24 \
  ~/my-project/icons/octicons.svg
```

### How It Works

1. **Scans** input directory for files ending with `-24.svg`
2. **Extracts** SVG content and viewBox from each file
3. **Generates** Frappe-compatible symbol IDs:
   - Regular icons: `icon-octicon-[name]-24`
   - Fill variants: `icon-octicon-[name]-fill-24`
4. **Creates** properly formatted icons.svg file
5. **Outputs** progress information

### Output Format

The script generates an SVG file with this structure:

```xml
<!--
Octicons 24px icons converted for Frappe Framework
Source: https://github.com/primer/octicons
License: MIT
-->
<svg id="frappe-symbols" aria-hidden="true" style="display: none;" class="icon" xmlns="http://www.w3.org/2000/svg">
    <symbol viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" id="icon-octicon-alert-24">
        <!-- SVG content -->
    </symbol>
    
    <symbol viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" id="icon-octicon-alert-fill-24">
        <!-- SVG content -->
    </symbol>
    
    <!-- More symbols... -->
</svg>
```

### Icon Naming Convention

- **Input:** `alert-24.svg` → **Output ID:** `icon-octicon-alert-24`
- **Input:** `alert-fill-24.svg` → **Output ID:** `icon-octicon-alert-fill-24`

### Usage in Frappe

After generating the icons.svg file:

1. **Place** the file in your Frappe app's public directory:
   ```
   apps/your-app/your-app/public/icons/octicons/icons.svg
   ```

2. **Use** in Frappe templates:
   ```html
   <svg class="icon icon-md">
       <use href="#icon-octicon-alert-24"></use>
   </svg>
   ```

3. **Include** in your app's hooks.py:
   ```python
   app_include_css = [
       "your-app/public/icons/octicons/icons.svg"
   ]
   ```

### Troubleshooting

#### No 24px SVG Files Found
```
Error: No 24px SVG files found in '[directory]'.
Looking for files ending with '-24.svg'
```

**Solution:** Ensure you're pointing to a directory containing Octicons 24px SVG files. Download from: https://github.com/primer/octicons

#### Permission Denied
```
PermissionError: [Errno 13] Permission denied: '[output_file]'
```

**Solution:** Ensure you have write permissions for the output directory:
```bash
chmod +w /path/to/output/directory
```

#### Invalid SVG Format
```
Error parsing [file]: [error message]
```

**Solution:** Ensure SVG files are valid. The script handles both single-line and multi-line SVGs, but malformed files may fail.

### Tips

- **Batch Processing:** Process multiple icon sets by running the script multiple times
- **Version Control:** Commit the generated icons.svg file to your repository
- **Updates:** Re-run the script when Octicons are updated
- **Customization:** Edit the generated file to add/remove specific icons

---

## 🔧 General Script Usage Tips

### Making Scripts Executable

```bash
# Make all shell scripts executable
find scripts/ -type f -name "*.sh" -exec chmod +x {} \;

# Make all Python scripts executable
find scripts/ -type f -name "*.py" -exec chmod +x {} \;
```

### Running Scripts

```bash
# From repository root
./scripts/category/script.sh

# With full path
/path/to/automation-scripts/scripts/category/script.sh

# If installed system-wide
script-name
```

### Debugging

```bash
# Bash scripts - verbose mode
bash -x scripts/category/script.sh

# Python scripts - verbose mode
python3 -v scripts/category/script.py

# Check syntax
bash -n scripts/category/script.sh
python3 -m py_compile scripts/category/script.py
```

---

## 📚 Additional Resources

- [Frappe Framework Documentation](https://frappeframework.com/docs)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Apache Documentation](https://httpd.apache.org/docs/)
- [Octicons Repository](https://github.com/primer/octicons)

---

## ❓ Need Help?

If you encounter issues not covered in this guide:

1. Check script comments for inline documentation
2. Review error messages carefully
3. Check system logs: `/var/log/syslog`, `/var/log/nginx/error.log`
4. Open an issue on GitHub with:
   - Script name and version
   - Error message
   - Steps to reproduce
   - System information

---

*Last updated: 2025*

