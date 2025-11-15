# 📖 Usage Guidelines

Comprehensive usage documentation for all scripts in this repository.

---

## Table of Contents

- [Apache to Nginx Reverse Proxy](#apache-to-nginx-reverse-proxy)
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

