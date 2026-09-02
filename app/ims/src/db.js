const { Pool } = require('pg');

const SCHEMA_SQL = `
CREATE TABLE IF NOT EXISTS items (
  id SERIAL PRIMARY KEY,
  sku TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 0,
  warehouse_location TEXT NOT NULL,
  reorder_level INTEGER NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
`;

function createPoolFromEnv() {
  return new Pool({
    host: process.env.PGHOST || 'localhost',
    port: Number(process.env.PGPORT) || 5432,
    user: process.env.PGUSER || 'ims',
    password: process.env.PGPASSWORD || 'ims',
    database: process.env.PGDATABASE || 'ims',
  });
}

async function migrate(pool) {
  await pool.query(SCHEMA_SQL);
}

module.exports = { createPoolFromEnv, migrate, SCHEMA_SQL };
