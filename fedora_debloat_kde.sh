#!/usr/bin/env bash
# ==============================================================================
#  fedora_debloat_kde.sh — Повне очищення від блоатвару (Alacritty, MPV, KWallet, KGames)
# ==============================================================================
#  Видаляє Alacritty, MPV, KWallet, K-ігри та K-утиліти БЕЗ ВТРАТИ SDDM/FIREWALL!
# ==============================================================================

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "❌ Помилка: Запустіть цей скрипт з правами root: sudo bash $0"
    exit 1
fi

echo "========================================================================"
echo " 🧹 Повне очищення системи (Alacritty, MPV, KWallet, K-ігри)"
echo "========================================================================"

# Список НЕПОТРІБНИХ програм та утиліт для видалення (ЗБЕРЕЖЕНО FirewallD!)
DEBLOAT_PACKAGES=(
    # Зайві термінали та програвачі (є Kitty та VLC)
    alacritty
    mpv mpv-libs mpv-devel
    konsole
    dolphin

    # KWallet (нав'язливі спливаючі вікна паролів)
    kwalletmanager5 pam-kwallet signon-kwallet-extension kwalletmanager

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

echo "🚀 Видалення розширеного списку блоатвару (--noautoremove для захисту SDDM)..."
dnf remove -y --noautoremove "${DEBLOAT_PACKAGES[@]}" || true

echo "🛡️ Гарантований захист SDDM, Firewalld, Pipewire та порталів для трансляції в Discord..."
dnf install -y sddm sddm-kcm firewalld firewall-config xdg-desktop-portal xdg-desktop-portal-gnome pipewire wireplumber xwayland-satellite

systemctl set-default graphical.target
systemctl enable --now sddm firewalld

echo "========================================================================"
echo " 🎉 Очищення успішно завершено! Alacritty, MPV, KWallet та K-блоатвар видалено."
echo "========================================================================"
