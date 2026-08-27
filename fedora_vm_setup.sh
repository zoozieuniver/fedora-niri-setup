#!/usr/bin/env bash
# ==============================================================================
# FEDORA VM COMPLETE SETUP SCRIPT (Dedicated for VMware / VirtualBox Testing)
# ==============================================================================
#  Installs Niri, Waybar, Wofi, Kitty, Thunar, Fonts, Cursors, Wallpaper Engine,
#  sets up SDDM, applies Alt+ keybindings for VM, and runs safe KDE debloat.
# ==============================================================================

set -euo pipefail

LOG_FILE="/tmp/fedora_vm_setup.log"
exec > >(tee -i "$LOG_FILE") 2>&1

echo "========================================================================"
echo " 🚀 Fedora Niri VM Complete Automated Setup & Debloat"
echo "========================================================================"

TARGET_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$TARGET_USER")

if [[ $EUID -ne 0 ]]; then
    echo "❌ Error: Please run this script with sudo: sudo bash $0"
    exit 1
fi

echo "👤 Target user: $TARGET_USER ($USER_HOME)"

# ------------------------------------------------------------------------------
# 1. ENABLE REPOSITORIES & UPDATE DNF
# ------------------------------------------------------------------------------
echo "📦 Enabling RPM Fusion & Flathub repositories..."
sudo dnf install -y --skip-unavailable \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm || true

sudo dnf config-manager setopt fedora-cinnamon.enabled=0 2>/dev/null || true
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true

# ------------------------------------------------------------------------------
# 2. INSTALL SYSTEM PACKAGES
# ------------------------------------------------------------------------------
echo "🖥️ Installing Niri Desktop environment and all required system applications..."
sudo dnf install -y --allowerasing --skip-unavailable --nogpgcheck \
    sddm \
    sddm-kcm \
    niri \
    waybar \
    SwayNotificationCenter \
    wofi \
    kitty \
    thunar \
    thunar-archive-plugin \
    dolphin \
    grim \
    slurp \
    wl-clipboard \
    cliphist \
    xsettingsd \
    xwayland-satellite \
    papirus-icon-theme \
    easyeffects \
    pavucontrol \
    pulseaudio-utils \
    btop \
    fastfetch \
    qbittorrent \
    yt-dlp \
    vlc \
    gimp \
    krita \
    obs-studio \
    handbrake \
    baobab \
    rpi-imager \
    chromium \
    telegram-desktop \
    steam \
    protontricks \
    mangohud \
    gamemode \
    cups \
    firewalld

# ------------------------------------------------------------------------------
# 3. UNPACK DOTFILES, FONTS, CURSORS & WALLPAPERS FROM MASTER ARCHIVE
# ------------------------------------------------------------------------------
ARCHIVE_PATH="$USER_HOME/Downloads/all-customizations-and-dotfiles.tar.gz"
[ -f "$ARCHIVE_PATH" ] || ARCHIVE_PATH="./all-customizations-and-dotfiles.tar.gz"

if [ -f "$ARCHIVE_PATH" ]; then
    echo "🎨 Unpacking dotfiles, Monocraft fonts, Deltarune cursors, and Wallpaper Engine items..."
    sudo -u "$TARGET_USER" tar -xzf "$ARCHIVE_PATH" -C "$USER_HOME" 2>/dev/null || true
    
    # Fix paths from host (/home/zoozienix -> $USER_HOME)
    sudo -u "$TARGET_USER" find "$USER_HOME/.config/niri" "$USER_HOME/.local/bin" -type f -exec sed -i "s|/home/zoozienix|$USER_HOME|g" {} + 2>/dev/null || true
    sudo -u "$TARGET_USER" find "$USER_HOME/.config/niri" "$USER_HOME/.local/bin" -type f -exec sed -i "s|/home/zoozie_fedora|$USER_HOME|g" {} + 2>/dev/null || true
else
    echo "⚠️ Master archive not found at $ARCHIVE_PATH. Skipping extraction."
fi

# ------------------------------------------------------------------------------
# 4. CONVERT NIRI KEYBINDINGS TO Alt+ FOR VM COMPATIBILITY
# ------------------------------------------------------------------------------
KBD_CONF="$USER_HOME/.config/niri/keybindings.kdl"
if [ -f "$KBD_CONF" ]; then
    echo "🔑 Converting Niri keybindings to Alt+ for VM compatibility..."
    sudo -u "$TARGET_USER" sed -i 's/Mod+/Alt+/g' "$KBD_CONF"
    sudo -u "$TARGET_USER" sed -i 's/Super+Alt+L/Alt+Super+L/g' "$KBD_CONF"
fi

# ------------------------------------------------------------------------------
# 5. REGISTER FONTS & CURSORS
# ------------------------------------------------------------------------------
echo "🔤 Registering Monocraft fonts and Deltarune cursors..."
sudo -u "$TARGET_USER" fc-cache -fv || true

sudo -u "$TARGET_USER" mkdir -p "$USER_HOME/.icons/default"
sudo -u "$TARGET_USER" cat << 'EOF' > "$USER_HOME/.icons/default/index.theme"
[Icon Theme]
Inherits=Deltarune-Dark-Cursors
EOF

# ------------------------------------------------------------------------------
# 6. CONFIGURE SDDM DISPLAY MANAGER
# ------------------------------------------------------------------------------
echo "🖥️ Configuring SDDM Display Manager for Niri..."
sudo systemctl set-default graphical.target
sudo systemctl enable --now sddm || true

sudo mkdir -p /etc/sddm.conf.d
cat << EOF | sudo tee /etc/sddm.conf.d/niri.conf > /dev/null
[Theme]
Current=breeze

[Autologin]
User=$TARGET_USER
Session=niri.desktop
EOF

# ------------------------------------------------------------------------------
# 7. RUN SAFE KDE DEBLOAT
# ------------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEBLOAT_SCRIPT="$SCRIPT_DIR/fedora_debloat_kde.sh"
[ -f "$DEBLOAT_SCRIPT" ] || DEBLOAT_SCRIPT="$USER_HOME/fedora_debloat_kde.sh"

if [ -f "$DEBLOAT_SCRIPT" ]; then
    echo "🧹 Executing safe KDE debloat script..."
    bash "$DEBLOAT_SCRIPT" || true
fi

# ------------------------------------------------------------------------------
# 8. PERMISSIONS & FINISH
# ------------------------------------------------------------------------------
sudo chown -R "$TARGET_USER:$TARGET_USER" "$USER_HOME/.config" "$USER_HOME/.local" "$USER_HOME/.icons" 2>/dev/null || true

echo "========================================================================"
echo " 🎉 Fedora Niri VM Setup Completed Successfully!"
echo " Log file saved to: $LOG_FILE"
echo "========================================================================"
