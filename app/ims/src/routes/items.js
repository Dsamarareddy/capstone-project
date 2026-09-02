const express = require('express');

function isValidItemPayload(body) {
  return (
    typeof body.sku === 'string' &&
    body.sku.trim().length > 0 &&
    typeof body.name === 'string' &&
    body.name.trim().length > 0 &&
    typeof body.warehouseLocation === 'string' &&
    body.warehouseLocation.trim().length > 0 &&
    (body.quantity === undefined || Number.isInteger(body.quantity)) &&
    (body.reorderLevel === undefined || Number.isInteger(body.reorderLevel))
  );
}

function toApiShape(row) {
  return {
    id: row.id,
    sku: row.sku,
    name: row.name,
    quantity: row.quantity,
    warehouseLocation: row.warehouse_location,
    reorderLevel: row.reorder_level,
    updatedAt: row.updated_at,
  };
}

function createItemsRouter(pool) {
  const router = express.Router();

  router.get('/items', async (req, res, next) => {
    try {
      const result = await pool.query('SELECT * FROM items ORDER BY id ASC');
      res.json(result.rows.map(toApiShape));
    } catch (err) {
      next(err);
    }
  });

  router.get('/items/:id', async (req, res, next) => {
    try {
      const result = await pool.query('SELECT * FROM items WHERE id = $1', [req.params.id]);
      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'item not found' });
      }
      res.json(toApiShape(result.rows[0]));
    } catch (err) {
      next(err);
    }
  });

  router.post('/items', async (req, res, next) => {
    if (!isValidItemPayload(req.body)) {
      return res.status(400).json({ error: 'invalid item payload' });
    }
    try {
      const { sku, name, warehouseLocation } = req.body;
      const quantity = req.body.quantity ?? 0;
      const reorderLevel = req.body.reorderLevel ?? 0;
      const result = await pool.query(
        `INSERT INTO items (sku, name, quantity, warehouse_location, reorder_level)
         VALUES ($1, $2, $3, $4, $5) RETURNING *`,
        [sku, name, quantity, warehouseLocation, reorderLevel]
      );
      res.status(201).json(toApiShape(result.rows[0]));
    } catch (err) {
      if (err.code === '23505') {
        return res.status(409).json({ error: 'sku already exists' });
      }
      next(err);
    }
  });

  router.put('/items/:id', async (req, res, next) => {
    if (!isValidItemPayload(req.body)) {
      return res.status(400).json({ error: 'invalid item payload' });
    }
    try {
      const { sku, name, warehouseLocation } = req.body;
      const quantity = req.body.quantity ?? 0;
      const reorderLevel = req.body.reorderLevel ?? 0;
      const result = await pool.query(
        `UPDATE items
         SET sku = $1, name = $2, quantity = $3, warehouse_location = $4, reorder_level = $5, updated_at = now()
         WHERE id = $6 RETURNING *`,
        [sku, name, quantity, warehouseLocation, reorderLevel, req.params.id]
      );
      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'item not found' });
      }
      res.json(toApiShape(result.rows[0]));
    } catch (err) {
      if (err.code === '23505') {
        return res.status(409).json({ error: 'sku already exists' });
      }
      next(err);
    }
  });

  router.delete('/items/:id', async (req, res, next) => {
    try {
      const result = await pool.query('DELETE FROM items WHERE id = $1 RETURNING id', [req.params.id]);
      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'item not found' });
      }
      res.status(204).send();
    } catch (err) {
      next(err);
    }
  });

  return router;
}

module.exports = { createItemsRouter, isValidItemPayload };
