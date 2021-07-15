# This project has been superseded by https://github.com/David-Else/developer-workstation-setup-script !

I have totally re-written and improved everything. I think it is different enough to warrant a new repository.

If you have any feedback or questions please head over to https://github.com/David-Else/developer-workstation-setup-script/discussions

# Fedora and Centos Ultimate Setup Scripts v5.1 (Jan 2021)

**Welcome to your new ultimate desktop!** You can now choose between long term support with Centos and cutting edge features with Fedora. Run these scripts after a fresh install of your favorite OS. You can re-create the same set of applications and settings across both distributions.

I have written a blog article [CentOS 8 Setup for Developers](https://www.elsewebdevelopment.com/centos-8-setup-for-developers/) that explains how the script works to help with customization.

Enjoy!

### Browsers

- Firefox
- Chromium

### Graphics and photography

- Krita
- Shotwell
- ImageMagick

### Sound and video

- Deadbeef
- MPV
- Handbrake
- MKVToolNix

### Security and backup

- KeepassXC
- Syncthing
- BorgBackup

### (Optional) Development tools

- Visual Studio Code
- PHP / Node.js / Deno
- Podman (Centos) / Docker (Fedora)
- Gnome Boxes

There are two scripts for each distribution, `install` and `setup`. Install requires running with `sudo`, this was done to prevent it timing out when left unattended.

## Install script

![Fedora and centos app differences](images/install-script-v5.png)

You will be prompted for a choice between standard install and web development install. These are both highly opinionated, but simple to change editing the scripts:

```shell
# >>>>>> start of user settings <<<<<<
Add and remove the applications you want from repositories
# >>>>>> end of user settings <<<<<<

# Repositories are intelligently added for your choices if needed:
case " ${packages_to_install[*]} " in
*' code '*)
    # Action if 'code' is included in packages
    ;;&
*' brave-browser '*)
    # Action if 'brave-browser' is included in packages
    ;;
esac

# If web development is chosen additional actions can be performed other than adding more packages
if [[ $webdev =~ ^[Yy]$ ]]; then
    # Additional actions
fi
```

## Setup script

If web development was chosen then a lot of extra things are setup here. Most people will want to heavily edit this file for their own preferences. Highlights include:

- Better Gnome settings
- Set your Github name and email
- PHP settings
- Set host name
- Write config files only for software that you have installed previously
- Improve Pulse Audio defaults
- Subpixel rendering for Xorg
- Various fixes and enhancements

# New in version 6

- Use [stow](https://www.gnu.org/software/stow/) to install dotfiles

Now all the relevant dotfiles for the software installed live in `~/dotfiles` and are magically symlinked to the correct location in the home directory using `stow`. You can read about how this works in [Managing Dotfiles with GNU Stow](https://www.stevenrbaker.com/tech/managing-dotfiles-with-gnu-stow.html)

- Added [Neovim](https://neovim.io/) setup script

I have included a bonus script to install and setup Neovim 0.5 from scratch using the latest nightly build. I have tried to create a VS Code style setup in as minimalist way as possible using the new built in LSP and the https://github.com/hrsh7th/nvim-compe autocompletion plugin.

With the new built in LSP Neovim is the best editor, but VS Code has so many useful extensions you may still need it for some things.

Enjoy these shortcuts:

```
"==========================================="
"         Custom Key Mappings               "
"                                           "
"  <leader>f  = format                      "
"  <leader>c  = edit init.vim config        "
"  <leader>cc = toggle colorcolumn          "
"  <leader>n  = toggle line numbers         "
"  <leader>s  = toggle spell check          "
"  <leader>w  = toggle whitespaces          "
"  <leader>t  = new terminal                "
"  <leader>cd = working dir to current file "
"                                           "
"  <leader>b   = open buffers               "
"  <leader>h   = open file history          "
"  <leader>gl  = git files (git ls-files)   "
"  <leader>gs  = git files (git status)     "
"  <leader>gc  = git commits current buffer "
"  <leader>rg  = ripgrep search results     "
"                                           "
"          jk = escape                      "
"         TAB = cycle buffers               "
"      ctrl-s = save                        "
"      ctrl-e = toggle netrw file explorer  "
"      ctrl-p = open fzf file explorer      "
"         ESC = search highlighting off     "
"==========================================="
```

- Added [nnn](https://github.com/jarun/nnn) setup script. This is the ultimate file browser, never use Gnome files unless it is an emergency!

# New in version 5.1:

- Tested on Fedora 33 and Centos 8.3
- Added and removed some apps

# New in version 5:

- Tested on Fedora 32 and Centos 8.1
- Add new apps and remove old ones
- Synchronize Fedora and Centos application versions as much as possible taking advantage of newly available EPEL-8 and Flatpak packages. Always prefer official repository versions where possible.

![Fedora and centos app differences](images/differences_centos_fedora_packages.png)

- Add option to auto start programs on boot using `.config/autostart` with a default `TODO.txt` list and terminal instance
- Add updated compatible `abattis cantarell fonts` for Centos 8.1, it ships with old ones
- Refactor, update and improve all scripts

## Fedora Installation and running scripts

Download this repository using git, CD into the directory, and run:

```
git clone https://github.com/David-Else/fedora-ultimate-setup-script
cd fedora-ultimate-setup-script
sudo ./fedora-ultimate-install-script.sh
./fedora-ultimate-setup-script.sh
```

## Centos 8 Installation and running scripts

Download this repository using git, CD into the directory, and run:

```
git clone https://github.com/David-Else/fedora-ultimate-setup-script
cd fedora-ultimate-setup-script
sudo ./centos8-ultimate-install-script.sh
./centos8-ultimate-setup-script.sh
```

### FAQ

**Q**: Does this script disable the caps lock key? I've noticed that it works during login but after that it stops working altogether.

**A**: It makes the caps lock into a delete for touch typing purposes, to change it modify this line in the setup script before running:

```shell
 capslock_delete="false"
```
