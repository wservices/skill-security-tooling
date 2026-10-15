"""Tests for the security-tooling manifests and scripts. No network, no apt.

Validates:
  * base manifest parses to a clean, non-empty, de-duplicated package list
  * shell scripts are syntactically valid (bash -n)
  * install script refuses a non-existent manifest
"""
import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
SKILL = ROOT / "skills" / "security-tooling"
MANIFEST = ROOT / "base-image" / "packages.base.txt"
SCRIPTS = sorted((SKILL / "scripts").glob("*.sh"))


def parse_manifest(path: Path) -> list[str]:
    pkgs = []
    for line in path.read_text().splitlines():
        line = line.split("#", 1)[0].strip()
        if not line:
            continue
        pkgs.append(line.split()[0])
    return pkgs


def test_base_manifest_parses_clean():
    pkgs = parse_manifest(MANIFEST)
    assert pkgs, "manifest is empty"
    assert "nmap" in pkgs and "tshark" in pkgs and "jq" in pkgs
    # Debian-renamed package present under its real APT name:
    assert "fd-find" in pkgs
    assert "dnsutils" in pkgs  # provides dig


def test_manifest_has_no_duplicates():
    pkgs = parse_manifest(MANIFEST)
    dupes = {p for p in pkgs if pkgs.count(p) > 1}
    assert not dupes, f"duplicate packages: {dupes}"


def test_manifest_excludes_metapackages():
    pkgs = parse_manifest(MANIFEST)
    banned = [p for p in pkgs if p.startswith("kali-linux-") or p.startswith("kali-tools-")]
    assert not banned, f"base image must not pull Kali metapackages: {banned}"


@pytest.mark.skipif(not shutil.which("bash"), reason="bash not available")
@pytest.mark.parametrize("script", SCRIPTS, ids=lambda p: p.name)
def test_scripts_syntax_valid(script):
    res = subprocess.run(["bash", "-n", str(script)], capture_output=True, text=True)
    assert res.returncode == 0, res.stderr


@pytest.mark.skipif(not shutil.which("bash"), reason="bash not available")
def test_install_script_rejects_missing_manifest(tmp_path):
    script = SKILL / "scripts" / "install_from_manifest.sh"
    res = subprocess.run(
        ["bash", str(script), str(tmp_path / "nope.txt")],
        capture_output=True, text=True,
    )
    assert res.returncode == 2


@pytest.mark.skipif(not shutil.which("bash"), reason="bash not available")
def test_install_script_dry_run_lists_packages():
    script = SKILL / "scripts" / "install_from_manifest.sh"
    res = subprocess.run(
        ["bash", str(script), str(MANIFEST), "--dry-run"],
        capture_output=True, text=True,
    )
    assert res.returncode == 0
    assert "dry-run" in res.stdout
    assert "nmap" in res.stdout
