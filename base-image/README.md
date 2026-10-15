# Base image build & pinning

```bash
docker build -t agents/cyber-base:0.1.0 .
```

## Reproducibility

Pin the upstream Kali image to a digest instead of the moving tag:

```dockerfile
FROM kalilinux/kali-rolling@sha256:<digest>
```

Resolve the current digest with:

```bash
docker pull kalilinux/kali-rolling
docker inspect --format='{{index .RepoDigests 0}}' kalilinux/kali-rolling
```

Record the digest and the resolved package versions (`dpkg -l` output) as build
provenance alongside each tagged image.

## What's installed

See `packages.base.txt`. Core CLI utilities only — no Kali metapackages, no GUI.
Role images extend this base with their own `tools/packages.txt` layer via
`skills/security-tooling/scripts/install_from_manifest.sh`.
