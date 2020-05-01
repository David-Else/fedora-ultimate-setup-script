#!/bin/bash

# select SOFTWARE / Software Selection / Base Environment > Workstation
# when you create user tick 'make user administrator'
# tested 21/01/20 on fresh install of CentOS-8.1.1911-x86_64

#==============================================================================
# script settings and checks
#==============================================================================
set -euo pipefail
exec 2> >(tee "error_log_$(date -Iseconds).txt")

GREEN=$(tput setaf 2)
BOLD=$(tput bold)
RESET=$(tput sgr0)

if [ "$(id -u)" != 0 ]; then
    echo "You're not root! Run script with sudo" && exit 1
fi

#==============================================================================
# common packages to install/remove *arrays can be left empty, but don't delete
#==============================================================================
packages_to_remove=(
    gnome-boxes
    evolution
    rhythmbox
    totem
    pidgin
    cheese)

packages_to_install=(
    # brave-browser
    borgbackup
    ntfs-3g
    gnome-tweaks
    youtube-dl
    keepassxc
    lshw
    mpv
    deadbeef
    libva-intel-driver
    ffmpeg
    mediainfo
    syncthing
    ImageMagick
    fuse-exfat
	htop
	mlocate
	mc
	grc
	neofetch
	numlockx
)

flathub_packages_to_install=(
    org.kde.krita
    org.kde.okular
    org.gnome.Shotwell
    org.gnome.Boxes
    fr.handbrake.ghb
    org.bunkus.mkvtoolnix-gui
    com.transmissionbt.Transmission
    org.zealdocs.Zeal)

#==============================================================================
# Ask for user input
#==============================================================================
clear
read -p "Are you going to use this machine for web development? (y/n) " -n 1 webdev
echo
echo

if [[ $webdev =~ ^[Yy]$ ]]; then
    #==========================================================================
    # packages for web development option * deno added if selected
    #==========================================================================
    developer_packages=(
        php
        code)

    code_extensions=(
        # bmewburn.vscode-intelephense-client
        ban.spellright
        bierner.markdown-preview-github-styles
        esbenp.prettier-vscode
        foxundermoon.shell-format
        msjsdiag.debugger-for-chrome
        nicoespeon.abracadabra
        ritwickdey.LiveServer
        timonwong.shellcheck
        WallabyJs.quokka-vscode)

    packages_to_install+=("${developer_packages[@]}")

elif [[ ! $webdev =~ ^[Nn]$ ]]; then
    echo "Invalid selection" && exit 1
fi

#==============================================================================
# display user settings
#==============================================================================
cat <<EOL
${BOLD}Packages to install${RESET}
${BOLD}-------------------${RESET}

DNF packages: ${GREEN}${packages_to_install[*]}${RESET}

Flathub packages: ${GREEN}${flathub_packages_to_install[*]}${RESET}

Visual Studio Code extensions: ${GREEN}${code_extensions[*]}${RESET}

${BOLD}Packages to remove${RESET}
${BOLD}------------------${RESET}
DNF packages: ${GREEN}${packages_to_remove[*]}${RESET}

EOL
read -rp "Press enter to install, or ctrl+c to quit"

#==============================================================================
# add default and conditional repositories
#==============================================================================
echo "${BOLD}Adding repositories...${RESET}"
dnf -y config-manager --enable PowerTools
dnf -y install epel-release
dnf -y install --nogpgcheck https://download1.rpmfusion.org/free/el/rpmfusion-free-release-8.noarch.rpm https://download1.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-8.noarch.rpm
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
dnf -y install snapd; ln -s /var/lib/snapd/snap /snap; snap install snap-store; systemctl enable --now snapd.socket; snap set system refresh.timer=4:00-7:00,21:00-23:50; sh -c "echo 'export PATH="\$PATH:/snap/bin/"' >> /etc/profile"

dnf install -y dnf-plugins-core
dnf copr enable -y tkorbar/cheat
dnf copr enable -y konimex/neofetch
dnf copr enable -y angeldm/psensor

# note the spaces to make sure something like 'notnode' could not trigger 'nodejs' using [*]
case " ${packages_to_install[*]} " in
*' code '*)
    rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    ;;&
*' brave-browser '*)
    dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/x86_64/
    rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
    ;;
esac

#==============================================================================
# install packages
#==============================================================================
echo "${BOLD}Removing unwanted programs...${RESET}"
dnf -y remove "${packages_to_remove[@]}"

echo "${BOLD}Updating Centos8...${RESET}"
dnf -y --refresh upgrade

echo "${BOLD}Installing packages...${RESET}"
dnf -y install "${packages_to_install[@]}"

echo "${BOLD}Installing flatpak packages...${RESET}"
flatpak install -y flathub "${flathub_packages_to_install[@]}"
flatpak uninstall -y --unused

#==============================================================================
# install binaries
#==============================================================================
echo "${BOLD}Downloading and installing binaries...${RESET}"

curl -Of https://shellcheck.storage.googleapis.com/shellcheck-v0.7.0.linux.x86_64.tar.xz
echo "84e06bee3c8b8c25f46906350fb32708f4b661636c04e55bd19cdd1071265112d84906055372149678d37f09a1667019488c62a0561b81fe6a6b45ad4fae4ac0 ./shellcheck-v0.7.0.linux.x86_64.tar.xz" |
    sha512sum --check
tar -C /usr/local/bin/ -xf shellcheck-v0.7.0.linux.x86_64.tar.xz --no-anchored 'shellcheck' --strip=1

curl -LOf https://github.com/jgm/pandoc/releases/download/2.9.2.1/pandoc-2.9.2.1-linux-amd64.tar.gz
echo "37f791e766b4e91824814241709243436ba25447bf908626c1d588ba098161bb6c821a6aa4abd2096ae70a8a4207dc862d090abce2f0d64cf582421d6f0f96c6 ./pandoc-2.9.2.1-linux-amd64.tar.gz" |
    sha512sum --check
tar -C /usr/local/bin/ -xf pandoc-2.9.2.1-linux-amd64.tar.gz --no-anchored 'pandoc' --strip=2

#==============================================================================
# install extras conditionally
#==============================================================================
if [[ $webdev =~ ^[Yy]$ ]]; then
    curl -fsSL https://deno.land/x/install/install.sh | sh
fi

case " ${packages_to_install[*]} " in
*' code '*)
    echo "${BOLD}Installing Visual Studio Code extensions...${RESET}"
    for extension in "${code_extensions[@]}"; do
        /usr/bin/su - "$SUDO_USER" -c "code --install-extension $extension"
    done
    ;;
esac

cat <<EOL
=============================================================================
Congratulations, everything is installed!!

To add nodejs 12:

  - 'sudo dnf module install nodejs:12/common' or
  - curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.2/install.sh | bash
    nvm install --lts (after opening new terminal)

...don't forget to install PNPM globally

- Update abattis-cantarell-fonts

Now use the setup script...
=============================================================================
EOL
