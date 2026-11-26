# PXE privilege review

## Current blockers

- The entrypoint starts ISC DHCP and TFTP via service scripts. These expect root initialization, writable runtime state and binding to privileged UDP ports. DHCP may also require raw packet sockets and an interface with appropriate broadcast reachability.
- The image sync loop mounts CIFS itself. Mounting generally needs CAP_SYS_ADMIN and suitable host/kernel permissions; this is a broad privilege and must not be granted to the application container merely to satisfy the scanner.
- The Docker build references missing boot files and daemon configuration. Real privilege requirements cannot be verified until these inputs and runtime topology are supplied.
- Existing Compose does not supply the approved-lab environment or external credentials/checksum mounts. Network and boot behavior must be tested on an isolated provisioning VLAN.

## Proposed split

1. Mount the SMB share on the host, read-only, with protected host-side credentials. Give a non-root sync service a read-only bind mount of the mounted share and a writable staging directory; use an independently trusted, read-only checksum manifest. Do not add CAP_SYS_ADMIN.
2. Serve only verified assets through a separate non-root TFTP service listening on an unprivileged internal port such as 1069, with a host UDP 69 mapping where supported. Verify TFTP transfer sockets and firewall/NAT behavior.
3. Prefer the existing authorized network DHCP service for PXE boot options. If a dedicated DHCP container is required, evaluate exact capabilities in a lab (e.g. NET_BIND_SERVICE and NET_RAW) and daemon privilege dropping; do not assume these are sufficient or use host networking without review.
4. Keep automatic disk restoration disabled. Require explicit client authorization before designing a recovery workflow.

## Validation gate

Test image sync with absent mounts, invalid hashes, symlinks and filesystem permissions; verify the non-root UID/GID and effective capabilities; test DHCP/TFTP on an isolated virtual network and validate that no unintended DHCP replies or disk writes occur. Keep the root-user Trivy finding visible until implementation and integration tests establish a safe design.

This review does not change runtime behavior, introduce a privileged container, or claim that the current Docker image is deployable.
