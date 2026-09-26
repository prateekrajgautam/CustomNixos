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

## 30. Repository Audit (2026-09-25)

This section records the state found at the start of the 2026-09-25 audit. Section 36 records the fixes and successful builds completed afterward.

### Current build entry points

| Build | Configuration | Current behavior |
| --- | --- | --- |
| Minimal | `iso-minimal.nix` via `build-iso-minimal.sh` | Imports the NixOS graphical Calamares base and adds Cinnamon plus a small application set |
| Full | `iso-full.nix` via `build-iso-full.sh` | Imports the same graphical installer base and adds Cinnamon plus the large package modules |
| Common dispatcher | `build-iso.sh minimal\|full` | Implements naming, logging, direct store-result capture, safe copy and checksum generation for both wrappers |

Both named builds are intended to boot into a Cinnamon graphical live session. This has been demonstrated for at least one built ISO, but it is not yet protected by an automated boot test.

### Installer finding

The missing desktop installation shortcut was an expected result of the pre-fix configuration:

* The minimal image does not include Calamares.
* The full image adds the generic `calamares` package through `modules/systemPackagesforiso.nix`.
* Neither image imports NixOS's Calamares graphical installer integration.
* No repository-owned Calamares `settings.conf`, module configuration, branding, launch wrapper, desktop entry or autostart definition exists.
* The required Polkit `pkexec` wrapper and partition-manager integration are not enabled.

Adding the generic package is therefore insufficient. The implemented baseline now imports the NixOS 26.05 graphical Calamares module, which provides `calamares-nixos`, `calamares-nixos-extensions`, an autostart item, partition-manager integration, live-media Polkit authorization and all supported locales. The project layers its **Install Testing** launcher and desktop branding on top.

### Live-user permissions finding

The pre-fix live user placed `security.sudo.wheelNeedsPassword` incorrectly inside `users.users.nixos` and added `docker` even to Minimal. The corrected module defines the sudo policy at system level, enables graphical automatic login, and limits the shared live user to `networkmanager` and `wheel`; the Full Docker module adds `docker` only for Full. Evaluation and ISO construction pass, while runtime privilege behavior remains part of the VM test matrix.

The live-image permission baseline shall be:

* `nixos` is a normal live user and is automatically logged into the live desktop.
* `nixos` belongs to `wheel` and `networkmanager`.
* Passwordless sudo is enabled for `wheel` only in the live environment.
* Calamares elevation works through Polkit/`pkexec` without asking for an unknown password.
* GParted can be launched through the desktop and can acquire the privileges required to inspect or edit disks.
* The `docker` group is present only in editions where Docker is enabled and required.
* The installed system does not inherit the live user's passwordless-sudo policy or any fixed live/root password.

### GParted finding

GParted is already included in both named builds:

* Minimal: directly in `iso-minimal.nix`.
* Full: through `modules/systemPackagesforiso.nix`.

Package inclusion does not by itself prove that desktop launch and privilege elevation work. These remain release-test requirements.

### Pre-fix reproducibility and maintainability findings

* The build scripts request the moving `nixos-26.05` channel; there is no flake or lock file in this folder, so builds are not pinned.
* The former duplicate build scripts did not share one implementation. They now delegate to the common `build-iso.sh` dispatcher.
* The former scripts did not save logs or hashes. The common dispatcher now saves timestamped logs and SHA-256 files, while machine-readable release metadata remains pending.
* The full package list mixes live tools, installed-system packages and optional post-install packages, preventing a dependable offline closure boundary.
* Several advanced services and development packages are imported into the full live image even though they are not necessary for installation.
* There is no first-boot selector, persisted setup state, or package-selection manifest in the repository yet.

## 31. Product Editions for the Testing Customization Milestone

The initial customization milestone shall use the distribution name **Testing**. It is a temporary, replaceable brand used to validate the customization architecture.

### Shared behavior

Both editions shall:

1. Boot into a usable Cinnamon graphical live environment.
2. Allow the user to explore the live system without installing.
3. Show a clearly labelled **Install Testing** desktop shortcut and application-menu entry.
4. Include a working graphical partitioning path and GParted.
5. Install their defined base system with all network interfaces disconnected.
6. Boot the installed system into a graphical environment immediately after installation.
7. Use the same shared branding, live-user and installer modules.
8. Keep the live configuration separate from the target installed-system configuration.

### Testing Minimal

Testing Minimal is a small offline-installable graphical base. The ISO contains everything needed to install and boot the base desktop, but large and optional packages are deferred.

After the installed system boots, a **Testing Setup** application shall:

1. Explain that the base system is already usable.
2. Check network availability without blocking use of the desktop.
3. Ask whether the user wants to refresh the configuration/package definitions before applying them.
4. Display packages/features grouped by purpose with sensible defaults.
5. Let the user select or unselect optional packages before any changes are applied.
6. Show a summary of planned changes and require confirmation.
7. Apply the selected declarative configuration as a new NixOS generation.
8. Preserve the current working generation if download, evaluation or activation fails.
9. Save progress under `/var/lib/testing-setup/` and allow safe retry later.

The update question and package selection are distinct decisions. Declining the update must not silently prevent use of the locally shipped configuration when that configuration can be applied offline.

### Testing Full

Testing Full contains the selected full workstation package closure on the ISO and installs it without Internet. It shall still present the same live desktop, installer, branding and recovery behavior as Testing Minimal. Post-install setup may offer updates and profile changes, but the installed full profile must be usable before those optional online actions.

### Package classification

Every package or service must belong to exactly one initial class:

| Class | Minimal ISO | Full ISO | Installed offline | User-selectable after boot |
| --- | --- | --- | --- | --- |
| Live-only | Yes | Yes | No | No |
| Shared base | Yes | Yes | Yes | No |
| Full profile | No | Yes | Full only | Yes, where modular |
| Optional online | No | No unless explicitly cached | No | Yes |

The current `modules/systemPackagesforiso.nix` list must be split according to this table before the offline-install guarantee can be accepted.

## 32. Testing Brand and Theme Requirements

The customization proof shall demonstrate that identity is data-driven rather than scattered across ISO definitions.

Required replaceable inputs:

* Product name: `Testing`
* Edition: `Minimal` or `Full`
* Version and build identifier
* Primary and accent colors
* Desktop wallpaper
* Login-screen background
* Installer name, icon, slideshow and color treatment
* Boot-menu title and artwork where supported
* Welcome/setup application identity

The implemented source of truth for these identity values is `branding/branding.json`. It currently defines the product ID and name, tagline, wallpaper, logo, installer icon, primary and secondary colors, GTK theme and icon theme. Asset paths are relative to the `branding/` directory. Both edition definitions and shared live modules consume the same file.

For the first visual test, use one repository-owned wallpaper and one coherent Cinnamon/GTK color theme. The brand module shall expose these inputs to both editions, while edition-specific values are limited to the edition name and package/profile selection.

Brand assets must be stored in a dedicated `branding/` tree with license and source information. Theme application must be declarative and must work for the live user and newly created installed users.

## 33. Offline Installation Contract

An edition may be described as offline-installable only when all of the following pass with networking disabled before boot:

1. The ISO reaches the live graphical desktop.
2. **Install Testing** launches successfully from the desktop shortcut.
3. Automatic UEFI/GPT/ext4 installation completes on an empty virtual disk.
4. User, locale, keyboard and time-zone selections are reflected in the installed system.
5. Installation performs no required network fetch.
6. The installed bootloader starts.
7. The installed system reaches its graphical login or desktop.
8. The created user can perform intended administrative actions using the installed-system policy.
9. Minimal remains usable when Stage 2 is postponed or fails.
10. Full contains and launches the promised full-profile applications without a post-install download.

The build pipeline must test both UEFI and legacy BIOS boot where supported. UEFI is the release-blocking target for the first milestone.

## 34. First-Boot Package Selection Requirements

The selector is a configuration generator, not an imperative package installer. It shall write a user choice manifest consumed by Nix modules or a flake profile.

Initial selectable groups should include:

* Browsers
* Office and PDF tools
* Graphics and media
* Development languages and editors
* Containers and virtualization
* Networking and remote-access tools
* Printing and scanning
* Advanced storage tools

Dependencies and mutually exclusive choices must be enforced by the model. The user interface shall show approximate download size when it can be calculated, clearly mark packages requiring Internet, and offer **Select defaults**, **Select all**, and **Clear optional** actions.

Before activation the application shall show:

* Configuration source and revision
* Whether definitions were refreshed
* Selected profile and packages
* Packages requiring download
* Available disk space and estimated requirement
* The rollback behavior

No update or rebuild shall run automatically merely because the machine gained Internet access.

## 35. Acceptance Criteria for the Next Milestone

The next milestone is complete only when:

- [ ] Minimal and Full both boot to the branded Testing Cinnamon live desktop.
- [ ] Both have a visible, correctly named installer shortcut.
- [ ] Both use the NixOS-aware Calamares package and required extensions/configuration.
- [ ] Live-user sudo, Polkit, Calamares and GParted elevation are tested.
- [ ] Both complete the defined offline installation test.
- [ ] Both installed systems boot graphically without Internet.
- [ ] Minimal starts the first-boot setup flow without making changes automatically.
- [ ] The setup flow asks about definition updates and allows package selection/unselection.
- [ ] A failed or cancelled Stage 2 leaves a working system and can be retried.
- [ ] Testing name, wallpaper and color theme appear consistently in boot/live/installer/installed surfaces selected for this milestone.
- [ ] Builds are pinned through a lock file.
- [x] Builds produce a timestamped log and ISO SHA-256 file.
- [ ] Builds produce machine-readable release metadata.
- [ ] The full package inventory is classified as live-only, shared base, full-profile or optional-online.

Earlier `[x]` examples in the suggested MVP section describe desired deliverables, not verified repository status. Only this acceptance checklist records completion status for the current implementation.

## 36. Build Record (2026-09-25 UTC)

The updated Minimal and Full configurations both evaluated and built successfully in the existing Ubuntu WSL environment against the `nixos-26.05` channel.

| Edition | Result | ISO size | SHA-256 |
| --- | --- | ---: | --- |
| Testing Minimal | Build and checksum verification passed | 3,288,973,312 bytes | `0c2b51e963ee9035827715ae12f025833504ebb0d876646a4e0a1bc2aebbd5cc` |
| Testing Full | Build and checksum verification passed | 7,988,520,960 bytes | `383ed21d4830cb774664d190c5da5d9c07b59cdf2aff09735cd3463c1a35155e` |

Both artifacts were identified as bootable ISO 9660 images with DOS/MBR boot sectors. This build record does not mark the graphical boot or offline-install acceptance criteria complete; those require VM execution and installation tests.

Build-time defects corrected during this run:

* Replaced the generic Calamares package with the NixOS graphical Calamares integration.
* Added the installer desktop launcher and live-only elevation path.
* Corrected the misplaced sudo option and removed the irrelevant Docker group from Minimal.
* Corrected the Full Docker module's hard-coded, undefined user.
* Removed the Cloudflare host-secret dependency from the public Full live image.
* Replaced Windows-mounted Nix result symlinks with direct store-result capture.
* Added partial-copy handling, stable artifact names, timestamped logs and checksums.

Observed non-blocking issue:

* Full includes both VS Code and VSCodium, causing extensive system-path collision warnings. The build succeeds, but the future package-profile split must select one by default.

## 37. Configuration, Automation and Secret-Handling Update (2026-09-26)

### Automated dual build

`shell.nix` is the automation entry point. Entering `nix-shell` runs the Minimal build followed by the Full build using the common logged build scripts. `TESTING_SKIP_AUTO_BUILD=1 nix-shell` opens a maintenance shell without starting either build.

This automation does not replace release pinning. It currently follows the configured `nixos-26.05` channel, so a flake and lock file remain required for reproducible releases.

### Branding configuration contract

`branding/branding.json` is the editable branding contract. The following fields are implemented:

| Field | Consumer |
| --- | --- |
| `id` | Hostname prefix, release file path, ISO/log/checksum filename prefix and desktop launcher ID |
| `name` | Installer label and release identity |
| `tagline` | Release metadata and installer launcher description |
| `wallpaper` | Cinnamon live-desktop background |
| `logo` | Installed branding asset for later boot/installer surfaces |
| `installerIcon` | Installer desktop and menu entry |
| `primaryColor`, `secondaryColor` | Cinnamon background colors |
| `gtkTheme`, `iconTheme` | Cinnamon interface defaults |

Changing a branding value must not require editing either edition definition. JSON parsing and both ISO evaluations must pass before accepting a branding change.

### Cloudflare security contract

Cloudflare Tunnel is an opt-in installed-system service and must not be imported into public live media. The module shall never read a build-host token or interpolate a token into the Nix store or systemd command line.

The implemented service uses a runtime token path, defaulting to:

```text
/etc/testing/secrets/cloudflare-tunnel-token
```

The service uses `cloudflared tunnel run --token-file`. It starts only when the token file exists. The administrator must provision the file after installation with ownership readable by the `cloudflared` service account and restrictive permissions. Repository files contain placeholders only.

### Caddy security contract

Caddy is an opt-in installed-system service and is excluded from both live images. The repository's Caddy files are sanitized examples containing no real domains, public routes, private LAN/Tailscale addresses, tokens or credentials.

Production routing must be supplied by the installed-system configuration. Authentication material must remain in permission-restricted runtime secret files and must never be committed inside a Caddy configuration.

### ZFS safety contract

ZFS pool management is disabled by default. Enabling `testing.zfs` requires:

* A unique eight-hex-digit `testing.zfs.hostId` generated for the installed machine.
* An explicit, non-empty `testing.zfs.poolName`.
* A deliberate decision before enabling `testing.zfs.forceImportRoot`; its default is `false`.

The module imports only the explicitly named pool, enables scrub and trim for that pool, and does not use the former shared `89ABCDEF` host ID or assume a pool named `tank`.

### Verification status

The following evaluation checks passed after this update:

- [x] `shell.nix` evaluates.
- [x] `branding/branding.json` parses.
- [x] Minimal and Full ISO configurations evaluate with JSON-driven branding.
- [x] Cloudflare, Caddy and ZFS modules evaluate together with their opt-in features enabled and placeholder test values.
- [x] Sanitized configuration trees contain none of the removed real domains or private node addresses.
- [ ] Minimal and Full artifacts have been rebuilt after this update.
- [ ] Runtime Cloudflare, Caddy and ZFS behavior has been tested on an installed system.



# Cache tar archieve for reuse
- warning: Nix search path entry 'channel:nixos-26.05' does not exist, ignoring
- unpacking 'https://nixos.org/channels/nixos-26.05/nixexprs.tar.xz' into the Git cache...
- warning: error: unable to download 'https://nixos.org/channels/nixos-26.05/nixexprs.tar.xz': SSL connect error (35) TLS connect error: error:00000000:lib(0)::reason(0); retrying in 279 ms