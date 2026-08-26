#!/usr/bin/env bash
# ==============================================================================
#   FEDORA MASTER SETUP SCRIPT FOR ZOOZIENIX NIRI DESKTOP (V9 LOGGING & FIXES)
# ==============================================================================
set -e

# Enable full execution logging to ~/fedora_setup.log
LOGFILE="$HOME/fedora_setup.log"
exec > >(tee -i "$LOGFILE") 2>&1

echo "🚀 Starting Fedora Master Setup Script (Logging to $LOGFILE)..."

# ------------------------------------------------------------------------------
# 1. UPDATE SYSTEM & INSTALL RPM REPOSITORIES
# ------------------------------------------------------------------------------
echo "📦 Updating system and enabling RPM repositories..."
sudo dnf update -y || true
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm || true

# Enable Cisco OpenH264
sudo dnf config-manager enable fedora-cisco-openh264 2>/dev/null || true

# ------------------------------------------------------------------------------
# 2. REMOVE ALL KDE BLOAT & SLOP (KMahjongg, KPat, KMines, DragonPlayer, etc.)
# ------------------------------------------------------------------------------
echo "🧹 Removing KDE bloat & games slop..."
sudo dnf remove -y kmahjongg kpat kmines dragonplayer ktorrent kmail libreoffice* gnome-tour gnome-boxes mediawriter || true

# ------------------------------------------------------------------------------
# 3. INSTALL COMPILERS, DEV TOOLS, QT/KDE INTEGRATION & UTILITIES
# ------------------------------------------------------------------------------
echo "🛠️ Installing compilers, Zed Editor, QT/KDE Wayland integration & tools..."
sudo dnf install -y --skip-unavailable \
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
    e2fsprogs \
    ethtool \
    qt5-qtwayland \
    qt6-qtwayland \
    kwayland-integration \
    xdg-desktop-portal-kde \
    file-roller \
    zip \
    unzip \
    p7zip \
    p7zip-plugins \
    unrar

# Install Zed Code Editor natively
if ! command -v zed &> /dev/null; then
    echo "⚡ Installing Zed Code Editor..."
    curl -fssSL https://zed.dev/install.sh | sh || true
fi

# Install Satty natively (pre-compiled binary release)
if ! command -v satty &> /dev/null; then
    echo "⚡ Installing Satty screenshot editor natively..."
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
# 4. INSTALL 100% OF SYSTEM PACKAGES FROM NIXOS CONFIG
# ------------------------------------------------------------------------------
echo "🖥️ Installing Niri Desktop environment and ALL NixOS applications..."
sudo dnf install -y --skip-unavailable \
    niri \
    waybar \
    SwayNotificationCenter \
    wofi \
    kitty \
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
    firewalld

# ------------------------------------------------------------------------------
# 5. NATIVE RPM DOWNLOADS (VESKTOP, HEROIC LAUNCHER & ONLYOFFICE)
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

cd "$HOME"
rm -rf "$TMP_RPM"

# ------------------------------------------------------------------------------
# 6. FLATPAK SETUP (SOBER ROBLOX, VIBER, PRISMLAUNCHER, PROTONUP, CZKAWKA) & 100% NATIVE PERMISSIONS
# ------------------------------------------------------------------------------
echo "🌐 Configuring Flatpak applications (Sober Roblox, Viber, PrismLauncher, Czkawka)..."
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
sudo flatpak update --appstream || true

# Install Flatpaks seamlessly
sudo flatpak install -y flathub org.vinegarhq.Sober || true
sudo flatpak install -y flathub org.prismlauncher.PrismLauncher || true
sudo flatpak install -y flathub net.davidhi.ProtonUp-Qt || true
sudo flatpak install -y flathub com.github.qarmin.czkawka || true
sudo flatpak install -y flathub com.viber.Viber || true

echo "🔓 Unlocking FULL system access permissions for Flatpaks (Operating 100% like native apps)..."
sudo flatpak override --filesystem=host --filesystem=host-etc --device=all --share=ipc --share=network --socket=wayland --socket=x11 --socket=pulseaudio --socket=session-bus --socket=system-bus --allow=devel || true
flatpak override --user --filesystem=host --filesystem=host-etc --device=all --share=ipc --share=network --socket=wayland --socket=x11 --socket=pulseaudio --socket=session-bus --socket=system-bus --allow=devel || true

# ------------------------------------------------------------------------------
# 7. AUTOMATED VMWARE WORKSTATION INSTALLATION & MODULE COMPILATION
# ------------------------------------------------------------------------------
echo "💻 Setting up VMware Workstation..."
if ! command -v vmware &> /dev/null; then
    echo "📥 Downloading VMware Workstation via jetfir3 script..."
    cd "$HOME"
    curl -fsSL https://gist.githubusercontent.com/jetfir3/e25e74a42e7c7ac2c808a537b12dc768/raw/download_workstation.sh -o download_workstation.sh || true
    if [ -f download_workstation.sh ]; then
        chmod +x download_workstation.sh
        ./download_workstation.sh -v 17.6.4 || ./download_workstation.sh || true
        rm -f download_workstation.sh
    fi
    
    VM_BUNDLE=$(find "$HOME" -maxdepth 2 -name "VMware-Workstation-*.bundle" 2>/dev/null | head -n 1 || true)
    if [ -n "$VM_BUNDLE" ]; then
        echo "⚙️ Executing VMware installer bundle: $VM_BUNDLE..."
        sudo bash "$VM_BUNDLE" --console --required --eulas-agreed || true
        rm -f "$VM_BUNDLE"
    fi
fi

# Build VMware kernel modules for Linux 6.x
mkdir -p "$HOME/.local/bin"
cat << 'EOF' > "$HOME/.local/bin/build-vmware-modules.sh"
#!/usr/bin/env bash
set -e
echo "Building VMware kernel modules..."
CDIR=$(mktemp -d)
cd "$CDIR"
git clone https://github.com/mkubecek/vmware-host-modules.git
cd vmware-host-modules
git checkout workstation-$(vmware --version 2>/dev/null | awk '{print $3}') || git checkout master
make
sudo make install
sudo systemctl enable --now vmware-USBArbitrator.service 2>/dev/null || true
sudo vmware-networks --start || true
echo "✅ VMware modules built successfully!"
EOF
chmod +x "$HOME/.local/bin/build-vmware-modules.sh"

if command -v vmware &> /dev/null; then
    bash "$HOME/.local/bin/build-vmware-modules.sh" || true
fi

# ------------------------------------------------------------------------------
# 8. SDDM & ACCOUNTS SERVICE DEFAULT SESSION SETUP (FORCE NIRI ON BOOT)
# ------------------------------------------------------------------------------
echo "🖥️ Forcing Niri as default Wayland desktop session in SDDM and AccountsService..."
sudo mkdir -p /etc/sddm.conf.d
cat << 'EOF' | sudo tee /etc/sddm.conf.d/niri-session.conf > /dev/null
[Desktop]
Session=niri.desktop

[Autologin]
Session=niri.desktop
EOF

# Update main sddm.conf
if [ -f /etc/sddm.conf ]; then
    sudo sed -i 's/Session=.*/Session=niri.desktop/' /etc/sddm.conf || true
fi

# Update AccountsService for all users to force Niri session
for user_path in /var/lib/AccountsService/users/*; do
    if [ -f "$user_path" ]; then
        sudo sed -i 's/Session=.*/Session=niri/' "$user_path" || true
    fi
done

# Ensure ~/.dmrc has Session=niri
cat << 'EOF' > "$HOME/.dmrc"
[Desktop]
Session=niri
EOF

# Ensure wayland sessions directory has niri.desktop
if [ ! -f /usr/share/wayland-sessions/niri.desktop ] && command -v niri &>/dev/null; then
    sudo mkdir -p /usr/share/wayland-sessions
    cat << 'EOF' | sudo tee /usr/share/wayland-sessions/niri.desktop > /dev/null
[Desktop Entry]
Name=Niri
Comment=Scrollable-tiling Wayland compositor
Exec=niri
Type=Application
DesktopNames=Niri
EOF
fi

# ------------------------------------------------------------------------------
# 9. FIREWALL CONFIGURATION (MATCHING NIXOS FIREWALL RULES)
# ------------------------------------------------------------------------------
echo "🛡️ Configuring Firewall rules (Minecraft, Steam Remote Play, Local Transfer, CUPS)..."
sudo systemctl enable --now firewalld || true
sudo firewall-cmd --permanent --add-port=25565/tcp || true
sudo firewall-cmd --permanent --add-port=25565/udp || true
sudo firewall-cmd --permanent --add-port=27036-27037/tcp || true
sudo firewall-cmd --permanent --add-port=27040/tcp || true
sudo firewall-cmd --permanent --add-port=27031-27036/udp || true
sudo firewall-cmd --permanent --add-port=631/tcp || true
sudo firewall-cmd --permanent --add-port=631/udp || true
sudo firewall-cmd --permanent --add-service=mdns || true
sudo firewall-cmd --reload || true

# ------------------------------------------------------------------------------
# 10. RESTORE NIRI DOTFILES, ZED CONFIG & ADAPT SCRIPTS FOR FEDORA
# ------------------------------------------------------------------------------
echo "🎨 Restoring Niri dotfiles, Zed config, and assets..."
if [ -f "$HOME/niri-dotfiles-backup.tar.gz" ]; then
    tar -xzf "$HOME/niri-dotfiles-backup.tar.gz" -C "$HOME"
    echo "✅ Dotfiles and Zed configuration restored!"
fi

mkdir -p "$HOME/.config/zed"
mkdir -p "$HOME/.local/bin"
if [ -f "$HOME/.local/bin/set-fifine-default.sh" ]; then
    chmod +x "$HOME/.local/bin/set-fifine-default.sh"
fi

# Steam dev config (64 HTTP streams)
mkdir -p "$HOME/.local/share/Steam"
cat << 'EOF' > "$HOME/.local/share/Steam/steam_dev.cfg"
@nCSClientReadBufferSizeBytes 33554432
@ClientMinHTTPReqCount 64
@c_bEnableHTTP3 0
EOF

# Steam desktop launcher with AMD ACO Vulkan compiler
mkdir -p "$HOME/.local/share/applications"
cat << 'EOF' > "$HOME/.local/share/applications/steam.desktop"
[Desktop Entry]
Name=Steam
Comment=Application for managing and playing games on Steam
Exec=env RADV_PERF=aco steam -tcp %U
Icon=steam
Terminal=false
Type=Application
Categories=Network;FileTransfer;Game;
MimeType=x-scheme-handler/steam;x-scheme-handler/steamlink;
Actions=Store;Community;Library;Servers;Screenshots;News;Settings;BigPicture;Friends;
EOF

# ------------------------------------------------------------------------------
# 11. BTRFS NO-DATA-COW (+C) FOR GAMES, DOWNLOADS & STEAM
# ------------------------------------------------------------------------------
echo "🚀 Creating Games directory and applying Btrfs nodatacow (+C) attributes..."
mkdir -p "$HOME/Downloads"
mkdir -p "$HOME/Games"
mkdir -p "$HOME/Games/Heroic"
mkdir -p "$HOME/Games/Steam"
mkdir -p "$HOME/.local/share/Steam/steamapps/downloading"
mkdir -p "$HOME/.local/share/Steam/steamapps/common"
mkdir -p "$HOME/.var/app"

sudo chattr +C "$HOME/Downloads" || true
sudo chattr +C "$HOME/Games" || true
sudo chattr +C "$HOME/Games/Heroic" || true
sudo chattr +C "$HOME/Games/Steam" || true
sudo chattr +C "$HOME/.local/share/Steam/steamapps/downloading" || true
sudo chattr +C "$HOME/.local/share/Steam/steamapps/common" || true
sudo chattr +C "$HOME/.var/app" || true

# ------------------------------------------------------------------------------
# 12. PRINTER SETUP (HP LaserJet 2420n @ 192.168.66.10 PCL6)
# ------------------------------------------------------------------------------
echo "🖨️ Configuring HP LaserJet 2420n Printer..."
sudo systemctl enable --now cups || true
sudo systemctl enable --now avahi-daemon || true

sudo lpadmin -p HP_LaserJet_2420n -v socket://192.168.66.10:9100 -E -m gutenprint.5.3://hp-lj_2420/expert -D "HP LaserJet 2420n Network Printer" || true
sudo lpadmin -d HP_LaserJet_2420n || true

# ------------------------------------------------------------------------------
# 13. DUAL-BOOT ASPM SPEED FIX (DISABLE EEE ON ENO1 ONLY IF INTERFACE EXISTS)
# ------------------------------------------------------------------------------
if ip link show eno1 &>/dev/null; then
    echo "⚡ Disabling Energy Efficient Ethernet on eno1..."
    cat << 'EOF' | sudo tee /etc/systemd/system/disable-eee.service > /dev/null
[Unit]
Description=Disable Energy Efficient Ethernet on eno1 for Gigabit speed
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/ethtool --set-eee eno1 eee off
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl daemon-reload
    sudo systemctl enable --now disable-eee.service || true
fi

# ------------------------------------------------------------------------------
# 14. GRUB CONFIGURATION
# ------------------------------------------------------------------------------
echo "⚙️ Configuring GRUB for Windows dual-boot and kernel parameters..."
sudo grub2-editenv - set kernelopts="$(sudo grub2-editenv - list 2>/dev/null | grep kernelopts | cut -d= -f2-) pcie_aspm=off" 2>/dev/null || true

if [ -f /etc/default/grub ] && ! grep -q "GRUB_DISABLE_OS_PROBER=false" /etc/default/grub; then
    echo 'GRUB_DISABLE_OS_PROBER=false' | sudo tee -a /etc/default/grub
fi

if [ -d /boot/grub2 ]; then
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg 2>/dev/null || true
fi
if [ -f /boot/efi/EFI/fedora/grub.cfg ]; then
    sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg 2>/dev/null || true
fi

echo ""
echo "🎉 ==========================================================================="
echo "🎉   FEDORA SETUP COMPLETE! LOGFILE SAVED TO: $LOGFILE"
echo "🎉   REBOOT TO ENTER YOUR CUSTOM NIRI DESKTOP!"
echo "🎉 ==========================================================================="
