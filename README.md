# Fedora on the Dell Chromebook 3110 2-in-1

<div align="center">
  <img src="https://img.shields.io/badge/Status-Boot-path-proven-2ea44f?style=for-the-badge" alt="status" />
  <img src="https://img.shields.io/badge/Platform-Chromebook%20x86__64-1f6feb?style=for-the-badge" alt="platform" />
  <img src="https://img.shields.io/badge/Target-Fedora%20XFCE-4a6fff?style=for-the-badge" alt="target" />
  <img src="https://img.shields.io/badge/License-GPLv3-blue?style=for-the-badge" alt="license" />
</div>

A no-USB Fedora install journal for a Dell Chromebook 3110 2-in-1 (Cret360 / Intel Jasper Lake N4500).

This repo documents the path from a locked ChromeOS boot process to a working UEFI + GRUB path, the failed ISO boot, and the exact next step required to finish the install: a valid Fedora Xfce x86_64 Live ISO copied onto a writable path.

> This is a practical recovery log, not a generic app template. It is designed to be readable, copy/paste friendly, and honest about what worked and what failed.

## Highlights

- developer mode + VT2 access
- MrChromebox UEFI conversion
- internal EFI boot path created on the stateful partition
- GRUB loopback boot from a local ISO
- full boot path reached, but blocked by a bad or incomplete ISO image

## Hardware

- Model: Dell Chromebook 3110 2-in-1
- Board: Cret360
- CPU: Intel Jasper Lake N4500
- Architecture: x86_64
- Target OS: Fedora Xfce (Live ISO)

## Why this exists

The device does not behave like a normal laptop. ChromeOS is tightly controlled, the stock boot path is locked down, and the install required a custom internal EFI boot flow.

The important part is that we did reach the hard part successfully:

- UEFI firmware was switched to full ROM / UEFI mode
- GRUB was successfully loaded from the internal EFI directory
- the ISO path was visible on the internal disk

The remaining blocker is the bad or incomplete `fedora.iso` file itself.

## Current status

Status: boot path reached, installer media still invalid.

At this point the machine is not “bricked” in the usual sense. It is in a UEFI + GRUB staging state. The remaining issue is not firmware anymore — it is the Fedora install media.

## Official Fedora Xfce ISO

Use the official x86_64 Live ISO from Fedora Spins:

- https://spins.fedoraproject.org/xfce/download/index.html

Recommended file:

```text
Fedora-Xfce-Live-x86_64-44.iso
```

Expected SHA256:

```text
55ea8cb52ac16e62f436e37f9fdb4e978d7b9f75814a9d42e8b69d05e3b496ad
```

## Verify the download on Windows

```powershell
Get-FileHash "C:\path\to\Fedora-Xfce-Live-x86_64-44.iso" -Algorithm SHA256
```

If the hash matches, the file is valid.

## Quick start

### 1) Enable dev mode and root shell

```bash
sudo chromeos-setdevpasswd
```

### 2) Put the ISO on the internal stateful partition

```bash
path=$(sudo find /home /mnt/stateful_partition -maxdepth 6 -type f -iname 'fedora*.iso' -print -quit)
echo "found: $path"
sudo cp -v "$path" /mnt/stateful_partition/fedora.iso && sudo sync
sudo ls -lh /mnt/stateful_partition/fedora.iso
sudo sha256sum /mnt/stateful_partition/fedora.iso
```

### 3) Install the UEFI firmware path

```bash
sudo bash -lc 'curl -L https://mrchromebox.tech/firmware-util.sh -o /tmp/firmware-util.sh && bash /tmp/firmware-util.sh'
```

Then select:

```text
2) Install/Update UEFI (Full ROM) Firmware
```

### 4) Boot the ISO via GRUB

```text
set root=(hd0,gpt1)
loopback loop /fedora.iso
ls (loop)/
ls (loop)/images/pxeboot
linuxefi (loop)/images/pxeboot/vmlinuz iso-scan/filename=/fedora.iso rd.live.image quiet
initrdefi (loop)/images/pxeboot/initramfs.img
boot
```

### 5) If the ISO is valid, install Fedora

- choose `Install to Hard Drive`
- choose `Automatic`
- finish installation

## Important GRUB config

This is the config to use when the ISO is known-good:

```text
set default=0
set timeout=5

menuentry "Boot Fedora Live ISO" {
    search --file --no-floppy --set=root /fedora.iso
    loopback loop /fedora.iso
    linuxefi (loop)/images/pxeboot/vmlinuz iso-scan/filename=/fedora.iso rd.live.image quiet
    initrdefi (loop)/images/pxeboot/initramfs.img
}
```

Place this in:

```text
/mnt/stateful_partition/EFI/BOOT/grub.cfg
```

## The exact failure we hit

This is the final blocker we saw:

```text
error: .../grub-core/fs/fat.c:grub_fsys_find_file:257: file '/images/pxeboot' not found
```

and

```text
error: .../grub-core/fs/fat.c:grub_fsys_find_file:257: file '/images/pxeboot' not found.
```

That means the file on disk was not a valid Fedora Live ISO or was incomplete/corrupt. The machine was in the right boot stage; the install media was not.

## Files in this repo

- `README.md` — landing page and commands
- `docs/boot-journey.md` — timeline of the investigation
- `downloads/README.md` — where to keep the ISO
- `scripts/Verify-FedoraISO.ps1` — Windows SHA256 checker

## Recommended next step

The install can continue only once a valid Fedora Xfce x86_64 Live ISO is present on a writable path, usually via:

- a USB flash drive
- a working data cable with USB debugging / ADB support
- or a real network transfer path

Once valid media is on the device, the boot path above is the path to finish the installation.

## Project direction

This repo is intentionally a field log and a recovery playbook. It is meant to be copied, forked, and extended by anyone trying the same path on a similar Chromebook model.

## License

This project is licensed under the GNU General Public License v3.0.

See the [LICENSE](LICENSE) file for the full text.
