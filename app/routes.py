"""Intentionally vulnerable routes. Compare with app/clean/safe_patterns.py."""
import hashlib
import os
import subprocess

import yaml
from flask import Blueprint, abort, jsonify, request

from app.db import get_conn

bp = Blueprint("demo", __name__)

FILES_DIR = os.path.join(os.path.dirname(__file__), "files")


@bp.get("/users")
def get_user():
    username = request.args.get("username", "")
    # ORCA-DEMO: SAST – SQL injection: user input string-formatted into a SQLite query
    query = "SELECT id, username, email FROM users WHERE username = '%s'" % username
    with get_conn() as conn:
        rows = conn.execute(query).fetchall()
    return jsonify([{"id": r[0], "username": r[1], "email": r[2]} for r in rows])


@bp.get("/lookup")
def lookup_host():
    host = request.args.get("host", "localhost")
    # ORCA-DEMO: SAST – OS command injection: subprocess with shell=True on user input
    out = subprocess.check_output(f"getent hosts {host}", shell=True, text=True)
    return jsonify(result=out)


@bp.get("/files")
def read_file():
    name = request.args.get("name", "readme.txt")
    # ORCA-DEMO: SAST – path traversal: open() on a user-supplied filename (try name=../../etc/passwd)
    with open(os.path.join(FILES_DIR, name)) as fh:
        return fh.read(), 200, {"Content-Type": "text/plain"}


@bp.post("/import")
def import_config():
    body = request.get_data()
    if not body:
        abort(400, "POST a YAML document")
    # ORCA-DEMO: SAST – insecure deserialization: yaml.load without SafeLoader
    # ORCA-DEMO: SCA reachability – this call makes PyYAML 5.3.1 (CVE-2020-14343) REACHABLE
    config = yaml.load(body)
    return jsonify(imported=config)


@bp.post("/register")
def register():
    username = request.form.get("username", "")
    password = request.form.get("password", "")
    # ORCA-DEMO: SAST – weak hashing algorithm (MD5) used for passwords
    password_hash = hashlib.md5(password.encode()).hexdigest()
    with get_conn() as conn:
        conn.execute(
            "INSERT OR REPLACE INTO users (username, password_hash) VALUES (?, ?)",
            (username, password_hash),
        )
    return jsonify(registered=username)
