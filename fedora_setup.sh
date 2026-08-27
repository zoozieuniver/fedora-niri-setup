#!/usr/bin/env bash
# ==============================================================================
#   FEDORA MASTER SETUP SCRIPT FOR ZOOZIENIX NIRI DESKTOP (V15 PERFECT)
# ==============================================================================
set -e

# ------------------------------------------------------------------------------
# 0. ABSOLUTE COMPLETE VERBOSE LOGGING SETUP (SHOWS EVERYTHING)
# ------------------------------------------------------------------------------
REAL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

LOGFILE1="/tmp/fedora_setup.log"
LOGFILE2="/var/log/fedora_setup.log"
LOGFILE3="$USER_HOME/fedora_setup.log"

touch "$LOGFILE1" "$LOGFILE2" "$LOGFILE3" 2>/dev/null || true
chmod 666 "$LOGFILE1" "$LOGFILE2" "$LOGFILE3" 2>/dev/null || true

exec &> >(tee -a "$LOGFILE1" "$LOGFILE2" "$LOGFILE3")
set -x # Enable 100% verbose shell tracing live

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 Starting Fedora Master Setup Script for user: $REAL_USER ($USER_HOME)..."

# ------------------------------------------------------------------------------
# 1. UPDATE SYSTEM & INSTALL RPM REPOSITORIES
# ------------------------------------------------------------------------------
echo "📦 Updating system and enabling RPM repositories..."
sudo dnf update -y || true
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm || true

# Enable Helium COPR & Flathub
echo "🌐 Enabling Helium Browser COPR repository..."
sudo dnf copr enable -y imput/helium || true
sudo dnf config-manager enable fedora-cisco-openh264 2>/dev/null || true
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true

# ------------------------------------------------------------------------------
# 2. CREATE OFFICIAL XDG SYSTEM DIRECTORIES (DOWNLOADS, DOCUMENTS, PICTURES)
# ------------------------------------------------------------------------------
echo "📁 Creating official XDG user directories..."
sudo dnf install -y xdg-user-dirs || true
sudo -u "$REAL_USER" xdg-user-dirs-update --force 2>/dev/null || true
mkdir -p "$USER_HOME/Projects" "$USER_HOME/Games" "$USER_HOME/Downloads" "$USER_HOME/Documents" "$USER_HOME/Pictures" "$USER_HOME/Music" "$USER_HOME/Videos" 2>/dev/null || true

# ------------------------------------------------------------------------------
# 3. RESOLVE RPM CONFLICTS & INSTALL SYSTEM PACKAGES
# ------------------------------------------------------------------------------
echo "🧹 Resolving pre-installed Fedora 44 kmime package conflicts..."
sudo dnf remove -y kmime kmime-libs 2>/dev/null || true
sudo rpm -e --nodeps kmime 2>/dev/null || true

echo "🖥️ Installing Niri Desktop environment, Helium browser, and ALL NixOS applications..."
sudo dnf install -y --allowerasing --skip-unavailable --nogpgcheck \
    helium-bin \
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
echo "⚡ Installing Zed Code Editor..."
if ! command -v zed &> /dev/null; then
    sudo -u "$REAL_USER" curl -f https://zed.dev/install.sh | sh || true
fi

# ------------------------------------------------------------------------------
# 4. NATIVE RPM DOWNLOADS (VESKTOP, HEROIC LAUNCHER & ONLYOFFICE)
# ------------------------------------------------------------------------------
echo "📦 Installing native RPM packages for Vesktop, Heroic Games Launcher & OnlyOffice..."
TMP_RPM=$(mktemp -d)
cd "$TMP_RPM"

VESKTOP_RPM_URL=$(curl -s https://api.github.com/repos/Vencord/Vesktop/releases/latest | grep "browser_download_url.*x86_64.rpm" | cut -d '"' -f 4 | head -n 1 || true)
if [ -n "$VESKTOP_RPM_URL" ]; then
    echo "📥 Downloading Vesktop Native RPM..."
    curl -sL "$VESKTOP_RPM_URL" -o vesktop.rpm
    sudo dnf install -y ./vesktop.rpm || true
fi

HEROIC_RPM_URL=$(curl -s https://api.github.com/repos/Heroic-Games-Launcher/HeroicGamesLauncher/releases/latest | grep "browser_download_url.*x86_64.rpm" | cut -d '"' -f 4 | head -n 1 || true)
if [ -n "$HEROIC_RPM_URL" ]; then
    echo "📥 Downloading Heroic Games Launcher Native RPM..."
    curl -sL "$HEROIC_RPM_URL" -o heroic.rpm
    sudo dnf install -y ./heroic.rpm || true
fi

echo "📥 Downloading OnlyOffice Native RPM..."
curl -sL "https://download.onlyoffice.com/install/desktop/editors/linux/onlyoffice-desktopeditors.x86_64.rpm" -o onlyoffice.rpm || true
if [ -f onlyoffice.rpm ]; then
    sudo dnf install -y ./onlyoffice.rpm || true
fi

cd "$USER_HOME"
rm -rf "$TMP_RPM"

# ------------------------------------------------------------------------------
# 5. FLATPAK SETUP (SOBER ROBLOX, VIBER, PRISMLAUNCHER, PROTONUP, CZKAWKA, HELIUM FALLBACK)
# ------------------------------------------------------------------------------
echo "🌐 Configuring Flatpak applications..."
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

# Set Helium as default browser
sudo -u "$REAL_USER" xdg-settings set default-web-browser net.imput.Helium.desktop 2>/dev/null || true

# ------------------------------------------------------------------------------
# 6. VMWARE WORKSTATION INSTALLER & MODULE BUILDER (FROM TAR.GZ)
# ------------------------------------------------------------------------------
echo "💻 Setting up VMware Workstation..."
VM_BUNDLE=$(find "$USER_HOME" /tmp "$SCRIPT_DIR" -iname "VMware-Workstation-*.bundle" 2>/dev/null | head -n 1 || true)

if [ -z "$VM_BUNDLE" ] && ! command -v vmware &> /dev/null; then
    echo "📥 Downloading VMware Workstation..."
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

# Build VMware host modules
echo "⚙️ Building VMware host kernel modules (vmmon & vmnet)..."
TMP_MOD=$(mktemp -d)
cd "$TMP_MOD"
curl -fsSL "https://github.com/user-attachments/files/19986002/vmware-host-modules-workstation-17.6.0.tar.gz" -o vmware-modules.tar.gz || true
if [ -f vmware-modules.tar.gz ]; then
    tar -xzf vmware-modules.tar.gz
    cd vmware-host-modules* || true
    make || true
    sudo make install || true
    sudo modprobe -a vmmon vmnet 2>/dev/null || true
fi
cd "$USER_HOME"
rm -rf "$TMP_MOD"

# Configure Kitty fastfetch auto-start in .bashrc
if ! grep -q "fastfetch" "$USER_HOME/.bashrc" 2>/dev/null; then
    cat << 'EOF' >> "$USER_HOME/.bashrc"

# Auto-start fastfetch inside interactive terminals (like Kitty)
if [[ $- == *i* ]] && [ "$TERM_PROGRAM" != "zed" ]; then
    fastfetch
fi
EOF
fi

# ------------------------------------------------------------------------------
# 7. SDDM & ACCOUNTS SERVICE DEFAULT SESSION SETUP
# ------------------------------------------------------------------------------
echo "🖥️ Configuring SDDM Display Manager & SSH service..."
sudo systemctl enable --now sshd 2>/dev/null || true
sudo systemctl set-default graphical.target
sudo systemctl enable --now sddm 2>/dev/null || true

sudo mkdir -p /etc/sddm.conf.d 2>/dev/null || true
cat << EOF | sudo tee /etc/sddm.conf.d/niri-session.conf > /dev/null
[Desktop]
Session=niri.desktop

[Autologin]
User=$REAL_USER
Session=niri.desktop
EOF

# ------------------------------------------------------------------------------
# 8. RUN SAFE KDE DEBLOAT
# ------------------------------------------------------------------------------
DEBLOAT_PACKAGES=(
    alacritty
    mpv mpv-libs mpv-devel
    konsole
    dolphin
    kwalletmanager5 pam-kwallet signon-kwallet-extension kwalletmanager kf5-kwallet kf6-kwallet
    kmouth
    kcharselect
    kamera
    sweeper kfind kget krdc krfb krfb-libs kjournald krenamer
    kmahjongg kpat kmines ksudoku knavalbattle kbounce kblocks klines kreversi
    kbattleship kblackbox bovo granatier kapman katomic kdiamond kigo killbots
    kiriki kjumpingcube knetwalk knights kolf kollision kshisen ksnakeduel
    kspaceduel ksquares ktuberling kubrick lskat palapeli picmi
    dragonplayer elisa-player ktorrent kmail kontact kaddressbook korganizer akregator
    "libreoffice*" gnome-tour gnome-boxes mediawriter
)

echo "🧹 Executing safe KDE debloat..."
sudo dnf remove -y --noautoremove "${DEBLOAT_PACKAGES[@]}" || true

# ------------------------------------------------------------------------------
# 9. PERMISSIONS & FINISH
# ------------------------------------------------------------------------------
sudo chown -R "$REAL_USER:$REAL_USER" "$USER_HOME/.config" "$USER_HOME/.local" "$USER_HOME/.icons" "$USER_HOME/Projects" "$USER_HOME/Games" "$USER_HOME/fedora_setup.log" 2>/dev/null || true

echo "========================================================================"
echo " 🎉 Fedora Master Setup Completed Successfully!"
echo " Log files saved to: $LOGFILE1, $LOGFILE2, and $LOGFILE3"
echo "========================================================================"
