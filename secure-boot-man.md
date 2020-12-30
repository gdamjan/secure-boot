SECURE-BOOT 8 "December 2020" "secure-boot 1.5.0" "User Manual"
==================================================

# NAME
secure-boot - UEFI SecureBoot on ArchLinux

# SYNOPSIS
secure-boot [**OPTIONS**] *\<command\>*

# DESCRIPTION
`secure-boot` is a userspace application to use UEFI secure boot on ArchLinux.
It generates keys to sign the bootimage, enrolls the keys into the UEFI
firmware (experimental), signs the bootimage and creates EFI boot entries (no
intermediate bootloader is needed).

This process is fully configurable by putting the options into
`/etc/secure-boot/config.mk` (in makefile format) or specify them on the
command line (see `EXAMPLES`).

Secure boot must be enabled in the UEFI firmware.

# OPTIONS
**ESP**=*\<path\>*
    Path to ESP directory, default: `/boot`

**EFIDIR**=*\<path\>*
    Path to EFI directory, default: `/EFI/Secure`

**EFIBOOTDEVICE**=*\<path\>*
    Path to EFI boot device to override `efibootmgr -d` defaults

**SUFFIX**=*\<suffix\>*
    Deprecated, use KERNEL, default: "linux"

**SIGNER**=*\<name\>*
    Name of the signer, passed as part of **/CN** to OpenSSLs key generation, default: ArchSecureBoot

**KERNEL**=*\<kernel\>*
    Specify a kernel, e.g. linux, default: "${SUFFIX}"

**VMLINUZ**=*\<path\>*
    Path to linux kernel image, default: `/boot/vmlinuz-${KERNEL}`

**INITRAMFS**=*\<path\>*
    Path to initramfs default: `/boot/initramfs-${KERNEL}.img`

**EFISTUB**=*\<path\>*
    Path to EFI stub, default: `/usr/lib/systemd/boot/efi/linuxx64.efi.stub`

**UCODE**=*\<path\>*
    Path to CPU microcode image, default: `/boot/intel-ucode.img`

**CMDLINE**=*\<path\>*
    Path to kernel command line, default: `/etc/kernel/cmdline`

**DESTFILE**=*\<name\>*
    Name of merged EFI boot image, default: "secure-boot-${KERNEL}.efi"

**EFIBOOTMGR**=*\<executable\>*
    Efibootmgr executable, default: `efibootmgr`

**EFIBOOTLBL**=*\<label\>*
    Label of EFI boot entry, default: "SecureBoot ${KERNEL}"

**RSAKEYSIZE**=*\<number\>*
    RSA key size, default: 4096

# COMMANDS
###  gen-keys
Generates the keys into `/etc/secure-boot`. Make sure that no-one can access
them!

###  enroll
**Experimental!** Enrolls the generated keys into the UEFI firmware using
`efi-updatevar` from package `efitools`.

###  update
Updates the EFI executable `${BOOTDIR}/${DESTFILE}`.

###  install
Runs `secure-boot update` and add an entry to the EFI boot list using `efibootmgr`.

# EXAMPLES
Generate keys:

`secure-boot gen-keys`

To use 2048bit RSA use:

`secure-boot RSAKEYSIZE=2048 gen-keys`

Enroll keys into UEFI firmware:

`secure-boot enroll`

Create, sign and install an EFI boot image and EFI boot entry:

`secure-boot install`

Update the boot image (e.g. after kernel update):

`secure-boot update`

Pass option on command line to sign and setup the -lts kernel:

`secure-boot KERNEL=linux-lts update`

By default the script expects a cpu microcode archive exists at `/boot/intel-ucode.img`, and packs it to the common initramfs. To disable it run

`secure-boot UCODE= update`

# HOOKS
`secure-boot.hook` can be installed as pacman hook (`/etc/pacman.d/hooks/`) to
update the EFI bootimage when the `linux`, `{intel,amd}-ucode` package or `initramfs` is updated.

# BUGS
Please report any bugs, feature requests, etc. to https://github.com/gdamjan/secure-boot

# SEE ALSO
`efibootmgr`(8), `efi-updatevar`(1)

