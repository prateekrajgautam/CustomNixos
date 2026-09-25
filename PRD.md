# PRD: Custom NixOS-Based Distribution

## 1. Product Overview

### Working concept

Build a custom Linux distribution based on NixOS with:

1. A **small, bootable Live ISO**.
2. A complete **GUI live environment** that works without Internet.
3. A **Try Before Install** experience.
4. A graphical installer launched from the live desktop.
5. **Offline base installation** with no network dependency.
6. A usable GUI system immediately after the first reboot.
7. Automatic or user-triggered **second-stage `nixos-rebuild`** after Internet becomes available.
8. Custom branding across boot, installer, desktop and system.
9. Modular NixOS configuration that defines the final distribution.
10. Optional applications and advanced configuration installed after networking is available.

The central architectural principle is:

> **The ISO is a Live/Installer environment, not the complete distribution. The NixOS flake is the source of truth for the installed distribution.**

## 2. Product Goals

### Primary goals

| Goal                 | Requirement                                                               |
| -------------------- | ------------------------------------------------------------------------- |
| Offline installation | Installation must not require Internet                                    |
| Live environment     | User can boot and use the GUI without installing                          |
| Try before install   | Desktop, networking and basic hardware should be testable                 |
| GUI installation     | No terminal required for normal installation                              |
| Small ISO            | Avoid shipping the entire software catalog                                |
| Nix-native           | Final system should be declaratively defined                              |
| Custom identity      | Boot, login, desktop and applications should carry distro branding        |
| Recoverability       | Failed configuration/update should be recoverable through Nix generations |
| Extensibility        | Modules and profiles should allow future features                         |
| Reproducibility      | Releases should be pinned through `flake.lock`                            |
| Online optionality   | Internet is needed only for post-install expansion/update                 |

### Non-goals for the first release

Avoid making v1 unnecessarily large.

Do not initially target:

* Every possible desktop environment
* Multiple architectures
* Custom package repository
* Custom binary cache
* Custom kernel
* Custom package manager
* Full graphical package manager
* Cloud synchronization
* Proprietary hardware support for everything
* A completely independent installer framework

These can come later.

## 3. User Journey

The ideal user experience should be:

```text
Download ISO
    |
    v
Create USB
    |
    v
Boot USB
    |
    v
Live Desktop
    |
    +----------------------+
    |                      |
    v                      v
Try MyDistro           Install MyDistro
    |                      |
    |                      v
    |                Graphical Installer
    |                      |
    |                      v
    |                Offline Installation
    |                      |
    |                      v
    |                   Reboot
    |                      |
    |                      v
    |                Installed GUI
    |                      |
    |                 Internet available?
    |                    /        \
    |                  No          Yes
    |                  |            |
    |                  v            v
    |              Basic       nixos-rebuild
    |              system          |
    |                               v
    |                        Complete System
    |
    v
Continue using Live Mode
```

## 4. Live ISO Requirements

The ISO should boot directly into a graphical desktop.

Example:

```text
             MyDistro Live

       ┌─────────────────────────┐
       │                         │
       │       MyDistro          │
       │                         │
       │   Try without install   │
       │                         │
       │   [ Install MyDistro ]  │
       │                         │
       └─────────────────────────┘
```

The desktop should contain:

* File manager
* Terminal
* Browser if feasible
* Network settings
* System settings
* Hardware information
* Installer launcher
* Documentation
* Basic troubleshooting utilities

The live environment should not require an account.

## 5. Live Mode Must Be Useful Without Internet

This is important because the user's primary requirement is avoiding network-dependent installation.

The following should work offline:

* Boot
* Desktop
* Keyboard
* Mouse/touchpad
* Display
* File manager
* Terminal
* Installer
* Disk detection
* Partitioning
* Basic hardware detection
* Basic system information
* Screenshots
* Local documentation

Networking can be available but should not be a prerequisite.

## 6. Try Before Install

The live system should explicitly communicate:

> You are currently running MyDistro from the USB. Changes made here will not normally persist after reboot.

A small welcome application could provide:

```text
Welcome to MyDistro

You are running the Live environment.

Test your hardware:
[ Display ]
[ Audio ]
[ Wi-Fi ]
[ Bluetooth ]
[ Keyboard ]
[ Touchpad ]

Ready to install?

[ Install MyDistro ]
```

This is especially useful for checking whether the user's hardware is supported before touching the disk.

## 7. Graphical Installer

The installer should be available directly from the desktop.

### Installation stages

```text
1. Welcome
2. Language
3. Keyboard
4. Time zone
5. Network - optional
6. Disk selection
7. Partitioning
8. Encryption
9. User account
10. Installation profile
11. Summary
12. Install
13. Reboot
```

### Network step

The installer should explicitly say:

```text
Internet connection

Internet is optional for installation.

Your base system can be installed completely offline.

You can configure Internet after the first reboot
to install additional software and updates.
```

This should be a major product characteristic.

## 8. Disk Installation

Support at least two modes.

### Automatic

```text
Use entire disk
[ ] Encrypt disk
[ ] Create swap
```

### Manual

For advanced users:

```text
EFI
/
swap
/home
```

Initially, supporting:

* UEFI
* GPT
* ext4

would keep the installer manageable.

Btrfs, LVM and ZFS can be added later.

## 9. Offline Installation Architecture

The ISO contains:

```text
Live environment
+
Installer
+
Base system closure
+
Distribution configuration
```

Conceptually:

```text
ISO
├── Live desktop
├── Installer
├── Nix
├── Base NixOS closure
└── /etc/nixos
    ├── flake.nix
    ├── flake.lock
    └── modules
```

The installer generates hardware-specific configuration and installs the base system from the local Nix store.

The critical requirement is:

> `nixos-install` must not need to download anything during the base installation.

## 10. What Is the Base System?

Define this explicitly in the PRD.

For example:

```text
Base
├── Kernel
├── Firmware
├── systemd
├── Nix
├── NetworkManager
├── KDE Plasma
├── Display manager
├── Terminal
├── File manager
├── Basic utilities
├── Fonts
├── MyDistro branding
└── First-boot configuration
```

Anything beyond this is potentially Stage 2.

## 11. First Boot

The first boot should produce a **complete enough system that the user doesn't feel the installation failed**.

Example:

```text
First Boot
    |
    v
Login
    |
    v
Desktop
    |
    v
MyDistro Welcome
    |
    +-- Offline
    |      |
    |      v
    |   Continue using base system
    |
    +-- Online
           |
           v
     Apply full configuration
```

## 12. Stage 2 Configuration

The second stage should apply the complete distro configuration.

For example:

```text
Stage 1
├── KDE
├── NetworkManager
├── Basic utilities
└── Branding

Stage 2
├── Firefox configuration
├── Additional applications
├── Developer tools
├── Docker
├── Services
├── Custom packages
├── Additional themes
└── User preferences
```

The configuration should be performed using:

```bash
nixos-rebuild switch --flake /etc/nixos#mydistro
```

rather than a collection of imperative installation scripts.

## 13. Network Failure Handling

This is a critical requirement.

If Internet is unavailable after the first boot:

```text
MyDistro
    |
    v
Network unavailable
    |
    v
Do not break the system
    |
    v
Continue with Base System
```

The user should be able to manually retry later:

```bash
mydistro setup
```

or through a GUI:

```text
MyDistro Setup

Internet connection required for additional configuration.

Status: Offline

[Retry]
```

Never leave the system half-configured because a Wi-Fi connection failed.

## 14. Distribution Configuration Architecture

The flake should be the central source of truth.

```text
mydistro/
├── flake.nix
├── flake.lock
├── hosts/
├── modules/
├── profiles/
├── packages/
├── branding/
├── installer/
├── iso/
└── docs/
```

### Modules

```text
modules/
├── boot.nix
├── branding.nix
├── desktop.nix
├── networking.nix
├── audio.nix
├── fonts.nix
├── browser.nix
├── security.nix
├── applications.nix
├── developer.nix
└── firstboot.nix
```

### Profiles

```text
profiles/
├── base.nix
├── desktop.nix
├── developer.nix
├── workstation.nix
└── server.nix
```

This lets you build different editions later without duplicating the entire configuration.

## 15. Branding System

Branding should be a dedicated subsystem.

```text
branding/
├── logo.svg
├── logo.png
├── wallpapers/
├── icons/
├── sounds/
├── plymouth/
├── boot/
└── login/
```

### Branding targets

| Area                | Customization             |
| ------------------- | ------------------------- |
| ISO                 | Name and artwork          |
| Bootloader          | Logo/background           |
| Plymouth            | Boot animation            |
| Login manager       | Background/theme          |
| Desktop             | Wallpaper                 |
| Desktop theme       | Colors/style              |
| Icons               | Custom icon set           |
| Terminal            | Prompt/theme              |
| Browser             | Homepage/bookmarks        |
| Welcome application | Branding                  |
| About dialog        | Distribution information  |
| System information  | Distribution name/version |
| Documentation       | Branding                  |

## 16. Common NixOS Module API

Create a namespace such as:

```nix
mydistro = {
  branding.enable = true;

  desktop.enable = true;

  browser.enable = true;

  developer.enable = false;

  firstboot.enable = true;
};
```

This is preferable to exposing dozens of unrelated configuration fragments.

Example:

```nix
{
  mydistro.desktop = {
    enable = true;
    environment = "kde";
  };

  mydistro.branding = {
    enable = true;
    name = "MyDistro";
  };
}
```

## 17. ISO and Installed System Must Share Modules Carefully

There should be a distinction between:

```text
ISO configuration
```

and:

```text
Installed distribution configuration
```

For example:

```text
modules/
├── common/
│   ├── branding.nix
│   └── networking.nix
│
├── distro/
│   ├── desktop.nix
│   ├── applications.nix
│   └── developer.nix
│
└── iso/
    ├── live-desktop.nix
    └── installer.nix
```

The live ISO should not accidentally inherit the entire final workstation configuration.

## 18. Package Strategy

Classify packages into three categories.

### A. ISO-required

Must work offline:

```text
Installer
Partitioner
Desktop
NetworkManager
Terminal
File manager
Hardware tools
```

### B. Base-installed

Installed onto every target system:

```text
Browser
Git
Basic utilities
Your CLI
Your branding
```

### C. Optional

Downloaded after Internet is available:

```text
Docker
Kubernetes
VS Code
Development SDKs
AI tools
Large applications
```

This classification directly controls ISO size.

## 19. Hardware Support

The live environment should allow hardware testing before installation.

Test:

```text
CPU
RAM
GPU
Display
Wi-Fi
Ethernet
Bluetooth
Audio
USB
Storage
Keyboard
Touchpad
```

The installer should generate:

```text
/etc/nixos/hardware-configuration.nix
```

for the target system.

## 20. Recovery

Because this is NixOS, make generations visible to users.

The system should support:

```text
Current Generation
Previous Generation
Recovery
```

If Stage 2 fails:

```text
Stage 2 failed
    |
    v
Keep previous generation
    |
    v
Boot working system
```

Do not replace the working system with a partially successful configuration.

## 21. First-Boot State Machine

I would explicitly design the first-boot process as a state machine:

```text
                Installed
                    |
                    v
              First Boot
                    |
          +---------+---------+
          |                   |
       Offline              Online
          |                   |
          v                   v
      Base Ready        Apply Stage 2
          |                   |
          |             +-----+-----+
          |             |           |
          |          Success      Failure
          |             |           |
          |             v           v
          |          Complete    Retry Later
          |                         |
          +-------------------------+
```

Persist the state somewhere such as:

```text
/var/lib/mydistro/
```

For example:

```text
/var/lib/mydistro/
├── installation-complete
├── firstboot-complete
└── configuration-version
```

## 22. Update Model

Eventually:

```text
MyDistro Release
        |
        v
Git repository
        |
        v
flake.lock
        |
        v
CI build
        |
        +---- ISO
        |
        +---- Packages
        |
        +---- Binary cache
```

Users then receive updates through normal NixOS mechanisms.

Do not create a completely separate update mechanism until there is a concrete need.

## 23. ISO Size Budget

Make ISO size an explicit product requirement.

For example, establish targets such as:

```text
Target:
    < 2 GB      ideal
    < 3 GB      acceptable
    > 4 GB      investigate
```

The actual number should be decided after selecting the desktop environment and hardware support.

Track:

```text
Live desktop
+ firmware
+ kernel
+ installer
+ base Nix closure
+ branding
= ISO size
```

Every large package added to the base should have a reason.

## 24. Offline Test Matrix

This should be part of every release test.

### Test A: Completely disconnected

```text
Wi-Fi: OFF
Ethernet: disconnected
```

Verify:

* ISO boots
* Desktop starts
* Hardware detection works
* Installer launches
* Disk installation works
* Bootloader works
* Installed system boots
* GUI works

### Test B: Network unavailable after installation

Verify:

* First boot works
* Stage 2 does not break the system
* User can continue using base system
* Retry is possible

### Test C: Network available

Verify:

* Stage 2 completes
* Optional packages install
* Configuration is applied
* Reboot preserves configuration

## 25. Release Types

I would eventually define:

```text
MyDistro
│
├── Live ISO
│   └── Offline installation
│
├── Stable
│   └── Recommended release
│
├── Testing
│   └── New Nixpkgs/configuration
│
└── Development
    └── Latest configuration
```

For v1, only **Stable** is necessary.

## 26. Security and Trust

The ISO should provide:

```text
SHA256SUMS
Release signature
Version
Build date
Nixpkgs revision
Git revision
```

The user should be able to determine exactly what they installed.

Your release metadata could display:

```text
MyDistro 1.0

NixOS:       26.05
Nixpkgs:     <revision>
Kernel:      <version>
Git revision: <revision>
Build date:  <date>
```

## 27. Licensing

Before public distribution, audit:

* NixOS/Nix licenses
* Nixpkgs package licenses
* Fonts
* Wallpapers
* Icons
* Sound effects
* Themes
* Browser branding
* Firmware
* Proprietary drivers
* Third-party applications

Keep a:

```text
LICENSES/
```

directory in the project and ideally provide an installed license viewer.

## 28. Suggested MVP

Don't implement everything at once.

### MVP 1: Custom Live ISO

Deliver:

```text
[x] NixOS base
[x] GUI live environment
[x] Custom wallpaper
[x] Custom boot branding
[x] Terminal
[x] NetworkManager
[x] Installer launcher
```

### MVP 2: Offline installer

Add:

```text
[x] Graphical disk selection
[x] Automatic partitioning
[x] User creation
[x] Hardware configuration
[x] Offline installation
[x] First reboot
```

### MVP 3: Two-stage system

Add:

```text
[x] Minimal offline base
[x] /etc/nixos/flake.nix
[x] First-boot detection
[x] Internet detection
[x] nixos-rebuild
[x] Retry mechanism
```

### MVP 4: Distribution identity

Add:

```text
[x] Logo
[x] Plymouth
[x] Bootloader branding
[x] Login branding
[x] Desktop theme
[x] Icons
[x] Wallpapers
[x] Custom sounds
[x] About dialog
```

### MVP 5: Distribution modules

Add:

```text
[x] branding
[x] desktop
[x] browser
[x] applications
[x] developer
[x] security
[x] networking
```

### MVP 6: Release engineering

Add:

```text
[x] Git repository
[x] flake.lock
[x] Automated ISO build
[x] SHA256
[x] Release metadata
[x] VM testing
[x] Hardware testing
```

## 29. Final Product Architecture

The complete architecture can be summarized as:

```text
                              MyDistro
                                 |
                +----------------+----------------+
                |                                 |
                v                                 v
          Live ISO                              Flake
                |                                 |
       +--------+--------+             +----------+----------+
       |                 |             |                     |
       v                 v             v                     v
    Live GUI        Installer      Common Modules        Profiles
       |                 |             |                     |
       |                 v             |              +------+------+
       |           Offline Install     |              |             |
       |                 |             v              v             v
       |                 |          Branding       Desktop      Developer
       |                 |             |              |             |
       +-----------------+-------------+--------------+-------------+
                         |
                         v
                  First Boot System
                         |
                  Network available?
                    /           \
                  No             Yes
                  |               |
                  v               v
              Base GUI      nixos-rebuild
                                  |
                                  v
                         Complete MyDistro
```

### The key product decision

Your distro should effectively have **three experiences**:

1. **Live Mode** — "Try MyDistro without installing."
2. **Base Installed Mode** — "I can install and use it completely offline."
3. **Complete Mode** — "Once Internet is available, MyDistro configures itself into the full intended environment."

That is a strong foundation for a NixOS-based distribution. The most important engineering task before implementing branding or additional packages is to define the **Stage 1 closure and Stage 2 module boundary** precisely. Once those are stable, the ISO, installer, branding and post-install configuration can all be built around the same flake.
