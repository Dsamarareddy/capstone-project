# IMS Application Architecture

The Inventory Management System (`app/ims`) is the platform's reference application. It is a Python 3.12
**Flask 3** app using **Flask-SQLAlchemy**, **marshmallow** for request validation, and **gunicorn** as the WSGI
server. It serves a browser UI and a JSON REST API under `/api/v1`, with product catalogue, cart, checkout and
order endpoints.

## 1. Components

| Module | Responsibility |
|---|---|
| `wsgi.py` | Entry point. gunicorn loads `wsgi:app` |
| `app/__init__.py` | `create_app()` application factory, `database_url_from_env()`, `/` and `/health` routes, JSON error handler for every `HTTPException`, `db.create_all()` and `seed()` at startup |
| `app/routes.py` | `api` blueprint mounted at `/api/v1`: products, stats, cart, checkout, orders. `require_api_key` decorator |
| `app/schemas.py` | marshmallow `ProductSchema`, `CartAddSchema`, `CartUpdateSchema` |
| `app/models.py` | SQLAlchemy models `Product`, `CartItem`, `Order` |
| `app/seed.py` | Inserts demo products on first start |
| `app/templates/index.html`, `app/static/logo.png` | Single-page web UI, "Inventory Management System" |

```mermaid
flowchart LR
    subgraph Clients
        UI["Browser UI<br/>index.html + fetch"]
        API_C["API clients<br/>curl, scripts, other services"]
        LB["Load balancer / probes<br/>GET /health"]
    end

    subgraph Container["IMS container - python:3.12-alpine, user appuser"]
        GU["gunicorn<br/>1 worker x 4 threads, :3000"]
        subgraph Flask["Flask app - create_app"]
            CORE["core routes<br/>/ and /health"]
            BP["api blueprint<br/>/api/v1"]
            AUTH["require_api_key<br/>X-API-Key"]
            SCH["marshmallow schemas"]
            ERR["HTTPException handler<br/>JSON errors"]
        end
        ORM["Flask-SQLAlchemy<br/>pool_pre_ping"]
    end

    DB[("PostgreSQL 16<br/>or SQLite fallback")]

    UI --> GU
    API_C --> GU
    LB --> GU
    GU --> CORE
    GU --> BP
    BP --> AUTH
    BP --> SCH
    BP --> ORM
    CORE --> ORM
    BP -.-> ERR
    ORM --> DB
```

### Configuration

`database_url_from_env()` picks the database in this order:

1. `DATABASE_URL`, used as-is.
2. If `PGHOST` is set: `postgresql+psycopg2://PGUSER:PGPASSWORD@PGHOST:PGPORT/PGDATABASE` (defaults `ims`/`ims`/`5432`/`ims`).
3. Otherwise `sqlite:///inventory.db`, for quick local runs and tests.

Other settings: `API_KEY` (default `demo-key`) and `PORT` (default `3000`, used by the gunicorn `CMD`). At startup
the factory runs `db.create_all()` and `seed()`. There is no migration tool. The schema is created when missing,
which is enough for a reference app but should not be relied on for schema changes (see
[Future work](#7-future-work)).

## 2. Data model

Taken directly from `app/models.py`. In the diagram the `Order` model is shown as `ORDERS`. `Order.items` is a JSON snapshot of the cart lines at checkout, so later
price or name changes do not rewrite order history. It also means `Order` has no foreign key to `Product`.

```mermaid
erDiagram
    PRODUCT ||--o| CART_ITEM : "is in cart as"
    PRODUCT {
        int id PK
        string sku UK "len 40, not null"
        string name "len 120, not null"
        string category "len 60, default General"
        int quantity "not null, default 0"
        float price "not null"
        datetime created_at "tz aware"
        datetime updated_at "tz aware, onupdate"
    }
    CART_ITEM {
        int id PK
        int product_id FK "unique, ON DELETE CASCADE"
        int quantity "not null"
    }
    ORDERS {
        int id PK
        float total "not null"
        json items "snapshot of cart lines"
        datetime created_at "tz aware"
    }
```

Notes:

- `CartItem.product_id` is **unique**, so each product has at most one cart line. Adding the same product again
  increases that line's quantity.
- There is a single, global cart. The app has no users or sessions. This is a deliberate simplification of the
  reference app.
- `Product.to_dict()` adds a computed `in_stock` (`quantity > 0`). `CartItem.to_dict()` adds `name`,
  `unit_price` and `line_total`.

## 3. Checkout flow

`POST /api/v1/cart/checkout` validates the whole cart before changing anything, then decrements stock, clears the
cart and records the order in **one `db.session.commit()`**, so either everything is applied or nothing is.

```mermaid
sequenceDiagram
    autonumber
    participant C as Client
    participant R as routes.checkout
    participant S as SQLAlchemy session
    participant DB as Database

    C->>R: POST /api/v1/cart/checkout
    R->>S: CartItem.query.all()
    S->>DB: SELECT cart items and products
    DB-->>S: rows
    alt cart is empty
        R-->>C: 400 Cart is empty
    else a line exceeds product stock
        R-->>C: 409 Not enough stock for name
    else all lines are valid
        R->>R: _cart_payload - items and total
        loop each cart item
            R->>S: product.quantity -= item.quantity
            R->>S: delete cart item
        end
        R->>S: add Order with total and JSON items
        R->>S: commit
        S->>DB: UPDATE product, DELETE cart_item, INSERT order
        R-->>C: 201 order JSON
    end
```

Concurrency caveat: the stock check and the decrement are not protected by a row lock (`SELECT ... FOR UPDATE`).
Two checkouts at the same moment could oversell. That is acceptable at today's scale of one worker and one global
cart, but needs fixing before any multi-task deployment.

## 4. Local runtime

There are two equivalent ways to run the stack locally. Both start Postgres `16.4-bookworm` and the IMS image,
built from `app/ims/Dockerfile`.

```mermaid
flowchart LR
    DEV["Developer"]

    subgraph Compose["docker compose up - app/ims/docker-compose.yml"]
        API1["api<br/>build: Dockerfile<br/>3000:3000<br/>API_KEY=demo-key, PG* env"]
        DB1[("db<br/>postgres:16.4-bookworm<br/>5432:5432<br/>volume ims-db-data")]
        API1 -- "depends_on service_healthy<br/>pg_isready" --> DB1
    end

    subgraph IDP["idp up - podman or docker"]
        NET["network ims-net"]
        API2["ims-api<br/>image ims:local<br/>-p PORT:3000"]
        DB2[("ims-db<br/>postgres:16.4-bookworm<br/>no published port, no volume")]
        API2 --- NET
        DB2 --- NET
    end

    DEV -- "http://localhost:3000" --> API1
    DEV -- "idp up / idp status / idp down" --> API2
```

| Aspect | `docker compose up` | `idp up` |
|---|---|---|
| Runtime | Docker Compose | Podman if installed, otherwise Docker |
| DB persistence | Named volume `ims-db-data` | Ephemeral, removed by `idp down` |
| DB readiness | Compose healthcheck `pg_isready` | Polls `pg_isready` up to 30 times |
| App readiness | Image `HEALTHCHECK` on `/health` | `idp up` waits up to 60 s for `/health` to return 200 |
| `API_KEY` | `demo-key` explicitly | Not passed, so the app default `demo-key` applies |

For tests and quick runs without containers: `idp bootstrap` creates `.venv` and installs requirements, and
`idp test` runs pytest against SQLite.

## 5. API summary

All `/api/v1` responses are JSON. Errors use `{"error": <name>, "message": <description>}`. Validation errors use
`{"error": "Validation failed", "details": {...}}` with status 400.

| Method | Path | Auth | Description | Success | Errors |
|---|---|---|---|---|---|
| GET | `/` | - | Web UI | 200 HTML | |
| GET | `/health` | - | Runs `SELECT 1` against the DB | 200 `{status, database}` | 500 if DB unreachable |
| GET | `/api/v1/products` | - | List. Query: `search` (name/sku ilike), `category`, `in_stock=true`, `sort` (`id,name,price,quantity,category,created_at`, prefix `-` for desc), `page`, `per_page` (max 100) | 200 `{items,page,per_page,total,pages}` | 400 bad sort |
| GET | `/api/v1/products/{id}` | - | Get one | 200 | 404 |
| POST | `/api/v1/products` | X-API-Key | Create | 201 | 400, 401, 409 duplicate SKU |
| PUT | `/api/v1/products/{id}` | X-API-Key | Full replace | 200 | 400, 401, 404, 409 |
| PATCH | `/api/v1/products/{id}` | X-API-Key | Partial update | 200 | 400, 401, 404, 409 |
| DELETE | `/api/v1/products/{id}` | X-API-Key | Delete product and its cart line | 204 | 401, 404 |
| GET | `/api/v1/stats` | - | `total_products`, `total_units`, `inventory_value`, `low_stock` (qty < 5), `orders` | 200 | |
| GET | `/api/v1/cart` | - | Cart lines and total | 200 | |
| POST | `/api/v1/cart` | - | Add `{product_id, quantity=1}` | 201 | 400, 404, 409 over stock |
| PUT | `/api/v1/cart/{item_id}` | - | Set quantity | 200 | 400, 404, 409 |
| DELETE | `/api/v1/cart/{item_id}` | - | Remove a line | 200 | 404 |
| DELETE | `/api/v1/cart` | - | Clear the cart | 200 | |
| POST | `/api/v1/cart/checkout` | - | Place an order | 201 order | 400 empty, 409 stock |
| GET | `/api/v1/orders` | - | Orders, newest first | 200 | |

`app/ims/openapi.yaml` is the machine-readable contract.

## 6. Container image

`app/ims/Dockerfile` is a two-stage `python:3.12-alpine` build. The `deps` stage runs `pip install --prefix=/install`.
The `runtime` stage then:

- runs `apk upgrade` to pick up OS patches
- copies only the installed packages, `app/` and `wsgi.py`
- uninstalls `pip`, `setuptools` and `wheel`
- runs as non-root `appuser` (UID 1001)
- has a Python-based `HEALTHCHECK` on `/health`
- starts `gunicorn --workers 1 --threads 4`

## 7. Future work

- Schema migrations (Alembic or Flask-Migrate) instead of `create_all()` at startup.
- Row-level locking or optimistic versioning on checkout.
- Per-user carts and real authentication. Today a single shared API key protects product writes only.
