// Express.js server setup for SOS API
// Save as server/index.js

import express from 'express';
import bodyParser from 'body-parser';
import cors from 'cors';
import sendSOSEmail from './send-sos-email.js';

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(bodyParser.json());

// Mount the SOS email route only
app.use('/api', sendSOSEmail);

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
