// Sample Express.js backend for sending SOS SMS using Twilio
// Save as src/api/send-sos.js or server/send-sos.js (adjust for your backend structure)

import express from 'express';
import twilio from 'twilio';

const router = express.Router();

// Replace with your Twilio credentials
const accountSid = process.env.TWILIO_ACCOUNT_SID;
const authToken = process.env.TWILIO_AUTH_TOKEN;
const fromNumber = process.env.TWILIO_PHONE_NUMBER;
const client = twilio(accountSid, authToken);

router.post('/send-sos', async (req, res) => {
  const { contacts, message } = req.body;
  if (!contacts || !message) {
    return res.status(400).json({ error: 'Missing contacts or message' });
  }
  try {
    const results = await Promise.all(
      contacts.map(phone =>
        client.messages.create({
          body: message,
          from: fromNumber,
          to: phone
        })
      )
    );
    res.json({ success: true, results });
  } catch (err) {
    res.status(500).json({ error: 'Failed to send messages', details: err.message });
  }
});

export default router;
