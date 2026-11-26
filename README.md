# PXE provisioning prototype — security review

Unattended disk restoration and network-request-triggered deployment have been disabled. The default boot entry is local boot; there is no approved remote restore operation in this draft. Only run on an isolated, explicitly authorized lab network. Enforce network-level DHCP and client authorization before implementing interactive recovery.

Set PXE_LAB_APPROVED=yes only after network isolation is verified. Mount an operator-provided SHA-256 manifest (flat ISO files, `sha256sum` format) at /run/secrets/image-sha256sums and a mode 0400 or 0600 CIFS credentials file at /run/secrets/samba-credentials. Set SAMBA_SERVER at runtime. The manifest must be generated from independently trusted images, not obtained from the same untrusted share. Image synchronization is non-destructive and validates copied bytes before publishing each file. Previously published images are not removed; review them before use. The prototype does not verify NFS Clonezilla trees or boot assets and does not implement client allowlisting.

The original Dockerfile references missing build inputs. A reproducible offline build, required runtime tools (CIFS mount utilities), and container mount permissions need separate testing. Do not deploy this draft as-is.
