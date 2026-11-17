# CyberNeon KDE lab: Arch Linux + Plasma 6 running headless (KWin virtual backend, software rendering).
# Used to test the KDE edition and take real Plasma screenshots from any Linux host with Docker.
FROM archlinux:latest
RUN pacman -Syu --noconfirm --needed \
        plasma-desktop plasma-workspace kwin kscreen kded kde-cli-tools konsole dolphin spectacle \
        breeze kpackage kconfig libksysguard ksystemstats plasma-integration \
        xorg-xwayland mesa qt6-declarative qt6-tools sddm gtk3 \
        python python-pillow python-cairo curl sudo dbus noto-fonts ttf-jetbrains-mono-nerd \
    && pacman -Scc --noconfirm
# headless display for screenshots: KWin renders into Xvfb, captured with xwd
RUN pacman -Sy --noconfirm --needed xorg-server-xvfb xorg-xwd imagemagick && pacman -Scc --noconfirm
# Application Dashboard (kickerdash) lives in kdeplasma-addons on Plasma 6
RUN pacman -Sy --noconfirm --needed kdeplasma-addons && pacman -Scc --noconfirm
# Kvantum (Qt widget style used by the CyberNeon Kvantum theme)
RUN pacman -Sy --noconfirm --needed kvantum && pacman -Scc --noconfirm
RUN useradd -m -s /bin/bash netrunner
USER netrunner
WORKDIR /home/netrunner
