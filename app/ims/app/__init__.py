import logging
import os
import tempfile

from flask import Flask, jsonify, render_template
from werkzeug.exceptions import HTTPException

from .models import db


def database_url_from_env():
    """DATABASE_URL wins; otherwise PG* vars (as injected by docker-compose / ECS) select Postgres;
    with neither, fall back to a SQLite file in the temp dir (writable by the non-root container user)."""
    if os.getenv("DATABASE_URL"):
        return os.environ["DATABASE_URL"]
    if os.getenv("PGHOST"):
        return "postgresql+psycopg2://{user}:{password}@{host}:{port}/{db}".format(
            user=os.getenv("PGUSER", "ims"),
            password=os.getenv("PGPASSWORD", "ims"),
            host=os.environ["PGHOST"],
            port=int(os.getenv("PGPORT", "5432")),
            db=os.getenv("PGDATABASE", "ims"),
        )
    return "sqlite:///" + os.path.join(tempfile.gettempdir(), "inventory.db")


def create_app(config=None):
    app = Flask(__name__)
    app.config.update(
        SQLALCHEMY_DATABASE_URI=database_url_from_env(),
        SQLALCHEMY_ENGINE_OPTIONS={"pool_pre_ping": True},
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
