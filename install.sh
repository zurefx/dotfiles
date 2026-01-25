#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# GLOBALS
# ============================================================
USER_NAME="$(logname)"
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
# CONFIRM
# ============================================================
banner
read -rp "Continue installation? (Y/n): " ans
ans=${ans,,}
[[ -n "$ans" && "$ans" != "y" && "$ans" != "yes" ]] && exit 0

# ============================================================
# SUDO PASSWORD
# ============================================================
while true; do
  step "Enter sudo password"
  read -s SUDO_PASS
  echo
  echo "$SUDO_PASS" | sudo -S -v &>/dev/null && break
  sleep 1
done

run_sudo() {
  echo "$SUDO_PASS" | sudo -S "$@"
}

# ============================================================
# SUDO NOPASSWD (PERMANENT)
# ============================================================
setup_sudo() {
  step "Configuring sudo NOPASSWD"

  run_sudo tee "$SUDO_FILE" >/dev/null <<EOF
$USER_NAME ALL=(ALL) NOPASSWD: ALL
EOF

  run_sudo chmod 440 "$SUDO_FILE"

  run_sudo visudo -cf "$SUDO_FILE" || {
    run_sudo rm -f "$SUDO_FILE"
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
  for pkg in "$@"; do
    step "Installing AUR $pkg"
    yay -Qi "$pkg" &>/dev/null || yay -S --needed --noconfirm "$pkg"
  done
}

# ============================================================
# YAY
# ============================================================
setup_yay() {
  command -v yay &>/dev/null && return
  step "Installing yay"
  run_sudo pacman -S --needed git base-devel
  cd /tmp
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm
}

# ============================================================
# SERVICES
# ============================================================
setup_services() {
  step "Services"
  sudo systemctl enable NetworkManager lxdm
  sudo systemctl start NetworkManager
  echo "exec bspwm" > ~/.xinitrc
  sudo chsh -s /bin/zsh "$USER"
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
# DOTFILES (RESPETA TU TREE)
# ============================================================
setup_dotfiles() {
  step "Dotfiles"
  git clone "$DOTFILES_REPO" || true
  mkdir -p ~/.config
  cp -r dotfiles/config/* ~/.config/
  cp -r dotfiles/home/* ~/
}

# ============================================================
# ROOT SYNC
# ============================================================
setup_root() {
  step "Root sync"
  sudo chsh -s /bin/zsh root
  sudo cp -r ~/.oh-my-zsh /root/
  sudo cp ~/.zshrc /root/
  sudo cp -r ~/.config /root/
}

# ============================================================
# SSH
# ============================================================
setup_ssh() {
  step "SSH"
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh
  ssh-keygen -t ed25519 -C "envertex@$(hostname)" -f ~/.ssh/id_ed25519
  cat ~/.ssh/id_ed25519.pub
}

# ============================================================
# PACKAGES
# ============================================================
PACMAN_PKGS=(
  xorg xorg-xinit bspwm sxhkd picom feh lxdm
  kitty zsh tmux neovim rofi thunar gvfs
  bat eza xclip brightnessctl pamixer
  papirus-icon-theme dunst flameshot
  linux linux-firmware mesa xf86-video-amdgpu
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

sudo dracut --regenerate-all --force

banner
echo "✔ DONE — Arch listo, sudo libre 🤙"
