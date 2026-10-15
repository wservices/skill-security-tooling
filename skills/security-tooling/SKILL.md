---
name: security-tooling
description: Install and verify CLI security tools in Kali.
version: 0.1.0
author: Pascal (pascal), Hermes Agent
license: MIT
platforms: [linux]
metadata:
  hermes:
    tags: [kali, tooling, apt, install, verification]
    related_skills: [cve-research]
---

# Security Tooling Skill

Reproducibly install and verify the CLI tools a cybersecurity role needs inside
the Kali Rolling sandbox, from a declared manifest. It does not install the full
Kali metapackage and it never runs untrusted `curl | bash` installers.

## When to Use

- Bootstrapping a role's container tools from its `tools/packages.txt`.
- Verifying that required tools are present (and which versions) before a workflow.
- Adding one upstream binary (e.g. `osv-scanner`, ProjectDiscovery tools) with a
  pinned version and checksum.
- **Don't use for:** installing the whole Kali tool collection, GUI apps, or any
  tool a role doesn't need.

## Prerequisites

- Kali Rolling container (Hermes `terminal.backend: docker`, image
  `kalilinux/kali-rolling`), running as root or with passwordless sudo.
- Network egress to the Debian/Kali APT mirrors.
- For raw-socket tools at runtime: `--cap-add NET_RAW` via `docker_extra_args`
  (Security Policy §4). Install does not need it; capture/scan does.

## How to Run

`terminal(command="bash scripts/install_from_manifest.sh tools/packages.txt --verify-bin nmap,tshark,jq", timeout=600)`

## Quick Reference

```
install_from_manifest.sh <packages.txt> [--verify-bin a,b,c] [--dry-run]
verify_tools.sh bin1 bin2 ... | --from-file verify.txt
```

Upstream pinned binary pattern (example: osv-scanner, NOT an apt package):

```bash
ver=2.5.1
base="https://github.com/google/osv-scanner/releases/download/v${ver}"
curl -fsSLO "${base}/osv-scanner_linux_amd64"
curl -fsSLO "${base}/osv-scanner_SHA256SUMS"
grep "osv-scanner_linux_amd64" osv-scanner_SHA256SUMS | sha256sum -c -   # verify before use
install -m 0755 osv-scanner_linux_amd64 /usr/local/bin/osv-scanner
osv-scanner --version
```

## Procedure

1. **Declare the manifest.** The role's `tools/packages.txt` lists APT packages
   (one per line, `#` comments allowed). Completion: manifest parses and lists
   only packages the role actually uses.
2. **Install.** Run `install_from_manifest.sh tools/packages.txt --verify-bin <key bins>`.
   Completion: exit 0 and every `--verify-bin` prints `OK`.
3. **Pinned upstream binaries.** For tools not in APT, download the release
   asset, **verify its SHA256 against the published `SHA256SUMS`**, then install.
   Completion: checksum verified (`sha256sum -c` prints `OK`) before the binary
   is placed on PATH.
4. **Final verification.** Run `verify_tools.sh --from-file tools/verify.txt`.
   Completion: "all N tools present"; otherwise the missing list is non-empty and
   you stop and fix it.

## Pitfalls

- **Ephemeral containers lose APT installs.** With `container_persistent: true`
  they persist; otherwise re-run the manifest each session (that's why it's
  idempotent). Prefer baking a role image from the Dockerfile for speed.
- **Binary name renames.** Debian ships `fd-find` as `fdfind` and keeps
  `wireshark` CLI as `tshark`. The base image symlinks `fd`; don't assume
  upstream names.
- **tshark setuid prompt.** The base image preseeds `dumpcap` non-setuid; capture
  relies on `NET_RAW`, not setuid root.
- **No untrusted installers.** Never pipe a remote script into a shell. Pin
  versions and verify checksums (Security Policy: reproducible, no untrusted scripts).

## Verification

- `bash scripts/install_from_manifest.sh base-image/packages.base.txt --dry-run`
  lists the parsed package set without changing anything.
- `python3 -m pytest tests -q` validates manifest parsing and script syntax.
- After a real install, `verify_tools.sh` reports all requested tools `OK`.
