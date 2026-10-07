from flask import Flask, jsonify, request, render_template_string

app = Flask(__name__)

# In-memory inventory store
inventory = {
    1: {"id": 1, "name": "Laptop", "quantity": 10, "price": 75000.0},
    2: {"id": 2, "name": "Mouse", "quantity": 50, "price": 500.0},
}
next_id = 3


def validate(data, partial=False):
    fields = {"name": str, "quantity": int, "price": (int, float)}
    for key, typ in fields.items():
        if key not in data:
            if not partial:
                return f"'{key}' is required"
            continue
        if not isinstance(data[key], typ):
            return f"'{key}' has invalid type"
    return None


@app.get("/api/items")
def list_items():
    return jsonify(list(inventory.values()))


@app.get("/api/items/<int:item_id>")
def get_item(item_id):
    item = inventory.get(item_id)
    if not item:
        return jsonify({"error": "Item not found"}), 404
    return jsonify(item)


@app.post("/api/items")
def add_item():
    global next_id
    data = request.get_json(silent=True) or {}
    err = validate(data)
    if err:
        return jsonify({"error": err}), 400
    item = {"id": next_id, "name": data["name"], "quantity": data["quantity"], "price": float(data["price"])}
    inventory[next_id] = item
    next_id += 1
    return jsonify(item), 201


@app.put("/api/items/<int:item_id>")
def replace_item(item_id):
    if item_id not in inventory:
        return jsonify({"error": "Item not found"}), 404
    data = request.get_json(silent=True) or {}
    err = validate(data)
    if err:
        return jsonify({"error": err}), 400
    inventory[item_id] = {"id": item_id, "name": data["name"], "quantity": data["quantity"], "price": float(data["price"])}
    return jsonify(inventory[item_id])


@app.patch("/api/items/<int:item_id>")
def update_item(item_id):
    if item_id not in inventory:
        return jsonify({"error": "Item not found"}), 404
    data = request.get_json(silent=True) or {}
    err = validate(data, partial=True)
    if err:
        return jsonify({"error": err}), 400
    for key in ("name", "quantity", "price"):
        if key in data:
            inventory[item_id][key] = float(data[key]) if key == "price" else data[key]
    return jsonify(inventory[item_id])


@app.delete("/api/items/<int:item_id>")
def delete_item(item_id):
    if inventory.pop(item_id, None) is None:
        return jsonify({"error": "Item not found"}), 404
    return jsonify({"message": f"Item {item_id} deleted"})


@app.get("/health")
def health():
    return jsonify({"status": "ok"})


PAGE = """<!doctype html>
<html><head><meta charset="utf-8"><title>Inventory Cart</title>
<style>
body{font-family:Arial;margin:40px;background:#f4f6f9}
h1{color:#2c3e50}table{border-collapse:collapse;width:100%;background:#fff}
th,td{padding:10px;border:1px solid #ddd;text-align:left}th{background:#2c3e50;color:#fff}
input{padding:8px;margin:4px}button{padding:8px 14px;margin:2px;cursor:pointer;border:none;border-radius:4px;color:#fff}
.add{background:#27ae60}.upd{background:#2980b9}.del{background:#c0392b}
</style></head><body>
<h1>Inventory Cart</h1>
<div>
<input id="id" placeholder="ID (for update)" size="10">
<input id="name" placeholder="Name">
<input id="qty" type="number" placeholder="Quantity">
<input id="price" type="number" step="0.01" placeholder="Price">
<button class="add" onclick="addItem()">Add (POST)</button>
<button class="upd" onclick="updateItem()">Update (PUT)</button>
</div><br>
<table><thead><tr><th>ID</th><th>Name</th><th>Quantity</th><th>Price</th><th>Actions</th></tr></thead>
<tbody id="rows"></tbody></table>
<script>
const $=id=>document.getElementById(id);
async function load(){
 const items=await (await fetch('/api/items')).json();
 $('rows').innerHTML=items.map(i=>`<tr><td>${i.id}</td><td>${i.name}</td><td>${i.quantity}</td><td>${i.price}</td>
 <td><button class="upd" onclick='edit(${JSON.stringify(i)})'>Edit</button>
 <button class="del" onclick="del(${i.id})">Delete</button></td></tr>`).join('');
}
function body(){return JSON.stringify({name:$('name').value,quantity:parseInt($('qty').value),price:parseFloat($('price').value)})}
async function send(url,method){
 const r=await fetch(url,{method,headers:{'Content-Type':'application/json'},body:body()});
 if(!r.ok) alert((await r.json()).error); else {['id','name','qty','price'].forEach(k=>$(k).value='');load();}
}
function addItem(){send('/api/items','POST')}
function updateItem(){if(!$('id').value)return alert('Click Edit on a row first');send('/api/items/'+$('id').value,'PUT')}
function edit(i){$('id').value=i.id;$('name').value=i.name;$('qty').value=i.quantity;$('price').value=i.price}
async function del(id){await fetch('/api/items/'+id,{method:'DELETE'});load()}
load();
</script></body></html>"""


@app.get("/")
def index():
    return render_template_string(PAGE)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
