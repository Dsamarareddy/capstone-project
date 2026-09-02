const request = require('supertest');
const { newDb } = require('pg-mem');
const { createApp } = require('../src/server');
const { SCHEMA_SQL } = require('../src/db');

function createTestPool() {
  const db = newDb({ autoCreateForeignKeyIndices: true });
  db.public.registerFunction({
    name: 'now',
    returns: 'timestamptz',
    implementation: () => new Date(),
  });
  const { Pool } = db.adapters.createPg();
  return new Pool();
}

describe('IMS items API', () => {
  let app;
  let pool;

  beforeEach(async () => {
    pool = createTestPool();
    await pool.query(SCHEMA_SQL);
    app = createApp(pool);
  });

  test('GET /health returns ok', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
  });

  test('GET /items returns an empty list initially', async () => {
    const res = await request(app).get('/items');
    expect(res.status).toBe(200);
    expect(res.body).toEqual([]);
  });

  test('POST /items creates an item', async () => {
    const res = await request(app).post('/items').send({
      sku: 'SKU-001',
      name: 'Widget',
      quantity: 10,
      warehouseLocation: 'A1',
      reorderLevel: 2,
    });
    expect(res.status).toBe(201);
    expect(res.body).toMatchObject({
      sku: 'SKU-001',
      name: 'Widget',
      quantity: 10,
      warehouseLocation: 'A1',
      reorderLevel: 2,
    });
    expect(res.body.id).toBeDefined();
  });

  test('POST /items rejects an invalid payload', async () => {
    const res = await request(app).post('/items').send({ sku: '' });
    expect(res.status).toBe(400);
  });

  test('POST /items rejects a duplicate sku', async () => {
    await request(app).post('/items').send({
      sku: 'SKU-DUP',
      name: 'Widget',
      warehouseLocation: 'A1',
    });
    const res = await request(app).post('/items').send({
      sku: 'SKU-DUP',
      name: 'Widget 2',
      warehouseLocation: 'A2',
    });
    expect(res.status).toBe(409);
  });

  test('GET /items/:id returns 404 for missing item', async () => {
    const res = await request(app).get('/items/999');
    expect(res.status).toBe(404);
  });

  test('PUT /items/:id updates an existing item', async () => {
    const created = await request(app).post('/items').send({
      sku: 'SKU-002',
      name: 'Gadget',
      quantity: 5,
      warehouseLocation: 'B1',
      reorderLevel: 1,
    });
    const res = await request(app).put(`/items/${created.body.id}`).send({
      sku: 'SKU-002',
      name: 'Gadget v2',
      quantity: 20,
      warehouseLocation: 'B2',
      reorderLevel: 3,
    });
    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({ name: 'Gadget v2', quantity: 20, warehouseLocation: 'B2' });
  });

  test('DELETE /items/:id removes an item', async () => {
    const created = await request(app).post('/items').send({
      sku: 'SKU-003',
      name: 'Doohickey',
      warehouseLocation: 'C1',
    });
    const del = await request(app).delete(`/items/${created.body.id}`);
    expect(del.status).toBe(204);

    const get = await request(app).get(`/items/${created.body.id}`);
    expect(get.status).toBe(404);
  });
});
