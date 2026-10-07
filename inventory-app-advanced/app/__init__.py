import logging
import os

from flask import Flask, jsonify, render_template
from werkzeug.exceptions import HTTPException

from .models import db


def create_app(config=None):
    app = Flask(__name__)
    app.config.update(
        SQLALCHEMY_DATABASE_URI=os.getenv("DATABASE_URL", "sqlite:////data/inventory.db"),
        API_KEY=os.getenv("API_KEY", "demo-key"),
        JSON_SORT_KEYS=False,
    )
    if config:
        app.config.update(config)

    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
    db.init_app(app)

    from .routes import api
    app.register_blueprint(api, url_prefix="/api/v1")

    @app.get("/")
    def index():
        return render_template("index.html")

    @app.get("/health")
    def health():
        db.session.execute(db.text("SELECT 1"))
        return jsonify(status="ok", database="ok")

    @app.errorhandler(HTTPException)
    def http_error(e):
        return jsonify(error=e.name, message=e.description), e.code

    with app.app_context():
        db.create_all()
        from .seed import seed
        seed()

    return app
