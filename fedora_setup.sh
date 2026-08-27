#!/usr/bin/env bash
# ==============================================================================
# FEDORA MASTER SETUP SCRIPT FOR ZOOZIENIX NIRI DESKTOP (V25 PERFECT)
# ==============================================================================
set -e

REAL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

LOGFILE1="/tmp/fedora_setup.log"
LOGFILE2="/var/log/fedora_setup.log"
LOGFILE3="$USER_HOME/fedora_setup.log"
MEMLOG="$USER_HOME/memory.log"

touch "$LOGFILE1" "$LOGFILE2" "$LOGFILE3" "$MEMLOG" 2>/dev/null || true
chmod 666 "$LOGFILE1" "$LOGFILE2" "$LOGFILE3" "$MEMLOG" 2>/dev/null || true

exec &> >(tee -a "$LOGFILE1" "$LOGFILE2" "$LOGFILE3" "$MEMLOG")
set -x

if [[ $EUID -ne 0 ]]; then
    echo "❌ Error: Please run this script with sudo: sudo bash $0"
    exit 1
fi

echo "[$(date -Iseconds)] 🚀 Starting Fedora Master Setup for $REAL_USER ($USER_HOME)..."

# ------------------------------------------------------------------------------
# 1. PURGE PLASMA SESSIONS & CONFIGURE SDDM LOGIN SCREEN (NO PLASMA IN DROPDOWN)
# ------------------------------------------------------------------------------
echo "⚙️ Purging Plasma session files from SDDM..."
sudo rm -f /usr/share/wayland-sessions/plasma*.desktop /usr/share/xsessions/plasma*.desktop /usr/share/wayland-sessions/plasmax11*.desktop 2>/dev/null || true

if grub2-editenv - list 2>/dev/null | grep -q "kernelopts.* 3"; then
    CURRENT_KOPTS="$(sudo grub2-editenv - list 2>/dev/null | grep kernelopts | cut -d= -f2- | sed 's/ 3//g' || true)"
    sudo grub2-editenv - set "kernelopts=$CURRENT_KOPTS" 2>/dev/null || true
fi

# Remove autologin so user sees SDDM login screen
sudo rm -f /etc/sddm.conf.d/niri.conf /etc/sddm.conf.d/niri-session.conf /etc/sddm.conf.d/autologin.conf 2>/dev/null || true
cat << 'EOF' | sudo tee /etc/sddm.conf.d/theme.conf > /dev/null
[Theme]
Current=breeze
EOF

# ------------------------------------------------------------------------------
# 2. UPDATE REPOSITORIES & INSTALL PACKAGES (INCLUDING LIBXCRYPT-COMPAT)
# ------------------------------------------------------------------------------
echo "📦 Updating repositories and installing system dependencies..."
sudo dnf update -y || true
sudo dnf install -y --allowerasing --nogpgcheck https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm || true

sudo dnf copr enable -y imput/helium || true
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true

sudo dnf install -y --allowerasing --skip-unavailable --nogpgcheck \
    helium-bin sddm sddm-kcm plasma-discover niri waybar SwayNotificationCenter wofi kitty thunar \
    thunar-archive-plugin dolphin grim slurp wl-clipboard cliphist xsettingsd xwayland-satellite \
    papirus-icon-theme easyeffects pavucontrol pulseaudio-utils btop fastfetch qbittorrent yt-dlp \
    vlc gimp krita obs-studio handbrake baobab rpi-imager chromium telegram-desktop steam \
    protontricks mangohud gamemode gamescope waydroid cups gutenprint hplip firewalld gcc gcc-c++ \
    clang clang-tools-extra gdb nasm make cmake ninja-build cargo rust rust-analyzer nodejs \
    python3 python3-pip pipx git wget curl jq file-roller zip unzip p7zip p7zip-plugins unrar \
    apr apr-util zlib zlib-devel libpng12 libxcrypt-compat libxcrypt swww swaybg kernel-headers kernel-devel 2>/dev/null || true

# Tailscale
curl -fsSL https://tailscale.com/install.sh | sh || true
sudo systemctl enable --now tailscaled 2>/dev/null || true

# Zed Editor
if ! command -v zed &> /dev/null; then
    sudo -u "$REAL_USER" HOME="$USER_HOME" bash -c 'curl -fssSL https://zed.dev/install.sh | sh' || true
fi

# ------------------------------------------------------------------------------
# 3. SCAN SCRIPT_DIR FIRST FOR LOCAL ARCHIVES
# ------------------------------------------------------------------------------
echo "🔍 Scanning script directory first ($SCRIPT_DIR) for local archives..."

# ProtonUp-Qt
PROTONUP_APPIMAGE=$(find "$SCRIPT_DIR" "$USER_HOME/Downloads" "$USER_HOME/Завантаження" ./ /tmp -iname "ProtonUp-Qt-*.AppImage" 2>/dev/null | head -n 1 || true)
if [ -n "$PROTONUP_APPIMAGE" ] && [ -f "$PROTONUP_APPIMAGE" ]; then
    mkdir -p "$USER_HOME/.local/bin"
    cp "$PROTONUP_APPIMAGE" "$USER_HOME/.local/bin/protonup-qt"
    chmod +x "$USER_HOME/.local/bin/protonup-qt"
    sudo cp "$PROTONUP_APPIMAGE" /usr/local/bin/protonup-qt
    sudo chmod +x /usr/local/bin/protonup-qt
fi

# DaVinci Resolve
DAVINCI_ZIP=$(find "$SCRIPT_DIR" "$USER_HOME/Downloads" "$USER_HOME/Завантаження" ./ /tmp -iname "DaVinci_Resolve_*.zip" 2>/dev/null | head -n 1 || true)
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

# Fix DaVinci Resolve bundled library conflict with Fedora System APR/Glib
if [ -d /opt/resolve/libs ]; then
    sudo mv /opt/resolve/libs/libaprutil-1.so.0 /opt/resolve/libs/libaprutil-1.so.0.bak 2>/dev/null || true
    sudo mv /opt/resolve/libs/libglib-2.0.so.0 /opt/resolve/libs/libglib-2.0.so.0.bak 2>/dev/null || true
fi

# Flatpaks
sudo flatpak install -y flathub org.vinegarhq.Sober org.prismlauncher.PrismLauncher com.github.qarmin.czkawka com.viber.Viber net.imput.Helium com.github.unrud.VideoDownloader 2>/dev/null || true

# ------------------------------------------------------------------------------
# 4. CONFIGURE XDG_DATA_DIRS & DESKTOP FILES FOR WOFI INDEXING
# ------------------------------------------------------------------------------
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

# GTK Settings
mkdir -p "$USER_HOME/.config/gtk-3.0" "$USER_HOME/.config/gtk-4.0"
cat << 'EOF' > "$USER_HOME/.config/gtk-3.0/settings.ini"
[Settings]
gtk-application-prefer-dark-theme=1
gtk-theme-name=Adwaita-dark
gtk-cursor-theme-name=Deltarune-Dark-Cursors
gtk-cursor-theme-size=24
gtk-icon-theme-name=Papirus-Dark
EOF
cp "$USER_HOME/.config/gtk-3.0/settings.ini" "$USER_HOME/.config/gtk-4.0/settings.ini" 2>/dev/null || true

# ------------------------------------------------------------------------------
# 5. PURGE BLOATWARE & ENABLE SERVICES
# ------------------------------------------------------------------------------
EXACT_DEBLOAT_PACKAGES=(
    gnome-abrt abrt-libs abrt-gui-libs abrt-desktop abrt setroubleshoot-server setroubleshoot-plugins setroubleshoot
    kde-partitionmanager partitionmanager dragonplayer orca systemsettings alacritty mpv mpv-libs konsole dolphin
    gwenview okular neochat spectacle kolourpaint ark kwrite skanpage kamoso kcalc filelight kdebugsettings kde-connect
    kde-connect-libs kwalletmanager5 pam-kwallet signon-kwallet-extension kwalletmanager kf5-kwallet kf6-kwallet kf6-kwallet-libs
    kmouth kcharselect kamera sweeper kfind kget krdc krfb kjournald krenamer kmahjongg kpat kmines ksudoku knavalbattle
    kbounce kblocks klines kreversi kbattleship kblackbox bovo granatier kapman katomic kdiamond kigo killbots kiriki
    kjumpingcube knetwalk knights kolf kollision kshisen ksnakeduel kspaceduel ksquares ktuberling kubrick lskat palapeli
    picmi elisa-player ktorrent kmail kontact kaddressbook korganizer akregator gnome-tour gnome-boxes mediawriter
)

echo "🧹 Purging exact bloatware packages..."
for pkg in "${EXACT_DEBLOAT_PACKAGES[@]}"; do
    sudo dnf remove -y --noautoremove "$pkg" 2>/dev/null || true
done

sudo dnf install -y --allowerasing sddm sddm-kcm plasma-discover firewalld firewall-config xdg-desktop-portal xdg-desktop-portal-gnome pipewire wireplumber xwayland-satellite 2>/dev/null || true

sudo systemctl enable --now sshd sddm 2>/dev/null || true
sudo rm -f /etc/systemd/system/display-manager.service 2>/dev/null || true
sudo systemctl set-default graphical.target

sudo chown -R "$REAL_USER:$REAL_USER" "$USER_HOME/.config" "$USER_HOME/.local" "$USER_HOME/.icons" "$MEMLOG" 2>/dev/null || true

echo "[$(date -Iseconds)] 🎉 Fedora Master Setup Script completed successfully!" >> "$MEMLOG"
echo "========================================================================"
echo " 🎉 Master Setup Completed! Detailed history logged to: $MEMLOG"
echo "========================================================================"
