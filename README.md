# Linux Transfer Progress W/ No External Drives

<div align="center">
  <img src="https://img.shields.io/badge/Status-UEFI%20%2B%20GRUB-2ea44f?style=for-the-badge" alt="status" />
  <img src="https://img.shields.io/badge/Platform-Dell%20Chromebook%203110-1f6feb?style=for-the-badge" alt="platform" />
  <img src="https://img.shields.io/badge/Target-Fedora%20XFCE-4a6fff?style=for-the-badge" alt="target" />
  <img src="https://img.shields.io/badge/License-GPLv3-blue?style=for-the-badge" alt="license" />
</div>

A field log, boot journal, and recovery playbook for trying to move Linux onto a Chromebook without external storage.

This project documents the real-world path taken on a Dell Chromebook 3110 2-in-1: developer mode, UEFI firmware conversion, internal EFI boot setup, GRUB loopback experiments, and the point where the install stalled because the ISO itself was not valid.

> The focus is simple: transfer Linux without USB, keep the flow transparent, and archive the exact moves that worked and the ones that failed.

## What this repo is

This is not a polished installer script. It is a boot-and-transfer log for a very specific Chromebook path:

- ChromeOS developer mode
- MrChromebox firmware conversion
- internal stateful partition as a staging area
- GRUB booting from a loopback ISO file
- final blocker: invalid or incomplete Fedora installer media

## Device summary

- Model: Dell Chromebook 3110 2-in-1
- Board: Cret360
- CPU: Intel Jasper Lake N4500
- Architecture: x86_64
- Target: Fedora Xfce Live ISO

## Status

Current state: firmware is working and GRUB can reach the internal disk, but the valid Linux installer media is still missing.

This is the honest summary:

- UEFI boot path was proven
- internal EFI boot files were created
- GRUB successfully reached the stage where it could inspect the internal drive
- the install failed because the ISO currently on disk was not a valid Fedora image

## Why no external drives

The original goal was to avoid a USB drive entirely and still get Fedora installed. The practical issue is that a Chromebook running UEFI + GRUB still needs a valid Linux image on a writable path. Without a real transfer method, the install media cannot be refreshed.

That is the blocker now.

## What succeeded

- Developer mode was enabled
- shell access was gained
- the internal stateful partition was identified and used as the staging area
- the UEFI firmware path was switched from stock ChromeOS boot to a full UEFI form
- GRUB could see the internal EFI location and the mounted stateful partition

## What failed

- the ISO on disk was bad, incomplete, or not the correct Fedora image
- GRUB could see the file but not the expected Fedora boot tree
- the boot stopped before the kernel loaded

The exact failure we hit looked like this:

```text
error: .../grub-core/fs/fat.c:grub_fsys_find_file:257: file '/images/pxeboot' not found
```

That is not a firmware failure. It is a media failure.

## Official Fedora Xfce ISO

Use the official x86_64 ISO from Fedora Spins:

- https://spins.fedoraproject.org/xfce/download/index.html

Recommended file:

```text
Fedora-Xfce-Live-x86_64-44.iso
```

Expected SHA256:

```text
55ea8cb52ac16e62f436e37f9fdb4e978d7b9f75814a9d42e8b69d05e3b496ad
```

## Verify the ISO on Windows

```powershell
Get-FileHash "C:\path\to\Fedora-Xfce-Live-x86_64-44.iso" -Algorithm SHA256
```

## Command block library

### 1) Chrome OS shell: find the ISO

```bash
sudo find /home /mnt/stateful_partition -maxdepth 6 -type f -iname 'fedora*.iso' 2>/dev/null | sed -n '1,50p'
```

### 2) Copy ISO to the stateful partition

```bash
path=$(sudo find /home /mnt/stateful_partition -maxdepth 6 -type f -iname 'fedora*.iso' -print -quit)
echo "found: $path"
sudo cp -v "$path" /mnt/stateful_partition/fedora.iso && sudo sync
sudo ls -lh /mnt/stateful_partition/fedora.iso
sudo sha256sum /mnt/stateful_partition/fedora.iso
```

### 3) Mount the ISO for inspection

```bash
sudo mkdir -p /mnt/iso
sudo mount -o loop /mnt/stateful_partition/fedora.iso /mnt/iso
sudo ls -la /mnt/iso
```

### 4) Firmware conversion step

```bash
sudo bash -lc 'curl -L https://mrchromebox.tech/firmware-util.sh -o /tmp/firmware-util.sh && bash /tmp/firmware-util.sh'
```

Then choose:

```text
2) Install/Update UEFI (Full ROM) Firmware
```

### 5) GRUB loopback boot from the internal disk

```text
set root=(hd0,gpt1)
loopback loop /fedora.iso
ls (loop)/
ls (loop)/images/pxeboot
linuxefi (loop)/images/pxeboot/vmlinuz iso-scan/filename=/fedora.iso rd.live.image quiet
initrdefi (loop)/images/pxeboot/initramfs.img
boot
```

### 6) UEFI shell map test

```text
map -r
fs0:
ls
```

## Working GRUB config

When the ISO is valid, the correct config is:

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

Place it at:

```text
/mnt/stateful_partition/EFI/BOOT/grub.cfg
```

## What happens next

The process still requires a valid ISO on a writable path. At this point, the remaining path is not more firmware tweaking; it is a clean transfer of a valid Fedora Xfce ISO.

The practical options are:

- a USB flash drive
- a real data cable that exposes the device as a mass-storage device
- USB debugging / ADB path if the device enumerates properly
- a network transfer path from a laptop

Without one of those, the install cannot continue.

## Repo layout

```text
.
├── README.md
├── LICENSE
├── docs/
│   └── boot-journey.md
├── downloads/
│   └── README.md
├── scripts/
│   └── Verify-FedoraISO.ps1
└── .gitignore
```

## License

This project is licensed under the GNU General Public License v3.0.

See [LICENSE](LICENSE) for the full text.
