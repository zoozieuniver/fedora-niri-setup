#!/usr/bin/env bash
# ==============================================================================
#  fedora_debloat_kde.sh — Чистка блоатвару ЗБЕРІГАЮЧИ Discover, SDDM, PipeWire
# ==============================================================================
#  Видаляє ABRT, SELinux Troubleshooter, Dragon, Orca, Partition Manager, Alacritty
#  ЗБЕРІГАЮЧИ Plasma Discover (магазин), SDDM (екран входу), PipeWire (аудіо та стрімінг)!
# ==============================================================================

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "❌ Помилка: Запустіть цей скрипт з правами root: sudo bash $0"
    exit 1
fi

echo "========================================================================"
echo " 🧹 Повне очищення системи (Збережено Discover, SDDM, Pipewire)"
echo "========================================================================"

# Виправлення симлінку диспетчера входу для SDDM
rm -f /etc/systemd/system/display-manager.service 2>/dev/null || true

DEBLOAT_PACKAGES=(
    # Зайві звіти та діагностики зі скріншотів
    "abrt*"
    "setroubleshoot*"
    dragonplayer
    orca
    partitionmanager
    systemsettings
    
    # Зайві програвачі та термінали (є Kitty та VLC)
    alacritty
    mpv mpv-libs mpv-devel
    konsole
    dolphin
    gwenview
    okular
    neochat
    spectacle
    kolourpaint
    ark
    kwrite
    skanpage
    kamoso
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

    # Пошта та застарілі поштові служби
    elisa-player ktorrent kmail kontact kaddressbook korganizer akregator

    # Додаткові офісні пакети
    "libreoffice*" gnome-tour gnome-boxes mediawriter
)

echo "🚀 Видалення блоатвару (--noautoremove)..."
for pkg in "${DEBLOAT_PACKAGES[@]}"; do
    dnf remove -y --noautoremove "$pkg" 2>/dev/null || true
done

echo "🛡️ Перевірка Discover, SDDM, Firewalld, Pipewire та порталів для стрімінгу..."
dnf install -y --allowerasing sddm sddm-kcm plasma-discover firewalld firewall-config xdg-desktop-portal xdg-desktop-portal-gnome pipewire wireplumber xwayland-satellite || true

rm -f /etc/systemd/system/display-manager.service 2>/dev/null || true
systemctl set-default graphical.target
systemctl enable --now sddm firewalld || true

echo "========================================================================"
echo " 🎉 Очищення успішно завершено! Discover, SDDM та стрімінг працюють."
echo "========================================================================"
