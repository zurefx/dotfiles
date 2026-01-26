#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# GLOBALS
# ============================================================
USER_NAME="${SUDO_USER:-$USER}"
SUDO_FILE="/etc/sudoers.d/99_${USER_NAME}"
DOTFILES_REPO="https://github.com/envertex/dotfiles"

BANNER="
        Made by: envertex
Repo: https://github.com/envertex/dotfiles
"

# ============================================================
# UI
# ============================================================
banner() {
  clear
  echo -e "$BANNER\n"
}

step() {
  banner
  echo -e "➜ $1\n"
}

# ============================================================
# CHECKS
# ============================================================
[[ $EUID -eq 0 ]] && {
  echo "[!] Do not run as root"
  exit 1
}

# ============================================================
# SINGLE CONFIRM
# ============================================================
banner
read -rp "Continue installation? (Y/n): " ans
ans=${ans,,}
[[ -n "$ans" && "$ans" != "y" && "$ans" != "yes" ]] && exit 0

# ============================================================
# SUDO (ONCE)
# ============================================================
step "Caching sudo credentials"
sudo -v

run_sudo() {
  sudo "$@"
}

# ============================================================
# SUDO NOPASSWD
# ============================================================
setup_sudo() {
  step "Configuring sudo NOPASSWD"

  run_sudo sh -c "echo '$USER_NAME ALL=(ALL) NOPASSWD: ALL' > '$SUDO_FILE'"
  run_sudo chmod 440 "$SUDO_FILE"

  run_sudo visudo -cf "$SUDO_FILE" || {
    run_sudo rm -f "$SUDO_FILE"
    echo "[!] Invalid sudoers file, reverted"
    exit 1
  }
}

# ============================================================
# PACKAGE INSTALL
# ============================================================
install_pacman() {
  for pkg in "$@"; do
    step "Installing $pkg"
    pacman -Qi "$pkg" &>/dev/null || run_sudo pacman -S --needed --noconfirm "$pkg"
  done
}

install_yay() {
  command -v yay &>/dev/null || {
    echo "[!] yay not found, skipping AUR packages"
    return
  }

  for pkg in "$@"; do
    step "Installing AUR $pkg"
    yay -Qi "$pkg" &>/dev/null || yay -S --needed --noconfirm "$pkg"
  done
}

# ============================================================
# YAY (SAFE / IDEMPOTENT)
# ============================================================
setup_yay() {
  if command -v yay &>/dev/null; then
    step "yay already installed — skipping"
    return
  fi

  step "Installing yay"
  run_sudo pacman -S --needed --noconfirm git base-devel

  tmpdir="$(mktemp -d)"
  git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
  cd "$tmpdir/yay"

  makepkg -si --noconfirm
  cd /
  rm -rf "$tmpdir"
}

# ============================================================
# SERVICES
# ============================================================
setup_services() {
  step "Services"
  run_sudo systemctl enable NetworkManager lxdm
  run_sudo systemctl start NetworkManager
  echo "exec bspwm" > ~/.xinitrc
  run_sudo chsh -s /bin/zsh "$USER_NAME"
}

# ============================================================
# ZSH
# ============================================================
setup_zsh() {
  step "ZSH"
  [[ -d ~/.oh-my-zsh ]] || RUNZSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
  git clone https://github.com/zsh-users/zsh-autosuggestions \
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions" || true
  git clone https://github.com/zsh-users/zsh-syntax-highlighting \
    "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" || true
}

# ============================================================
# DOTFILES
# ============================================================
setup_dotfiles() {
  step "Dotfiles"

  DOTDIR="$HOME/dotfiles"

  # Si ya existe, no romper el flujo
  if [[ -d "$DOTDIR/.git" ]]; then
    echo "→ Dotfiles already exist, pulling updates"
    git -C "$DOTDIR" pull
  else
    git clone "$DOTFILES_REPO" "$DOTDIR"
  fi

  mkdir -p "$HOME/.config"

  [[ -d "$DOTDIR/config" ]] && cp -r "$DOTDIR/config/"* "$HOME/.config/"
  [[ -f "$DOTDIR/home/.zshrc" ]] && cp "$DOTDIR/home/.zshrc" "$HOME/"
  [[ -d "$DOTDIR/home/.mozilla" ]] && cp -r "$DOTDIR/home/.mozilla" "$HOME/"
  [[ -d "$DOTDIR/home/.local" ]] && cp -r "$DOTDIR/home/.local" "$HOME/"
  chmod +x "$HOME/.config/bspwm/bspwmrc"
  find "$HOME/.config/bspwm/scripts" -type f -exec chmod 755 {} \;
  mkdir -p "$HOME/Documents" "$HOME/Downloads" "$HOME/CTF"

}


# ============================================================
# ROOT SYNC
# ============================================================
setup_root() {
  step "Root sync"
  run_sudo chsh -s /bin/zsh root
  run_sudo cp -r ~/.oh-my-zsh /root/
  run_sudo cp ~/.zshrc /root/
  run_sudo cp -r ~/.config /root/
}


# ============================================================
# SSH (ROBUST / IDEMPOTENT)
# ============================================================
setup_ssh() {
  banner
  read -rp "Generate SSH keys? (Y/n): " ans
  ans=${ans,,}
  [[ -n "$ans" && "$ans" != "y" && "$ans" != "yes" ]] && return

  step "SSH key setup"

  DEFAULT_USER="$USER_NAME"

  echo -e "Choose SSH key mode:
  1) Default — no passphrase
  2) Secure  — with passphrase (recommended)"
  read -rp "Select option [1]: " mode
  [[ "$mode" != "2" ]] && mode=1

  read -rp "SSH key label [${DEFAULT_USER}]: " SSH_USER
  SSH_USER="${SSH_USER:-$DEFAULT_USER}"

  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"

  PASSPHRASE_RSA=""
  PASSPHRASE_ED25519=""

  if [[ "$mode" == "2" ]]; then
    while true; do
      echo "RSA passphrase:"
      read -s -p "Passphrase: " p1; echo
      read -s -p "Confirm: " p2; echo
      [[ "$p1" == "$p2" ]] && PASSPHRASE_RSA="$p1" && break
      echo "[!] Passphrases do not match"
    done

    read -s -p "ED25519 passphrase (ENTER = reuse RSA): " q1; echo
    if [[ -z "$q1" ]]; then
      PASSPHRASE_ED25519="$PASSPHRASE_RSA"
    else
      while true; do
        read -s -p "Confirm ED25519: " q2; echo
        [[ "$q1" == "$q2" ]] && PASSPHRASE_ED25519="$q1" && break
        echo "[!] Passphrases do not match"
      done
    fi
  fi

  generate_key() {
    local path="$1"
    local type="$2"
    local bits="$3"
    local pass="$4"

    if [[ -f "$path" ]]; then
      read -rp "[!] $path exists — overwrite? (y/N): " ow
      [[ "${ow,,}" != "y" ]] && return
      cp "$path" "$path.bak" 2>/dev/null || true
      cp "$path.pub" "$path.pub.bak" 2>/dev/null || true
      rm -f "$path" "$path.pub"
    fi

    step "Generating $type key"
    if [[ "$type" == "rsa" ]]; then
      ssh-keygen -t rsa -b "$bits" -f "$path" \
        -C "${SSH_USER}@$(hostname)" -N "$pass" -q
    else
      ssh-keygen -t ed25519 -f "$path" \
        -C "${SSH_USER}@$(hostname)" -N "$pass" -q
    fi

    chmod 600 "$path"
    chmod 644 "$path.pub"
  }

  generate_key "$HOME/.ssh/id_rsa" "rsa" 4096 "$PASSPHRASE_RSA"
  generate_key "$HOME/.ssh/id_ed25519" "ed25519" "" "$PASSPHRASE_ED25519"

  banner
  [[ -f ~/.ssh/id_rsa.pub ]] && {
    echo "--- id_rsa.pub ---"
    cat ~/.ssh/id_rsa.pub
    echo
  }

  [[ -f ~/.ssh/id_ed25519.pub ]] && {
    echo "--- id_ed25519.pub ---"
    cat ~/.ssh/id_ed25519.pub
    echo
  }

  read -rp "Press ENTER to continue..."
}


# ============================================================
# PACKAGES
# ============================================================
PACMAN_PKGS=(
  xorg xorg-xinit bspwm sxhkd picom feh lxdm
  kitty zsh tmux neovim rofi thunar gvfs
  bat eza xclip brightnessctl pamixer 
  pipewire pipewire-pulse wireplumber
  papirus-icon-theme dunst flameshot
  linux linux-firmware mesa xf86-video-amdgpu polybar
)

YAY_PKGS=( firefox-esr-bin i3lock-color )

# ============================================================
# MAIN
# ============================================================
setup_sudo
setup_yay
install_pacman "${PACMAN_PKGS[@]}"
install_yay "${YAY_PKGS[@]}"
setup_services
setup_zsh
setup_dotfiles
setup_root
setup_ssh

run_sudo dracut --regenerate-all --force

banner
echo "✔ DONE — Arch listo, flujo limpio 🤙"
