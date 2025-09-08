// Test script for /api/send-sos-email endpoint
// Usage: node server/test-send-sos-email.js

import fetch from 'node-fetch';

const API_URL = 'http://localhost:5000/api/send-sos-email';

const payload = {
  senderEmail: 'gonly7966@gmail.com', // <-- Replace with your Gmail
  appPassword: 'jethvrcumohcnubo',    // <-- Replace with your Gmail app password
  recipients: ['mjeyashankar189@gmail.com', 'mjeyashankar2005@gmail.com'], // <-- Replace with real emails
  message: 'Test SOS message from script.'
};

fetch(API_URL, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(payload)
})
  .then(res => res.json())
  .then(data => {
    console.log('Response:', data);
  })
  .catch(err => {
    console.error('Error:', err);
  });
