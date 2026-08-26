#!/usr/bin/env bash
# ==============================================================================
#   FEDORA MASTER SETUP SCRIPT FOR ZOOZIENIX NIRI DESKTOP (V5 ULTIMATE DNF5)
# ==============================================================================
set -e

echo "🚀 Starting Fedora Master Setup Script (Niri + ALL 100% Packages)..."

# ------------------------------------------------------------------------------
# 1. UPDATE SYSTEM & INSTALL RPM REPOSITORIES (RPM FUSION & ONLYOFFICE)
# ------------------------------------------------------------------------------
echo "📦 Updating system and adding RPM repositories..."
sudo dnf update -y || true
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm || true

# Add Cisco OpenH264 & OnlyOffice RPM repository (DNF5 compatible syntax)
sudo dnf config-manager enable fedora-cisco-openh264 2>/dev/null || sudo dnf config-manager --set-enabled fedora-cisco-openh264 2>/dev/null || true
sudo dnf config-manager addrepo --overwrite https://download.onlyoffice.com/repo/onlyoffice.repo 2>/dev/null || sudo dnf config-manager --add-repo https://download.onlyoffice.com/repo/onlyoffice.repo 2>/dev/null || true

# ------------------------------------------------------------------------------
# 2. REMOVE UNNEEDED BLOAT FROM FEDORA KDE SPIN
# ------------------------------------------------------------------------------
echo "🧹 Cleaning up unnecessary bloatware..."
sudo dnf remove -y libreoffice* gnome-tour gnome-boxes mediawriter kmines dragonplayer ktorrent kmail || true

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
    czkawka-gui \
    baobab \
    rpi-imager \
    chromium \
    telegram-desktop \
    steam \
    prismlauncher \
    protonup-qt \
    protontricks \
    onlyoffice-desktopeditors \
    mangohud \
    gamemode \
    cups \
    gutenprint \
    gutenprint-doc \
    hplip \
    firewalld

# ------------------------------------------------------------------------------
# 5. NATIVE RPM DOWNLOADS (VESKTOP & HEROIC LAUNCHER FROM GITHUB RELEASES)
# ------------------------------------------------------------------------------
echo "📦 Installing native RPM packages for Vesktop & Heroic Games Launcher..."
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

cd "$HOME"
rm -rf "$TMP_RPM"

# ------------------------------------------------------------------------------
# 6. FLATPAK SETUP (SOBER ROBLOX, VIBER, CZKAWKA)
# ------------------------------------------------------------------------------
echo "🌐 Configuring Flatpak applications (Sober Roblox, Viber, Czkawka)..."
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true

# Install Sober (Roblox Player), Viber & Czkawka from Flathub
sudo flatpak install -y flathub org.vinegarhq.Sober com.viber.Viber com.github.qarmin.czkawka org.gnome.Satty || true

echo "🔓 Unlocking Flatpak restrictions globally (Drag & Drop, Mic, File System access)..."
sudo flatpak override --filesystem=host --device=all --share=ipc --socket=wayland --socket=x11 --socket=pulseaudio || true

# ------------------------------------------------------------------------------
# 7. AUTOMATED VMWARE WORKSTATION KERNEL MODULE BUILDER
# ------------------------------------------------------------------------------
echo "💻 Setting up VMware Workstation kernel modules build script..."
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
sudo vmware-networks --start || true
echo "✅ VMware modules built successfully!"
EOF
chmod +x "$HOME/.local/bin/build-vmware-modules.sh"

if command -v vmware &> /dev/null; then
    bash "$HOME/.local/bin/build-vmware-modules.sh" || true
fi

# ------------------------------------------------------------------------------
# 8. SDDM DISPLAY MANAGER DEFAULT SESSION SETUP (DEFAULT TO NIRI ON BOOT)
# ------------------------------------------------------------------------------
echo "🖥️ Setting Niri as default Wayland session in SDDM..."
sudo mkdir -p /etc/sddm.conf.d
cat << 'EOF' | sudo tee /etc/sddm.conf.d/niri-session.conf > /dev/null
[Desktop]
Session=niri.desktop

[Autologin]
Session=niri.desktop
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
echo "🎉   FEDORA SETUP COMPLETE! REBOOT TO ENTER YOUR CUSTOM NIRI DESKTOP!"
echo "🎉 ==========================================================================="
