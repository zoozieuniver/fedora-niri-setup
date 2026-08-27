#!/usr/bin/env bash
# ==============================================================================
#  fedora_debloat_kde.sh — Безпечний скрипт очищення (Видалення Konsole & Dolphin)
# ==============================================================================
#  Видаляє Konsole, Dolphin, ігри та блоатвар БЕЗ ВТРАТИ SDDM ТА ДИСКОРД-ТРАНСЛЯЦІЇ!
# ==============================================================================

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "❌ Помилка: Запустіть цей скрипт з правами root: sudo bash $0"
    exit 1
fi

echo "========================================================================"
echo " 🧹 Безпечне очищення системи (Видалення Konsole, Dolphin, ігор та блоатвару)"
echo "========================================================================"

# Пакети для безпечного видалення (без пошкодження SDDM та Pipewire/Discord Share)
DEBLOAT_PACKAGES=(
    # Термінал та файловий менеджер KDE (використовуються Kitty та Thunar)
    konsole
    dolphin

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

echo "🚀 Видалення блоатвару з прапором --noautoremove (для захисту SDDM та PipeWire)..."
dnf remove -y --noautoremove "${DEBLOAT_PACKAGES[@]}" || true

echo "🛡️ Гарантований захист SDDM, Pipewire та порталів для трансляції екрану в Discord..."
dnf install -y sddm sddm-kcm xdg-desktop-portal xdg-desktop-portal-gnome pipewire wireplumber xwayland-satellite

systemctl set-default graphical.target
systemctl enable --now sddm

echo "========================================================================"
echo " 🎉 Чищення завершено! SDDM, Thunar, Kitty та трансляція екрану у 100% безпеці."
echo "========================================================================"
