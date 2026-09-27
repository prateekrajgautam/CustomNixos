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
        # Calamares is provided by the NixOS graphical installer module.
        chromium
	brave
        firefox-devedition
	copyq
	sqlitebrowser
        # DevOps & Development Tools
        git           # Version control system
	git-lfs
        gccgo13       # Go compiler
        nodejs        # JavaScript runtime
        python3   # Python 3 interpreter
	go
	rustup
        pipenv        # Python dependency management
       
        # Graphics and Multimedia
        gimp          # Image editor
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
        #gscan2pdf     # Scan documents to PDF
        pdfsam-basic  # PDF manipulation
	poppler-utils
        libreoffice    # Office suite
        #marktext      # Markdown editor
	uget
	uget-integrator
        telegram-desktop # Messaging app

        # System Utilities
        tftp-hpa      # TFTP server
        #netboot       # Network boot utilities
        gparted       # Partition editor
	ncdu
        samba         # File sharing service
        avahi         # mDNS/DNS-SD daemon
        ntfs3g       # NTFS filesystem driver
        zfs           # ZFS filesystem

        # Virtualization and Containers Virtual Machine Provisioning Tools
        wine64
        libvirt           # Management tool for virtualization
        logisim-evolution
        
        # Networking Tools
        tor-browser    # Anonymous browsing
        tailscale      # Zero config VPN
        wireshark      # Network protocol analyzer
	#teams-for-linux
	#zoom-us
	#webex
	x11vnc         # VNC server
        wlvncc
	openssl
        vscode
	# Keep one VS Code implementation. Installing vscode and vscodium together
	# creates extensive file collisions in the live system profile.
	
        # Shell Enhancements
        direnv        # 
        fzf           # Command-line fuzzy finder
        zsh           # Shell
        powerline-fonts # Fonts for powerline
        autojump      # Directory jumping
        bat           # A cat clone with syntax highlighting
        delta         # Syntax highlighting pager for git
        fastfetch      # System information tool
        zoxide        # Smart directory switcher
        
        # Software Development (Android)
        #android-studio # Android development IDE
        #android-tools  # Tools for Android development
        #waydroid       # Android in a container
	#genymotion
	
        # Additional Tools
        helm          # Kubernetes package manager
        #scilab-bin    # Scientific computing software
        vim           # Text editor
        #screen        # Terminal multiplexer
        tmux          # Terminal multiplexer
        gedit         # Text editor
        fsearch       # File search utility
 #       unetbootin    # Live USB creator

        # TeX and Documentation
        #texlive.combined.scheme-full # Full TeX Live distribution
        #texworks      # LaTeX editor
        #pandoc        # Document converter
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
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-xapp
        xdg-desktop-portal-gtk
      ];
      configPackages = [ pkgs.cinnamon ];
    };
    # To add Flathub as a remote: 
    # flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  };
}
