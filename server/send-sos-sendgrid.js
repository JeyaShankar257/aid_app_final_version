import express from 'express';
import { sendEmail, initSendGrid } from './sendgrid.js';

const router = express.Router();

// Initialize SendGrid if API key present
initSendGrid();

// POST /api/send-sos-email
router.post('/send-sos-email', async (req, res) => {
  const { recipients, message } = req.body;
  const from = process.env.SENDER_EMAIL || req.body.senderEmail;

  if (!recipients || !Array.isArray(recipients) || recipients.length === 0) {
    return res.status(400).json({ error: 'Missing recipients (array expected)' });
  }
  if (!message) {
    return res.status(400).json({ error: 'Missing message' });
  }
  if (!process.env.SENDGRID_API_KEY) {
    return res.status(500).json({ error: 'SendGrid not configured on server (SENDGRID_API_KEY missing)' });
  }
  if (!from) {
    return res.status(400).json({ error: 'Missing from address (SENDER_EMAIL env var or senderEmail in body)' });
  }

  try {
    await sendEmail({ from, to: recipients, subject: '🚨 SOS Alert', text: message, html: `<p>${message}</p>` });
    return res.json({ success: true });
  } catch (err) {
    console.error('SendGrid send error:', err?.message || err);
    return res.status(500).json({ error: 'Failed to send email', details: err?.message || String(err) });
  }
});

export default router;
