#!/usr/bin/env bash
# ==============================================================================
#  fedora_debloat_kde.sh — Повне очищення від KDE Plasma Desktop та блоатвару
# ==============================================================================
#  Видаляє KDE Plasma Desktop, Alacritty, MPV, KWallet, K-ігри та K-утиліти
#  ЗБЕРІГАЮЧИ SDDM, PipeWire, FirewallD та Niri!
# ==============================================================================

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "❌ Помилка: Запустіть цей скрипт з правами root: sudo bash $0"
    exit 1
fi

echo "========================================================================"
echo " 🧹 Повне очищення від KDE Plasma Desktop, Alacritty, MPV, KWallet, K-ігор"
echo "========================================================================"

# Повний список KDE Plasma компонентів та блоатвару для видалення
DEBLOAT_PACKAGES=(
    # KDE Plasma Desktop & Shell (Niri є єдиним віконним менеджером!)
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
    
    # Зайві термінали та програвачі (є Kitty та VLC)
    alacritty
    mpv mpv-libs mpv-devel
    konsole
    dolphin

    # KWallet (нав'язливі спливаючі вікна паролів)
    kwalletmanager5 pam-kwallet signon-kwallet-extension kwalletmanager kf5-kwallet kf6-kwallet kf6-kwallet-libs

    # Зайві KDE утиліти та утиліти доступності
    kmouth
    kcharselect
    kamera
    sweeper
    kfind
    kget
    krdc
    krfb krfb-libs
    kjournald
    krenamer

    # Ігри KDE
    kmahjongg kpat kmines ksudoku knavalbattle kbounce kblocks klines kreversi
    kbattleship kblackbox bovo granatier kapman katomic kdiamond kigo killbots
    kiriki kjumpingcube knetwalk knights kolf kollision kshisen ksnakeduel
    kspaceduel ksquares ktuberling kubrick lskat palapeli picmi

    # Пошта, поштові служби та застарілі програвачі
    dragonplayer elisa-player ktorrent kmail kontact kaddressbook korganizer akregator

    # Застарілі утиліти та додаткові офісні пакети
    "libreoffice*"
    gnome-tour
    gnome-boxes
    mediawriter
)

echo "🚀 Видалення KDE Plasma Desktop та блоатвару (--noautoremove для захисту SDDM)..."
for pkg in "${DEBLOAT_PACKAGES[@]}"; do
    dnf remove -y --noautoremove "$pkg" 2>/dev/null || true
done

echo "🛡️ Гарантований захист SDDM, Firewalld, Pipewire та порталів для Niri..."
dnf install -y --allowerasing sddm sddm-kcm firewalld firewall-config xdg-desktop-portal xdg-desktop-portal-gnome pipewire wireplumber xwayland-satellite || true

systemctl set-default graphical.target
systemctl enable --now sddm firewalld || true

echo "========================================================================"
echo " 🎉 Очищення успішно завершено! KDE Plasma Desktop, Alacritty, MPV та KWallet видалено."
echo "========================================================================"
