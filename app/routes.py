"""Application routes – remediated using the patterns in app/clean/safe_patterns.py."""
import os

import yaml
from flask import Blueprint, abort, jsonify, request

from app.clean import safe_patterns
from app.db import get_conn

bp = Blueprint("demo", __name__)

FILES_DIR = os.path.join(os.path.dirname(__file__), "files")


@bp.get("/users")
def get_user():
    username = request.args.get("username", "")
    # Fixed: parameterized query
    with get_conn() as conn:
        rows = safe_patterns.get_user(conn, username)
    return jsonify([{"id": r[0], "username": r[1], "email": r[2]} for r in rows])


@bp.get("/lookup")
def lookup_host():
    host = request.args.get("host", "localhost")
    # Fixed: no shell, strict hostname/IP validation, stdlib resolver
    try:
        return jsonify(result=safe_patterns.lookup_host(host))
    except (ValueError, OSError):
        abort(400, "invalid host")


@bp.get("/files")
def read_file():
    name = request.args.get("name", "readme.txt")
    # Fixed: resolved path must stay inside FILES_DIR
    try:
        path = safe_patterns.resolve_safe_path(FILES_DIR, name)
    except ValueError:
        abort(400, "invalid file name")
    if not os.path.isfile(path):
        abort(404)
    with open(path) as fh:
        return fh.read(), 200, {"Content-Type": "text/plain"}


@bp.post("/import")
def import_config():
    body = request.get_data()
    if not body:
        abort(400, "POST a YAML document")
    # Fixed: yaml.safe_load (and PyYAML bumped to 6.0.3)
    try:
        return jsonify(imported=safe_patterns.parse_yaml(body))
    except yaml.YAMLError:
        abort(400, "invalid or unsafe YAML")


@bp.post("/register")
def register():
    username = request.form.get("username", "")
    password = request.form.get("password", "")
    # Fixed: salted scrypt instead of MD5
    password_hash = safe_patterns.hash_password(password)
    with get_conn() as conn:
        conn.execute(
            "INSERT OR REPLACE INTO users (username, password_hash) VALUES (?, ?)",
            (username, password_hash),
        )
    return jsonify(registered=username)
