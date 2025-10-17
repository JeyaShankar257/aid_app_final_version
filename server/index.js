// Express.js server setup for SOS API
// Save as server/index.js

import express from 'express';
import bodyParser from 'body-parser';
import cors from 'cors';

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(bodyParser.json());

// Placeholder for the removed send-sos-email route.
// We keep a simple endpoint so the server does not break after deleting the old file.
import express from 'express';
const apiRouter = express.Router();
apiRouter.post('/send-sos-email', (req, res) => {
  res.status(501).json({ error: 'send-sos-email endpoint removed. Use SendGrid helper or implement a new handler.' });
});
app.use('/api', apiRouter);

app.get('/', (req, res) => {
  res.send('SOS API is running');
});

// Health check for cloud platforms
app.get('/health', (req, res) => {
  res.json({ ok: true, uptime: process.uptime() });
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Server running on port ${PORT}`);
});
