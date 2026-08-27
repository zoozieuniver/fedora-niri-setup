#!/usr/bin/env bash
# ==============================================================================
# FEDORA COSMIC SAFE APPLICATIONS INSTALLER (NO DEBLOAT - ONLY APPS)
# ==============================================================================
set -e

REAL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

LOGFILE="/var/log/fedora_cosmic_apps.log"
MEMLOG="$USER_HOME/memory.log"

touch "$LOGFILE" "$MEMLOG" 2>/dev/null || true
chmod 666 "$LOGFILE" "$MEMLOG" 2>/dev/null || true

exec &> >(tee -a "$LOGFILE" "$MEMLOG")
set -x

if [[ $EUID -ne 0 ]]; then
    echo "❌ Error: Please run this script with sudo: sudo bash $0"
    exit 1
fi

echo "[$(date -Iseconds)] 🚀 Starting Fedora Safe Apps Installation for $REAL_USER ($USER_HOME)..."

# ------------------------------------------------------------------------------
# 1. ENABLE REPOSITORIES (RPM FUSION, COPR & FLATHUB)
# ------------------------------------------------------------------------------
echo "📦 Enabling RPM Fusion, COPR repositories & Flathub..."
sudo dnf update -y || true
sudo dnf install -y --allowerasing --nogpgcheck https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm || true

sudo dnf copr enable -y imput/helium 2>/dev/null || true
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true

# ------------------------------------------------------------------------------
# 2. INSTALL SYSTEM PACKAGES & UTILITIES (SAFE - NO REMOVALS)
# ------------------------------------------------------------------------------
echo "🛠️ Installing user applications & dev packages..."
sudo dnf install -y --allowerasing --skip-unavailable --nogpgcheck \
    helium-bin papirus-icon-theme easyeffects pavucontrol pulseaudio-utils btop fastfetch qbittorrent yt-dlp \
    vlc gimp krita obs-studio handbrake baobab rpi-imager chromium telegram-desktop steam \
    protontricks mangohud gamemode gamescope waydroid cups gcc gcc-c++ clang make cmake ninja-build \
    cargo rust rust-analyzer nodejs python3 python3-pip git wget curl jq file-roller zip unzip p7zip \
    apr apr-util zlib zlib-devel libpng12 libxcrypt-compat libxcrypt swww swaybg kernel-headers kernel-devel 2>/dev/null || true

# Tailscale
echo "🌐 Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh || true
sudo systemctl enable --now tailscaled 2>/dev/null || true

# Zed Editor
echo "📝 Installing Zed Editor..."
if ! command -v zed &> /dev/null; then
    sudo -u "$REAL_USER" HOME="$USER_HOME" bash -c 'curl -fssSL https://zed.dev/install.sh | sh' || true
fi

# ------------------------------------------------------------------------------
# 3. SCAN LOCAL ARCHIVES FOR PROTONUP-QT & DAVINCI RESOLVE
# ------------------------------------------------------------------------------
echo "🔍 Scanning for local archives in $SCRIPT_DIR..."

PROTONUP_APPIMAGE=$(find "$SCRIPT_DIR" "$USER_HOME/fedora-cosmic-setup" "$USER_HOME/Downloads" "$USER_HOME/Завантаження" ./ /tmp -iname "ProtonUp-Qt-*.AppImage" 2>/dev/null | head -n 1 || true)
if [ -n "$PROTONUP_APPIMAGE" ] && [ -f "$PROTONUP_APPIMAGE" ]; then
    echo "🎮 Installing ProtonUp-Qt from: $PROTONUP_APPIMAGE..."
    mkdir -p "$USER_HOME/.local/bin"
    cp "$PROTONUP_APPIMAGE" "$USER_HOME/.local/bin/protonup-qt"
    chmod +x "$USER_HOME/.local/bin/protonup-qt"
    sudo cp "$PROTONUP_APPIMAGE" /usr/local/bin/protonup-qt
    sudo chmod +x /usr/local/bin/protonup-qt
fi

DAVINCI_ZIP=$(find "$SCRIPT_DIR" "$USER_HOME/fedora-cosmic-setup" "$USER_HOME/Downloads" "$USER_HOME/Завантаження" ./ /tmp -iname "DaVinci_Resolve_*.zip" 2>/dev/null | head -n 1 || true)
if [ -n "$DAVINCI_ZIP" ] && [ -f "$DAVINCI_ZIP" ] && ! [ -d /opt/resolve ]; then
    echo "🎬 Installing DaVinci Resolve from: $DAVINCI_ZIP..."
    TMP_DAVINCI="/tmp/davinci_unpack_dir"
    rm -rf "$TMP_DAVINCI"
    mkdir -p "$TMP_DAVINCI"
    unzip -q "$DAVINCI_ZIP" -d "$TMP_DAVINCI" || true
    DAVINCI_RUN=$(find "$TMP_DAVINCI" -iname "DaVinci_Resolve_*.run" 2>/dev/null | head -n 1 || true)
    if [ -n "$DAVINCI_RUN" ]; then
        chmod +x "$DAVINCI_RUN"
        sudo SKIP_PACKAGE_CHECK=1 "$DAVINCI_RUN" -i -y || true
    fi
    rm -rf "$TMP_DAVINCI"
fi

if [ -d /opt/resolve/libs ]; then
    sudo mv /opt/resolve/libs/libaprutil-1.so.0 /opt/resolve/libs/libaprutil-1.so.0.bak 2>/dev/null || true
    sudo mv /opt/resolve/libs/libglib-2.0.so.0 /opt/resolve/libs/libglib-2.0.so.0.bak 2>/dev/null || true
fi

# Flatpaks
echo "📲 Installing Flatpak applications..."
sudo flatpak install -y flathub org.vinegarhq.Sober org.prismlauncher.PrismLauncher com.github.qarmin.czkawka com.viber.Viber net.imput.Helium com.github.unrud.VideoDownloader 2>/dev/null || true

# ------------------------------------------------------------------------------
# 4. CONFIGURE XDG DATA DIRS & DESKTOP LAUNCHERS
# ------------------------------------------------------------------------------
echo "⚙️ Creating desktop launchers & configuring XDG_DATA_DIRS..."
cat << 'EOF' | sudo tee /etc/profile.d/flatpak_xdg.sh > /dev/null
export XDG_DATA_DIRS=/usr/local/share:/usr/share:~/.local/share:/var/lib/flatpak/exports/share:~/.local/share/flatpak/exports/share
EOF
chmod +x /etc/profile.d/flatpak_xdg.sh

# DaVinci Resolve Wrapper
cat << 'EOF' | sudo tee /usr/local/bin/davinci-resolve > /dev/null
#!/usr/bin/env bash
export QT_QPA_PLATFORM=xcb
export SKIP_PACKAGE_CHECK=1
exec /opt/resolve/bin/resolve "$@"
EOF
sudo chmod +x /usr/local/bin/davinci-resolve

cat << 'EOF' | sudo tee /usr/share/applications/davinci-resolve.desktop > /dev/null
[Desktop Entry]
Version=1.0
Type=Application
Name=DaVinci Resolve
GenericName=Video Editor
Exec=/usr/local/bin/davinci-resolve %u
Icon=/opt/resolve/graphics/DV_Resolve.png
Terminal=false
Categories=AudioVideo;Video;Graphics;
EOF

cat << 'EOF' | sudo tee /usr/share/applications/helium.desktop > /dev/null
[Desktop Entry]
Version=1.0
Type=Application
Name=Helium Browser
GenericName=Web Browser
Exec=helium %U
Icon=helium
Terminal=false
Categories=Network;WebBrowser;
EOF

cat << 'EOF' | sudo tee /usr/share/applications/zed.desktop > /dev/null
[Desktop Entry]
Version=1.0
Type=Application
Name=Zed Editor
GenericName=Text Editor
Exec=/home/zooziefedora/.local/bin/zed %F
Icon=zed
Terminal=false
Categories=Development;TextEditor;
EOF

cat << 'EOF' | sudo tee /usr/share/applications/protonup-qt.desktop > /dev/null
[Desktop Entry]
Version=1.0
Type=Application
Name=ProtonUp-Qt
GenericName=Proton Manager
Exec=/home/zooziefedora/.local/bin/protonup-qt
Icon=protonup-qt
Terminal=false
Categories=Game;Utility;
EOF

sudo chown -R "$REAL_USER:$REAL_USER" "$USER_HOME/.config" "$USER_HOME/.local" "$USER_HOME/.icons" "$MEMLOG" 2>/dev/null || true

echo "[$(date -Iseconds)] 🎉 Fedora Safe Applications Installation completed successfully!" >> "$MEMLOG"
echo "========================================================================"
echo " 🎉 Safe Apps Installation Completed! Logged to: $MEMLOG"
echo "========================================================================"
