#!/bin/bash

# -----------------------------------------------
# ------------------- BESPOKE -------------------
# A Simple Script to Setup a Fedora Linux Desktop
# -----------------------------------------------
# --- Sean Galie (https://www.seangalie.com/) ---
# -----------------------------------------------

# Update Fedora and install common packages
bespoke-install() {
    echo "\nUpdating your Fedora installation packages...\n"
    if [ "$ATOMICFEDORA" = true ]; then
        sudo rpm-ostree status
        sudo rpm-ostree upgrade --check
        sudo rpm-ostree upgrade
    elif [ "$ATOMICFEDORA" = false ]; then
        sudo dnf clean all
        sudo dnf update
        sudo dnf upgrade --refresh
        sudo dnf autoremove -y
        sudo dnf group upgrade core
    else
        echo "\nERROR - Initial Fedora Updates"
        echo "Script was not sure if Atomic or Not... installation stopped.\n"
        exit 1
    fi
    echo "\nUpdating your firmware...\n"
    sudo fwupdmgr get-devices
    sudo fwupdmgr refresh --force
    sudo fwupdmgr get-updates
    sudo fwupdmgr update -y
    echo "\Installing base packages (including RPM Fusion)...\n"
    if [ "$ATOMICFEDORA" = true ]; then
        sudo rpm-ostree install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
        sudo rpm-ostree update --uninstall $(rpm -q rpmfusion-free-release) --uninstall $(rpm -q rpmfusion-nonfree-release) --install rpmfusion-free-release --install rpmfusion-nonfree-release
        sudo rpm-ostree install -y distrobox stacer rclone lm_sensors unzip p7zip p7zip-plugins unrar timeshift ffmpegthumbnailer gnome-tweak-tool adw-gtk3-theme heif-pixbuf-loader libheif-freeworld libheif-tools pipewire-codec-aptx fastfetch make automake gcc gcc-c++ kernel-devel bwm-ng curl git htop iftop iotop nano net-tools redhat-rpm-config ruby ruby-devel sysbench sysstat util-linux-user vnstat wget zsh libavcodec-freeworld grubby julietaula-montserrat-fonts
        sudo rpm-ostree install -y 'google-roboto*' 'mozilla-fira*' fira-code-fonts fontawesome-fonts rsms-inter-fonts julietaula-montserrat-fonts aajohan-comfortaa-fonts adobe-source-sans-pro-fonts astigmatic-grand-hotel-fonts campivisivi-titillium-fonts lato-fonts open-sans-fonts overpass-fonts redhat-display-fonts redhat-text-fonts typetype-molot-fonts
    else
        sudo rpm -Uvh http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
        sudo rpm -Uvh http://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
        sudo dnf install -y distrobox stacer rclone lm_sensors unzip p7zip p7zip-plugins unrar timeshift ffmpegthumbnailer gnome-tweak-tool adw-gtk3-theme heif-pixbuf-loader libheif-freeworld libheif-tools pipewire-codec-aptx fastfetch make automake gcc gcc-c++ kernel-devel bwm-ng curl git htop iftop iotop nano net-tools redhat-rpm-config ruby ruby-devel sysbench sysstat util-linux-user vnstat wget zsh libavcodec-freeworld grubby julietaula-montserrat-fonts
        sudo dnf install -y 'google-roboto*' 'mozilla-fira*' fira-code-fonts fontawesome-fonts rsms-inter-fonts julietaula-montserrat-fonts aajohan-comfortaa-fonts adobe-source-sans-pro-fonts astigmatic-grand-hotel-fonts campivisivi-titillium-fonts lato-fonts open-sans-fonts overpass-fonts redhat-display-fonts redhat-text-fonts typetype-molot-fonts
        sudo dnf copr enable kwizart/fedy
        sudo dnf install -y fedy
    fi
    echo "\Adding some Kernel arguments...\n"
    if [ "$ATOMICFEDORA" = true ]; then
        sudo rpm-ostree kargs --append=mem_sleep_default=s2idle
        if [ "$DISABLEMITIGATIONS" = true ]; then
            sudo rpm-ostree kargs --append=mitigations=off
        fi
    else
        sudo grubby --update-kernel=ALL --args="mem_sleep_default=s2idle"
        if [ "$DISABLEMITIGATIONS" = true ]; then
            sudo grubby --update-kernel=ALL --args="mitigations=off"
        fi
    fi
    echo "\nConfiguring hardware and GPU drivers...\n"
    if [ "$INTELGPU" = true ]; then
        echo "\nConfiguring Intel drivers...\n"
        if [ "$ATOMICFEDORA" = true ]; then
            rpm-ostree override remove libva-intel-media-driver --install intel-media-driver
        else
            sudo dnf swap libva-intel-media-driver intel-media-driver --allowerasing
        fi
    fi
    if [ "$AMDGPU" = true ]; then
        echo "\nConfiguring AMD drivers...\n"
        if [ "$ATOMICFEDORA" = true ]; then
            rpm-ostree override remove mesa-va-drivers --install mesa-va-drivers-freeworld
            rpm-ostree override remove mesa-vdpau-drivers --install mesa-vdpau-drivers-freeworld
        else
            sudo dnf swap mesa-va-drivers mesa-va-drivers-freeworld
            sudo dnf swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld
        fi
    fi
    if [ "$NVIDIAGPU" = true ]; then
        echo "\nConfiguring Nvidia drivers...\n"
        if [ "$ATOMICFEDORA" = true ]; then
            sudo rpm-ostree install --apply-live akmod-nvidia xorg-x11-drv-nvidia xorg-x11-drv-nvidia-cuda
            sudo rpm-ostree kargs --append=rd.driver.blacklist=nouveau --append=modprobe.blacklist=nouveau --append=nvidia-drm.modeset=1
        else
            sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia xorg-x11-drv-nvidia-cuda
            echo "\nBuilding Graphics Driver Support (waiting 5 minutes)...\n"
            sleep 300
            modinfo -F version nvidia
            sudo grubby --update-kernel=ALL --args="nvidia-drm.modeset=1"
        fi
    fi
    echo "\nUpdating Flathub and Flatpak repositories...\n"
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    flatpak remote-modify --enable flathub
    flatpak install -y --reinstall flathub $(flatpak list --app-runtime=org.fedoraproject.Platform --columns=application | tail -n +1 )
    flatpak remote-add --user flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo
    flatpak update
    flatpak install -y flathub com.mattjakeman.ExtensionManager
    echo "\nInstalling base applications...\n"
    if [ "$ATOMICFEDORA" = true ]; then
        flatpak install -y flathub com.google.Chrome org.gnome.DejaDup
        sudo rpm-ostree install gnome-tweaks gnome-extensions-app flatseal
    else
        sudo dnf install -y fedora-workstation-repositories
        sudo dnf config-manager --set-enabled google-chrome
        sudo dnf install -y google-chrome-stable
        sudo dnf install -y gnome-tweaks gnome-extensions-app flatseal deja-dup
    fi
}

# Add additional application groups and packages based on interactive questions
bespoke-appinstalls() {
    if [ "$INSTALLOFFICE" = true ]; then
        echo "\nInstalling office apps...\n"
        flatpak install -y flathub eu.betterbird.Betterbird us.zoom.Zoom com.discordapp.Discord com.slack.Slack org.gnome.World.Iotas md.obsidian.Obsidian
        if [ "$ATOMICFEDORA" = true ]; then
            flatpak install -y flathub org.libreoffice.LibreOffice org.gnome.Evolution org.gnome.Geary org.gnucash.GnuCash org.kde.okular com.calibre_ebook.calibre
        else
            sudo dnf install -y libreoffice geary evolution gnucash okular calibre
        fi
    fi
    if [ "$INSTALLMEDIA" = true ]; then
        echo "\nInstalling multimedia player apps...\n"
        flatpak install -y flathub io.bassi.Amberol com.github.iwalton3.jellyfin-media-player org.nickvision.tubeconverter
        if [ "$ATOMICFEDORA" = true ]; then
            flatpak install -y flathub io.github.celluloid_player.Celluloid org.videolan.VLC com.github.johnfactotum.Foliate org.gnome.Rhythmbox3 org.gnome.Totem
        else
            sudo dnf install -y celluloid vlc yt-dlp foliate rhythmbox totem
        fi
    fi
    if [ "$INSTALLCREATIVE" = true ]; then
        echo "\nInstalling creative artist apps...\n"
        flatpak install -y flathub io.github.nate_xyz.Conjure io.gitlab.theevilskeleton.Upscaler
        if [ "$ATOMICFEDORA" = true ]; then
            flatpak install -y flathub org.gimp.GIMP org.inkscape.Inkscape org.kde.krita org.darktable.Darktable net.scribus.Scribus org.fontforge.FontForge org.gnome.Shotwell org.entangle_photo.Manager nl.hjdskes.gcolor3 net.sourceforge.Hugin com.github.jeromerobert.pdfarranger
        else
            sudo dnf install -y darktable gimp inkscape krita scribus fontforge shotwell entangle gcolor3 hugin pdfarranger
        fi
    fi
    if [ "$INSTALLVIDEO" = true ]; then
        echo "\nInstalling video production apps...\n"
        if [ "$ATOMICFEDORA" = true ]; then
            flatpak install -y flathub org.blender.Blender org.kde.kdenlive com.obsproject.Studio org.openshot.OpenShot org.pitivi.Pitivi org.synfig.SynfigStudio
        else
            sudo dnf install -y blender kdenlive obs-studio openshot pitivi synfigstudio
        fi
    fi
    if [ "$INSTALLAUDIO" = true ]; then
        echo "\nInstalling audio production apps...\n"
        flatpak install -y flathub org.tenacityaudio.Tenacity
        if [ "$ATOMICFEDORA" = true ]; then
            flatpak install -y flathub org.ardour.Ardour org.musescore.MuseScore org.soundconverter.SoundConverter org.denemo.Denemo
        else
            sudo dnf install -y ardour8 musescore soundconverter gnome-sound-recorder denemo
        fi
    fi
    if [ "$INSTALLDEVELOPMENT" = true ]; then
        echo "\nInstalling developer apps...\n"
        flatpak install -y flathub com.google.AndroidStudio dev.pulsar_edit.Pulsar
        if [ "$ATOMICFEDORA" = true ]; then
            flatpak install -y flathub com.visualstudio.code org.gnome.meld org.gnome.gitlab.somas.Apostrophe
        else
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc && \
            sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo' && \
            sudo dnf check-update && \
            sudo dnf install -y code meld apostrophe
        fi
    fi
    if [ "$INSTALLGIS" = true ]; then
        echo "\nInstalling GIS apps...\n"
        if [ "$ATOMICFEDORA" = true ]; then
            flatpak install -y flathub org.qgis.qgis
        else
            sudo dnf install -y qgis
        fi
    fi
    if [ "$INSTALLLLM" = true ]; then
        echo "\nInstalling LLM apps...\n"
        flatpak install -y flathub com.jeffser.Alpaca
    fi
    if [ "$INSTALLGAMING" = true ]; then
        echo "\nInstalling gaming apps...\n"
        if [ "$ATOMICFEDORA" = true ]; then
            flatpak install -Y flathub com.valvesoftware.Steam io.github.sharkwouter.Minigalaxy net.lutris.Lutris org.winehq.Wine com.usebottles.bottles
        else
            sudo dnf install -y steam minigalaxy lutris wine bottles gamemode gamescope
        fi
    fi
    if [ "$INSTALLSHARING" = true ]; then
        echo "\nInstalling file sharing apps...\n"
        if [ "$ATOMICFEDORA" = true ]; then
            rpm-ostree install https://www.dropbox.com/download?dl=packages/fedora/nautilus-dropbox-2024.04.17-1.fc39.x86_64.rpm
            flatpak install -y flathub org.sparkleshare.SparkleShare
        else
            sudo dnf install -y https://www.dropbox.com/download?dl=packages/fedora/nautilus-dropbox-2024.04.17-1.fc39.x86_64.rpm
            sudo dnf install -y sparkleshare
        fi
    fi
    if [ "$INSTALLTAILSCALE" = true ]; then
        echo "\nInstalling Tailscale...\n"
        if [ "$ATOMICFEDORA" = true ]; then
            sudo curl -s https://pkgs.tailscale.com/stable/fedora/tailscale.repo -o /etc/yum.repos.d/tailscale.repo > /dev/null
            sudo wget https://pkgs.tailscale.com/stable/fedora/repo.gpg -O /etc/pki/rpm-gpg/tailscale.gpg
            sudo sed -i 's\"https://pkgs.tailscale.com/stable/fedora/repo.gpg"\file:///etc/pki/rpm-gpg/tailscale.gpg\' /etc/yum.repos.d/tailscale.repo
            rpm-ostree install --apply-live tailscale
            sudo systemctl enable --now tailscaled
            sudo tailscale up
            sudo tailscale set --operator=$USER
        else
            sudo dnf config-manager --add-repo https://pkgs.tailscale.com/stable/fedora/tailscale.repo
            sudo dnf install -y tailscale
            sudo systemctl enable --now tailscaled
            sudo tailscale up
            sudo tailscale set --operator=$USER
        fi
    fi
}

# Start the script with a nice ASCII logo and an 'are you sure?' prompt
bespoke-start() {
    ASCIILOGO='
        ++----------------------------------------------++
        ++----------------------------------------------++
        ||                                              ||
        ||    ___   ____  __   ___   ___   _     ____   ||
        ||   | |_) | |_  ( (\` | |_) / / \ | |_/ | |_    ||
        ||   |_|_) |_|__ _)_) |_|   \_\_/ |_| \ |_|__   ||
        ||                                              ||
        ||                                              ||
        ++----------------------------------------------++
        ++----------------------------------------------++
        '
    sudo clear
    echo -e "$ASCIILOGO"
    echo "The BESPOKE script is for a fresh Fedora Workstation 40 or 41 installs only!"
    echo -e "\nIf you don't want to continue, press Control-C now to exit the script."
    echo "\nA few questions before we begin - this will help the script customize your Fedora installation."
}

bespoke-options() {
    echo "\nShould mitigations for Intel 5th-9th Gen Meltdown/Sceptre be disabled?"
    read -n 1 -p "If you are unsure of what this means, choose N for no. (y/n) " answer
    case ${answer:0:1} in
        y|Y )
            DISABLEMITIGATIONS=true
        ;;
        * )
            DISABLEMITIGATIONS=false
        ;;
    esac

    echo "\nIs this device an Intel 5th Gen or later with integrated Intel graphics?"
    read -n 1 -p "Choose Y (Yes) if you have a dedicated Intel GPU as well. (y/n) " answer
    case ${answer:0:1} in
        y|Y )
            INTELGPU=true
        ;;
        * )
            INTELGPU=false
        ;;
    esac

    read -n 1 -p "\nDo you have integrated AMD graphics or an AMD GPU? (y/n) " answer
    case ${answer:0:1} in
        y|Y )
            AMDGPU=true
        ;;
        * )
            AMDGPU=false
        ;;
    esac

    read -n 1 -p "\nDo you have integrated Nvidia graphics or a Nvidia GPU? (y/n) " answer
    case ${answer:0:1} in
        y|Y )
            NVIDIAGPU=true
        ;;
        * )
            NVIDIAGPU=false
        ;;
    esac

    read -n 1 -p "\nDo you want to choose apps to install? (y/n) " answer
    case ${answer:0:1} in
        y|Y )
            INSTALLAPPS=true
        ;;
        * )
            INSTALLAPPS=false
        ;;
    esac

    echo "\nDo you want to install File Management platforms?"
    read -n 1 -p "Dropbox, Google Drive, and more - (y/n) " answer
    case ${answer:0:1} in
        y|Y )
            INSTALLSHARING=true
        ;;
        * )
            INSTALLSHARING=false
        ;;
    esac

    read -n 1 -p "\nDo you want to install Tailscale? (y/n) " answer
    case ${answer:0:1} in
        y|Y )
            INSTALLTAILSCALE=true
        ;;
        * )
            INSTALLTAILSCALE=false
        ;;
    esac
}

bespoke-appoptions() {
    if [ "$INSTALLAPPS" = true ]; then
        echo "\nDo you want to install the office apps?"
        read -n 1 -p "LibreOffice, Email, GnuCash, Okular, and more - (y/n) " answer
        case ${answer:0:1} in
            y|Y )
                INSTALLOFFICE=true
            ;;
            * )
                INSTALLOFFICE=false
            ;;
        esac

        echo "\nDo you want to install the multimedia player apps?"
        read -n 1 -p "Amberol, Calibre, Celluloid, VLC, and more - (y/n) " answer
        case ${answer:0:1} in
            y|Y )
                INSTALLMEDIA=true
            ;;
            * )
                INSTALLMEDIA=false
            ;;
        esac

        echo "\nDo you want to install the creative artist apps?"
        read -n 1 -p "Darktable, GIMP, Inkscape, Krita, and more - (y/n) " answer
        case ${answer:0:1} in
            y|Y )
                INSTALLCREATIVE=true
            ;;
            * )
                INSTALLCREATIVE=false
            ;;
        esac

        echo "\nDo you want to install the video production apps?"
        read -n 1 -p "Blender, Kdenlive, OBS, OpenShot, Pitivi, and more - (y/n) " answer
        case ${answer:0:1} in
            y|Y )
                INSTALLVIDEO=true
            ;;
            * )
                INSTALLVIDEO=false
            ;;
        esac

        echo "\nDo you want to install the audio production apps?"
        read -n 1 -p "Ardour, MuseScore, Tenacity, and more - (y/n) " answer
        case ${answer:0:1} in
            y|Y )
                INSTALLAUDIO=true
            ;;
            * )
                INSTALLAUDIO=false
            ;;
        esac

        echo "\nDo you want to install the developer apps?"
        read -n 1 -p "Android Studio, Pulsar, Obsidian, and Visual Studio Code (y/n) " answer
        case ${answer:0:1} in
            y|Y )
                INSTALLDEVELOPMENT=true
            ;;
            * )
                INSTALLDEVELOPMENT=false
            ;;
        esac

        echo "\nDo you want to install GIS apps?"
        read -n 1 -p "QGIS (y/n) " answer
        case ${answer:0:1} in
            y|Y )
                INSTALLGIS=true
            ;;
            * )
                INSTALLGIS=false
            ;;
        esac

        echo "\nDo you want to install LLM apps?"
        read -n 1 -p "Alpaca (y/n) " answer
        case ${answer:0:1} in
            y|Y )
                INSTALLLLM=true
            ;;
            * )
                INSTALLLLM=false
            ;;
        esac

        echo "\nDo you want to install the gaming apps?"
        read -n 1 -p "Steam, Lutris, Wine, Bottles, and more (y/n) " answer
        case ${answer:0:1} in
            y|Y )
                INSTALLGAMING=true
            ;;
            * )
                INSTALLGAMING=false
            ;;
        esac
    else
        INSTALLOFFICE=false
        INSTALLMEDIA=false
        INSTALLCREATIVE=false
        INSTALLVIDEO=false
        INSTALLDAVINCI=false
        INSTALLAUDIO=false
        INSTALLDEVELOPMENT=false
        INSTALLGIS=false
        INSTALLLLM=false
        INSTALLGAMING=false
    fi
}

bespoke-atomic() {
    if [ ! -f /run/ostree-booted ]; then
        ATOMICFEDORA=false
    else
        ATOMICFEDORA=true
    fi
}

bespoke-distro() {
    echo "\nChecking if you are running Fedora...\n"
    if [ ! -f /etc/os-release ]; then
        echo "\nThis script was unable to determine your distribution."
        echo "/etc/os-release file not found - installation stopped."
        exit 1
    fi
    . /etc/os-release
    if [ "$ID" = "fedora" ]; then
        bespoke-version;
    else
        echo "\nThis script is not compatible with your distribution."
        echo "\nYour computer is is currently running: $ID $VERSION_ID"
        echo "\nThis script is for Fedora 40 or 41 - installation stopped."
        exit 1
    fi
}

bespoke-version() {
    echo "\nChecking your version of Fedora...\n"
    . /etc/os-release
    if [ "$VERSION_ID" >= 40 ]; then
        bespoke-atomic;
    else
        echo "\nThis script is not compatible with your distribution."
        echo "\nYour computer is is currently running: $ID $VERSION_ID"
        echo "\nThis script is for Fedora 40 or 41 - installation stopped."
        exit 1
    fi
}

RUNNING_GNOME=$([[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]] && echo true || echo false)
if $RUNNING_GNOME; then
    gsettings set org.gnome.desktop.screensaver lock-enabled false
    gsettings set org.gnome.desktop.session idle-delay 0
    gsettings set org.gnome.desktop.wm.preferences button-layout ":minimize,maximize,close"
    gsettings set org.gnome.desktop.interface show-battery-percentage true
    bespoke-start
    bespoke-distro
    bespoke-options
    bespoke-appoptions
    bespoke-install
    bespoke-appinstalls
    gsettings set org.gnome.desktop.screensaver lock-enabled true
    gsettings set org.gnome.desktop.session idle-delay 300
else
    bespoke-start
    bespoke-distro
    bespoke-options
    bespoke-appoptions
    bespoke-install
    bespoke-appinstalls
fi

echo "\nThe script has now completed and it is recommended to reboot the device."
read -n 1 -p "Do you want to restart now? (y/n) " answer
case ${answer:0:1} in
    y|Y )
        sudo systemctl reboot
    ;;
    * )
        exit 0
    ;;
esac