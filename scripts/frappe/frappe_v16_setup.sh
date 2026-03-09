#!/bin/bash
# =============================================================================
# Frappe Setup Wizard — Frappe v16 / develop
# Aligned with: https://docs.frappe.io/framework/user/en/installation
#
# Official v16 dependency matrix:
#   Python      3.14          (via uv)
#   Node.js     24            (via nvm)
#   MariaDB     11.8          (via MariaDB repo)
#   Redis       6+            (apt)
#   Yarn        1.22+         (via npm)
#   pip         25.3+         (managed by uv — not used directly)
#   wkhtmltopdf 0.12.6 patched-qt
#   bench CLI   frappe-bench  (via uv tool install)
#
# Supported OS: Ubuntu 24.04+ / Debian 13+
# DO NOT run as root.
# =============================================================================

set -euo pipefail

# ── Colour helpers ────────────────────────────────────────────────────────────
cecho()   { echo -e "\e[1;32m$1\e[0m"; }
cwarn()   { echo -e "\e[1;33m$1\e[0m"; }
cerror()  { echo -e "\e[1;31m$1\e[0m"; }
cstep()   { echo -e "\n\e[1;36m▶ $1\e[0m"; }
csep()    { echo -e "\e[0;90m────────────────────────────────────────────────\e[0m"; }

# ── Constants ─────────────────────────────────────────────────────────────────
readonly FRAPPE_HOME="$HOME"
readonly DEFAULT_FRAPPE_BRANCH="version-16"

readonly REQUIRED_PYTHON="3.14"
readonly REQUIRED_NODE="24"
readonly REQUIRED_YARN_MAJOR="1"
readonly REQUIRED_MARIADB="11.8"
readonly WKHTMLTOPDF_VER="0.12.6.1-2"

NVM_INSTALL_VERSION="v0.40.3"
readonly NVM_DIR="$HOME/.nvm"

# ── Guard: must not be root ───────────────────────────────────────────────────
if [[ $EUID -eq 0 ]]; then
  cerror "❌  Do NOT run this script as root. Run as a normal user with sudo access."
  exit 1
fi

trap 'cerror "\n❌  Error on line $LINENO — exiting." && exit 1' ERR

# =============================================================================
# HELPER: source shell environment so nvm / uv / bench are always on PATH
# =============================================================================
refresh_env() {
  # nvm
  if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    # Unset NVM_VERSION before sourcing — nvm.sh declares it as local
    # and bash readonly variables bleed into sourced scripts, causing errors
    unset NVM_VERSION 2>/dev/null || true
    # shellcheck disable=SC1090
    source "$NVM_DIR/nvm.sh"
  fi
  # uv (installs to ~/.local/bin by default on Linux)
  export PATH="$HOME/.local/bin:$PATH"
  # uv-managed tools (bench lives here)
  if command -v uv &>/dev/null; then
    UV_TOOL_BIN=$(uv tool dir --bin 2>/dev/null || echo "$HOME/.local/bin")
    export PATH="$UV_TOOL_BIN:$PATH"
  fi
}

refresh_env

# =============================================================================
# 1. VERIFY SYSTEM (non-destructive pre-flight check)
# =============================================================================
verify_system() {
  cstep "Running pre-flight system check"
  local ok=true

  # OS
  local distro; distro=$(lsb_release -cs 2>/dev/null || echo "unknown")
  echo "  OS codename : $distro"
  case "$distro" in
    noble|bookworm|trixie) cecho "  ✅ Supported OS ($distro)" ;;
    jammy)  cwarn "  ⚠️  Ubuntu 22.04 (jammy) — MariaDB 11.8 needs manual repo. Upgrade to 24.04 recommended." ;;
    *)      cwarn "  ⚠️  Untested OS ($distro). Proceeding anyway." ;;
  esac

  # Python 3.14
  if command -v python3.14 &>/dev/null; then
    cecho "  ✅ Python $(python3.14 --version 2>&1 | awk '{print $2}')"
  elif command -v uv &>/dev/null && uv python list 2>/dev/null | grep -q "3\.14"; then
    cecho "  ✅ Python 3.14 managed by uv"
  else
    cwarn "  ⚠️  Python $REQUIRED_PYTHON not found (will be installed via uv)"
    ok=false
  fi

  # Node
  if command -v node &>/dev/null; then
    local nv; nv=$(node -v | sed 's/v//' | cut -d. -f1)
    if [[ "$nv" -ge "$REQUIRED_NODE" ]]; then
      cecho "  ✅ Node.js $(node -v)"
    else
      cwarn "  ⚠️  Node.js $(node -v) is too old (need v${REQUIRED_NODE}+)"
      ok=false
    fi
  else
    cwarn "  ⚠️  Node.js not found (will be installed via nvm)"
    ok=false
  fi

  # Yarn
  if command -v yarn &>/dev/null; then
    cecho "  ✅ Yarn $(yarn --version 2>/dev/null)"
  else
    cwarn "  ⚠️  Yarn not found (will be installed via npm)"
    ok=false
  fi

  # MariaDB
  if command -v mariadb &>/dev/null; then
    local mv; mv=$(mariadb --version 2>&1 | grep -oP '\d+\.\d+\.\d+' | head -1)
    local mmajor; mmajor=$(echo "$mv" | cut -d. -f1)
    local mminor; mminor=$(echo "$mv" | cut -d. -f2)
    if [[ "$mmajor" -ge 11 && "$mminor" -ge 2 ]]; then
      cecho "  ✅ MariaDB $mv (>= 11.2 — compatible)"
    else
      cwarn "  ⚠️  MariaDB $mv — v16 recommends 11.8. Upgrade recommended."
      ok=false
    fi
  else
    cwarn "  ⚠️  MariaDB not found (will be installed)"
    ok=false
  fi

  # Redis
  if command -v redis-server &>/dev/null; then
    cecho "  ✅ Redis $(redis-server --version | grep -oP 'v=\K[\d.]+')"
  else
    cwarn "  ⚠️  Redis not found (will be installed)"
    ok=false
  fi

  # uv
  if command -v uv &>/dev/null; then
    cecho "  ✅ uv $(uv --version 2>/dev/null | awk '{print $2}')"
  else
    cwarn "  ⚠️  uv not found (will be installed)"
    ok=false
  fi

  # bench
  if command -v bench &>/dev/null; then
    cecho "  ✅ bench $(bench --version 2>/dev/null | head -1)"
  else
    cwarn "  ⚠️  bench CLI not found (will be installed via uv)"
    ok=false
  fi

  # wkhtmltopdf
  if command -v wkhtmltopdf &>/dev/null && wkhtmltopdf -V 2>&1 | grep -q "with patched qt"; then
    cecho "  ✅ wkhtmltopdf $(wkhtmltopdf -V 2>&1 | head -1) — patched qt ✔"
  elif command -v wkhtmltopdf &>/dev/null; then
    cwarn "  ⚠️  wkhtmltopdf found but WITHOUT patched qt — PDF generation may fail"
    ok=false
  else
    cwarn "  ⚠️  wkhtmltopdf not found (will be installed)"
    ok=false
  fi

  csep
  if $ok; then
    cecho "✅ All prerequisites satisfied."
  else
    cwarn "⚠️  Some prerequisites missing. Run 'Complete Setup' to install them."
  fi
}

# =============================================================================
# 2. APT BASE PACKAGES
# =============================================================================
install_apt_packages() {
  cstep "Installing APT system packages"

  # Minimal bootstrap
  sudo apt update -qq
  for pkg in curl ca-certificates apt-transport-https software-properties-common lsb-release gnupg; do
    dpkg -s "$pkg" &>/dev/null || sudo apt install -y "$pkg"
  done

  # ── MariaDB 11.8 official repo ──────────────────────────────────────────────
  cstep "Configuring MariaDB 11.8 repository"
  if ! (command -v mariadb &>/dev/null && mariadb --version 2>&1 | grep -qP '1[1-9]\.[2-9]'); then
    # Use MariaDB's official repo setup script targeting 11.8
    curl -LsSo /tmp/mariadb_repo_setup \
      https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
    chmod +x /tmp/mariadb_repo_setup
    sudo /tmp/mariadb_repo_setup --mariadb-server-version="mariadb-11.8" --skip-check-installed
    sudo apt update -qq
    rm -f /tmp/mariadb_repo_setup
    cecho "  ✅ MariaDB 11.8 repository configured"
  else
    cecho "  ✅ Compatible MariaDB already installed — skipping repo setup"
  fi

  # ── Main package list ───────────────────────────────────────────────────────
  local PACKAGES=(
    # Build essentials
    git build-essential gcc g++ make pkg-config
    libffi-dev libssl-dev zlib1g-dev
    # MariaDB 11.8
    mariadb-server mariadb-client libmariadb-dev libmariadb-dev-compat
    # Redis 6+
    redis-server
    # Supervisor & Nginx (production)
    supervisor nginx certbot python3-certbot-nginx
    # PDF generation support
    xvfb libfontconfig fontconfig
    # Miscellaneous
    cron fail2ban
  )

  for pkg in "${PACKAGES[@]}"; do
    if dpkg -s "$pkg" &>/dev/null; then
      echo "  ✔ $pkg (already installed)"
    else
      echo "  📦 Installing $pkg ..."
      sudo apt install -y "$pkg"
    fi
  done

  sudo systemctl enable --now redis-server
  sudo systemctl enable --now mariadb
  cecho "  ✅ APT packages installed"
}

# =============================================================================
# 3. wkhtmltopdf 0.12.6 — PATCHED QT  (required for PDF generation)
# =============================================================================
install_wkhtmltopdf() {
  cstep "Installing wkhtmltopdf $WKHTMLTOPDF_VER (patched qt)"

  if command -v wkhtmltopdf &>/dev/null && wkhtmltopdf -V 2>&1 | grep -q "with patched qt"; then
    cecho "  ✅ wkhtmltopdf (patched qt) already installed — skipping"
    return
  fi

  local codename; codename=$(lsb_release -cs 2>/dev/null || echo "noble")
  local deb=""

  case "$codename" in
    noble)   deb="wkhtmltox_${WKHTMLTOPDF_VER}.noble_amd64.deb" ;;
    jammy)   deb="wkhtmltox_${WKHTMLTOPDF_VER}.jammy_amd64.deb" ;;
    bookworm|trixie) deb="wkhtmltox_${WKHTMLTOPDF_VER}.bookworm_amd64.deb" ;;
    focal)   deb="wkhtmltox_${WKHTMLTOPDF_VER}.focal_amd64.deb" ;;
    *)
      cwarn "  ⚠️  No pre-built package for $codename. Trying noble package ..."
      deb="wkhtmltox_${WKHTMLTOPDF_VER}.noble_amd64.deb"
      ;;
  esac

  local url="https://github.com/wkhtmltopdf/packaging/releases/download/${WKHTMLTOPDF_VER}/${deb}"
  echo "  Downloading $url ..."

  if curl -fsSL -o "/tmp/$deb" "$url"; then
    sudo apt install -y "/tmp/$deb" || sudo dpkg -i "/tmp/$deb" || sudo apt install -f -y
    rm -f "/tmp/$deb"
    cecho "  ✅ wkhtmltopdf installed"
  else
    cwarn "  ⚠️  Download failed. Falling back to apt (may lack patched qt)."
    sudo apt install -y wkhtmltopdf || true
  fi
}

# =============================================================================
# 4. uv — Python / package manager (official Frappe v16 recommendation)
# =============================================================================
install_uv() {
  cstep "Installing uv (Python toolchain manager)"

  if command -v uv &>/dev/null; then
    cecho "  ✅ uv $(uv --version 2>/dev/null | awk '{print $2}') already installed"
    return
  fi

  curl -LsSf https://astral.sh/uv/install.sh | sh
  # shellcheck disable=SC1090
  source "$HOME/.local/bin/../.local/bin/env" 2>/dev/null || true
  export PATH="$HOME/.local/bin:$PATH"

  if command -v uv &>/dev/null; then
    cecho "  ✅ uv $(uv --version 2>/dev/null | awk '{print $2}') installed"
  else
    cerror "  ❌ uv installation failed — please install manually: https://docs.astral.sh/uv/"
    return 1
  fi
}

# =============================================================================
# 5. Python 3.14 via uv
# =============================================================================
install_python() {
  cstep "Installing Python $REQUIRED_PYTHON via uv"

  if ! command -v uv &>/dev/null; then
    cerror "  ❌ uv is required to install Python. Run install_uv first."
    return 1
  fi

  # Check if already installed
  if uv python list 2>/dev/null | grep -q "${REQUIRED_PYTHON}"; then
    cecho "  ✅ Python $REQUIRED_PYTHON already managed by uv"
  else
    echo "  📦 Fetching Python $REQUIRED_PYTHON ..."
    uv python install "${REQUIRED_PYTHON}" --default
    cecho "  ✅ Python $REQUIRED_PYTHON installed"
  fi

  # Verify — uv stores pythons under ~/.local/share/uv/python/
  local py_bin=""
  py_bin=$(command -v python3.14 2>/dev/null || true)
  if [[ -z "$py_bin" ]]; then
    py_bin=$(uv python find "cpython-${REQUIRED_PYTHON}" 2>/dev/null ||              uv python find "${REQUIRED_PYTHON}" 2>/dev/null || true)
  fi
  if [[ -n "$py_bin" ]]; then
    cecho "  ✅ Python binary: $py_bin ($("$py_bin" --version 2>&1))"
  else
    cwarn "  ⚠️  Python binary not yet on PATH — open a fresh terminal and re-verify."
  fi
}

# =============================================================================
# 6. Node.js 24 via nvm  (official Frappe v16 recommendation)
# =============================================================================
install_node() {
  cstep "Installing Node.js $REQUIRED_NODE via nvm"

  # Install nvm if missing
  if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
    echo "  📦 Installing nvm $NVM_INSTALL_VERSION ..."
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_INSTALL_VERSION}/install.sh" | bash
    unset NVM_VERSION 2>/dev/null || true
    # shellcheck disable=SC1090
    source "$NVM_DIR/nvm.sh"
    cecho "  ✅ nvm installed"
  else
    unset NVM_VERSION 2>/dev/null || true
    # shellcheck disable=SC1090
    source "$NVM_DIR/nvm.sh"
    cecho "  ✅ nvm already installed"
  fi

  # Install / use Node 24
  if nvm ls "$REQUIRED_NODE" &>/dev/null 2>&1 | grep -q "v${REQUIRED_NODE}"; then
    cecho "  ✅ Node.js v${REQUIRED_NODE} already installed via nvm"
  else
    echo "  📦 Installing Node.js $REQUIRED_NODE ..."
    nvm install "$REQUIRED_NODE"
  fi

  nvm use "$REQUIRED_NODE"
  nvm alias default "$REQUIRED_NODE"

  cecho "  ✅ Node.js $(node -v) active"

  # Persist nvm to shell rc
  _persist_nvm_to_rc

  # Install Yarn 1.x via npm (Frappe requires Yarn 1.22+)
  cstep "Installing Yarn (1.x)"
  if ! command -v yarn &>/dev/null; then
    npm install -g yarn@"${REQUIRED_YARN_MAJOR}"
    cecho "  ✅ Yarn $(yarn --version 2>/dev/null) installed"
  else
    local yv; yv=$(yarn --version 2>/dev/null | cut -d. -f1)
    if [[ "$yv" -eq 1 ]]; then
      cecho "  ✅ Yarn $(yarn --version) already installed (1.x)"
    else
      cwarn "  ⚠️  Yarn $yv detected — Frappe needs Yarn 1.x. Installing yarn@1 ..."
      npm install -g yarn@"${REQUIRED_YARN_MAJOR}"
      cecho "  ✅ Yarn $(yarn --version) installed"
    fi
  fi
}

_persist_nvm_to_rc() {
  local rc_files=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile")
  local nvm_snippet
  nvm_snippet=$(cat <<'EOF'

# nvm (added by frappe_setup_v16.sh)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
EOF
)

  for rc in "${rc_files[@]}"; do
    if [[ -f "$rc" ]] && ! grep -q 'NVM_DIR' "$rc"; then
      echo "$nvm_snippet" >> "$rc"
      echo "  ✔ Added nvm to $rc"
    fi
  done
}

# =============================================================================
# 7. MariaDB — configure for Frappe
# =============================================================================
configure_mariadb() {
  cstep "Configuring MariaDB for Frappe"

  sudo systemctl start mariadb
  sudo systemctl enable mariadb

  # Test if root login works without password (fresh install)
  if sudo mysql -u root -e "SELECT 1;" &>/dev/null 2>&1; then
    cecho "  ✅ MariaDB root accessible via sudo"
  fi

  # Write Frappe-required MariaDB config
  local conf_file="/etc/mysql/mariadb.conf.d/99-frappe.cnf"
  sudo tee "$conf_file" > /dev/null <<'MARIACONF'
# Frappe v16 recommended MariaDB settings
[mysqld]
character-set-client-handshake = FALSE
character-set-server            = utf8mb4
collation-server                = utf8mb4_unicode_ci
innodb_file_per_table           = 1
innodb_buffer_pool_size         = 512M
innodb_log_file_size            = 256M
innodb_strict_mode              = 1
sql_mode                        = NO_ENGINE_SUBSTITUTION

[mysql]
default-character-set           = utf8mb4
MARIACONF

  sudo systemctl restart mariadb
  cecho "  ✅ MariaDB configured with utf8mb4 + innodb settings"

  # Run secure installation only if not already secured
  if sudo mysql -u root -e "SELECT User FROM mysql.user WHERE User='root' AND authentication_string='';" 2>/dev/null | grep -q root; then
    cwarn "  ⚠️  MariaDB root has no password — running secure installation ..."
    sudo mysql_secure_installation
  else
    cecho "  ✅ MariaDB root already secured"
  fi
}

# =============================================================================
# 8. bench CLI via uv tool install
# =============================================================================
install_bench_cli() {
  cstep "Installing bench CLI (frappe-bench) via uv"

  if command -v bench &>/dev/null; then
    cecho "  ✅ bench already installed: $(bench --version 2>/dev/null | head -1)"
    return
  fi

  if ! command -v uv &>/dev/null; then
    cerror "  ❌ uv not found. Install uv first."
    return 1
  fi

  uv tool install frappe-bench
  refresh_env

  if command -v bench &>/dev/null; then
    cecho "  ✅ bench installed: $(bench --version 2>/dev/null | head -1)"
  else
    cerror "  ❌ bench not on PATH after install. Ensure ~/.local/bin is in PATH."
    echo "     Add to your shell rc:  export PATH=\"\$HOME/.local/bin:\$PATH\""
    return 1
  fi
}

# =============================================================================
# 9. SSH + Git
# =============================================================================
setup_ssh_git() {
  cstep "Setting up SSH key and Git config"

  # SSH
  if [[ ! -f "$HOME/.ssh/id_ed25519" ]] && [[ ! -f "$HOME/.ssh/id_rsa" ]]; then
    ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519" -N "" -C "frappe-dev-$(hostname)"
    cecho "  ✅ SSH key generated: $HOME/.ssh/id_ed25519"
    echo
    cwarn "  🔑 Your public key (add to GitHub / GitLab / Gitea):"
    cat "$HOME/.ssh/id_ed25519.pub"
    echo
  else
    cecho "  ✅ SSH key already exists"
  fi

  # Git global config
  if ! git config --global user.name &>/dev/null; then
    read -rp "  Git username: " GIT_USERNAME
    read -rp "  Git email:    " GIT_EMAIL
    git config --global user.name "$GIT_USERNAME"
    git config --global user.email "$GIT_EMAIL"
    git config --global init.defaultBranch main
    cecho "  ✅ Git configured"
  else
    cecho "  ✅ Git already configured ($(git config --global user.email))"
  fi
}

# =============================================================================
# 10. COMPLETE SETUP (calls all the above in order)
# =============================================================================
complete_setup() {
  cstep "Starting COMPLETE Frappe v16 System Setup"
  csep

  install_apt_packages
  install_wkhtmltopdf
  install_uv
  install_python
  install_node
  configure_mariadb
  install_bench_cli
  setup_ssh_git

  cecho ""
  cecho "🎉 Complete setup finished!"
  cecho "   Next step → run 'Create Bench' from the main menu."
  cecho "   Note: Open a fresh terminal (or run: source ~/.bashrc)"
  cecho "         so nvm and uv tool paths are active."
}

# =============================================================================
# 11. CREATE BENCH
# =============================================================================
create_bench() {
  cstep "Create a new Frappe Bench"
  refresh_env

  # Pre-flight
  for cmd in bench uv node yarn; do
    if ! command -v "$cmd" &>/dev/null; then
      cerror "  ❌ '$cmd' not found. Run 'Complete Setup' first."
      return 1
    fi
  done

  read -rp "  📁 Bench name               : " BENCH_NAME
  [[ -z "$BENCH_NAME" ]] && cerror "Bench name cannot be empty." && return 1

  read -rp "  🌿 Frappe branch [$DEFAULT_FRAPPE_BRANCH]: " FRAPPE_BRANCH
  FRAPPE_BRANCH="${FRAPPE_BRANCH:-$DEFAULT_FRAPPE_BRANCH}"

  local bench_path="$FRAPPE_HOME/$BENCH_NAME"

  if [[ -d "$bench_path" ]]; then
    cwarn "  ⚠️  '$bench_path' already exists."
    read -rp "  Continue anyway? (y/n): " CONT
    [[ "$CONT" != "y" ]] && return
  fi

  # Resolve Python 3.14 — must be an ABSOLUTE path for bench/uv venv to accept it
  local py_bin=""

  # 1. Glob uv's python store directly — always gives absolute path
  py_bin=$(compgen -G "$HOME/.local/share/uv/python/cpython-${REQUIRED_PYTHON}"*/bin/"python${REQUIRED_PYTHON}" 2>/dev/null     | head -1 || true)

  # 2. Direct PATH lookup (works if uv set it as default)
  if [[ -z "$py_bin" ]]; then
    py_bin=$(command -v "python${REQUIRED_PYTHON}" 2>/dev/null || true)
  fi

  # 3. uv python list — strip any leading ~/ or relative prefix to get absolute path
  if [[ -z "$py_bin" ]] && command -v uv &>/dev/null; then
    local raw; raw=$(uv python list --only-installed 2>/dev/null       | grep "${REQUIRED_PYTHON}"       | awk '{print $NF}'       | head -1 || true)
    # Expand ~ or prepend $HOME if path is not absolute
    if [[ "$raw" == "~/"* ]]; then
      py_bin="$HOME/${raw#~/}"
    elif [[ "$raw" != "/"* ]] && [[ -n "$raw" ]]; then
      py_bin="$HOME/$raw"
    else
      py_bin="$raw"
    fi
  fi

  # 4. Validate — must be executable and actually Python REQUIRED_PYTHON
  if [[ -n "$py_bin" && -x "$py_bin" ]]; then
    local py_ver; py_ver=$("$py_bin" -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>/dev/null || true)
    if [[ "$py_ver" != "${REQUIRED_PYTHON}" ]]; then
      cerror "  ❌ Found $py_bin but it reports Python $py_ver, not ${REQUIRED_PYTHON}."
      return 1
    fi
  else
    cerror "  ❌ Python ${REQUIRED_PYTHON} binary not found or not executable."
    cerror "     Run: uv python install ${REQUIRED_PYTHON} --default"
    cerror "     Then open a fresh terminal and retry."
    return 1
  fi

  echo ""
  echo "  🐍 Python    : $py_bin ($("$py_bin" --version 2>&1))"
  echo "  📦 Node.js   : $(node -v)"
  echo "  🧶 Yarn      : $(yarn --version)"
  echo "  🌿 Branch    : $FRAPPE_BRANCH"
  echo "  📁 Path      : $bench_path"
  echo ""

  cd "$FRAPPE_HOME"

  # bench init uses --python to select the interpreter
  bench init \
    --frappe-branch "$FRAPPE_BRANCH" \
    --python "$py_bin" \
    "$BENCH_NAME"

  cecho "  ✅ Bench '$BENCH_NAME' created at $bench_path"
  echo "     cd $bench_path && bench start"
}

# =============================================================================
# 12. CREATE SITE
# =============================================================================
create_site() {
  cstep "Create a new Frappe Site"
  refresh_env

  read -rp "  📁 Bench name: " BENCH_NAME
  local bench_path="$FRAPPE_HOME/$BENCH_NAME"
  if [[ ! -d "$bench_path" ]]; then
    cerror "  ❌ Bench '$bench_path' not found."
    return 1
  fi
  cd "$bench_path"

  read -rp "  🌐 Site name (e.g. mysite.local): " SITE_NAME
  [[ -z "$SITE_NAME" ]] && cerror "Site name cannot be empty." && return 1

  read -rp "  🗄️  MariaDB root user [root]: " DB_ROOT_USER
  DB_ROOT_USER="${DB_ROOT_USER:-root}"
  read -rsp "  🔑 MariaDB root password: " DB_ROOT_PASS; echo
  read -rsp "  🔑 Site admin password: "   ADMIN_PASS;   echo

  echo ""
  cecho "  🚧 Creating site $SITE_NAME ..."
  bench new-site "$SITE_NAME" \
    --db-root-username "$DB_ROOT_USER" \
    --db-root-password "$DB_ROOT_PASS" \
    --admin-password "$ADMIN_PASS"

  cecho "  ✅ Site '$SITE_NAME' created."

  # Optional: custom app
  read -rp "  🛠️  Create and install a custom app? (y/n): " CREATE_APP
  if [[ "$CREATE_APP" == "y" ]]; then
    read -rp "  📝 App name (snake_case): " APP_NAME
    if [[ -n "$APP_NAME" ]]; then
      bench new-app "$APP_NAME"
      bench --site "$SITE_NAME" install-app "$APP_NAME"
      cecho "  ✅ App '$APP_NAME' created and installed."

      read -rp "  🔗 Git remote URL (optional, press Enter to skip): " REPO_URL
      if [[ -n "$REPO_URL" ]]; then
        cd "apps/$APP_NAME"
        git add .
        git commit -m "feat: initial app scaffold for $APP_NAME"
        git remote add origin "$REPO_URL"
        git push -u origin main
        cd "$bench_path"
      fi
    fi
  fi

  # Environment
  echo ""
  cstep "Choose Environment"
  echo "  1) Development  — bench start (foreground)"
  echo "  2) Production   — supervisor + nginx"
  read -rp "  Choice [1-2]: " ENV_CHOICE

  case "$ENV_CHOICE" in
    1) setup_development "$bench_path" "$SITE_NAME" ;;
    2) setup_production  "$bench_path" "$BENCH_NAME" "$SITE_NAME" ;;
    *) cwarn "  No environment configured." ;;
  esac
}

# =============================================================================
# 13. DEVELOPMENT SETUP
# =============================================================================
setup_development() {
  local bench_path="$1"
  local site_name="$2"
  cstep "Development Setup"

  cd "$bench_path"

  # Enable developer mode
  bench --site "$site_name" set-config developer_mode 1
  bench --site "$site_name" clear-cache

  cecho "  ✅ Developer mode enabled."
  echo ""
  echo "  Useful commands:"
  echo "    cd $bench_path"
  echo "    bench start                          # start all services"
  echo "    bench --site $site_name migrate      # run migrations"
  echo "    bench --site $site_name console      # Python REPL"
  echo "    bench build --app frappe             # rebuild assets"
  echo ""

  read -rp "  🚀 Start dev server now? (y/n): " START
  [[ "$START" == "y" ]] && bench start
}

# =============================================================================
# 14. PRODUCTION SETUP
# =============================================================================
setup_production() {
  local bench_path="$1"
  local bench_name="$2"
  local site_name="$3"
  cstep "Production Setup"

  cd "$bench_path"

  # ── Supervisor ────────────────────────────────────────────────────────────
  cstep "Configuring Supervisor"
  bench setup supervisor --user "$USER" --yes
  sudo ln -sf "$bench_path/config/supervisor.conf" \
    "/etc/supervisor/conf.d/${bench_name}.conf"
  sudo supervisorctl reread
  sudo supervisorctl update
  cecho "  ✅ Supervisor configured"

  # ── Assets ────────────────────────────────────────────────────────────────
  cstep "Building front-end assets"
  bench build --app frappe
  bench --site "$site_name" clear-cache
  bench --site "$site_name" clear-website-cache

  # Ensure assets directory exists and has correct permissions
  mkdir -p "$bench_path/sites/assets"
  sudo chown -R "$USER:www-data" "$bench_path/sites"
  sudo chmod -R 755 "$bench_path/sites"
  find "$bench_path/sites/assets" -type f -exec chmod 644 {} \;

  # ── Nginx ─────────────────────────────────────────────────────────────────
  cstep "Configuring Nginx"
  bench setup nginx --yes

  # Patch config: remove undefined 'main' log format if present
  sed -i 's|access_log[[:space:]]*\([^ ]*\)[[:space:]]*main;|access_log \1;|g' \
    "$bench_path/config/nginx.conf"

  sudo ln -sf "$bench_path/config/nginx.conf" \
    "/etc/nginx/conf.d/${bench_name}.conf"

  if sudo nginx -t; then
    sudo systemctl reload nginx
    cecho "  ✅ Nginx configured and reloaded"
  else
    cerror "  ❌ Nginx configuration test failed — check $bench_path/config/nginx.conf"
    return 1
  fi

  # ── DNS multitenancy ──────────────────────────────────────────────────────
  bench config dns_multitenant on

  # ── SSL via Let's Encrypt ─────────────────────────────────────────────────
  read -rp "  🔐 Set up SSL (Let's Encrypt)? (y/n): " SETUP_SSL
  if [[ "$SETUP_SSL" == "y" ]]; then
    read -rp "  🌐 Domain name: " DOMAIN
    if [[ -n "$DOMAIN" ]]; then
      if host "$DOMAIN" &>/dev/null; then
        sudo certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos \
          --email "admin@${DOMAIN}" || cwarn "  ⚠️  certbot failed — set up SSL manually."
        bench setup add-domain --site "$site_name" "$DOMAIN" || true
        cecho "  ✅ SSL configured for $DOMAIN"
      else
        cwarn "  ⚠️  '$DOMAIN' does not resolve — configure DNS before running certbot."

      fi
    fi
  fi

  # Final permissions
  sudo chown -R "$USER:www-data" "$bench_path/sites"
  sudo chmod -R 755 "$bench_path/sites"

  echo ""
  cecho "🎉 Production setup complete!"
  echo ""
  echo "  Management:"
  echo "    sudo supervisorctl restart all      # restart all workers"
  echo "    sudo supervisorctl status           # check worker status"
  echo "    sudo systemctl reload nginx         # reload nginx"
  echo "    bench --site $site_name migrate     # run DB migrations"
  echo "    bench update --reset                # update frappe/apps"
}

# =============================================================================
# 15. UPGRADE bench + apps
# =============================================================================
upgrade_bench() {
  cstep "Upgrading bench CLI and Frappe apps"
  refresh_env

  read -rp "  📁 Bench path (full) or name under $FRAPPE_HOME: " B
  local bench_path
  if [[ -d "$B" ]]; then
    bench_path="$B"
  elif [[ -d "$FRAPPE_HOME/$B" ]]; then
    bench_path="$FRAPPE_HOME/$B"
  else
    cerror "  ❌ Bench not found: $B"
    return 1
  fi

  # Upgrade bench CLI itself
  uv tool upgrade frappe-bench
  cecho "  ✅ bench CLI upgraded: $(bench --version 2>/dev/null | head -1)"

  cd "$bench_path"
  bench update --reset
  cecho "  ✅ Apps updated. Run 'bench migrate' per site if needed."
}

# =============================================================================
# 16. FIX MISSING — auto-detect and install only what is absent
# =============================================================================
fix_missing() {
  cstep "Auto-fixing missing prerequisites"
  refresh_env
  local fixed=0

  # ── Node.js 24 via nvm ───────────────────────────────────────────────────
  local node_ok=false
  if command -v node &>/dev/null; then
    local nv; nv=$(node -v | sed 's/v//' | cut -d. -f1)
    [[ "$nv" -ge "$REQUIRED_NODE" ]] && node_ok=true
  fi
  if ! $node_ok; then
    cwarn "  → Node.js $REQUIRED_NODE missing — installing via nvm ..."
    install_node
    refresh_env
    (( fixed++ )) || true
  else
    cecho "  ✅ Node.js $(node -v) — OK"
  fi

  # ── Yarn 1.x ────────────────────────────────────────────────────────────
  local yarn_ok=false
  if command -v yarn &>/dev/null; then
    local yv; yv=$(yarn --version 2>/dev/null | cut -d. -f1)
    [[ "$yv" -eq 1 ]] && yarn_ok=true
  fi
  if ! $yarn_ok; then
    cwarn "  → Yarn 1.x missing — installing via npm ..."
    npm install -g yarn@"${REQUIRED_YARN_MAJOR}"
    refresh_env
    (( fixed++ )) || true
    cecho "  ✅ Yarn $(yarn --version) installed"
  else
    cecho "  ✅ Yarn $(yarn --version) — OK"
  fi

  # ── wkhtmltopdf patched qt ───────────────────────────────────────────────
  local wk_ok=false
  if command -v wkhtmltopdf &>/dev/null && wkhtmltopdf -V 2>&1 | grep -q "with patched qt"; then
    wk_ok=true
  fi
  if ! $wk_ok; then
    cwarn "  → wkhtmltopdf (patched qt) missing — installing ..."
    # Remove unpatched version first to avoid conflicts
    if command -v wkhtmltopdf &>/dev/null; then
      sudo apt remove -y wkhtmltopdf 2>/dev/null || true
    fi
    install_wkhtmltopdf
    (( fixed++ )) || true
  else
    cecho "  ✅ wkhtmltopdf (patched qt) — OK"
  fi

  # ── Python 3.14 via uv ──────────────────────────────────────────────────
  local py_ok=false
  if command -v uv &>/dev/null && uv python list 2>/dev/null | grep -q "${REQUIRED_PYTHON}"; then
    py_ok=true
  fi
  if ! $py_ok; then
    cwarn "  → Python $REQUIRED_PYTHON missing — installing via uv ..."
    install_uv
    install_python
    refresh_env
    (( fixed++ )) || true
  else
    cecho "  ✅ Python $REQUIRED_PYTHON (uv) — OK"
  fi

  # ── bench CLI ────────────────────────────────────────────────────────────
  if ! command -v bench &>/dev/null; then
    cwarn "  → bench CLI missing — installing via uv ..."
    install_bench_cli
    refresh_env
    (( fixed++ )) || true
  else
    cecho "  ✅ bench $(bench --version 2>/dev/null | head -1) — OK"
  fi

  echo ""
  if [[ "$fixed" -eq 0 ]]; then
    cecho "✅ Nothing to fix — all checked prerequisites are satisfied."
  else
    cecho "✅ Fixed $fixed missing prerequisite(s)."
    cwarn "   Run option 1 (Verify System) to confirm everything is green."
    cwarn "   You may need to open a fresh terminal for PATH changes to take effect."
  fi
}

# =============================================================================
# MAIN MENU
# =============================================================================
main_menu() {
  while true; do
    echo ""
    csep
    cecho " 🚀  Frappe Setup Wizard  —  v16 Edition"
    csep
    echo "  1) Verify System     (pre-flight check)"
    echo "  2) Fix Missing       (install only what's absent)"
    echo "  3) Complete Setup    (all dependencies, safe to re-run)"
    echo "  4) Create Bench"
    echo "  5) Create Site"
    echo "  6) Upgrade bench CLI + apps"
    echo "  7) Exit"
    csep
    read -rp "  Choose [1-7]: " CHOICE

    case "$CHOICE" in
      1) verify_system ;;
      2) fix_missing ;;
      3) complete_setup ;;
      4) create_bench ;;
      5) create_site ;;
      6) upgrade_bench ;;
      7)
        echo ""
        cecho "👋 Bye!"
        exit 0
        ;;
      *) cerror "  Invalid choice. Try again." ;;
    esac
  done
}

# =============================================================================
# ENTRY POINT
# =============================================================================
cecho "
╔═══════════════════════════════════════════════════════╗
║       Frappe Setup Wizard — v16 / develop             ║
║  Python 3.14 · Node 24 · MariaDB 11.8 · uv · nvm     ║
╚═══════════════════════════════════════════════════════╝"

# Always refresh PATH so we pick up nvm/uv/bench from previous runs
refresh_env

main_menu
