#! /usr/bin/make -f

BOOTDIR   := /boot/Efi/Secure
CERTDIR   := /etc/secure-boot
SIGNER    := ArchSecureBoot

KERNEL    := /boot/vmlinuz-linux
INITRAMFS := /boot/intel-ucode.img /boot/initramfs-linux.img
EFISTUB   := /usr/lib/systemd/boot/efi/linuxx64.efi.stub

BUILDDIR  := $(shell mktemp -d)

# or use uuidgen
GUUID     := 1737c18a-2142-4723-a62d-36945aedc25e


all:
	@echo Make targets: keys, install, update

build:   $(BUILDDIR)/combined-boot.efi
sign:    $(BUILDDIR)/combined-boot-signed.efi
update:  $(BOOTDIR)/combined-boot-signed.efi
install: update
	efibootmgr -c -l '\Efi\Secure\combined-boot-signed.efi' -L 'Linux SecureBoot'

clean:
	rm -rf $(BUILDDIR)



$(BUILDDIR)/cmdline.txt:
	@mkdir -p $(BUILDDIR)
	echo -n `</proc/cmdline` > $(BUILDDIR)/cmdline.txt

$(BUILDDIR)/initramfs.img: $(INITRAMFS)
	@mkdir -p $(BUILDDIR)
	cat  $(INITRAMFS) > $(BUILDDIR)/initramfs.img

$(BUILDDIR)/combined-boot.efi: $(BUILDDIR)/cmdline.txt $(BUILDDIR)/initramfs.img $(EFISTUB) /etc/os-release
	objcopy \
	        --add-section .osrel=/etc/os-release --change-section-vma .osrel=0x20000 \
	        --add-section .cmdline=$(BUILDDIR)/cmdline.txt --change-section-vma .cmdline=0x30000 \
	        --add-section .linux=$(KERNEL) --change-section-vma .linux=0x40000 \
	        --add-section .initrd=$(BUILDDIR)/initramfs.img --change-section-vma .initrd=0x3000000 \
	        $(EFISTUB) $(BUILDDIR)/combined-boot.efi

$(BUILDDIR)/combined-boot-signed.efi: $(BUILDDIR)/combined-boot.efi $(CERTDIR)/db.key
	sbsign --key $(CERTDIR)/db.key --cert $(CERTDIR)/db.crt --output $(BUILDDIR)/combined-boot-signed.efi \
	        $(BUILDDIR)/combined-boot.efi


$(BOOTDIR)/combined-boot-signed.efi: $(BUILDDIR)/combined-boot-signed.efi
	@mkdir -p $(BOOTDIR)
	cp $(BUILDDIR)/combined-boot-signed.efi $(BOOTDIR)/combined-boot-signed.efi


### setup keys.
### need only run once.

keys: $(CERTDIR)/PK.auth $(CERTDIR)/KEK.auth $(CERTDIR)/db.auth

$(CERTDIR)/%.crt: $(CERTDIR)/%.key;
$(CERTDIR)/%.key: COMMONNAME = $(SIGNER) $(basename $(notdir $@))
$(CERTDIR)/%.key:
	@mkdir -p $(CERTDIR)
	openssl req -new -x509 -newkey rsa:2048 -subj "/CN=$(COMMONNAME)/" \
	    -keyout $@ -out $(@:.key=.crt) -days 3650 -nodes -sha256

$(CERTDIR)/%.esl: $(CERTDIR)/%.key
	cert-to-efi-sig-list -g $(GUUID) $(@:.esl=.crt) $@


$(CERTDIR)/PK.auth: $(CERTDIR)/PK.crt $(CERTDIR)/PK.esl
	sign-efi-sig-list -k $(CERTDIR)/PK.key -c $(CERTDIR)/PK.crt PK $(CERTDIR)/PK.esl $(CERTDIR)/PK.auth

$(CERTDIR)/KEK.auth: $(CERTDIR)/PK.crt $(CERTDIR)/KEK.esl
	sign-efi-sig-list -c $(CERTDIR)/PK.crt -k $(CERTDIR)/PK.key KEK $(CERTDIR)/KEK.esl $(CERTDIR)/KEK.auth

$(CERTDIR)/db.auth: $(CERTDIR)/KEK.crt $(CERTDIR)/db.esl
	sign-efi-sig-list -c $(CERTDIR)/KEK.crt -k $(CERTDIR)/KEK.key db $(CERTDIR)/db.esl $(CERTDIR)/db.auth


.PRECIOUS: $(CERTDIR)/%.key $(CERTDIR)/%.crt $(CERTDIR)/%.esl
.PHONY: all clean
