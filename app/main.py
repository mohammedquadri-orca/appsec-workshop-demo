"""Application entry point.

The container ENTRYPOINT runs `python -m app.main`, so everything imported
from here (including app.routes -> yaml.load) is on an executed code path.
That is what Orca static reachability walks when it analyzes the running
container asset.
"""
import os

from flask import Flask, jsonify

from app import db
from app.routes import bp


def create_app() -> Flask:
    app = Flask(__name__)
    db.init_db()
    app.register_blueprint(bp)

    @app.get("/health")
    def health():
        return jsonify(status="ok")

    return app


app = create_app()


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8080"))
    # ORCA-DEMO: SAST – hardcoded Flask debug mode (Werkzeug debugger enabled)
    app.run(host="0.0.0.0", port=port, debug=True)
