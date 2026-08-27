#!/usr/bin/env bash
# ==============================================================================
#  fedora_debloat_kde.sh — Виправлений та безпечний скрипт очищення KDE
# ==============================================================================
#  Видаляє непотрібні ігри, пошту та блоатвар KDE БЕЗ ВТРАТИ SDDM ТА ДИСПЛЕЯ!
# ==============================================================================

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "❌ Помилка: Запустіть цей скрипт з правами root: sudo bash $0"
    exit 1
fi

echo "========================================================================"
echo " 🧹 Безпечне очищення системи від ігор та блоатвару KDE"
echo "========================================================================"

# Список НЕПОТРІБНИХ ігор та програм (БЕЗ plasma-workspace та SDDM!)
DEBLOAT_PACKAGES=(
    # Ігри KDE
    kmahjongg kpat kmines ksudoku knavalbattle kbounce kblocks klines kreversi
    kbattleship kblackbox bovo granatier kapman katomic kdiamond kigo killbots
    kiriki kjumpingcube knetwalk knights kolf kollision kshisen ksnakeduel
    kspaceduel ksquares ktuberling kubrick lskat palapeli picmi

    # Пошта, поштові служби та застарілі програвачі
    dragonplayer elisa-player ktorrent kmail kontact kaddressbook korganizer akregator

    # Допоміжні утиліти (для офісу є OnlyOffice)
    "libreoffice*"
    gnome-tour
    gnome-boxes
    mediawriter
)

echo "🚀 Видалення блоатвару з прапором --noautoremove (для захисту SDDM)..."
dnf remove -y --noautoremove "${DEBLOAT_PACKAGES[@]}" || true

echo "🛡️ Гарантований захист та відновлення SDDM..."
dnf install -y sddm sddm-kcm
systemctl set-default graphical.target
systemctl enable --now sddm

echo "========================================================================"
echo " 🎉 Чищення завершено! Графічний екран входу SDDM у 100% безпеці."
echo "========================================================================"
