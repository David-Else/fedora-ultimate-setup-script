#!/bin/bash

#==============================================================================
#
#         FILE: fedora-xfce-ultimate-install-script.sh
#        USAGE: sudo fedora-xfce-ultimate-install-script.sh
#
#  DESCRIPTION: Post-installation install script for Fedora 29/30/31 Xfce
#      WEBSITE: https://github.com/CSRedRat/fedora-xfce-setup-script
#
# REQUIREMENTS: Fresh copy of Fedora Xfce installed on your computer
#               https://spins.fedoraproject.org/ru/xfce/
#       AUTHOR: David Else
#      COMPANY: https://www.elsewebdevelopment.com/
#      VERSION: 3.0
#
#      TODO if ban.spellright ln -s /usr/share/myspell ~/.config/Code/Dictionaries
#==============================================================================

#==============================================================================
# script settings and checks
#==============================================================================
set -euo pipefail
exec 2> >(tee "error_log_$(date -Iseconds).txt")

GREEN=$(tput setaf 2)
BOLD=$(tput bold)
RESET=$(tput sgr0)

if [ "$(id -u)" != 0 ]; then
    echo "You're not root! Use sudo ./fedora-xfce-ultimate-install-script.sh" && exit 1
fi

if [[ $(rpm -E %fedora) -lt 29 ]]; then
    echo >&2 "You must install at least ${GREEN}Fedora 29${RESET} to use this script" && exit 1
fi

# >>>>>> start of user settings <<<<<<

#==============================================================================
# packages to remove
#==============================================================================
packages_to_remove=(
    gnome-photos
    gnome-documents
    rhythmbox
    totem
    cheese
	claws-mail
	abiword
	gnumeric
	pidgin
	)

#==============================================================================
# common packages to install *arrays can be left empty, but don't delete them
#==============================================================================
fedora=(
    shotwell
    #java-1.8.0-openjdk
    jack-audio-connection-kit
    mediainfo
    mkvtoolnix-gui
    tldr
    mame
    chromium
    youtube-dl
    keepassxc
    transmission-gtk
    lshw
    fuse-exfat
	vulkan
    mpv
	htop
	mlocate
	mc
	grc
	neofetch
	numlockx
    #akmod-nvidia-340xx xorg-x11-drv-nvidia-340xx xorg-x11-drv-nvidia-340xx-cuda xorg-x11-drv-nvidia-340xx-libs gcc kernel-headers kernel-devel
)

rpmfusion=(
    libva-intel-driver
	libva-intel-hybrid-driver
	vdpauinfo
	libva-vdpau-driver
	libva-utils
    chromium-libs-media-freeworld
    ffmpeg)

WineHQ=(
    winehq-stable)

flathub_packages_to_install=(
    org.kde.krita
    org.kde.okular
    fr.handbrake.ghb
    net.sf.fuse_emulator)

#==============================================================================
# Ask for user input
#==============================================================================
clear
read -p "Are you going to use this machine for web development? (y/n) " -n 1
echo
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    #==========================================================================
    # packages for software development option
    # *LAMP: mariadb-server php-json phpmyadmin php-mysqlnd php-opcache sendmail
    #==========================================================================
    modules_to_enable=(
        nodejs:12)

    fedora_developer=(
        docker
        docker-compose
        nodejs
        php
        composer
        ShellCheck
        zeal)

    composer_packages_to_install=(
        squizlabs/php_codesniffer
        wp-coding-standards/wpcs
        wp-cli/wp-cli-bundle)

    node_global_packages_to_install=(
        pnpm
        npm-check)

    vscode=(
        code)

    code_extensions=(
        ban.spellright
        bierner.markdown-preview-github-styles
        bmewburn.vscode-intelephense-client
        deerawan.vscode-dash
        esbenp.prettier-vscode
        foxundermoon.shell-format
        msjsdiag.debugger-for-chrome
        ritwickdey.LiveServer
        timonwong.shellcheck
        WallabyJs.quokka-vscode)

    dnf_packages_to_install+=("${fedora[@]}" "${rpmfusion[@]}" "${WineHQ[@]}" "${fedora_developer[@]}" "${vscode[@]}")

elif [[ $REPLY =~ ^[Nn]$ ]]; then
    dnf_packages_to_install+=("${fedora[@]}" "${rpmfusion[@]}" "${WineHQ[@]}")

else
    echo "Invalid selection" && exit 1
fi

# >>>>>> end of user settings <<<<<<

#==============================================================================
# display user settings
#==============================================================================
cat <<EOL
${BOLD}Packages to install${RESET}
${BOLD}-------------------${RESET}
DNF modules to enable: ${GREEN}${modules_to_enable[*]}${RESET}

DNF packages: ${GREEN}${dnf_packages_to_install[*]}${RESET}

Flathub packages: ${GREEN}${flathub_packages_to_install[*]}${RESET}

Composer packages: ${GREEN}${composer_packages_to_install[*]}${RESET}

Node packages: ${GREEN}${node_global_packages_to_install[*]}${RESET}

Visual Studio Code extensions: ${GREEN}${code_extensions[*]}${RESET}

${BOLD}Packages to remove${RESET}
${BOLD}------------------${RESET}
DNF packages: ${GREEN}${packages_to_remove[*]}${RESET}

EOL
read -rp "Press enter to install, or ctrl+c to quit"

#==============================================================================
# add repositories
#==============================================================================
echo "${BOLD}Adding repositories...${RESET}"
dnf -y install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
dnf -y install https://github.com/rpmsphere/noarch/raw/master/r/rpmsphere-release-30-1.noarch.rpm
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
dnf -y install snapd; ln -s /var/lib/snapd/snap /snap; snap install snap-store; systemctl enable --now snapd.socket; snap set system refresh.timer=4:00-7:00,21:00-23:50; sh -c "echo 'export PATH="\$PATH:/snap/bin/"' >> /etc/profile"

dnf install -y dnf-plugins-core
dnf copr enable -y tkorbar/cheat
dnf copr enable -y konimex/neofetch
dnf copr enable -y angeldm/psensor

# note the spaces to make sure something like 'notnode' could not trigger 'nodejs' using [*]
case " ${dnf_packages_to_install[*]} " in
*' code '*)
    rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    ;;&
*' winehq-stable '*)
    dnf config-manager --add-repo https://dl.winehq.org/wine-builds/fedora/30/winehq.repo
    ;;
esac

#==============================================================================
# install packages
#==============================================================================
echo "${BOLD}Removing unwanted programs...${RESET}"
dnf -y remove "${packages_to_remove[@]}"

echo "${BOLD}Updating Fedora, enabling module streams...${RESET}"
dnf -y --refresh upgrade

if [[ ${modules_to_enable[@]} ]]; then
    dnf -y module enable "${modules_to_enable[@]}"
fi

echo "${BOLD}Installing packages...${RESET}"
dnf -y install "${dnf_packages_to_install[@]}"

echo "${BOLD}Installing flathub packages...${RESET}"
flatpak install -y flathub "${flathub_packages_to_install[@]}"

case " ${dnf_packages_to_install[*]} " in
*' composer '*)
    echo "${BOLD}Installing global composer packages...${RESET}"
    /usr/bin/su - "$SUDO_USER" -c "composer global require ${composer_packages_to_install[*]}"
    ;;&

*' nodejs '*)
    echo "${BOLD}Installing global NodeJS packages...${RESET}"
    npm install -g "${node_global_packages_to_install[@]}"
    ;;&

*' code '*)
    echo "${BOLD}Installing Visual Studio Code extensions...${RESET}"
    for extension in "${code_extensions[@]}"; do
        /usr/bin/su - "$SUDO_USER" -c "code --install-extension $extension"
    done
    ;;
esac

cat <<EOL
  =================================================================
  Congratulations, everything is installed!

  Now use the setup script...
  =================================================================
EOL
