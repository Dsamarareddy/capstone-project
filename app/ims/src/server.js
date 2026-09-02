const express = require('express');
const { createItemsRouter } = require('./routes/items');

function createApp(pool) {
  const app = express();
  app.use(express.json());

  app.get('/health', (req, res) => {
    res.json({ status: 'ok', service: 'ims', timestamp: new Date().toISOString() });
  });

  app.use(createItemsRouter(pool));

  // eslint-disable-next-line no-unused-vars
  app.use((err, req, res, next) => {
    console.error(err);
    res.status(500).json({ error: 'internal server error' });
  });

  return app;
}

if (require.main === module) {
  require('dotenv').config();
  const { createPoolFromEnv, migrate } = require('./db');
  const pool = createPoolFromEnv();
  const port = Number(process.env.PORT) || 3000;

  migrate(pool)
    .then(() => {
      const app = createApp(pool);
      app.listen(port, () => {
        console.log(`ims listening on port ${port}`);
      });
    })
    .catch((err) => {
      console.error('failed to run migrations', err);
      process.exit(1);
    });
}

module.exports = { createApp };
