import pytest

from app import create_app

KEY = {"X-API-Key": "test-key"}


@pytest.fixture
def client():
    app = create_app({"SQLALCHEMY_DATABASE_URI": "sqlite:///:memory:", "API_KEY": "test-key", "TESTING": True})
    return app.test_client()


def test_list_products(client):
    r = client.get("/api/v1/products")
    assert r.status_code == 200
    assert r.json["total"] == 4


def test_create_requires_key(client):
    r = client.post("/api/v1/products", json={"sku": "X1", "name": "X", "quantity": 1, "price": 1})
    assert r.status_code == 401


def test_crud(client):
    r = client.post("/api/v1/products", headers=KEY, json={"sku": "TAB-1", "name": "Tablet", "quantity": 3, "price": 20000})
    assert r.status_code == 201
    pid = r.json["id"]
    assert client.patch(f"/api/v1/products/{pid}", headers=KEY, json={"quantity": 7}).json["quantity"] == 7
    assert client.delete(f"/api/v1/products/{pid}", headers=KEY).status_code == 204
    assert client.get(f"/api/v1/products/{pid}").status_code == 404


def test_validation_and_duplicate(client):
    r = client.post("/api/v1/products", headers=KEY, json={"sku": "LAP-001", "name": "Dup", "quantity": 1, "price": 1})
    assert r.status_code == 409
    r = client.post("/api/v1/products", headers=KEY, json={"sku": "N1", "name": "Bad", "quantity": -1, "price": 1})
    assert r.status_code == 400


def test_cart_checkout_reduces_stock(client):
    client.post("/api/v1/cart", json={"product_id": 1, "quantity": 2})
    assert client.get("/api/v1/cart").json["total"] == 150000
    r = client.post("/api/v1/cart/checkout")
    assert r.status_code == 201
    assert client.get("/api/v1/products/1").json["quantity"] == 8
    assert client.get("/api/v1/cart").json["items"] == []


def test_cart_stock_limit(client):
    r = client.post("/api/v1/cart", json={"product_id": 4, "quantity": 999})
    assert r.status_code == 409
