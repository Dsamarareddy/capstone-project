import logging
from functools import wraps

from flask import Blueprint, abort, current_app, jsonify, request
from marshmallow import ValidationError

from .models import CartItem, Order, Product, db
from .schemas import CartAddSchema, CartUpdateSchema, ProductSchema

api = Blueprint("api", __name__)
log = logging.getLogger(__name__)

SORTABLE = {"id", "name", "price", "quantity", "category", "created_at"}


def require_api_key(fn):
    @wraps(fn)
    def wrapper(*args, **kwargs):
        if request.headers.get("X-API-Key") != current_app.config["API_KEY"]:
            abort(401, "Missing or invalid X-API-Key header")
        return fn(*args, **kwargs)
    return wrapper


def load(schema, partial=False):
    try:
        return schema.load(request.get_json(silent=True) or {}, partial=partial)
    except ValidationError as e:
        resp = jsonify(error="Validation failed", details=e.messages)
        resp.status_code = 400
        abort(resp)


# ---------- Products ----------

@api.get("/products")
def list_products():
    q = Product.query
    if search := request.args.get("search"):
        q = q.filter(Product.name.ilike(f"%{search}%") | Product.sku.ilike(f"%{search}%"))
    if category := request.args.get("category"):
        q = q.filter(Product.category == category)
    if request.args.get("in_stock") == "true":
        q = q.filter(Product.quantity > 0)

    sort = request.args.get("sort", "id")
    desc = sort.startswith("-")
    col = sort.lstrip("-")
    if col not in SORTABLE:
        abort(400, f"Cannot sort by '{col}'")
    column = getattr(Product, col)
    q = q.order_by(column.desc() if desc else column.asc())

    page = request.args.get("page", 1, type=int)
    per_page = min(request.args.get("per_page", 10, type=int), 100)
    p = q.paginate(page=page, per_page=per_page, error_out=False)
    return jsonify(items=[x.to_dict() for x in p.items], page=p.page,
                   per_page=p.per_page, total=p.total, pages=p.pages)


@api.get("/products/<int:pid>")
def get_product(pid):
    return jsonify(db.get_or_404(Product, pid).to_dict())


@api.post("/products")
@require_api_key
def create_product():
    data = load(ProductSchema())
    if Product.query.filter_by(sku=data["sku"]).first():
        abort(409, f"SKU '{data['sku']}' already exists")
    p = Product(**data)
    db.session.add(p)
    db.session.commit()
    log.info("Created product %s", p.sku)
    return jsonify(p.to_dict()), 201


@api.put("/products/<int:pid>")
@require_api_key
def replace_product(pid):
    return _update(pid, partial=False)


@api.patch("/products/<int:pid>")
@require_api_key
def patch_product(pid):
    return _update(pid, partial=True)


def _update(pid, partial):
    p = db.get_or_404(Product, pid)
    data = load(ProductSchema(), partial=partial)
    if "sku" in data and data["sku"] != p.sku and Product.query.filter_by(sku=data["sku"]).first():
        abort(409, f"SKU '{data['sku']}' already exists")
    for k, v in data.items():
        setattr(p, k, v)
    db.session.commit()
    log.info("Updated product %s", p.id)
    return jsonify(p.to_dict())


@api.delete("/products/<int:pid>")
@require_api_key
def delete_product(pid):
    p = db.get_or_404(Product, pid)
    CartItem.query.filter_by(product_id=pid).delete()
    db.session.delete(p)
    db.session.commit()
    log.info("Deleted product %s", pid)
    return "", 204


@api.get("/stats")
def stats():
    products = Product.query.all()
    return jsonify(
        total_products=len(products),
        total_units=sum(p.quantity for p in products),
        inventory_value=round(sum(p.quantity * p.price for p in products), 2),
        low_stock=[p.to_dict() for p in products if p.quantity < 5],
        orders=Order.query.count(),
    )


# ---------- Cart ----------

def _cart_payload():
    items = CartItem.query.all()
    return {"items": [i.to_dict() for i in items],
            "total": round(sum(i.product.price * i.quantity for i in items), 2)}


@api.get("/cart")
def get_cart():
    return jsonify(_cart_payload())


@api.post("/cart")
def add_to_cart():
    data = load(CartAddSchema())
    product = db.get_or_404(Product, data["product_id"])
    item = CartItem.query.filter_by(product_id=product.id).first()
    new_qty = data["quantity"] + (item.quantity if item else 0)
    if new_qty > product.quantity:
        abort(409, f"Only {product.quantity} '{product.name}' in stock")
    if item:
        item.quantity = new_qty
    else:
        db.session.add(CartItem(product_id=product.id, quantity=new_qty))
    db.session.commit()
    return jsonify(_cart_payload()), 201


@api.put("/cart/<int:item_id>")
def update_cart_item(item_id):
    item = db.get_or_404(CartItem, item_id)
    data = load(CartUpdateSchema())
    if data["quantity"] > item.product.quantity:
        abort(409, f"Only {item.product.quantity} '{item.product.name}' in stock")
    item.quantity = data["quantity"]
    db.session.commit()
    return jsonify(_cart_payload())


@api.delete("/cart/<int:item_id>")
def remove_cart_item(item_id):
    db.session.delete(db.get_or_404(CartItem, item_id))
    db.session.commit()
    return jsonify(_cart_payload())


@api.delete("/cart")
def clear_cart():
    CartItem.query.delete()
    db.session.commit()
    return jsonify(_cart_payload())


@api.post("/cart/checkout")
def checkout():
    items = CartItem.query.all()
    if not items:
        abort(400, "Cart is empty")
    for i in items:
        if i.quantity > i.product.quantity:
            abort(409, f"Not enough stock for '{i.product.name}'")
    payload = _cart_payload()
    for i in items:
        i.product.quantity -= i.quantity
        db.session.delete(i)
    order = Order(total=payload["total"], items=payload["items"])
    db.session.add(order)
    db.session.commit()
    log.info("Order %s placed, total %s", order.id, order.total)
    return jsonify(order.to_dict()), 201


@api.get("/orders")
def list_orders():
    return jsonify([o.to_dict() for o in Order.query.order_by(Order.id.desc()).all()])
