// Sample Express.js backend for sending SOS SMS using Twilio (CommonJS)
const express = require('express');
const router = express.Router();

const admin = require('firebase-admin');
// Initialize Firebase Admin SDK
const serviceAccount = require('../firebase-service-account.json'); // Place your service account file here
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}


router.post('/send-sos', async (req, res) => {
  const { tokens, message } = req.body;
  if (!tokens || !message) {
    return res.status(400).json({ error: 'Missing FCM tokens or message' });
  }
  const payload = {
    notification: {
      title: 'SOS Alert',
      body: message,
    },
    data: {
      type: 'SOS',
      message,
    }
  };
  try {
    const response = await admin.messaging().sendToDevice(tokens, payload);
    res.json({ success: true, response });
  } catch (err) {
    res.status(500).json({ error: 'Failed to send push notifications', details: err.message });
  }
});

module.exports = router;
