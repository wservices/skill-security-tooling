# Shared cybersecurity base image for Hermes Kali sandboxes.
#
# Layers common CLI utilities onto the official Kali Rolling image. Role images
# (or role tools/install.sh manifests) extend this with their own tool layer.
# The full Kali tool collection is deliberately NOT installed.
#
# Build:
#   docker build -t agents/cyber-base:0.1.0 base-image/
# Pin the Kali digest in CI for reproducibility (see README).

FROM kalilinux/kali-rolling

LABEL org.opencontainers.image.title="agents-cyber-base" \
      org.opencontainers.image.source="https://gitlab.wservices.ch/agents/shared/cybersecurity/security-tooling" \
      org.opencontainers.image.description="Kali Rolling + shared CLI utilities for Hermes cybersecurity agents" \
      org.opencontainers.image.licenses="MIT"

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_BREAK_SYSTEM_PACKAGES=0 \
    LANG=C.UTF-8

# Preseed so tshark/wireshark-common does NOT install dumpcap setuid-root.
# Capture capability is granted at runtime via --cap-add NET_RAW, not setuid.
RUN echo "wireshark-common wireshark-common/install-setuid boolean false" | debconf-set-selections

COPY packages.base.txt /tmp/packages.base.txt

RUN apt-get update \
 && grep -vE '^\s*(#|$)' /tmp/packages.base.txt | sed 's/#.*//' | awk '{print $1}' \
      | xargs apt-get install -y --no-install-recommends \
 && rm -rf /var/lib/apt/lists/* /tmp/packages.base.txt

# 'yq' via pipx (python yq wraps jq); keep it isolated from system site-packages.
RUN pipx install yq || true
ENV PATH="/root/.local/bin:${PATH}"

# Convenience symlinks for the Debian-renamed binaries so skills can call the
# conventional names. (fd-find -> fdfind; fd name clashes with another pkg.)
RUN ln -sf "$(command -v fdfind)" /usr/local/bin/fd 2>/dev/null || true

WORKDIR /workspace

# Sanity layer: fail the build if a core tool is missing.
RUN for b in bash curl wget git jq rg fdfind python3 pipx dig whois nc socat tcpdump tshark nmap openssl; do \
      command -v "$b" >/dev/null 2>&1 || { echo "MISSING: $b" >&2; exit 1; }; \
    done && echo "base image tool check OK"

CMD ["/bin/bash"]
