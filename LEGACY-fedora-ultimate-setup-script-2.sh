#!/bin/bash

#==================================================================================================
#
#         FILE: fedora-ultimate-setup-script.sh
#        USAGE: fedora-ultimate-setup-script.sh
#
#  DESCRIPTION: Post-installation setup script for Fedora 29 Workstation
#      WEBSITE: https://www.elsewebdevelopment.com/
#
# REQUIREMENTS: Fresh copy of Fedora 29/30 installed on your computer
#               https://dl.fedoraproject.org/pub/fedora/linux/releases/29/Workstation/x86_64/iso/
#       AUTHOR: David Else
#      COMPANY: Else Web Development
#      VERSION: 2.2.1
#==================================================================================================

# WARNING sudo time outs and you need to enter password a few times

GREEN=$(tput setaf 2)
BOLD=$(tput bold)
RESET=$(tput sgr0)

#==================================================================================================
# set user preferences
#==================================================================================================
system_updates_dir="$HOME/offline-system-updates"
user_updates_dir="$HOME/offline-user-packages"
GIT_EMAIL='example@example.com'
GIT_USER_NAME='example-name'
REMOVE_LIST=(gnome-photos gnome-documents rhythmbox totem cheese)

create_package_list() {
    declare -A packages=(
        ['drivers']='libva-intel-driver fuse-exfat'
        ['multimedia']='mpv ffmpeg mkvtoolnix-gui shotwell'
        ['utils']='gnome-tweaks tldr whipper keepassx transmission-gtk lshw mediainfo klavaro youtube-dl'
        ['gnome_extensions']='gnome-shell-extension-auto-move-windows.noarch gnome-shell-extension-pomodoro'
        ['emulation']='winehq-stable dolphin-emu mame'
        ['audio']='jack-audio-connection-kit'
        ['backup_sync']='borgbackup syncthing'
        ['languages']='java-1.8.0-openjdk nodejs php php-json'
        ['webdev']='code chromium chromium-libs-media-freeworld docker docker-compose ShellCheck'
        ['firefox extensions']='mozilla-https-everywhere mozilla-privacy-badger mozilla-ublock-origin'
    )
    for package in "${!packages[@]}"; do
        echo "$package: ${GREEN}${packages[$package]}${RESET}" >&2
        PACKAGES_TO_INSTALL+=(${packages[$package]})
    done
}

#==================================================================================================
# add repositories
#==================================================================================================
add_repositories() {
    echo "${BOLD}Adding repositories...${RESET}"
    sudo dnf -y install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    if [[ ${PACKAGES_TO_INSTALL[*]} == *'winehq-stable'* ]]; then
        sudo dnf config-manager --add-repo https://dl.winehq.org/wine-builds/fedora/29/winehq.repo
    fi

    if [[ ${PACKAGES_TO_INSTALL[*]} == *'code'* ]]; then
        sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
        sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    fi
}

#==================================================================================================
# setup visual studio code
#==================================================================================================
setup_vscode() {
    local code_extensions=(ban.spellright
        bierner.markdown-preview-github-styles
        deerawan.vscode-dash
        esbenp.prettier-vscode
        foxundermoon.shell-format
        ms-vsliveshare.vsliveshare
        msjsdiag.debugger-for-chrome
        ritwickdey.LiveServer
        timonwong.shellcheck
        WallabyJs.quokka-vscode)
    for extension in "${code_extensions[@]}"; do
        code --install-extension "$extension"
    done

    cat >"$HOME/.config/Code/User/settings.json" <<EOL
// Place your settings in this file to overwrite the default settings
{
  // VS Code 1.36 general settings
  "editor.renderWhitespace": "all",
  "editor.dragAndDrop": false,
  "editor.formatOnSave": true,
  "editor.minimap.enabled": false,
  "editor.detectIndentation": false,
  "editor.tabSize": 2,
  "workbench.activityBar.visible": false,
  "workbench.tree.renderIndentGuides": "none",
  "workbench.list.keyboardNavigation": "filter",
  "window.menuBarVisibility": "toggle",
  "zenMode.restore": true,
  "zenMode.centerLayout": false,
  "zenMode.fullScreen": false,
  "git.autofetch": true,
  "git.enableSmartCommit": true,
  "git.decorations.enabled": false,
  "npm.enableScriptExplorer": true,
  "explorer.decorations.colors": false,
  "search.followSymlinks": false,
  // Privacy
  "telemetry.enableTelemetry": false,
  "extensions.showRecommendationsOnlyOnDemand": true,
  // Language settings
  "php.validate.executablePath": "/usr/bin/php",
  "javascript.preferences.quoteStyle": "single",
  "typescript.updateImportsOnFileMove.enabled": "always",
  "files.exclude": {
    "**/*.js": { "when": "$(basename).ts" },
    "**/*.js.map": true
  },
  "[javascript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[json]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[jsonc]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  // Shell Format extension
  "shellformat.flag": "-i 4",
  // Live Server extension
  "liveServer.settings.donotShowInfoMsg": true,
  "liveServer.settings.ChromeDebuggingAttachment": true,
  "liveServer.settings.AdvanceCustomBrowserCmdLine": "/usr/bin/chromium-browser --remote-debugging-port=9222",
  // Prettier extension
  "prettier.singleQuote": true,
  "prettier.trailingComma": "all",
  "prettier.proseWrap": "always",
  // Spellright extension
  "spellright.language": ["English (British)"],
  "spellright.documentTypes": ["markdown", "latex", "plaintext"]
  // "typescript.referencesCodeLens.enabled": true,
  // "javascript.referencesCodeLens.enabled": true,
}
EOL
}

#==================================================================================================
# setup jack
#==================================================================================================
setup_jack() {
    sudo usermod -a -G jackuser "$USERNAME" # Add current user to jackuser group
    sudo tee /etc/security/limits.d/95-jack.conf <<EOL
# Default limits for users of jack-audio-connection-kit

@jackuser - rtprio 98
@jackuser - memlock unlimited

@pulse-rt - rtprio 20
@pulse-rt - nice -20
EOL
}

#==================================================================================================
# setup git
#==================================================================================================
setup_git() {
    if [[ -z $(git config --get user.name) ]]; then
        git config --global user.name $GIT_USER_NAME
        echo "No global git user name was set, I have set it to ${BOLD}$GIT_USER_NAME${RESET}"
    fi

    if [[ -z $(git config --get user.email) ]]; then
        git config --global user.email $GIT_EMAIL
        echo "No global git email was set, I have set it to ${BOLD}$GIT_EMAIL${RESET}"
    fi
}

#==================================================================================================
# setup mpv (before it is run config file or dir does not exist)
#==================================================================================================
setup_mpv() {
    mkdir "$HOME/.config/mpv"
    cat >"$HOME/.config/mpv/mpv.conf" <<EOL
profile=gpu-hq
hwdec=auto
fullscreen=yes
EOL
}

#==================================================================================================
# install and create offline install
#==================================================================================================
create_offline_install() {
    mkdir "$system_updates_dir" "$user_updates_dir"

    echo "${BOLD}Updating Fedora, installing packages, and saving .rpm files...${RESET}"
    sudo dnf -y --refresh upgrade --downloadonly --downloaddir="$system_updates_dir" --setopt=keepcache=1
    sudo dnf -y install "$system_updates_dir"/*.rpm --setopt=keepcache=1
    sudo dnf -y install "${PACKAGES_TO_INSTALL[@]}" --downloadonly --downloaddir="$user_updates_dir" --setopt=keepcache=1
    sudo dnf -y install "$user_updates_dir"/*.rpm --setopt=keepcache=1

    echo
    echo "Your .rpm files live in ${GREEN}$system_updates_dir${RESET} and ${GREEN}$user_updates_dir${RESET}"
    echo "On Fresh Fedora ISO install copy dirs into home folder and run script choosing option 3 (or use ${GREEN}sudo dnf install *.rpm${RESET} in respective directories)"
}

#==================================================================================================
# update_and_install_online
#==================================================================================================
update_and_install_online() {
    echo "${BOLD}Updating Fedora and installing packages...${RESET}"
    sudo dnf -y --refresh upgrade
    sudo dnf -y install "${PACKAGES_TO_INSTALL[@]}"
}

#==================================================================================================
# update_and_install_offline
#==================================================================================================
update_and_install_offline() {
    if [[ ! -d "$system_updates_dir" || ! -d "$user_updates_dir" ]]; then
        echo "${GREEN}$system_updates_dir${RESET} or ${GREEN}$user_updates_dir${RESET} do not exist!"
        exit 1
    else
        echo "${BOLD}Updating Fedora and installing packages...${RESET}"
        sudo dnf -y install "$system_updates_dir"/*.rpm --setopt=keepcache=1
        sudo dnf -y install "$user_updates_dir"/*.rpm --setopt=keepcache=1
    fi
}

#==================================================================================================
# remove_unwanted_programs
#==================================================================================================
remove_unwanted_programs() {
    echo "${BOLD}Removing unwanted programs...${RESET}"
    sudo dnf -y remove "${REMOVE_LIST[@]}"
}

#==================================================================================================
# main
#==================================================================================================
main() {
    if [[ $(rpm -E %fedora) -lt 29 ]]; then
        echo >&2 "You must install at least ${GREEN}Fedora 29${RESET} to use this script" && exit 1
    fi

    clear
    cat <<EOL
===================================================================================================
Welcome to the Fedora 29+ Ultimate Setup Script!
===================================================================================================

${BOLD}Programs to add:${RESET}

EOL
    create_package_list
    cat <<EOL

${BOLD}Programs to remove:${RESET}

${GREEN}${REMOVE_LIST[*]}${RESET}

${BOLD}Git globals will be set to:${RESET} USER_NAME ${GREEN}$GIT_USER_NAME${RESET} EMAIL ${GREEN}$GIT_EMAIL${RESET}

Would you like to use your internet connection to:

${BOLD}1${RESET} Download system updates and install/setup user selected programs
${BOLD}2${RESET} Download system updates and install/setup user selected programs
  and create offline install files for future use

Or use offline install files created previously to:

${BOLD}3${RESET} Install system updates and install/setup user selected programs

EOL

    #==============================================================================================
    # choose options and set host name
    #==============================================================================================
    read -p "Please select from the above options (1/2/3) " -n 1 -r

    echo
    local hostname
    read -rp "What is this computer's name? [$HOSTNAME] " hostname
    if [[ ! -z "$hostname" ]]; then
        hostnamectl set-hostname "$hostname"
    fi

    case $REPLY in
    1)
        set -euo pipefail
        add_repositories
        remove_unwanted_programs
        update_and_install_online
        ;;
    2)
        set -euo pipefail
        add_repositories
        remove_unwanted_programs
        create_offline_install
        ;;
    3)
        add_repositories
        remove_unwanted_programs
        update_and_install_offline
        ;;
    *)
        echo "$REPLY was an invalid choice"
        exit
        ;;
    esac

    #==============================================================================================
    # setup software
    #==============================================================================================
    echo "${BOLD}Setting up git globals...${RESET}"
    setup_git

    # note the spaces to make sure something like 'notnode' could not trigger 'nodejs' using [*]
    case " ${PACKAGES_TO_INSTALL[*]} " in
    *' code '*)
        echo "${BOLD}Setting up Visual Studio Code...${RESET}"
        setup_vscode
        ;;&
    *' nodejs '*)
        echo "${BOLD}Setting up pnpm...${RESET}"
        sudo npm install -g pnpm npm-check eslint jsdom
        cat >>"$HOME/.bashrc" <<EOL
export NPM_CHECK_INSTALLER=pnpm
EOL
        ;;&
    *' mpv '*)
        echo "${BOLD}Setting up mpv...${RESET}"
        setup_mpv
        ;;&
    *' jack-audio-connection-kit '*)
        echo "${BOLD}Setting up jack...${RESET}"
        setup_jack
        ;;&
    esac

    #==============================================================================================
    # setup pulse audio
    #
    # *pacmd list-sinks | grep sample and see bit-depth available for interface
    # *pulseaudio --dump-re-sample-methods and see re-sampling available
    #
    # *MAKE SURE your interface can handle s32le 32bit rather than the default 16bit
    #==============================================================================================
    echo "${BOLD}Setting up Pulse Audio...${RESET}"
    sudo sed -i "s/; default-sample-format = s16le/default-sample-format = s32le/g" /etc/pulse/daemon.conf
    sudo sed -i "s/; resample-method = speex-float-1/resample-method = speex-float-10/g" /etc/pulse/daemon.conf
    sudo sed -i "s/; avoid-resampling = false/avoid-resampling = true/g" /etc/pulse/daemon.conf

    #==============================================================================================
    # setup gnome desktop gsettings
    #==============================================================================================
    echo "${BOLD}Setting up Gnome...${RESET}"
    gsettings set org.gnome.settings-daemon.plugins.media-keys max-screencast-length 0 # Ctrl + Shift + Alt + R to start and stop screencast
    gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
    gsettings set org.gnome.desktop.interface clock-show-date true
    gsettings set org.gnome.desktop.session idle-delay 1200
    gsettings set org.gnome.desktop.input-sources xkb-options "['caps:backspace', 'terminate:ctrl_alt_bksp']"
    gsettings set org.gnome.shell.extensions.auto-move-windows application-list "['org.gnome.Nautilus.desktop:2', 'org.gnome.Terminal.desktop:3', 'code.desktop:1', 'firefox.desktop:1']"
    gsettings set org.gnome.shell enabled-extensions "['pomodoro@arun.codito.in', 'auto-move-windows@gnome-shell-extensions.gcampax.github.com']"
    gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true

    #==============================================================================================
    # make a few little changes
    #==============================================================================================
    mkdir "$HOME/sites"
    echo "Xft.lcdfilter: lcdlight" >>"$HOME/.Xresources"
    echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p
    touch ~/Templates/empty-file # so you can create new documents from nautilus
    cat >>"$HOME/.bashrc" <<EOL
alias ls="ls -ltha --color --group-directories-first" # l=long listing format, t=sort by modification time (newest first), h=human readable sizes, a=print hidden files
alias tree="tree -Catr --noreport --dirsfirst --filelimit 100" # -C=colorization on, a=print hidden files, t=sort by modification time, r=reversed sort by time (newest first)
EOL

    cat <<EOL
  ===================================================
  REBOOT NOW!!!! (or things may not work as expected)
  shutdown -r
  ===================================================
EOL
}
main

# NOTES

# - mpv addition settings include:
#  gpu-context=drm
#  video-sync=display-resample
#  interpolation
#  tscale=oversample
#
# - Install 'Hide Top Bar' extension from Gnome software
# - Firefox "about:support" what is compositor? If 'basic' open "about:config"
#   find "layers.acceleration.force-enabled" and switch to true, this will
#   force OpenGL acceleration
# - Update .bash_profile with
#   'PATH=$PATH:$HOME/.local/bin:$HOME/bin:$HOME/Documents/scripts:$HOME/Documents/scripts/borg-backup'
# - Files > preferences > views > sort folders before files
# - Change shotwell import directory format to %Y/%m + rename lower case, import photos from external drive
# - UMS > un-tick general config > enable external network + check force network on interface correct network (wlp2s0)
# - make symbolic links to media ln -s /run/media/david/WD-Red-2TB/Media/Audio ~/Music
