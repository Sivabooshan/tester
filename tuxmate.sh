#!/bin/bash
#
#  ████████╗██╗   ██╗██╗  ██╗███╗   ███╗ █████╗ ████████╗███████╗
#  ╚══██╔══╝██║   ██║╚██╗██╔╝████╗ ████║██╔══██╗╚══██╔══╝██╔════╝
#     ██║   ██║   ██║ ╚███╔╝ ██╔████╔██║███████║   ██║   █████╗
#     ██║   ██║   ██║ ██╔██╗ ██║╚██╔╝██║██╔══██║   ██║   ██╔══╝
#     ██║   ╚██████╔╝██╔╝ ██╗██║ ╚═╝ ██║██║  ██║   ██║   ███████╗
#     ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝
#
#  Linux App Installer
#  https://github.com/abusoww/tuxmate
#
#  Distribution: Arch Linux
#
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
#  Colors & Utilities
# ─────────────────────────────────────────────────────────────────────────────

if [ -t 1 ]; then
  RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m'
  BLUE='\033[0;34m' CYAN='\033[0;36m' BOLD='\033[1m' DIM='\033[2m' NC='\033[0m'
else
  RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' DIM='' NC=''
fi

info() { echo -e "${BLUE}::${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}!${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1" >&2; }
skip() { echo -e "${DIM}○${NC} $1 ${DIM}(already installed)${NC}"; }
timing() { echo -e "${GREEN}✓${NC} $1 ${DIM}($2s)${NC}"; }

# Graceful exit on Ctrl+C
trap 'printf "\n"; warn "Installation cancelled by user"; print_summary; exit 130' INT

CURRENT=0
FAILED=()
SUCCEEDED=()
SKIPPED=()
INSTALL_TIMES=()
START_TIME=$(date +%s)
PACMAN_CURRENT=0
PACMAN_TOTAL=37
AUR_CURRENT=0
AUR_TOTAL=11
EXT_CURRENT=0
EXT_TOTAL=6
TOTAL=$((PACMAN_TOTAL + AUR_TOTAL + EXT_TOTAL))
AVG_TIME=8 # Initial estimate: 8 seconds per package

show_progress() {
    local current=$1 total=$2 name=$3
    local percent=$((current * 100 / total))
    local filled=$((percent / 5))
    local empty=$((20 - filled))

    # Calculate ETA
    local remaining=$((total - current))
    local eta=$((remaining * AVG_TIME))
    local eta_str=""
    if [ $eta -ge 60 ]; then
        eta_str="~$((eta / 60))m"
    else
        eta_str="~${eta}s"
    fi

    printf "\r\033[K[${CYAN}"
    printf "%${filled}s" | tr ' ' '#'
    printf "${NC}"
    printf "%${empty}s" | tr ' ' '.'
    printf "] %3d%% (%d/%d) ${BOLD}%s${NC} ${DIM}%s left${NC}" "$percent" "$current" "$total" "$name" "$eta_str"
}

# Update average install time
update_avg_time() {
  local new_time=$1
  if [ ${#INSTALL_TIMES[@]} -eq 0 ]; then
    AVG_TIME=$new_time
  else
    local sum=$new_time
    for t in "${INSTALL_TIMES[@]}"; do
      sum=$((sum + t))
    done
    AVG_TIME=$((sum / (${#INSTALL_TIMES[@]} + 1)))
  fi
  INSTALL_TIMES+=($new_time)
}

# Safe command executor (no eval)
run_cmd() {
  "$@" 2>&1
}

# Network retry wrapper - uses run_cmd for safety
with_retry() {
  local max_attempts=3
  local attempt=1
  local delay=5

  while [ $attempt -le $max_attempts ]; do
    if output=$(run_cmd "$@"); then
      echo "$output"
      return 0
    fi

    # Check for network errors
    if echo "$output" | grep -qiE "network|connection|timeout|unreachable|resolve"; then
      if [ $attempt -lt $max_attempts ]; then
        warn "Network error, retrying in ${delay}s... (attempt $attempt/$max_attempts)"
        sleep $delay
        delay=$((delay * 2))
        attempt=$((attempt + 1))
        continue
      fi
    fi

    echo "$output"
    return 1
  done
  return 1
}

print_summary() {
  local end_time=$(date +%s)
  local duration=$((end_time - START_TIME))
  local mins=$((duration / 60))
  local secs=$((duration % 60))

  echo
  echo "─────────────────────────────────────────────────────────────────────────────"
  local installed=${#SUCCEEDED[@]}
  local skipped_count=${#SKIPPED[@]}
  local failed_count=${#FAILED[@]}

  if [ $failed_count -eq 0 ]; then
    if [ $skipped_count -gt 0 ]; then
      echo -e "${GREEN}✓${NC} Done! $installed installed, $skipped_count already installed ${DIM}(${mins}m ${secs}s)${NC}"
    else
      echo -e "${GREEN}✓${NC} All $TOTAL packages installed! ${DIM}(${mins}m ${secs}s)${NC}"
    fi
  else
    echo -e "${YELLOW}!${NC} $installed installed, $skipped_count skipped, $failed_count failed ${DIM}(${mins}m ${secs}s)${NC}"
    echo
    echo -e "${RED}Failed:${NC}"
    for pkg in "${FAILED[@]}"; do
      echo "  • $pkg"
    done
  fi
  echo "─────────────────────────────────────────────────────────────────────────────"
}

is_installed() { pacman -Qi "$1" &>/dev/null; }

install_pacman() {
  local name=$1 pkg=$2
  
  if is_installed "$pkg"; then
    skip "$name"
    SKIPPED+=("$name")
    PACMAN_CURRENT=$((PACMAN_CURRENT + 1))
    return 0
  fi
  PACMAN_CURRENT=$((PACMAN_CURRENT + 1))
  show_progress "$PACMAN_CURRENT" "$PACMAN_TOTAL" "$name"
  local start=$(date +%s)

  local output
  if output=$(with_retry sudo pacman -S --needed --noconfirm "$pkg"); then
    local elapsed=$(($(date +%s) - start))
    update_avg_time $elapsed
    printf "\r\033[K"
    timing "$name" "$elapsed"
    SUCCEEDED+=("$name")
  else
    printf "\r\033[K${RED}✗${NC} %s\n" "$name"
    if echo "$output" | grep -q "target not found"; then
      echo -e "    ${DIM}Package not found${NC}"
    elif echo "$output" | grep -q "signature"; then
      echo -e "    ${DIM}GPG issue - try: sudo pacman-key --refresh-keys${NC}"
    fi
    FAILED+=("$name")
  fi
}

install_aur() {
  local name=$1 pkg=$2
  
  if is_installed "$pkg"; then
    skip "$name"
    SKIPPED+=("$name")
    AUR_CURRENT=$((AUR_CURRENT + 1))
    return 0
  fi
  
  AUR_CURRENT=$((AUR_CURRENT + 1))
  
  show_progress "$AUR_CURRENT" "$AUR_TOTAL" "$name"
  local start=$(date +%s)

  local output
  if output=$(with_retry paru -S --needed --noconfirm "$pkg"); then
    local elapsed=$(($(date +%s) - start))
    update_avg_time $elapsed
    printf "\r\033[K"
    timing "$name" "$elapsed"
    SUCCEEDED+=("$name")
  else
    printf "\r\033[K${RED}✗${NC} %s\n" "$name"
    if echo "$output" | grep -q "target not found"; then
      echo -e "    ${DIM}Package not found in AUR${NC}"
    fi
    FAILED+=("$name")
  fi
}

install_gnome_ext() {
  local name=$1 func=$2
  
  if [[ "$name" == "Blur My Shell" && -d ~/.local/share/gnome-shell/extensions/blur-my-shell@aunetx ]] ||
     [[ "$name" == "Clipboard Indicator" && -d ~/.local/share/gnome-shell/extensions/clipboard-indicator@tudmotu.com ]] ||
     [[ "$name" == "AppIndicator Support" && -d ~/.local/share/gnome-shell/extensions/appindicatorsupport@rgcjonas.gmail.com ]] ||
     [[ "$name" == "Internet Speed Meter" && -d ~/.local/share/gnome-shell/extensions/InternetSpeedMeter@Shakib ]] ||
     [[ "$name" == "Weekly Commits" && -d ~/.local/share/gnome-shell/extensions/weekly-commits@funinkina.is-a.dev ]] ||
     [[ "$name" == "Kimpanel" && -d ~/.local/share/gnome-shell/extensions/kimpanel@keyboard-input-method ]]; then
    skip "$name (already installed)"
    SKIPPED+=("$name")
    EXT_CURRENT=$((EXT_CURRENT + 1))
    return 0
  fi
  
  EXT_CURRENT=$((EXT_CURRENT + 1))
  show_progress "$EXT_CURRENT" "$EXT_TOTAL" "$name"
  local start=$(date +%s)
  
  if output=$(with_retry bash -c "$func"); then
    local elapsed=$(($(date +%s) - start))
    printf "\r\033[K"
    timing "$name" "$elapsed"
    SUCCEEDED+=("$name")
  else
    printf "\n${RED}✗${NC} $name\n"
    echo "  ${DIM}Failed: $output${NC}"
    FAILED+=("$name")
  fi
}

checkpoint() {
  local msg="$1"
  local time_str
  time_str=$(date +"%H:%M:%S")
  echo -e "\n${CYAN}>>> [${time_str}] ${BOLD}${msg}${NC}\n"
}

# ─────────────────────────────────────────────────────────────────────────────

[ "$EUID" -eq 0 ] && {
  error "Run as regular user, not root."
  exit 1
}

while [ -f /var/lib/pacman/db.lck ]; do
  warn "Waiting for pacman lock..."
  sleep 2
done

checkpoint "Starting base setup (syncing pacman)"

info "Syncing databases..."
with_retry sudo pacman -Sy --noconfirm >/dev/null && success "Synced" || warn "Sync failed, continuing..."

if ! command -v paru &>/dev/null; then
  warn "Installing paru for AUR packages..."

  sudo pacman -S --needed --noconfirm git base-devel
  tmp=$(mktemp -d)

  info "Cloning paru from AUR..."
  git clone https://aur.archlinux.org/paru.git "$tmp/paru"

  info "Building paru (this takes ~2-5 min)..."
  (cd "$tmp/paru" && makepkg -si --noconfirm)

  rm -rf "$tmp"

  if command -v paru &>/dev/null; then
    success "paru installed successfully"
  else
    error "paru installation failed"
    exit 1
  fi
fi

echo
info "Installing $TOTAL packages ($PACMAN_TOTAL pacman + $AUR_TOTAL AUR + $EXT_TOTAL extensions)"
echo

info "Installing $PACMAN_TOTAL system applications (pacman)"

install_pacman "Tor Browser" "torbrowser-launcher"
install_pacman "Discord" "discord"
install_pacman "Telegram" "telegram-desktop"
install_pacman "Strawberry" "strawberry"
install_pacman "VLC" "vlc"
install_pacman "mpv" "mpv"
install_pacman "LibreOffice" "libreoffice-still"
install_pacman "Calibre" "calibre"
install_pacman "Okular" "okular"
install_pacman "KDE Connect" "kdeconnect"
install_pacman "Timeshift" "timeshift"
install_pacman "qBittorrent" "qbittorrent"
install_pacman "Zsh" "zsh"
install_pacman "Ghostty" "ghostty"
install_pacman "Starship" "starship"
install_pacman "tmux" "tmux"
install_pacman "gThumb" "gthumb"
install_pacman "Fcitx5 Core" "fcitx5"
install_pacman "Fcitx5 GTK" "fcitx5-gtk"
install_pacman "Fcitx5 Config" "fcitx5-configtool"
install_pacman "Mozc Japanese IME" "fcitx5-mozc"
install_pacman "Japanese Fonts" "noto-fonts-cjk"
install_pacman "MKVToolNix GUI" "mkvtoolnix-gui"
install_pacman "Hyprland Portal (Hyprland)" "xdg-desktop-portal-hyprland"
install_pacman "Hyprland Portal (GTK)" "xdg-desktop-portal-gtk"
install_pacman "Neovim" "neovim"
install_pacman "Fastfetch" "fastfetch"
install_pacman "Entr" "entr"
install_pacman "Hyprland" "hyprland"
install_pacman "Flatpak" "flatpak"
install_pacman "Build Essentials" "base-devel"
install_pacman "CMake" "cmake"
install_pacman "jq" "jq"
install_pacman "Zip" "zip"
install_pacman "Gettext" "gettext"
install_pacman "Flameshot" "flameshot"

info "Installing $AUR_TOTAL AUR packages"
 
if command -v paru &>/dev/null; then
  install_aur "Zen Browser" "zen-browser-bin"
  install_aur "ProtonUp-Qt" "protonup-qt"
  install_aur "Proton VPN" "proton-vpn-gtk-app"
  install_aur "LocalSend" "localsend-bin"
  install_aur "YASP" "yasp"
  install_aur "Stacher7" "stacher7"
  install_aur "Pomodoro" "gnome-shell-pomodoro"
  install_aur "ZapZap" "zapzap-git"
  install_aur "Music Presence" "music-presence-bin"
  install_aur "Memento" "memento"
  install_aur "Telegram Video Downloader" "tdl"
fi

echo
info "Setting up Japanese Input Method"
echo

if ! grep -q "fcitx" ~/.pam_environment 2>/dev/null; then
  {
    echo
    echo '# Japanese Input Method'
    echo 'GTK_IM_MODULE=fcitx'
    echo 'QT_IM_MODULE=fcitx'
    echo 'XMODIFIERS=@im=fcitx'
  } >>~/.pam_environment
  success "Japanese input environment configured (~/.pam_environment)"
else
  skip "Japanese input environment (already configured)"
fi

checkpoint "Setting up Flatpak Extension Manager"
with_retry flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
with_retry flatpak install -y flathub com.mattjakeman.ExtensionManager

if fc-cache -fv >/dev/null 2>&1; then
  success "Font cache refreshed"
else
  warn "Font cache refresh skipped"
fi
echo

checkpoint "Final configuration (Hyprland)"

if [ -d ~/.config/hypr ]; then
  echo "exec-once = /usr/lib/kdeconnectd" >>~/.config/hypr/hyprland.conf
  echo "exec-once = xdg-desktop-portal-hyprland" >>~/.config/hypr/hyprland.conf
  success "Hyprland KDE Connect configured"
fi

info "Installing $EXT_TOTAL GNOME Shell extensions"

install_gnome_ext "Blur My Shell" 'mkdir -p ~/.local/share/gnome-shell/extensions && tmpdir=$(mktemp -d) && cd "$tmpdir" && git clone https://github.com/aunetx/blur-my-shell && cd blur-my-shell && make install SHELL_VERSION_OVERRIDE="" && rm -rf "$tmpdir"'
install_gnome_ext "Clipboard Indicator" 'rm -rf ~/.local/share/gnome-shell/extensions/clipboard-indicator@tudmotu.com && mkdir -p ~/.local/share/gnome-shell/extensions && tmpdir=$(mktemp -d) && cd "$tmpdir" && git clone https://github.com/Tudmotu/gnome-shell-extension-clipboard-indicator.git && mv gnome-shell-extension-clipboard-indicator ~/.local/share/gnome-shell/extensions/clipboard-indicator@tudmotu.com && rm -rf "$tmpdir"'
install_gnome_ext "AppIndicator Support" 'rm -rf /tmp/g-s-appindicators-build && tmpdir=$(mktemp -d) && cd "$tmpdir" && git clone https://github.com/ubuntu/gnome-shell-extension-appindicator.git && cd gnome-shell-extension-appindicator && mv locale/it.po locale/it.po.bak && meson . /tmp/g-s-appindicators-build && ninja -C /tmp/g-s-appindicators-build install && rm -rf "$tmpdir" /tmp/g-s-appindicators-build'
install_gnome_ext "Internet Speed Meter" 'tmpdir=$(mktemp -d) && cd "$tmpdir" && git clone https://github.com/AlShakib/InternetSpeedMeter.git && cd InternetSpeedMeter && ./install.sh && rm -rf "$tmpdir"'
install_gnome_ext "Weekly Commits" 'rm -rf ~/.local/share/gnome-shell/extensions/weekly-commits@funinkina.is-a.dev && mkdir -p ~/.local/share/gnome-shell/extensions && tmpdir=$(mktemp -d) && cd "$tmpdir" && git clone https://github.com/funinkina/weekly-commits.git && mv weekly-commits ~/.local/share/gnome-shell/extensions/weekly-commits@funinkina.is-a.dev && rm -rf "$tmpdir"'
install_gnome_ext "Kimpanel" 'tmpdir=$(mktemp -d) && cd "$tmpdir" && git clone https://github.com/wengxt/gnome-shell-extension-kimpanel.git && cd gnome-shell-extension-kimpanel && ./install.sh && rm -rf "$tmpdir"'

print_summary
