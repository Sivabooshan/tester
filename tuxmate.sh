#!/bin/bash
#
#  ████████╗██╗   ██╗██╗  ██╗███╗   ███╗ █████╗ ████████╗███████╗
#  ╚══██╔══╝██║   ██║╚██╗██╔╝████╗ ████║██╔══██╗╚══██╔══╝██╔════╝
#     ██║   ██║   ██║ ╚███╔╝ ██╔████╔██║███████║   ██║   █████╗
#     ██║   ██║   ██║ ██╔██╗ ██║╚██╔╝██║██╔══██║   ██║   ██╔══╝
#     ██║   ╚██████╔╝██╔╝ ██╗██║ ╚═╝ ██║██║  ██║   ██║   ███████╗
#     ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝
#
#  Linux App Installer + Dotfiles Ritual
#  [https://github.com/abusoww/tuxmate](https://github.com/abusoww/tuxmate)
#
#  Distribution: Arch Linux
#
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
#  Colors & Utilities
# ─────────────────────────────────────────────────────────────────────────────
if [ -t 1 ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  CYAN='\033[0;36m'
  PURPLE='\033[0;35m'
  WHITE='\033[1;37m'
  BOLD='\033[1m'
  DIM='\033[2m'
  NC='\033[0m'
else
  RED='' GREEN='' YELLOW='' BLUE='' CYAN='' PURPLE='' WHITE='' BOLD='' DIM='' NC=''
fi

announce_quest() { echo -e "${CYAN}⚓  ${BOLD}$1${NC}"; }
checkpoint() {
  local msg="$1"
  local time_str
  time_str=$(date +"%H:%M:%S")
  echo -e "\n${BLUE}>>> [${time_str}] ${BOLD}${msg}${NC}\n"
}

# ─────────────────────────────────────────────────────────────────────────────
#  Pirate‑themed DX + Logging
# ─────────────────────────────────────────────────────────────────────────────

readonly SCRIPT_VERSION="1.0.11"
readonly SCRIPT_NAME="No Maidens UwU Sacred Installer"
readonly PIRATE_CAPTAIN="typpo_24"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_REPO="https://github.com/Sivabooshan/No_Maidens_UwU.git"
readonly DOTFILES_SANCTUARY="$HOME/No_Maidens_UwU"
readonly BACKUP_VAULT="$HOME/.config/dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
readonly SACRED_SCROLLS="$HOME/.local/log/dotfiles-ritual-$(date +%Y%m%d-%H%M%S).log"

mkdir -p "$(dirname "$SACRED_SCROLLS")"

inspire_logo() {
  cat << EOF
╔═════════════════════════════════════════════════════════════════╗
║      🏴‍☠️ Mine Sacred Dotfiles of Power - Linux Installer 🏴‍☠️      ║
║         No Maidens UwU – Apps + Dotfiles for Arch Linux         ║
╚═════════════════════════════════════════════════════════════════╝
EOF
}

inscribe_scroll() {
  local ts=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$ts] - $1" | tee -a "$SACRED_SCROLLS"

  if [[ "$VERBOSE_MODE" == "true" ]]; then
    printf "${BLUE}[VERBOSE] $1${NC}\n"
  fi
}

celebrate_victory() {
  printf "${GREEN}✓${NC} $1\n"
  inscribe_scroll "VICTORY: $1"
}

whisper_warning() {
  printf "${YELLOW}!${NC} Ancient Wisdom: $1${NC}\n"
  inscribe_scroll "WARNING: $1"
}

cry_of_despair() {
  printf "${RED}✗${NC} Curse of Failure: $1${NC}\n" >&2
  inscribe_scroll "CURSE: $1"
}

info() { printf "${BLUE}::${NC} $1\n"; }
error() { echo -e "${RED}✗${NC} $1" >&2; inscribe_scroll "ERROR: $1"; }
skip() { echo -e "${DIM}○${NC} $1 ${DIM}(already installed)${NC}"; }

# ─────────────────────────────────────────────────────────────────────────────
#  Flags
# ─────────────────────────────────────────────────────────────────────────────

DRY_RUN_MODE=false
FORCE_MODE=false
VERBOSE_MODE=false
SKIP_AUR=false
DIAGNOSE_MODE=false

process_flags() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        echo "Usage: $0 [OPTIONS]"
        echo "  --dry-run     Simulate without making changes"
        echo "  --force       Force operations (override conflicts)"
        echo "  --verbose     Enable verbose output"
        echo "  --skip-aur    Skip AUR package installation"
        echo "  --diagnose    Run system diagnostics instead of installing"
        echo "  -h, --help    Show this help"
        exit 0
        ;;
      --dry-run)
        DRY_RUN_MODE=true
        whisper_warning "Dry‑run mode: no changes will be applied"
        shift
        ;;
      --force)
        FORCE_MODE=true
        whisper_warning "Force mode enabled"
        shift
        ;;
      --verbose)
        VERBOSE_MODE=true
        whisper_warning "Verbose logging enabled"
        shift
        ;;
      --skip-aur)
        SKIP_AUR=true
        whisper_warning "AUR package installation will be skipped"
        shift
        ;;
      --diagnose)
        DIAGNOSE_MODE=true
        whisper_warning "Diagnostics mode only"
        shift
        ;;
      *)
        cry_of_despair "Unknown flag: $1"
        echo "Use --help for available options"
        exit 1
        ;;
    esac
  done
}

process_flags "$@"
unset -f process_flags

# ─────────────────────────────────────────────────────────────────────────────
#  Root + Arch + Diagnostics
# ─────────────────────────────────────────────────────────────────────────────

if [[ "$EUID" -eq 0 ]]; then
  error "This script must NOT be run as root."
  echo "Run as your regular user; script uses sudo internally when needed."
  echo "Correct invocation:"
  echo "  ./new.sh [DIVINE_FLAGS]"
  echo "  --dry-run      Simulate"
  echo "  --force        Force operations"
  echo "  --verbose      Verbose logging"
  echo "  --diagnose     Run diagnostics only"
  exit 1
fi

run_sacred_diagnostics() {
  inspire_logo
  echo -e "${PURPLE}╔════════════════════════════════════════════════════════╗"
  echo -e "${PURPLE}║            🏴‍☠️ SACRED SYSTEM DIAGNOSTICS 🏴‍☠️             ║${NC}"
  echo -e "${PURPLE}╚════════════════════════════════════════════════════════╝${NC}"
  echo

  # ─── USER CHECK ─────────────────────────────────────────────
  if [[ "$EUID" -eq 0 ]]; then
    echo "  ❌ Running as root"
    local user_ok=false
  else
    echo "  ✅ Running for user: $(whoami)"
    local user_ok=true
  fi

  # ─── ARCH CHECK ─────────────────────────────────────────────
  if [[ -f /etc/arch-release ]]; then
    echo "  ✅ Arch Linux base detected"
    local arch_ok=true
  else
    echo "  ❌ Not running on Arch base"
    local arch_ok=false
  fi

  # ─── NETWORK CHECK (STANDARDIZED: CURL ONLY) ────────────────
  local net_ok=false
  if curl -s --max-time 5 https://archlinux.org >/dev/null; then
    echo "  ✅ Internet connection OK"
    net_ok=true
  else
    echo "  ❌ No internet connection"
  fi

  # ─── ESSENTIAL TOOLS ────────────────────────────────────────
  echo
  echo -e "${CYAN}🔧 ESSENTIAL TOOLS:${NC}"
  local tools=(git curl zsh stow paru base-devel)

  for t in "${tools[@]}"; do
    if command -v "$t" &>/dev/null; then
      echo "  ✅ $t"
    else
      echo "  ❌ $t"
    fi
  done

  # ─── FINAL SUGGESTION ───────────────────────────────────────
  echo
  echo -e "${WHITE}💡 SUGGESTION:${NC}"

  if [[ "$user_ok" != true ]] || [[ "$arch_ok" != true ]] || [[ "$net_ok" != true ]]; then
    echo -e "${RED}🛡️  System not ready – fix root, Arch base, or network${NC}"
  else
    echo -e "${GREEN}🎉 System is ready for the sacred ritual${NC}"
  fi
}

if [[ "$DIAGNOSE_MODE" == "true" ]]; then
  run_sacred_diagnostics
  exit 0
fi

# ─────────────────────────────────────────────
# Package Definitions (Single Source of Truth)
# ─────────────────────────────────────────────

PACMAN_PKGS=(
  "GNU Stow:stow"
  "Tor Browser:torbrowser-launcher"
  "Discord:discord"
  "Telegram:telegram-desktop"
  "Strawberry:strawberry"
  "VLC:vlc"
  "mpv:mpv"
  "LibreOffice:libreoffice-still"
  "Calibre:calibre"
  "Okular:okular"
  "KDE Connect:kdeconnect"
  "Timeshift:timeshift"
  "qBittorrent:qbittorrent"
  "Zsh:zsh"
  "Ghostty:ghostty"
  "Starship:starship"
  "tmux:tmux"
  "gThumb:gthumb"
  "Fcitx5 Core:fcitx5"
  "Fcitx5 GTK:fcitx5-gtk"
  "Fcitx5 Config:fcitx5-configtool"
  "Mozc Japanese IME:fcitx5-mozc"
  "Japanese Fonts:noto-fonts-cjk"
  "MKVToolNix GUI:mkvtoolnix-gui"
  "Hyprland Portal (Hyprland):xdg-desktop-portal-hyprland"
  "Hyprland Portal (GTK):xdg-desktop-portal-gtk"
  "Neovim:neovim"
  "Fastfetch:fastfetch"
  "Entr:entr"
  "Hyprland:hyprland"
  "Flatpak:flatpak"
  "Build Essentials:base-devel"
  "CMake:cmake"
  "jq:jq"
  "Zip:zip"
  "Gettext:gettext"
  "Flameshot:flameshot"
)

AUR_PKGS=(
  "Zen Browser:zen-browser-bin"
  "ProtonUp-Qt:protonup-qt"
  "Proton VPN:proton-vpn-gtk-app"
  "LocalSend:localsend-bin"
  "YASP:yasp"
  "Stacher7:stacher7"
  "Pomodoro:gnome-shell-pomodoro"
  "ZapZap:zapzap-git"
  "Music Presence:music-presence-bin"
  "Memento:memento"
  "Telegram Video Downloader:tdl"
  "Minecraft:sklauncher"
)

# ─────────────────────────────────────────────────────────────────────────────
#  Utilities for new.sh engine
# ─────────────────────────────────────────────────────────────────────────────

CURRENT=0
FAILED=()
SUCCEEDED=()
SKIPPED=()
INSTALL_TIMES=()
START_TIME=$(date +%s)
PACMAN_CURRENT=0
PACMAN_TOTAL=${#PACMAN_PKGS[@]}
AUR_CURRENT=0
AUR_TOTAL=${#AUR_PKGS[@]}
EXT_CURRENT=0
EXT_TOTAL=6
AVG_TIME=8

if [[ "$SKIP_AUR" == "true" ]]; then
  TOTAL=$((PACMAN_TOTAL + EXT_TOTAL))
else
  TOTAL=$((PACMAN_TOTAL + AUR_TOTAL + EXT_TOTAL))
fi

show_progress() {
  local current=$1 total=$2 name=$3
  local percent=$((current * 100 / total))
  local filled=$((percent / 5))
  local empty=$((20 - filled))
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

run_cmd() {
  "$@" 2>&1
}

with_retry() {
  local max_attempts=3
  local attempt=1
  local delay=5
  local output
  while [ $attempt -le $max_attempts ]; do
    if output=$(run_cmd "$@"); then
      echo "$output"
      return 0
    fi
    if printf '%s' "$output" | grep -qiE "network|connection|timeout|unreachable|resolve|failed|download|temporary"; then
      if [ $attempt -lt $max_attempts ]; then
        echo -e "${YELLOW}!${NC} Network error, retrying in ${delay}s... (attempt $attempt/$max_attempts)"
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
  local installed=${#SUCCEEDED[@]}
  local skipped_count=${#SKIPPED[@]}
  local failed_count=${#FAILED[@]}

  echo
  echo "─────────────────────────────────────────────────────────────────────────────"
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

  # Pirate‑style finale banner
  echo
  echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║               🎉 SACRED RITUAL COMPLETE! 🎉                   ║${NC}"
  echo -e "${GREEN}║           🏴‍☠️ Welcome to the Ultimate Realm! 🏴‍☠️             ║${NC}"
  echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
  echo -e "${GREEN}✓ ${installed} succeeded, ${skipped_count} skipped, ${failed_count} failed${NC}"
  echo -e "${DIM}(${mins}m ${secs}s total)${NC}"
  [[ ${failed_count} -gt 0 ]] && {
    echo
    echo -e "${RED}💀 Failed: ${FAILED[*]}${NC}"
  }
}

# Dry‑run wrapper
dry_run_wrap() {
  if [[ "$DRY_RUN_MODE" == "true" ]]; then
    whisper_warning "DRY RUN: Would execute: $*"
    return 0
  fi
  "$@"
}

is_installed() {
  pacman -Q "$1" &>/dev/null
}

# ─────────────────────────────────────────────────────────────────────────────
#  Dotfiles‑only helpers (old.sh style)
# ─────────────────────────────────────────────────────────────────────────────

create_backup_sanctuary() {
  info "Creating dotfiles backup sanctuary: $BACKUP_VAULT"
  if [[ "$DRY_RUN_MODE" == "true" ]]; then
    whisper_warning "DRY RUN: Would create backup vault"
    return 0
  fi
  mkdir -p "$BACKUP_VAULT"
  local configs=(
    "$HOME/.zshrc"
    "$HOME/.tmux.conf"
    "$HOME/.config/hypr"
    "$HOME/.config/tmux"
    "$HOME/.config/ghostty"
    "$HOME/.config/starship.toml"
    "$HOME/.config/quickshell"
  )
  local count=0
  for c in "${configs[@]}"; do
    if [[ -e "$c" ]]; then
      cp -r "$c" "$BACKUP_VAULT/" 2>/dev/null || true
      ((count++))
    fi
  done
  echo "  • $count existing configs backed up"
}

acquire_dotfiles_repo() {
  info "Acquiring dotfiles repository: $DOTFILES_SANCTUARY"
  if [[ "$DRY_RUN_MODE" == "true" ]]; then
    celebrate_victory "DRY RUN: Would clone dotfiles repo"
    return 0
  fi
  if [[ -d "$DOTFILES_SANCTUARY" ]]; then
    if [[ "$FORCE_MODE" == "true" ]]; then
      rm -rf "$DOTFILES_SANCTUARY"
    else
      read -p "$(echo -e "${YELLOW}Dotfiles directory exists; purge and re‑clone? [y/N]: ${NC}")" -n1 -r
      echo
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$DOTFILES_SANCTUARY"
      else
        return 0
      fi
    fi
  fi
  dry_run_wrap git clone "$DOTFILES_REPO" "$DOTFILES_SANCTUARY" || {
    cry_of_despair "Failed to acquire dotfiles repo"
    return 1
  }
  celebrate_victory "Dotfiles repo acquired"
  inscribe_scroll "Dotfiles repo: $DOTFILES_REPO"
}

deploy_stow_configs() {
  if ! [[ -d "$DOTFILES_SANCTUARY" ]]; then
    whisper_warning "No dotfiles sanctuary; run acquire_dotfiles_repo first"
    return 1
  fi
  info "Deploying configs with GNU Stow"
  if [[ "$DRY_RUN_MODE" == "true" ]]; then
    celebrate_victory "DRY RUN: Would run stow in $DOTFILES_SANCTUARY"
    return 0
  fi
  (
    cd "$DOTFILES_SANCTUARY" || exit 1
    if stow . 2>/dev/null; then
      celebrate_victory "Configs deployed via stow"
    else
      cry_of_despair "Stow deployment failed"
      echo "Run 'stow --simulate .' in $DOTFILES_SANCTUARY to inspect conflicts"
      return 1
    fi
  )
}

summon_oh_my_zsh_with_plugins() {
  if ! command -v zsh &>/dev/null; then
    whisper_warning "Zsh not installed; install it first"
    return 1
  fi
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    whisper_warning "Oh My Zsh already installed, skipping"
    return 0
  fi
  info "Installing Oh My Zsh"
  if [[ "$DRY_RUN_MODE" == "true" ]]; then
    celebrate_victory "DRY RUN: Would install Oh My Zsh"
    return 0
  fi
 dry_run_wrap env RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || {
   cry_of_despair "Oh My Zsh install failed"
   return 1
 }
 celebrate_victory "Oh My Zsh installed"

  local plugin_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
  mkdir -p "$plugin_dir"

  local plugins=(
    "https://github.com/zsh-users/zsh-autosuggestions"
    "https://github.com/zsh-users/zsh-syntax-highlighting"
    "https://github.com/marlonrichert/zsh-autocomplete"
    "https://github.com/MichaelAquilina/zsh-you-should-use"
  )

  for url in "${plugins[@]}"; do
    local name=$(basename "$url")
    local dest="$plugin_dir/$name"
    if [[ ! -d "$dest" ]]; then
      git clone "$url" "$dest" || {
        whisper_warning "Failed to install plugin: $name"
        continue
      }
      celebrate_victory "Plugin installed: $name"
    else
      whisper_warning "Plugin already present: $name"
    fi
  done
}

offer_shell_change() {
  if [[ -z "$SHELL" ]] || ! command -v zsh &>/dev/null; then
    whisper_warning "Either SHELL is empty or zsh not installed; cannot change shell"
    return 0
  fi
  if [[ "$SHELL" == "$(command -v zsh)" ]]; then
    whisper_warning "Default shell already set to zsh"
    return 0
  fi

  if [[ "$FORCE_MODE" == "true" ]]; then
    if [[ "$DRY_RUN_MODE" == "true" ]]; then
      whisper_warning "DRY RUN: Would run chsh -s $(command -v zsh)"
      return 0
    fi
    if chsh -s "$(command -v zsh)" "$USER"; then
      info "Default shell changed to zsh"
    else
      whisper_warning "Could not change shell; run 'chsh -s $(command -v zsh)' manually"
    fi
  else
    read -p "$(echo -e "${YELLOW}Change default shell to zsh? [Y/n]: ${NC}")" -n1 -r
    echo
    if [[ "$DRY_RUN_MODE" == "true" ]]; then
      whisper_warning "DRY RUN: Would prompt for shell change"
      return 0
    fi
    if [[ $REPLY =~ ^[Nn]$ ]]; then
      whisper_warning "Keeping current shell: $SHELL"
    else
      if chsh -s "$(command -v zsh)" "$USER"; then
        celebrate_victory "Default shell changed to zsh"
      else
        whisper_warning "Could not change shell; run 'chsh -s $(command -v zsh)' manually"
      fi
    fi
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
#  Core installers: pacman, AUR, GNOME shell extensions
# ─────────────────────────────────────────────────────────────────────────────

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
    printf "${GREEN}✓${NC} %s ${DIM}(%ds)${NC}\n" "$name" "$elapsed"
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
  if [[ "$SKIP_AUR" == "true" ]]; then
    whisper_warning "AUR package installation skipped (--skip-aur)"
    return 0
  fi

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
    printf "${GREEN}✓${NC} %s ${DIM}(%ds)${NC}\n" "$name" "$elapsed"
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
  local name=$1 func=$2 uuid=""
  case "$name" in
    "Blur My Shell")          uuid="blur-my-shell@aunetx" ;;
    "Clipboard Indicator")    uuid="clipboard-indicator@tudmotu.com" ;;
    "AppIndicator Support")   uuid="appindicatorsupport@rgcjonas.gmail.com" ;;
    "Internet Speed Meter")   uuid="InternetSpeedMeter@Shakib" ;;
    "Weekly Commits")         uuid="weekly-commits@funinkina.is-a.dev" ;;
    "Kimpanel")               uuid="kimpanel@keyboard-input-method" ;;
  esac

  # Path‑based “installed” checks
  case "$name" in
    "Blur My Shell")
      if [[ -d "$HOME/.local/share/gnome-shell/extensions/blur-my-shell@aunetx" ]]; then
        skip "$name (already installed)"
        SKIPPED+=("$name")
        EXT_CURRENT=$((EXT_CURRENT + 1))
        return 0
      fi
      ;;
    "Clipboard Indicator")
      if [[ -d "$HOME/.local/share/gnome-shell/extensions/clipboard-indicator@tudmotu.com" ]]; then
        skip "$name (already installed)"
        SKIPPED+=("$name")
        EXT_CURRENT=$((EXT_CURRENT + 1))
        return 0
      fi
      ;;
    "AppIndicator Support")
      if [[ -d "$HOME/.local/share/gnome-shell/extensions/appindicatorsupport@rgcjonas.gmail.com" ]]; then
        skip "$name (already installed)"
        SKIPPED+=("$name")
        EXT_CURRENT=$((EXT_CURRENT + 1))
        return 0
      fi
      ;;
    "Internet Speed Meter")
      if [[ -d "$HOME/.local/share/gnome-shell/extensions/InternetSpeedMeter@Shakib" ]]; then
        skip "$name (already installed)"
        SKIPPED+=("$name")
        EXT_CURRENT=$((EXT_CURRENT + 1))
        return 0
      fi
      ;;
    "Weekly Commits")
      if [[ -d "$HOME/.local/share/gnome-shell/extensions/weekly-commits@funinkina.is-a.dev" ]]; then
        skip "$name (already installed)"
        SKIPPED+=("$name")
        EXT_CURRENT=$((EXT_CURRENT + 1))
        return 0
      fi
      ;;
    "Kimpanel")
      if [[ -d "$HOME/.local/share/gnome-shell/extensions/kimpanel@keyboard-input-method" ]]; then
        skip "$name (already installed)"
        SKIPPED+=("$name")
        EXT_CURRENT=$((EXT_CURRENT + 1))
        return 0
      fi
      ;;
  esac

  EXT_CURRENT=$((EXT_CURRENT + 1))
  show_progress "$EXT_CURRENT" "$EXT_TOTAL" "$name"
  local start=$(date +%s)
  local output
  if output=$(with_retry bash -c "$func"); then
    local elapsed=$(($(date +%s) - start))
    printf "\r\033[K"
    printf "${GREEN}✓${NC} %s ${DIM}(%ds)${NC}\n" "$name" "$elapsed"

    if [[ -n "$uuid" ]] && command -v gnome-extensions &>/dev/null; then
      if gnome-extensions enable "$uuid"; then
        celebrate_victory "Enabled $name ($uuid)"
      else
        whisper_warning "Failed to enable $name (run manually: gnome-extensions enable $uuid)"
      fi
    fi
    SUCCEEDED+=("$name")
  else
    printf "\n${RED}✗${NC} $name\n"
    echo "  ${DIM}Failed: $output${NC}"
    FAILED+=("$name")
  fi
}


# ─────────────────────────────────────────────────────────────────────────────

[ "$EUID" -eq 0 ] && {
  error "Run as regular user, not root."
  exit 1
}

max_wait=60  # seconds
waited=0

while [ -f /var/lib/pacman/db.lck ] && [ $waited -lt $max_wait ]; do
  whisper_warning "Waiting for pacman lock... (${waited}s)"
  sleep 2
  waited=$((waited + 2))
done

if [ -f /var/lib/pacman/db.lck ]; then
  error "Pacman lock still present after ${max_wait}s."
  echo "Another package manager may be stuck."
  echo "If you're sure nothing is running, remove it manually:"
  echo "  sudo rm /var/lib/pacman/db.lck"
  exit 1
fi

checkpoint "Starting base setup (syncing pacman)"

info "Syncing databases..."
with_retry sudo pacman -Syu --noconfirm >/dev/null && celebrate_victory "Synced" || whisper_warning "Sync failed, continuing..."


echo
checkpoint "Installing paru AUR helper"

if ! command -v paru &>/dev/null; then
  whisper_warning "Installing paru for AUR packages..."

  sudo pacman -S --needed --noconfirm git base-devel
  tmp=$(mktemp -d)

  info "Cloning paru from AUR..."
  git clone https://aur.archlinux.org/paru.git "$tmp/paru"|| {
  error "Failed to clone paru"
  exit 1
}

  info "Building paru (this takes ~2-5 min)..."

  if ! (cd "$tmp/paru" && makepkg -si --noconfirm); then
    error "paru installation failed"
    rm -rf "$tmp"
    exit 1
  fi

  rm -rf "$tmp"

  if command -v paru &>/dev/null; then
    celebrate_victory "paru installed successfully"
  else
    error "paru installation failed"
    exit 1
  fi
fi

# ════════════════════════════════════════════════════════════════════════════
# GRAND RITUAL EXECUTION
# ════════════════════════════════════════════════════════════════════════════

for cmd in git curl sudo; do
  command -v "$cmd" &>/dev/null || {
    error "Missing required tool: $cmd"
    exit 1
  }
done

begin_sacred_ritual() {
  # Use the flags you already defined: DRY_RUN_MODE, VERBOSE_MODE, etc.
  trap 'cry_of_despair "Ritual interrupted! Backup: $BACKUP_VAULT"; print_summary; exit 130' INT

  echo
  info "Installing $TOTAL packages ($PACMAN_TOTAL pacman + $AUR_TOTAL AUR + $EXT_TOTAL extensions)"
  echo

  echo
  info "Installing $PACMAN_TOTAL system applications (pacman)"
  echo

  checkpoint "Authenticating sudo for Pacman Packages installation"
  sudo -v
  celebrate_victory "Sudo authenticated - no more prompts during Pacman installation"
  echo

  inscribe_scroll "=== SACRED RITUAL COMMENCED ==="

  # DIVINE CONSENT
  if [[ "$DRY_RUN_MODE" != true ]]; then
    echo -e "${WHITE}🏴‍☠️ SACRED GIFTS:${NC}"
    echo "• 35 pacman + 9 AUR apps (Zen Browser, ProtonVPN, Discord...)"
    echo "• Sacred dotfiles deployment (zshrc, tmux, hyprland...)"
    echo "• Oh My Zsh + 4 mystical plugins"
    echo "• Automatic backups + detailed logs"
    echo "• Optional Zsh shell transformation"
    echo
    echo -e "${YELLOW}⚠️  WARNINGs: Arch only, may take 30–60 minutes${NC}"
    # 👉 AUTO-CONFIRM LOGIC
    if [[ "$FORCE_MODE" == "true" ]]; then
      REPLY="y"
      whisper_warning "Auto-confirm enabled (--force)"
    else
      read -p "$(echo -e "${WHITE}⚔️  Proceed with the sacred ritual? [y/N]: ${NC}")" -n1 -r
      echo
    fi
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      whisper_warning "Ritual respectfully declined"
      exit 0
    fi
  fi
  
  # Quick final check
  echo
  checkpoint "Running sacred diagnostics"
  run_sacred_diagnostics  # you already have this defined

  # BACKUP & DOTFILES
  echo
  checkpoint "Creating dotfiles backup sanctuary"
  create_backup_sanctuary

  echo
  checkpoint "Acquiring sacred dotfiles repository"
  acquire_dotfiles_repo

  # PACMAN PACKAGES
  echo
  announce_quest "Installing $PACMAN_TOTAL system applications "
  for entry in "${PACMAN_PKGS[@]}"; do
    name="${entry%%:*}"
    pkg="${entry##*:}"
    install_pacman "$name" "$pkg"
  done

  # AUR PACKAGES
  echo
  announce_quest "Acquiring $AUR_TOTAL AUR treasures..."

  if command -v paru &>/dev/null && [[ "$SKIP_AUR" == "false" ]]; then
    for entry in "${AUR_PKGS[@]}"; do
      name="${entry%%:*}"
      pkg="${entry##*:}"
      install_aur "$name" "$pkg"
    done
  fi

# FLATPAK
echo
announce_quest "Setting up Flatpak & Japanese IME..."
if ! command -v flatpak &>/dev/null; then
  whisper_warning "Flatpak not installed, skipping Flatpak setup"
else
  if ! flatpak --version &>/dev/null; then
    whisper_warning "Flatpak not fully initialized (try relogin if issues occur)"
  fi
  if [[ "$DRY_RUN_MODE" == "true" ]]; then
    whisper_warning "DRY RUN: Would run flatpak commands"
  else
    if with_retry flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo; then
      celebrate_victory "Flathub remote added"
    else
      whisper_warning "Failed to add Flathub remote"
    fi
    if with_retry flatpak install -y flathub com.mattjakeman.ExtensionManager; then
      celebrate_victory "Extension Manager installed"
    else
      whisper_warning "Flatpak install failed"
    fi
  fi
fi

  # JAPANESE INPUT
  echo
  checkpoint "Japanese Input Method"
  if ! grep -q 'fcitx' ~/.pam_environment 2>/dev/null; then
    cat >> ~/.pam_environment << 'EOF'

  # Japanese Input Method
  GTK_IM_MODULE=fcitx
  QT_IM_MODULE=fcitx
  XMODIFIERS=@im=fcitx
EOF
    celebrate_victory "Japanese input environment configured (~/.pam_environment)"
  else
    skip "Japanese input environment (already configured)"
  fi

  # GNOME EXTENSIONS (re‑use your existing install_gnome_ext)
  echo
  announce_quest "Installing GNOME Shell extensions..."
  install_gnome_ext "Blur My Shell" 'mkdir -p "$HOME/.local/share/gnome-shell/extensions" && tmpdir=$(mktemp -d) && cd "$tmpdir" && git clone https://github.com/aunetx/blur-my-shell && cd blur-my-shell && make install SHELL_VERSION_OVERRIDE="" && rm -rf "$tmpdir"'
  install_gnome_ext "Clipboard Indicator" 'rm -rf "$HOME/.local/share/gnome-shell/extensions/clipboard-indicator@tudmotu.com" && mkdir -p "$HOME/.local/share/gnome-shell/extensions" && tmpdir=$(mktemp -d) && cd "$tmpdir" && git clone https://github.com/Tudmotu/gnome-shell-extension-clipboard-indicator.git && mv gnome-shell-extension-clipboard-indicator "$HOME/.local/share/gnome-shell/extensions/clipboard-indicator@tudmotu.com" && rm -rf "$tmpdir"'
  install_gnome_ext "AppIndicator Support" 'rm -rf /tmp/g-s-appindicators-build && tmpdir=$(mktemp -d) && cd "$tmpdir" && git clone https://github.com/ubuntu/gnome-shell-extension-appindicator.git && cd gnome-shell-extension-appindicator && mv locale/it.po locale/it.po.bak && meson . /tmp/g-s-appindicators-build && ninja -C /tmp/g-s-appindicators-build install && rm -rf "$tmpdir" /tmp/g-s-appindicators-build'
  install_gnome_ext "Internet Speed Meter" 'tmpdir=$(mktemp -d) && cd "$tmpdir" && git clone https://github.com/AlShakib/InternetSpeedMeter.git && cd InternetSpeedMeter && ./install.sh && rm -rf "$tmpdir"'
  install_gnome_ext "Weekly Commits" 'rm -rf "$HOME/.local/share/gnome-shell/extensions/weekly-commits@funinkina.is-a.dev" && mkdir -p "$HOME/.local/share/gnome-shell/extensions" && tmpdir=$(mktemp -d) && cd "$tmpdir" && git clone https://github.com/funinkina/weekly-commits.git && mv weekly-commits "$HOME/.local/share/gnome-shell/extensions/weekly-commits@funinkina.is-a.dev" && rm -rf "$tmpdir"'
  install_gnome_ext "Kimpanel" 'tmpdir=$(mktemp -d) && cd "$tmpdir" && git clone https://github.com/wengxt/gnome-shell-extension-kimpanel.git && cd gnome-shell-extension-kimpanel && ./install.sh && rm -rf "$tmpdir"'

# HYPR CONFIG
echo
checkpoint "Hyprland configuration"
mkdir -p "$HOME/.config/hypr"
(
  cd "$HOME/.config/hypr" || exit 1
  # Ensure file exists
  touch hyprland.conf
  if ! grep -q 'kdeconnectd' hyprland.conf; then
    echo "exec-once = /usr/lib/kdeconnectd" >> hyprland.conf
  fi
  if ! grep -q 'xdg-desktop-portal-hyprland' hyprland.conf; then
    echo "exec-once = xdg-desktop-portal-hyprland" >> hyprland.conf
  fi
)
celebrate_victory "Hyprland KDE Connect configured"

  # SACRED FINALE – using your existing functions
  echo
  checkpoint "Summoning Oh My Zsh & Plugins"
  summon_oh_my_zsh_with_plugins

  echo
  checkpoint "Deploying sacred dotfiles via Stow"
  deploy_stow_configs

  echo
  checkpoint "Offering shell transformation"
  offer_shell_change

  # SUMMARY + BLESSINGS
  print_summary
  echo
  echo -e "${PURPLE}🏴‍☠️ FINAL BLESSINGS ⚔️${NC}"
  echo "• Backup vault: $BACKUP_VAULT"
  echo "• Sacred scrolls: $SACRED_SCROLLS"
  echo "• Restart shell: ${CYAN}source ~/.zshrc${NC}"
  echo "• Full effect: Log out & back in"
  inscribe_scroll "=== ULTIMATE RITUAL COMPLETED SUCCESSFULLY ==="
}
