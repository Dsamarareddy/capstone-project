# TODO(new-service): replace this skeleton with your real application routes.
import os
from datetime import datetime, timezone

from flask import Flask, jsonify


def create_app():
    app = Flask(__name__)

    @app.get("/health")
    def health():
        return jsonify(status="ok", service="TODO-service-name", timestamp=datetime.now(timezone.utc).isoformat())

    # TODO(new-service): register your blueprints here, e.g. app.register_blueprint(whatever_bp)

    return app


if __name__ == "__main__":
    create_app().run(host="0.0.0.0", port=int(os.getenv("PORT", "3000")))
