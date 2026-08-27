#!/usr/bin/env bash
# ==============================================================================
#   FEDORA MASTER SETUP SCRIPT FOR ZOOZIENIX NIRI DESKTOP (V22 BULLETPROOF)
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
# 1. REMOVE RUNLEVEL "3" OVERRIDE FROM GRUB COMMAND LINE
# ------------------------------------------------------------------------------
echo "⚙️ Purging runlevel 3 override from GRUB boot options..."
if grub2-editenv - list 2>/dev/null | grep -q "kernelopts.* 3"; then
    CURRENT_KOPTS="$(sudo grub2-editenv - list 2>/dev/null | grep kernelopts | cut -d= -f2- | sed 's/ 3//g' || true)"
    sudo grub2-editenv - set "kernelopts=$CURRENT_KOPTS" 2>/dev/null || true
fi

# ------------------------------------------------------------------------------
# 2. UPDATE SYSTEM & INSTALL RPM REPOSITORIES
# ------------------------------------------------------------------------------
echo "📦 Updating system and enabling RPM repositories..."
sudo dnf update -y || true
sudo dnf install -y --allowerasing --nogpgcheck https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm || true

# Enable Helium COPR & Flathub
echo "🌐 Enabling Helium Browser COPR repository..."
sudo dnf copr enable -y imput/helium || true
sudo dnf config-manager enable fedora-cisco-openh264 2>/dev/null || true
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true

# ------------------------------------------------------------------------------
# 3. CREATE OFFICIAL XDG SYSTEM DIRECTORIES (DOWNLOADS, DOCUMENTS, PICTURES)
# ------------------------------------------------------------------------------
echo "📁 Creating official XDG user directories..."
sudo dnf install -y xdg-user-dirs || true
sudo -u "$REAL_USER" HOME="$USER_HOME" xdg-user-dirs-update --force 2>/dev/null || true
mkdir -p "$USER_HOME/Projects" "$USER_HOME/Games" "$USER_HOME/Downloads" "$USER_HOME/Documents" "$USER_HOME/Pictures" "$USER_HOME/Music" "$USER_HOME/Videos" 2>/dev/null || true

# ------------------------------------------------------------------------------
# 4. RESOLVE RPM CONFLICTS & INSTALL SYSTEM PACKAGES
# ------------------------------------------------------------------------------
echo "🧹 Resolving pre-installed Fedora 44 kmime package conflicts..."
sudo dnf remove -y kmime kmime-libs 2>/dev/null || true
sudo rpm -e --nodeps kmime 2>/dev/null || true

echo "🖥️ Installing Niri Desktop environment, Helium browser, Discover, and ALL NixOS applications..."
sudo dnf install -y --allowerasing --skip-unavailable --nogpgcheck \
    helium-bin \
    sddm \
    sddm-kcm \
    plasma-discover \
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
    gamescope \
    waydroid \
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

# Install Tailscale VPN via official installer script
echo "🌐 Installing Tailscale VPN..."
curl -fsSL https://tailscale.com/install.sh | sh || true
sudo systemctl enable --now tailscaled 2>/dev/null || true

# Install Zed Code Editor natively for REAL_USER and globally
echo "⚡ Installing Zed Code Editor..."
if ! command -v zed &> /dev/null; then
    sudo -u "$REAL_USER" HOME="$USER_HOME" bash -c 'curl -fssSL https://zed.dev/install.sh | sh' || true
    if [ -f "$USER_HOME/.local/bin/zed" ]; then
        sudo cp "$USER_HOME/.local/bin/zed" /usr/local/bin/zed
        sudo chmod +x /usr/local/bin/zed
    fi
fi

# Install Satty screenshot editor
if ! command -v satty &> /dev/null; then
    echo "⚡ Installing Satty screenshot editor..."
    SATTY_URL=$(curl -s https://api.github.com/repos/gabm/Satty/releases/latest | grep "browser_download_url.*x86_64.*tar.gz" | cut -d '"' -f 4 | head -n 1 || true)
    if [ -n "$SATTY_URL" ]; then
        curl -sL "$SATTY_URL" | tar -xz -C /tmp || true
        if [ -f /tmp/satty ]; then
            sudo mv /tmp/satty /usr/local/bin/satty
            sudo chmod +x /usr/local/bin/satty
        fi
    fi
fi

# ------------------------------------------------------------------------------
# 5. LOCAL ARCHIVE INTEGRATIONS (PROTONUP-QT APPIMAGE & DAVINCI RESOLVE ZIP)
# ------------------------------------------------------------------------------
echo "📦 Installing local AppImage & Zip archives (ProtonUp-Qt & DaVinci Resolve)..."

PROTONUP_APPIMAGE=$(find /tmp "$USER_HOME/Downloads" "$SCRIPT_DIR" ./ -iname "ProtonUp-Qt-*.AppImage" 2>/dev/null | head -n 1 || true)
if [ -n "$PROTONUP_APPIMAGE" ] && [ -f "$PROTONUP_APPIMAGE" ]; then
    echo "⚙️ Installing local ProtonUp-Qt AppImage: $PROTONUP_APPIMAGE..."
    mkdir -p "$USER_HOME/.local/bin"
    cp "$PROTONUP_APPIMAGE" "$USER_HOME/.local/bin/protonup-qt"
    chmod +x "$USER_HOME/.local/bin/protonup-qt"
    sudo cp "$PROTONUP_APPIMAGE" /usr/local/bin/protonup-qt
    sudo chmod +x /usr/local/bin/protonup-qt
fi

DAVINCI_ZIP=$(find /tmp "$USER_HOME/Downloads" "$SCRIPT_DIR" ./ -iname "DaVinci_Resolve_*.zip" 2>/dev/null | head -n 1 || true)
if [ -n "$DAVINCI_ZIP" ] && [ -f "$DAVINCI_ZIP" ] && ! [ -d /opt/resolve ]; then
    echo "🎬 Unpacking and installing local DaVinci Resolve archive: $DAVINCI_ZIP..."
    TMP_DAVINCI="/tmp/davinci_unpack"
    rm -rf "$TMP_DAVINCI"
    mkdir -p "$TMP_DAVINCI"
    unzip -q "$DAVINCI_ZIP" -d "$TMP_DAVINCI" || true
    DAVINCI_RUN=$(find "$TMP_DAVINCI" -iname "DaVinci_Resolve_*.run" 2>/dev/null | head -n 1 || true)
    if [ -n "$DAVINCI_RUN" ]; then
        chmod +x "$DAVINCI_RUN"
        echo "🚀 Executing DaVinci Resolve installer..."
        sudo "$DAVINCI_RUN" --noconcur -i -y || true
    fi
    rm -rf "$TMP_DAVINCI"
fi

# ------------------------------------------------------------------------------
# 6. VMWARE WORKSTATION INSTALLER & KERNEL MODULES BUILDER
# ------------------------------------------------------------------------------
if ! command -v vmware &> /dev/null; then
    echo "📥 Installing VMware Workstation Workstation bundle..."
    TMP_VM="/tmp/vmware_install"
    rm -rf "$TMP_VM"
    mkdir -p "$TMP_VM"
    cd "$TMP_VM"
    curl -fsSL https://gist.githubusercontent.com/jetfir3/e25e74a42e7c7ac2c808a537b12dc768/raw/download_workstation.sh -o download_workstation.sh || true
    if [ -f download_workstation.sh ]; then
        chmod +x download_workstation.sh
        bash download_workstation.sh -v 17.6.4 || bash download_workstation.sh || true
        VM_BUNDLE=$(find "$TMP_VM" /tmp ./ -iname "VMware-Workstation-*.bundle" 2>/dev/null | head -n 1 || true)
        if [ -n "$VM_BUNDLE" ]; then
            sudo bash "$VM_BUNDLE" --console --required --eulas-agreed || true
        fi
    fi
    cd "$USER_HOME"
    rm -rf "$TMP_VM"
fi

# Build VMware host kernel modules (vmmon & vmnet) from local tar.gz
echo "⚙️ Building VMware host kernel modules (vmmon & vmnet)..."
VMWARE_TAR=$(find /tmp "$USER_HOME/Downloads" "$SCRIPT_DIR" ./ -iname "vmware-host-modules-*.tar.gz" 2>/dev/null | head -n 1 || true)

TMP_MOD="/tmp/vmware_mod_build"
rm -rf "$TMP_MOD"
mkdir -p "$TMP_MOD"
cd "$TMP_MOD"
if [ -n "$VMWARE_TAR" ] && [ -f "$VMWARE_TAR" ]; then
    echo "📦 Extracting local VMware modules archive: $VMWARE_TAR..."
    tar -xzf "$VMWARE_TAR"
else
    echo "📥 Downloading fallback VMware modules archive..."
    curl -fsSL "https://github.com/user-attachments/files/19986002/vmware-host-modules-workstation-17.6.0.tar.gz" -o vmware-modules.tar.gz || true
    tar -xzf vmware-modules.tar.gz 2>/dev/null || true
fi

if [ -d vmware-host-modules* ]; then
    cd vmware-host-modules* || true
    make || true
    sudo make install || true
    sudo modprobe -a vmmon vmnet 2>/dev/null || true
fi
cd "$USER_HOME"
rm -rf "$TMP_MOD"

# ------------------------------------------------------------------------------
# 7. NATIVE RPM DOWNLOADS (VESKTOP, HEROIC LAUNCHER & ONLYOFFICE)
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
# 8. FLATPAK SETUP (SOBER ROBLOX, VIBER, PRISMLAUNCHER, CZKAWKA, HELIUM, VIDEO-DOWNLOADER)
# ------------------------------------------------------------------------------
echo "🌐 Configuring Flatpak applications..."
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
sudo flatpak update --appstream || true

sudo flatpak install -y flathub org.vinegarhq.Sober || true
sudo flatpak install -y flathub org.prismlauncher.PrismLauncher || true
sudo flatpak install -y flathub com.github.qarmin.czkawka || true
sudo flatpak install -y flathub com.viber.Viber || true
sudo flatpak install -y flathub net.imput.Helium || true
sudo flatpak install -y flathub com.github.unrud.VideoDownloader || true

echo "🔓 Unlocking FULL system access permissions for Flatpaks..."
sudo flatpak override --filesystem=host --filesystem=host-etc --device=all --share=ipc --share=network --socket=wayland --socket=x11 --socket=pulseaudio --socket=session-bus --socket=system-bus --allow=devel || true
flatpak override --user --filesystem=host --filesystem=host-etc --device=all --share=ipc --share=network --socket=wayland --socket=x11 --socket=pulseaudio --socket=session-bus --socket=system-bus --allow=devel || true

# Set Helium as default browser
sudo -u "$REAL_USER" HOME="$USER_HOME" xdg-settings set default-web-browser net.imput.Helium.desktop 2>/dev/null || true

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
# 9. SDDM & ACCOUNTS SERVICE DEFAULT SESSION SETUP
# ------------------------------------------------------------------------------
echo "🖥️ Configuring SDDM Display Manager & SSH service..."
sudo systemctl enable --now sshd 2>/dev/null || true
sudo rm -f /etc/systemd/system/display-manager.service 2>/dev/null || true
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
# 10. NETWORK BBR TUNING & BTRFS NO-DATA-COW (+C) FOR GAMES & DOWNLOADS
# ------------------------------------------------------------------------------
echo "⚡ Applying Network BBR & Gigabit TCP buffer optimizations..."
cat << 'EOF' | sudo tee /etc/sysctl.d/99-gigabit-bbr.conf > /dev/null
net.core.default_qdisc = fq
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.core.netdev_max_backlog = 10000
EOF
sudo sysctl --system 2>/dev/null || true

# ------------------------------------------------------------------------------
# 11. PURGE EXACT REMAINING BLOATWARE PACKAGES
# ------------------------------------------------------------------------------
EXACT_DEBLOAT_PACKAGES=(
    gnome-abrt abrt-libs abrt-gui-libs abrt-desktop abrt
    setroubleshoot-server setroubleshoot-plugins setroubleshoot
    kde-partitionmanager partitionmanager
    dragonplayer orca systemsettings
    alacritty mpv mpv-libs konsole dolphin gwenview okular neochat spectacle
    kolourpaint ark kwrite skanpage kamoso kcalc filelight kdebugsettings
    kde-connect kde-connect-libs kwalletmanager5 pam-kwallet signon-kwallet-extension kwalletmanager
    kf5-kwallet kf6-kwallet kf6-kwallet-libs kmouth kcharselect kamera sweeper kfind kget krdc krfb kjournald krenamer
    kmahjongg kpat kmines ksudoku knavalbattle kbounce kblocks klines kreversi kbattleship kblackbox bovo granatier kapman
    katomic kdiamond kigo killbots kiriki kjumpingcube knetwalk knights kolf kollision kshisen ksnakeduel kspaceduel
    ksquares ktuberling kubrick lskat palapeli picmi elisa-player ktorrent kmail kontact kaddressbook
    korganizer akregator gnome-tour gnome-boxes mediawriter
)

echo "🧹 Purging exact remaining bloatware packages..."
for pkg in "${EXACT_DEBLOAT_PACKAGES[@]}"; do
    sudo dnf remove -y --noautoremove "$pkg" 2>/dev/null || true
done

# Re-verify SDDM and desktop portals
sudo dnf install -y --allowerasing sddm sddm-kcm firewalld firewall-config xdg-desktop-portal xdg-desktop-portal-gnome pipewire wireplumber xwayland-satellite 2>/dev/null || true

# ------------------------------------------------------------------------------
# 12. PERMISSIONS & FINISH
# ------------------------------------------------------------------------------
sudo chown -R "$REAL_USER:$REAL_USER" "$USER_HOME/.config" "$USER_HOME/.local" "$USER_HOME/.icons" "$USER_HOME/Projects" "$USER_HOME/Games" "$USER_HOME/fedora_setup.log" 2>/dev/null || true

echo "========================================================================"
echo " 🎉 Fedora Master Setup Completed Successfully!"
echo " Log files saved to: $LOGFILE1, $LOGFILE2, and $LOGFILE3"
echo "========================================================================"
