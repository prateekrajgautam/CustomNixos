{ config, pkgs, lib, ... }:

{
  config = {
    
    environment = {
      # Define system packages
      systemPackages = with pkgs; [
        
        # Essential System Utilities
	freefilesync
	dos2unix
        wget         # Download files from the web
        zip          # Package and compress files
	p7zip
	zarchive     # zarchivzarchive     # zarchivee
	archivemount # mount archive
        gnutar       # Archive files
        bash         # Shell for scripting
        coreutils    # Basic file utilities
        busybox      # Lightweight Unix utilities
	insomnia     # API testing
    chromium
	brave
    firefox-devedition
	copyq
	sqlitebrowser
	
	pocketbase

        # DevOps & Development Tools
        git           # Version control system
	git-lfs
        gccgo13       # Go compiler
        nodejs        # JavaScript runtime
        python315   # Python 3 interpreter
	go
	rustup
        pipenv        # Python dependency management
       # platformio    # Development environment for IoT
       # act	      # local test github actions
	#ansible       # Automation tool
       # terraform     # Infrastructure as code
        #jenkins       # Continuous integration server

        #maven         # Java project management
        #consul            # Service discovery
        #prometheus        # Monitoring toolkit
        #grafana           # Visualization platform

        # Graphics and Multimedia
#	immich-cli
	#immich-go
        gimp          # Image editor
	#darktable     #
	davinci-resolve	#
        inkscape      # Vector graphics editor
        blender       # 3D modeling software
        ardour
	audacity      # Audio editor
        lmms          # Music production software
        redshift      # Adjusts color temperature of your screen
        shotcut       # Video editor
        obs-studio    # Streaming and recording software
        droidcam
        obs-studio-plugins.droidcam-obs
        ffmpeg      # Video and audio converter
        vlc           # Media player
	soundwireserver # Turn your Android device into wireless headphones / wireless speaker
        gscan2pdf     # Scan documents to PDF
        pdfsam-basic  # PDF manipulation
	poppler-utils
        libreoffice    # Office suite
        #marktext      # Markdown editor
	uget
	uget-integrator
        telegram-desktop # Messaging app

        # System Utilities
        tftp-hpa      # TFTP server
        netboot       # Network boot utilities
        gparted       # Partition editor
	ncdu
        samba         # File sharing service
        avahi         # mDNS/DNS-SD daemon
        ntfs3g       # NTFS filesystem driver
        veracrypt     # Disk encryption software
        zfs           # ZFS filesystem

        # Virtualization and Containers Virtual Machine Provisioning Tools
        wine64
#	kubectl
 #  #     k3d
#	kubevirt
  #      kubernetes
   #     kubernix
#        minikube
        libvirt           # Management tool for virtualization
        packer            # Tool for creating machine images
#        podman        # Container management
        # qemu          # Emulator and virtualizer
        vagrant       # Virtual machine management
        #kicad         # Electronic design automation #requires long ompilation
	logisim-evolution
        gns3-server    # Network simulation
        gns3-gui      # GNS3 graphical interface
        nginx

        # Networking Tools
        tor-browser    # Anonymous browsing
        tailscale      # Zero config VPN
        wireshark      # Network protocol analyzer
        teamviewer     # Remote desktop
	teams-for-linux
	zoom-us
	webex
	#rustdesk-server
	#rustdesk
        #filelight# not in 25.11
	x11vnc         # VNC server
        wlvncc
        #multivnc
        novnc
	openssl
        kasmweb		# VNC over web
        #guacamole-server #guac
        corosync       # Cluster communication
        # zed-editor      # Text editor
        vscode
        vscodium
	#tigervnc
 # 	novnc
#	python3Packages.websockify

        # Shell Enhancements
        direnv        # 
        #neovim        # Improved Vim editor
        fzf           # Command-line fuzzy finder
        zsh           # Shell
        powerline-fonts # Fonts for powerline
        autojump      # Directory jumping
        warp-terminal  # Terminal enhancements
        bat           # A cat clone with syntax highlighting
        delta         # Syntax highlighting pager for git
        fastfetch      # System information tool
        zoxide        # Smart directory switcher
        npins

        # Software Development (Android)
        android-studio # Android development IDE
        android-tools  # Tools for Android development
        waydroid       # Android in a container
	genymotion
	
        # Additional Tools
        helm          # Kubernetes package manager
        scilab-bin    # Scientific computing software
        vim           # Text editor
        screen        # Terminal multiplexer
        tmux          # Terminal multiplexer
        gedit         # Text editor
        fsearch       # File search utility
 #       unetbootin    # Live USB creator

        # TeX and Documentation
        texlive.combined.scheme-full # Full TeX Live distribution
        texworks      # LaTeX editor
        pandoc        # Document converter
  #      mendeley      # Reference manager
        
        # AI MODEL
	#lmstudio
	#opencode
#	opencode-desktop
	#codex
	pi-coding-agent
	dig
	llama-cpp
        
        
        
      ] ++ [
        # Python Packages
        python3Packages.pip
        python3Packages.django
        python3Packages.fastapi
        python3Packages.uvicorn
      ];
    };
	#Enable uget
	services.dbus.enable = true;
	services.dbus.packages = with pkgs; [ uget ];

    # Package Overrides Example
    nixpkgs.config.packageOverrides = pkgs: {
      xsaneGimp = pkgs.xsane.override { gimpSupport = true; };
    };

    # Enable Flatpak for additional applications
    services.flatpak.enable = true;
    # To add Flathub as a remote: 
    # flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  };
}

