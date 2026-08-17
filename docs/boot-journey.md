# Boot journey log

This file is the narrative record of the Chromebook recovery path.

## Initial goal

Replace ChromeOS with Fedora XFCE on a Dell Chromebook 3110 2-in-1 without using an external USB drive.

## Decision path

1. The project started by exploring whether ChromeOS could be heavily customized.
2. A direct ChromeOS customization path was ruled out as too restricted and not practical.
3. A full Chromium rebuild was also rejected as too heavy and unnecessary.
4. The project switched to a full Fedora install route on a developer-mode Chromebook.

## Developer mode and shell access

The device was put into Developer Mode.

Important commands used:

```bash
sudo chromeos-setdevpasswd
```

This enabled a usable root/admin shell in the dev environment.

## Internal stateful partition

We discovered the device had enough free space in the internal stateful area and used it as the staging area:

```bash
sudo lsblk
sudo df -h
sudo mount
```

The internal stateful partition was used to hold:

- the Fedora ISO
- EFI boot files
- GRUB config

## ISO placement

The ISO was copied into the stateful partition:

```bash
sudo cp -v "$path" /mnt/stateful_partition/fedora.iso
sudo ls -lh /mnt/stateful_partition/fedora.iso
sudo sha256sum /mnt/stateful_partition/fedora.iso
```

## Firmware update

The firmware had to be changed to allow UEFI boot. The key command used:

```bash
sudo bash -lc 'curl -L https://mrchromebox.tech/firmware-util.sh -o /tmp/firmware-util.sh && bash /tmp/firmware-util.sh'
```

Then the menu choice was:

```text
2) Install/Update UEFI (Full ROM) Firmware
```

## EFI boot path

GRUB and rEFInd were copied into the internal EFI boot location and used to boot the ISO.

Example files on the internal stateful partition:

```text
/mnt/stateful_partition/EFI/BOOT/grub.cfg
/mnt/stateful_partition/EFI/BOOT/grubx64.efi
/mnt/stateful_partition/EFI/BOOT/BOOTX64.EFI
```

## GRUB loopback boot

The working conceptual path was:

```text
set root=(hd0,gpt1)
loopback loop /fedora.iso
linuxefi (loop)/images/pxeboot/vmlinuz iso-scan/filename=/fedora.iso rd.live.image quiet
initrdefi (loop)/images/pxeboot/initramfs.img
boot
```

## Where it stopped

The live ISO was found by GRUB, but not all the expected Fedora boot files were found. The failure was:

```text
error: .../grub-core/fs/fat.c:grub_fsys_find_file:257: file '/images/pxeboot' not found
```

This indicates the `fedora.iso` on disk was not a valid Fedora Live ISO image, or it was changed, incomplete, or not the correct x86_64 file.

## Root cause

The firmware and boot path were successfully fixed, but the install media was wrong. The final blocker was not ChromeOS; it was invalid install media.

## Safe path forward

The next safe step is:

1. download a fresh Fedora Xfce x86_64 Live ISO
2. verify its SHA256
3. transfer it by a real storage path
4. replace the broken ISO
5. boot the fresh ISO again

## Key lesson

This project is a valid example of a no-USB Chromebook install path that reaches the hard part successfully, but it cannot be completed without valid installer media on a writable path.
