// TODO(new-service): replace this skeleton with your real application routes.
const express = require('express');

const app = express();
app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'TODO-service-name', timestamp: new Date().toISOString() });
});

// TODO(new-service): add your routes here, e.g. app.use(require('./routes/whatever'));

if (require.main === module) {
  const port = Number(process.env.PORT) || 3000;
  app.listen(port, () => {
    console.log(`TODO-service-name listening on port ${port}`);
  });
}

module.exports = { app };
