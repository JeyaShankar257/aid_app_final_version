import express from 'express';
import { body, validationResult } from 'express-validator';
import { sendEmail, initSendGrid } from './sendgrid.js';

const router = express.Router();

// Initialize SendGrid if API key present
initSendGrid();

// POST /api/send-sos-email
router.post('/send-sos-email',
  // validation middleware
  body('recipients').isArray({ min: 1 }).withMessage('recipients must be a non-empty array'),
  body('recipients.*').isEmail().withMessage('each recipient must be a valid email'),
  body('message').isString().isLength({ min: 1, max: 5000 }).withMessage('message is required and must be <= 5000 chars'),
  async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
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
    const sendResult = await sendEmail({ from, to: recipients, subject: '🚨 SOS Alert', text: message, html: `<p>${message}</p>` });
    return res.json({ success: true, sent: sendResult });
  } catch (err) {
    console.error('SendGrid send error:', err?.message || err);
    return res.status(500).json({ error: 'Failed to send email', details: err?.message || String(err) });
  }
});

export default router;
