# security-tooling (shared skill + base image)

The shared Kali base image and the tooling skill used to install/verify CLI
tools reproducibly across every cybersecurity role. Maintained once here.

## Contents

```
base-image/
├── Dockerfile              # kalilinux/kali-rolling + shared CLI utilities
├── packages.base.txt       # verified base APT package manifest
└── README.md               # build/pin instructions
skills/security-tooling/
├── SKILL.md
└── scripts/
    ├── install_from_manifest.sh   # idempotent apt install + verify
    └── verify_tools.sh            # presence/version check
tests/test_tooling.py       # manifest + script validation (no network)
```

## Base image

```bash
docker build -t agents/cyber-base:0.1.0 base-image/
```

Deliberately excludes the `kali-linux-*` / `kali-tools-*` metapackages and GUI
apps. `zeek` is not reliably in Kali APT (packaging is uneven; the upstream route
is the openSUSE Build Service repo or source) — it is left to roles that truly
need it, which document the install. Core traffic analysis uses `tshark`,
`tcpdump`, and (per role) `suricata`.

For reproducibility, pin the base in CI to a Kali image **digest**
(`kalilinux/kali-rolling@sha256:...`) rather than the moving `latest` tag.

## Role usage

A role's `tools/install.sh` calls the shared installer:

```bash
bash /path/to/security-tooling/skills/security-tooling/scripts/install_from_manifest.sh \
  tools/packages.txt --verify-bin nmap,tshark,jq
```

## Tests

```bash
python3 -m pytest tests -q     # 7 tests, no network/apt
```

## License

MIT. Usage bound by `agents/platform/policies/SECURITY-POLICY.md` (esp. §4 on
container capabilities — never `--privileged`).
