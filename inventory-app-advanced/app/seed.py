from .models import Product, db

SAMPLE = [
    ("LAP-001", "Laptop", "Electronics", 10, 75000),
    ("MOU-001", "Wireless Mouse", "Accessories", 50, 500),
    ("KEY-001", "Mechanical Keyboard", "Accessories", 25, 3500),
    ("MON-001", "27in Monitor", "Electronics", 8, 18000),
]


def seed():
    if Product.query.count() == 0:
        for sku, name, cat, qty, price in SAMPLE:
            db.session.add(Product(sku=sku, name=name, category=cat, quantity=qty, price=price))
        db.session.commit()
