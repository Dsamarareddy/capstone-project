from marshmallow import Schema, fields, validate


class ProductSchema(Schema):
    sku = fields.String(required=True, validate=validate.Length(min=2, max=40))
    name = fields.String(required=True, validate=validate.Length(min=1, max=120))
    category = fields.String(load_default="General", validate=validate.Length(max=60))
    quantity = fields.Integer(required=True, validate=validate.Range(min=0))
    price = fields.Float(required=True, validate=validate.Range(min=0))


class CartAddSchema(Schema):
    product_id = fields.Integer(required=True)
    quantity = fields.Integer(load_default=1, validate=validate.Range(min=1))


class CartUpdateSchema(Schema):
    quantity = fields.Integer(required=True, validate=validate.Range(min=1))
