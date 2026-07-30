# Converting kdev's root to LUKS

`kdev.yaml` builds an unencrypted guest. This converts its root partition to
LUKS in place, so the root filesystem inside `~/.lima/kdev/disk` is ciphertext:
a process that copies the image **while the VM is stopped** cannot read the data
without the passphrase. That is a narrower guarantee than it sounds — read the
caveats, in particular that it buys nothing while the VM is running.

The passphrase is typed into the guest and never reaches the host, which is why
these steps are manual rather than part of provisioning.

`/boot` and the ESP stay plaintext (GRUB has to read the kernel and initramfs);
everything else, including `/nix`, `$HOME` and the journal, ends up encrypted.

## Why a second VM

The root cannot be reencrypted while mounted, so the disk is attached to a
throwaway VM. Two gotchas:

- The vz firmware will not boot when two attached disks both carry an ESP.
  Disable the bootloader on the disk under surgery first, from the host:
  `hdiutil attach -imagekey diskimage-class=CRawDiskImage -nomount <disk>`,
  `diskutil mount diskNs15`, rename `EFI/BOOT` and `EFI/ubuntu` aside, detach.
  Rename them back when finished.
- Reencryption rewrites every sector, which would fully allocate the sparse
  200 GiB image. Shrink the filesystem and partition first, then grow both back
  afterwards.

## Steps

Take a fallback clone first — APFS `cp -c` is instant and costs no space:

    cp -c ~/.lima/kdev/disk ~/.lima/kdev/disk.pre-luks

Attach a copy to a surgery VM (Ubuntu, with `cryptsetup`), bootloader disabled
as above, then inside it:

    umount /mnt/lima-<disk> || true
    e2fsck -fy /dev/vdb1
    resize2fs /dev/vdb1 7864320                      # 30 GiB
    echo "start=2099200, size=65011712, ..." | sfdisk --force -N 1 /dev/vdb

Encrypt and unlock — these two prompt, so run them from a real terminal:

    cryptsetup reencrypt --encrypt --reduce-device-size 32M /dev/vdb1
    cryptsetup open /dev/vdb1 kdevroot

Grow everything back (`cryptsetup resize` needs the key, so it prompts too):

    sfdisk --force -N 1 /dev/vdb   # original size=417331167
    partx -u -n 1 /dev/vdb
    cryptsetup resize kdevroot
    resize2fs /dev/mapper/kdevroot

Mount it, with `/boot` and the ESP in place and the API filesystems bound —
without these `apt-get` and `update-initramfs` fail or emit a broken image, and
`/run` is what gives the chroot working DNS:

    mount /dev/mapper/kdevroot /mnt/kdev
    mount /dev/vdb13 /mnt/kdev/boot
    mount /dev/vdb15 /mnt/kdev/boot/efi
    for d in dev dev/pts proc sys run; do mount --bind /$d /mnt/kdev/$d; done

Then install the unlock machinery:

    apt-get install -y cryptsetup-initramfs dropbear-initramfs
    echo "kdevroot UUID=<luks-uuid> none luks,discard" >> /etc/crypttab
    # /etc/default/grub: append "ip=dhcp net.ifnames=0" to GRUB_CMDLINE_LINUX
    # without clobbering an existing value. dropbear needs the network, and
    # net.ifnames=0 is not optional — see the trap below.
    # /etc/dropbear/initramfs/authorized_keys <- ~/.lima/_config/user.pub,
    # prefixed so the key cannot do anything but unlock (without it, that key
    # gets a full root shell in the initramfs):
    #   command="/usr/bin/cryptroot-unlock",no-port-forwarding,
    #   no-agent-forwarding,no-X11-forwarding <key>
    # Do NOT add no-pty — cryptsetup needs a TTY to read the passphrase.
    update-initramfs -u -k all && update-grub

An initramfs missing either piece is an unbootable VM, so verify:

    lsinitramfs /boot/initrd.img-* | grep -E "cryptroot|dropbear"

Restore the ESP names, copy the disk back over `~/.lima/kdev/disk`, and boot.

## The ip=dhcp / eth0 trap

`ip=dhcp` is what dropbear needs, and it also quietly breaks the guest network
unless `net.ifnames=0` is set alongside it. The symptom looks nothing like the
cause: the VM keeps its address and can still reach 192.168.5.2, but has no
default route and no DNS.

cloud-init ranks initramfs network config above the datasource, so `ip=dhcp`
makes netplan use `enp0s1` while Lima's cidata `bootcmd` (its workaround for
LP: #2136392) renames the NIC to `eth0` anyway. The rename needs the link down,
which drops the lease's default route, and nothing manages the interface
afterwards because netplan's unit matches `Name=enp0s1`. `net.ifnames=0` makes
the NIC `eth0` from the first moment, so nothing renames anything.

## Checking it worked

Against the pre-conversion clone as a control:

    dd if=disk.pre-luks bs=1m skip=1025 count=2048 | grep -ac lost+found   # hits
    dd if=disk         bs=1m skip=1025 count=2048 | grep -ac lost+found   # 0

And that the cmdline change held, since a missing default route is easy to miss
when the VM otherwise looks healthy:

    limactl shell kdev -- ip route          # must list a default via 192.168.5.2
    limactl shell kdev -- curl -sI https://example.com

## Caveats

What this does **not** protect against, in rough order of how easily it is
defeated:

- **A running VM.** `~/.lima/_config/user` is a 0600 key any process running as
  you can read, and `cloud-config.yaml` grants it `NOPASSWD:ALL`, so
  `limactl shell kdev -- tar c ~` reads everything in cleartext. The encryption
  only covers the window in which the VM is stopped — stop kdev when not in use
  or this buys very little.
- **An adversary who can write, not just read.** `/boot` and the ESP are
  plaintext in a file you own, and vz enforces no Secure Boot. Patching
  `initrd.img-*` to capture the passphrase at the next unlock is straightforward.
- **The unlock connection.** `kdev-unlock` uses `StrictHostKeyChecking=no`, so
  anything that can bind the forwarded port collects the passphrase. Pinning
  would not help: dropbear's host key lives in the same plaintext initramfs.
- **Guest RAM.** While unlocked the key is in the hostagent's address space —
  reachable by debugger, and pageable to `/private/var/vm/swapfile`, which is
  only encrypted under FileVault.
- **Metadata.** The image stays sparse and `crypttab` passes `discard` through,
  so a copier learns how much data exists and roughly where. The LUKS2 header is
  an offline target (argon2id t=13 m=1GiB makes that expensive, not impossible).

And the operational ones:

- Keep the guest swapless, or swap can spill plaintext onto the disk.
- Delete `disk.pre-luks` once the encrypted VM is trusted; it is a complete
  unencrypted copy and undoes the whole exercise.
- Lose the passphrase and the data is gone. There is no recovery key.
