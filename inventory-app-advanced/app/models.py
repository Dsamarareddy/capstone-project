from datetime import datetime, timezone

from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()


def now():
    return datetime.now(timezone.utc)


class Product(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    sku = db.Column(db.String(40), unique=True, nullable=False)
    name = db.Column(db.String(120), nullable=False)
    category = db.Column(db.String(60), default="General")
    quantity = db.Column(db.Integer, nullable=False, default=0)
    price = db.Column(db.Float, nullable=False)
    created_at = db.Column(db.DateTime(timezone=True), default=now)
    updated_at = db.Column(db.DateTime(timezone=True), default=now, onupdate=now)

    def to_dict(self):
        return {
            "id": self.id, "sku": self.sku, "name": self.name, "category": self.category,
            "quantity": self.quantity, "price": self.price,
            "in_stock": self.quantity > 0,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }


class CartItem(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    product_id = db.Column(db.Integer, db.ForeignKey("product.id", ondelete="CASCADE"), unique=True)
    quantity = db.Column(db.Integer, nullable=False)
    product = db.relationship("Product")

    def to_dict(self):
        return {
            "id": self.id, "product_id": self.product_id, "name": self.product.name,
            "unit_price": self.product.price, "quantity": self.quantity,
            "line_total": round(self.product.price * self.quantity, 2),
        }


class Order(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    total = db.Column(db.Float, nullable=False)
    items = db.Column(db.JSON, nullable=False)
    created_at = db.Column(db.DateTime(timezone=True), default=now)

    def to_dict(self):
        return {"id": self.id, "total": self.total, "items": self.items,
                "created_at": self.created_at.isoformat()}
