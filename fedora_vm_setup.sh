#!/usr/bin/env bash
# ==============================================================================
# FEDORA VM MASTER SETUP SCRIPT (100% FEATURE PARITY WITH FULL SETUP)
# ==============================================================================
#  Installs Niri, Waybar, Wofi, Kitty, Thunar, Fonts, Cursors, Wallpaper Engine,
#  Helium, Vesktop, Heroic, OnlyOffice, Flatpaks, VMware, Btrfs +C, Printer,
#  SDDM auto-login, Alt+ keybindings for VM, and runs safe KDE debloat.
# ==============================================================================

set -e

# Enable full execution logging to /tmp/fedora_vm_setup.log and ~/fedora_vm_setup.log
TARGET_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$TARGET_USER")
LOGFILE="/tmp/fedora_vm_setup.log"
USER_LOGFILE="$USER_HOME/fedora_vm_setup.log"

touch "$LOGFILE" "$USER_LOGFILE" 2>/dev/null || true
exec > >(tee -i "$LOGFILE" "$USER_LOGFILE") 2>&1
set -x # Enable 100% verbose shell tracing (+C)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $EUID -ne 0 ]]; then
    echo "❌ Error: Please run this script with sudo: sudo bash $0"
    exit 1
fi

echo "🚀 Starting Fedora VM Master Setup Script for user: $TARGET_USER ($USER_HOME)..."

# ------------------------------------------------------------------------------
# 1. UPDATE SYSTEM & ENABLE RPM FUSION & FLATHUB REPOSITORIES
# ------------------------------------------------------------------------------
echo "📦 Updating system and enabling RPM repositories..."
sudo dnf update -y || true
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm || true

# Enable Cisco OpenH264 & Flathub
sudo dnf config-manager enable fedora-cisco-openh264 2>/dev/null || true
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true

# ------------------------------------------------------------------------------
# 2. RESOLVE RPM CONFLICTS & INSTALL SYSTEM PACKAGES
# ------------------------------------------------------------------------------
echo "🧹 Resolving pre-installed Fedora 44 kmime package conflicts..."
sudo dnf remove -y kmime kmime-libs 2>/dev/null || true
sudo rpm -e --nodeps kmime 2>/dev/null || true

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
    gutenprint \
    gutenprint-doc \
    hplip \
    firewalld \
    gcc \
    gcc-c++ \
    clang \
    clang-tools-extra \
    gdb \
    nasm \
    make \
    cmake \
    ninja-build \
    cargo \
    rust \
    rust-analyzer \
    nodejs \
    python3 \
    python3-pip \
    pipx \
    git \
    wget \
    curl \
    jq \
    file-roller \
    zip \
    unzip \
    p7zip \
    p7zip-plugins \
    unrar \
    kernel-headers \
    kernel-devel \
    kernel-devel-$(uname -r) 2>/dev/null || true

# Install Zed Code Editor natively
if ! command -v zed &> /dev/null; then
    echo "⚡ Installing Zed Code Editor..."
    curl -fssSL https://zed.dev/install.sh | sh || true
fi

# ------------------------------------------------------------------------------
# 3. NATIVE RPM DOWNLOADS (VESKTOP, HEROIC LAUNCHER & ONLYOFFICE)
# ------------------------------------------------------------------------------
echo "📦 Installing native RPM packages for Vesktop, Heroic Games Launcher & OnlyOffice..."
TMP_RPM=$(mktemp -d)
cd "$TMP_RPM"

# Download and install Vesktop Native RPM
VESKTOP_RPM_URL=$(curl -s https://api.github.com/repos/Vencord/Vesktop/releases/latest | grep "browser_download_url.*x86_64.rpm" | cut -d '"' -f 4 | head -n 1 || true)
if [ -n "$VESKTOP_RPM_URL" ]; then
    echo "📥 Downloading Vesktop Native RPM..."
    curl -sL "$VESKTOP_RPM_URL" -o vesktop.rpm
    sudo dnf install -y ./vesktop.rpm || true
fi

# Download and install Heroic Games Launcher Native RPM
HEROIC_RPM_URL=$(curl -s https://api.github.com/repos/Heroic-Games-Launcher/HeroicGamesLauncher/releases/latest | grep "browser_download_url.*x86_64.rpm" | cut -d '"' -f 4 | head -n 1 || true)
if [ -n "$HEROIC_RPM_URL" ]; then
    echo "📥 Downloading Heroic Games Launcher Native RPM..."
    curl -sL "$HEROIC_RPM_URL" -o heroic.rpm
    sudo dnf install -y ./heroic.rpm || true
fi

# Download and install OnlyOffice Native RPM
echo "📥 Downloading OnlyOffice Native RPM..."
curl -sL "https://download.onlyoffice.com/install/desktop/editors/linux/onlyoffice-desktopeditors.x86_64.rpm" -o onlyoffice.rpm || true
if [ -f onlyoffice.rpm ]; then
    sudo dnf install -y ./onlyoffice.rpm || true
fi

cd "$USER_HOME"
rm -rf "$TMP_RPM"

# ------------------------------------------------------------------------------
# 4. FLATPAK SETUP (SOBER ROBLOX, VIBER, PRISMLAUNCHER, PROTONUP, CZKAWKA, HELIUM)
# ------------------------------------------------------------------------------
echo "🌐 Configuring Flatpak applications (Sober Roblox, Viber, PrismLauncher, Czkawka, Helium)..."
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
sudo flatpak update --appstream || true

sudo flatpak install -y flathub org.vinegarhq.Sober || true
sudo flatpak install -y flathub org.prismlauncher.PrismLauncher || true
sudo flatpak install -y flathub net.davidhi.ProtonUp-Qt || true
sudo flatpak install -y flathub com.github.qarmin.czkawka || true
sudo flatpak install -y flathub com.viber.Viber || true
sudo flatpak install -y flathub net.imput.Helium || true

echo "🔓 Unlocking FULL system access permissions for Flatpaks..."
sudo flatpak override --filesystem=host --filesystem=host-etc --device=all --share=ipc --share=network --socket=wayland --socket=x11 --socket=pulseaudio --socket=session-bus --socket=system-bus --allow=devel || true
flatpak override --user --filesystem=host --filesystem=host-etc --device=all --share=ipc --share=network --socket=wayland --socket=x11 --socket=pulseaudio --socket=session-bus --socket=system-bus --allow=devel || true

# ------------------------------------------------------------------------------
# 5. VMWARE WORKSTATION INSTALLER & MODULE BUILDER
# ------------------------------------------------------------------------------
echo "💻 Setting up VMware Workstation..."
VM_BUNDLE=$(find "$USER_HOME" /tmp "$SCRIPT_DIR" -iname "VMware-Workstation-*.bundle" 2>/dev/null | head -n 1 || true)

if [ -z "$VM_BUNDLE" ] && ! command -v vmware &> /dev/null; then
    echo "📥 Downloading VMware Workstation via jetfir3 script..."
    TMP_VM=$(mktemp -d)
    cd "$TMP_VM"
    curl -fsSL https://gist.githubusercontent.com/jetfir3/e25e74a42e7c7ac2c808a537b12dc768/raw/download_workstation.sh -o download_workstation.sh || true
    if [ -f download_workstation.sh ]; then
        chmod +x download_workstation.sh
        bash download_workstation.sh -v 17.6.4 || bash download_workstation.sh || true
        VM_BUNDLE=$(find "$TMP_VM" "$USER_HOME" -iname "VMware-Workstation-*.bundle" 2>/dev/null | head -n 1 || true)
    fi
fi

if [ -n "$VM_BUNDLE" ] && [ -f "$VM_BUNDLE" ] && ! command -v vmware &> /dev/null; then
    echo "⚙️ Executing VMware installer bundle: $VM_BUNDLE..."
    sudo bash "$VM_BUNDLE" --console --required --eulas-agreed || true
fi

# ------------------------------------------------------------------------------
# 6. UNPACK DOTFILES, THUNAR/KITTY CONFIGS, FONTS & CURSORS
# ------------------------------------------------------------------------------
ARCHIVE_PATH="$USER_HOME/Downloads/all-customizations-and-dotfiles.tar.gz"
[ -f "$ARCHIVE_PATH" ] || ARCHIVE_PATH="./all-customizations-and-dotfiles.tar.gz"

if [ -f "$ARCHIVE_PATH" ]; then
    echo "🎨 Unpacking Thunar, Kitty, Niri dotfiles, Monocraft fonts, Deltarune cursors, and Wallpaper Engine items..."
    sudo -u "$TARGET_USER" tar -xzf "$ARCHIVE_PATH" -C "$USER_HOME" 2>/dev/null || true
    
    # Fix paths from host (/home/zoozienix -> $USER_HOME)
    sudo -u "$TARGET_USER" find "$USER_HOME/.config/niri" "$USER_HOME/.local/bin" -type f -exec sed -i "s|/home/zoozienix|$USER_HOME|g" {} + 2>/dev/null || true
    sudo -u "$TARGET_USER" find "$USER_HOME/.config/niri" "$USER_HOME/.local/bin" -type f -exec sed -i "s|/home/zoozie_fedora|$USER_HOME|g" {} + 2>/dev/null || true
else
    echo "⚠️ Master archive not found at $ARCHIVE_PATH. Skipping extraction."
fi

# ------------------------------------------------------------------------------
# 7. CONVERT NIRI KEYBINDINGS TO Alt+ FOR VM COMPATIBILITY
# ------------------------------------------------------------------------------
KBD_CONF="$USER_HOME/.config/niri/keybindings.kdl"
if [ -f "$KBD_CONF" ]; then
    echo "🔑 Converting Niri keybindings to Alt+ for VM compatibility..."
    sudo -u "$TARGET_USER" sed -i 's/Mod+/Alt+/g' "$KBD_CONF"
    sudo -u "$TARGET_USER" sed -i 's/Super+Alt+L/Alt+Super+L/g' "$KBD_CONF"
fi

# ------------------------------------------------------------------------------
# 8. REGISTER FONTS & CURSORS
# ------------------------------------------------------------------------------
echo "🔤 Registering Monocraft fonts and Deltarune cursors..."
sudo -u "$TARGET_USER" fc-cache -fv || true

sudo -u "$TARGET_USER" mkdir -p "$USER_HOME/.icons/default"
sudo -u "$TARGET_USER" cat << 'EOF' > "$USER_HOME/.icons/default/index.theme"
[Icon Theme]
Inherits=Deltarune-Dark-Cursors
EOF

# ------------------------------------------------------------------------------
# 9. BTRFS NO-DATA-COW (+C) FOR GAMES & DOWNLOADS
# ------------------------------------------------------------------------------
echo "🚀 Creating Games directory and applying Btrfs nodatacow (+C) attributes..."
mkdir -p "$USER_HOME/Downloads" "$USER_HOME/Games" "$USER_HOME/.var/app"
sudo chattr +C "$USER_HOME/Downloads" "$USER_HOME/Games" "$USER_HOME/.var/app" 2>/dev/null || true

# ------------------------------------------------------------------------------
# 10. PRINTER SETUP (HP LaserJet 2420n @ 192.168.66.10 PCL6)
# ------------------------------------------------------------------------------
echo "🖨️ Configuring HP LaserJet 2420n Printer..."
sudo systemctl enable --now cups avahi-daemon || true
sudo lpadmin -p HP_LaserJet_2420n -v socket://192.168.66.10:9100 -E -m gutenprint.5.3://hp-lj_2420/expert -D "HP LaserJet 2420n Network Printer" 2>/dev/null || true
sudo lpadmin -d HP_LaserJet_2420n 2>/dev/null || true

# ------------------------------------------------------------------------------
# 11. CONFIGURE SDDM DISPLAY MANAGER & SSH SERVICE
# ------------------------------------------------------------------------------
echo "🖥️ Configuring SDDM Display Manager & SSH service for Niri..."
sudo systemctl enable --now sshd || true
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
# 12. RUN SAFE KDE DEBLOAT
# ------------------------------------------------------------------------------
DEBLOAT_SCRIPT="$SCRIPT_DIR/fedora_debloat_kde.sh"
[ -f "$DEBLOAT_SCRIPT" ] || DEBLOAT_SCRIPT="$USER_HOME/fedora_debloat_kde.sh"

if [ -f "$DEBLOAT_SCRIPT" ]; then
    echo "🧹 Executing safe KDE debloat script..."
    bash "$DEBLOAT_SCRIPT" || true
fi

# ------------------------------------------------------------------------------
# 13. PERMISSIONS & FINISH
# ------------------------------------------------------------------------------
sudo chown -R "$TARGET_USER:$TARGET_USER" "$USER_HOME/.config" "$USER_HOME/.local" "$USER_HOME/.icons" 2>/dev/null || true

echo "========================================================================"
echo " 🎉 Fedora Niri VM Master Setup Completed Successfully!"
echo " Log files saved to: $LOGFILE and $USER_LOGFILE"
echo "========================================================================"
