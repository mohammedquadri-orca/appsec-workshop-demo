"""Secure counterparts of every pattern in app/routes.py.

Used as the target pattern by the fix/remediate-findings branch and as a
"what good looks like" reference during the demo.
"""
import hashlib
import hmac
import ipaddress
import os
import re
import socket

import yaml
from unidecode import unidecode

_HOSTNAME_RE = re.compile(r"^(?=.{1,253}$)([A-Za-z0-9-]{1,63}\.)*[A-Za-z0-9-]{1,63}$")


def get_user(conn, username: str):
    """Parameterized query: the driver binds the value, never the SQL text."""
    return conn.execute(
        "SELECT id, username, email FROM users WHERE username = ?", (username,)
    ).fetchall()


def lookup_host(host: str) -> list[str]:
    """Resolve a hostname without a shell, after strict validation."""
    try:
        ipaddress.ip_address(host)
    except ValueError:
        if not _HOSTNAME_RE.match(host):
            raise ValueError("invalid host")
    return sorted({info[4][0] for info in socket.getaddrinfo(host, None)})


def resolve_safe_path(base_dir: str, name: str) -> str:
    """Confine a user-supplied filename to base_dir."""
    base = os.path.realpath(base_dir)
    candidate = os.path.realpath(os.path.join(base, name))
    if os.path.commonpath([base, candidate]) != base:
        raise ValueError("path escapes base directory")
    return candidate


def parse_yaml(data: bytes):
    """safe_load only constructs plain Python types."""
    return yaml.safe_load(data)


def hash_password(password: str, salt: bytes | None = None) -> str:
    """Salted scrypt (memory-hard KDF from the standard library)."""
    salt = salt or os.urandom(16)
    digest = hashlib.scrypt(password.encode(), salt=salt, n=2**14, r=8, p=1)
    return f"{salt.hex()}${digest.hex()}"


def verify_password(password: str, stored: str) -> bool:
    salt_hex, _ = stored.split("$", 1)
    return hmac.compare_digest(hash_password(password, bytes.fromhex(salt_hex)), stored)


def slugify(text: str) -> str:
    """Uses Unidecode (GPLv2+) – the license-policy demo dependency."""
    return re.sub(r"[^a-z0-9]+", "-", unidecode(text).lower()).strip("-")
