#!/usr/bin/env bash
# ==============================================================================
#  fedora_debloat_kde.sh — Повне очищення від KDE Plasma Desktop та блоатвару
# ==============================================================================
#  Видаляє KDE Plasma Desktop, Gwenview, Okular, Discover, KConnect, Firefox, MPV
#  ЗБЕРІГАЮЧИ SDDM, PipeWire, FirewallD та Niri!
# ==============================================================================

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "❌ Помилка: Запустіть цей скрипт з правами root: sudo bash $0"
    exit 1
fi

echo "========================================================================"
echo " 🧹 Повне очищення від KDE Plasma Desktop та всіх K-додатків"
echo "========================================================================"

# Виправлення симлінку диспетчера входу для SDDM
rm -f /etc/systemd/system/display-manager.service 2>/dev/null || true

# Повний список KDE Plasma компонентів та непотрібних програм для видалення
DEBLOAT_PACKAGES=(
    # KDE Plasma Desktop & Shell
    plasma-desktop
    plasma-workspace
    plasma-workspace-wayland
    plasma-workspace-libs
    plasma-nm
    plasma-pa
    kwin
    kwin-wayland
    kwin-common
    kde-cli-tools
    kservice
    kio-extras
    systemsettings
    
    # Зайві програми з меню (є Helium, Thunar, Kitty, VLC)
    firefox
    alacritty
    mpv mpv-libs mpv-devel
    konsole
    dolphin
    gwenview
    okular
    neochat
    spectacle
    orca
    plasma-discover
    kolourpaint
    ark
    kwrite
    skanpage
    kamoso
    partitionmanager
    kcalc
    filelight
    kdebugsettings
    kde-connect kde-connect-libs

    # KWallet
    kwalletmanager5 pam-kwallet signon-kwallet-extension kwalletmanager kf5-kwallet kf6-kwallet kf6-kwallet-libs

    # Зайві KDE утиліти
    kmouth kcharselect kamera sweeper kfind kget krdc krfb kjournald krenamer

    # Ігри KDE
    kmahjongg kpat kmines ksudoku knavalbattle kbounce kblocks klines kreversi
    kbattleship kblackbox bovo granatier kapman katomic kdiamond kigo killbots
    kiriki kjumpingcube knetwalk knights kolf kollision kshisen ksnakeduel
    kspaceduel ksquares ktuberling kubrick lskat palapeli picmi

    # Пошта, поштові служби та застарілі програвачі
    dragonplayer elisa-player ktorrent kmail kontact kaddressbook korganizer akregator

    # Додаткові офісні пакети
    "libreoffice*" gnome-tour gnome-boxes mediawriter
)

echo "🚀 Видалення KDE Plasma Desktop та блоатвару (--noautoremove)..."
for pkg in "${DEBLOAT_PACKAGES[@]}"; do
    dnf remove -y --noautoremove "$pkg" 2>/dev/null || true
done

echo "🛡️ Реєстрація чистих служб SDDM, Firewalld, Pipewire та порталів Niri..."
dnf install -y --allowerasing sddm sddm-kcm firewalld firewall-config xdg-desktop-portal xdg-desktop-portal-gnome pipewire wireplumber xwayland-satellite || true

rm -f /etc/systemd/system/display-manager.service 2>/dev/null || true
systemctl set-default graphical.target
systemctl enable --now sddm firewalld || true

echo "========================================================================"
echo " 🎉 Очищення успішно завершено! Всі KDE додатки та Firefox видалено."
echo "========================================================================"
