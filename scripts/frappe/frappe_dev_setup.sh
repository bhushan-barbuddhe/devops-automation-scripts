#!/bin/bash

set -euo pipefail

cecho() { echo -e "\e[1;32m$1\e[0m"; }
cwarning() { echo -e "\e[1;33m$1\e[0m"; }
cerror() { echo -e "\e[1;31m$1\e[0m"; }

FRAPPE_HOME="$HOME/frappe"
VENV_DIR="$FRAPPE_HOME/venv"
DEFAULT_FRAPPE_VERSION="develop"

trap 'cerror "\n❌ Error on line $LINENO. Exiting." && exit 1' ERR

ensure_not_root() {
  if [[ $EUID -eq 0 ]]; then
    cerror "❌ Don't run this script as root"
    exit 1
  fi
}

prepare_env() {
  mkdir -p "$FRAPPE_HOME"
  cd "$FRAPPE_HOME"
}

install_system_packages() {
  cecho "🛠️ Installing system dependencies in one go..."
  sudo apt update
  sudo apt install -y \
    curl git python3-dev python3-pip python3-setuptools python3-venv \
    libffi-dev build-essential redis-server supervisor libmysqlclient-dev \
    mariadb-server mariadb-client python3-mysqldb pkg-config default-libmysqlclient-dev \
    gcc nginx certbot python3-certbot-nginx wkhtmltopdf
}

install_node() {
  if command -v node &> /dev/null; then
    local node_major
    node_major=$(node -v | cut -d. -f1 | sed 's/v//')
    if [[ "$node_major" -lt 18 ]]; then
      cecho "🔁 Upgrading Node.js..."
      curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
      sudo apt install -y nodejs
    else
      cecho "✅ Node.js $(node -v) already installed"
    fi
  else
    cecho "📦 Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt install -y nodejs
  fi
}

install_yarn() {
  if ! command -v yarn &> /dev/null; then
    cecho "📦 Installing Yarn via Corepack..."
    sudo corepack enable
    sudo corepack prepare yarn@stable --activate
  else
    cecho "✅ Yarn $(yarn --version) already installed"
  fi
}

setup_mysql() {
  cecho "🗄️ Configuring MySQL/MariaDB..."
  sudo systemctl enable --now mariadb
  if ! sudo mysql -u root -e "SELECT 1;" &> /dev/null; then
    cecho "🔐 Running mysql_secure_installation..."
    sudo mysql_secure_installation
  else
    cecho "✅ MySQL already configured"
  fi
}

setup_ssh_git() {
  cecho "🔑 Setting up SSH and Git..."
  if [[ ! -f "$HOME/.ssh/id_rsa" ]]; then
    ssh-keygen -t rsa -b 4096 -f "$HOME/.ssh/id_rsa" -N ''
    cecho "🔑 Public SSH key:"
    cat "$HOME/.ssh/id_rsa.pub"
    echo
  fi

  if ! git config --global user.name &> /dev/null; then
    read -rp "Enter your Git username: " git_username
    git config --global user.name "$git_username"
  fi

  if ! git config --global user.email &> /dev/null; then
    read -rp "Enter your Git email: " git_email
    git config --global user.email "$git_email"
  fi
}

setup_venv() {
  cecho "🐍 Creating Python virtual environment..."
  if [[ ! -d "$VENV_DIR" ]]; then
    python3 -m venv "$VENV_DIR"
  fi
  source "$VENV_DIR/bin/activate"
  pip install --upgrade pip wheel frappe-bench
}

create_dev_bench() {
  cecho "🏗️ Creating development bench..."
  local bench_name="${1:-dev-bench}"
  local frappe_version="${2:-$DEFAULT_FRAPPE_VERSION}"

  if [[ -d "$FRAPPE_HOME/$bench_name" ]]; then
    cwarning "⚠️ Bench '$bench_name' already exists, skipping creation."
    return
  fi

  cd "$FRAPPE_HOME"
  bench init --frappe-branch "$frappe_version" "$bench_name"
}

create_dev_site() {
  local bench_name="${1:-dev-bench}"
  local site_name="${2:-site1.local}"
  cecho "🌐 Creating development site '$site_name' in bench '$bench_name'..."

  if [[ ! -d "$FRAPPE_HOME/$bench_name" ]]; then
    cerror "❌ Bench '$bench_name' not found. Run create_dev_bench first."
    exit 1
  fi

  cd "$FRAPPE_HOME/$bench_name"
  if bench list-sites | grep -qx "$site_name"; then
    cwarning "⚠️ Site '$site_name' already exists, skipping creation."
    return
  fi

  bench new-site "$site_name"
}

start_dev_server() {
  local bench_name="${1:-dev-bench}"
  cecho "🚀 Starting development server for bench '$bench_name'..."
  cd "$FRAPPE_HOME/$bench_name"
  bench start
}

main() {
  ensure_not_root
  prepare_env
  install_system_packages
  install_node
  install_yarn
  setup_mysql
  setup_ssh_git
  setup_venv

  cecho "✅ Base dependencies installed."

  read -rp "Create dev bench now? (y/n): " create_bench_choice
  if [[ "$create_bench_choice" == "y" ]]; then
    read -rp "Bench name [dev-bench]: " bench_name
    bench_name=${bench_name:-dev-bench}
    read -rp "Frappe branch [$DEFAULT_FRAPPE_VERSION]: " frappe_version
    frappe_version=${frappe_version:-$DEFAULT_FRAPPE_VERSION}
    create_dev_bench "$bench_name" "$frappe_version"

    read -rp "Create default site site1.local? (y/n): " create_site_choice
    if [[ "$create_site_choice" == "y" ]]; then
      read -rp "Site name [site1.local]: " site_name
      site_name=${site_name:-site1.local}
      create_dev_site "$bench_name" "$site_name"
    fi

    read -rp "Start bench start now? (y/n): " start_choice
    if [[ "$start_choice" == "y" ]]; then
      start_dev_server "$bench_name"
    else
      cecho "ℹ️ Run 'cd $FRAPPE_HOME/$bench_name && bench start' when ready."
    fi
  else
    cecho "ℹ️ Skip bench creation. You can run this script later to add it."
  fi
}

main "$@"

