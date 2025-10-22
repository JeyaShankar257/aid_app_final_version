import express from "express";
import nodemailer from "nodemailer";
import net from 'net';
import axios from 'axios';

const router = express.Router();

// Configure Brevo SMTP transporter using environment variables
const BREVO_SMTP_HOST = process.env.BREVO_SMTP_HOST || "smtp-relay.brevo.com";
const BREVO_SMTP_PORT = process.env.BREVO_SMTP_PORT ? parseInt(process.env.BREVO_SMTP_PORT, 10) : 587;
const BREVO_SMTP_USER = process.env.BREVO_SMTP_USER;
const BREVO_SMTP_PASS = process.env.BREVO_SMTP_PASS;
const BREVO_SENDER_EMAIL = process.env.BREVO_SENDER_EMAIL;

// Optional: Brevo HTTP API key (prefer this on cloud platforms where SMTP may be blocked)
const BREVO_API_KEY = process.env.BREVO_API_KEY;

// basic runtime validation to give clearer errors
if (!BREVO_SMTP_USER || !BREVO_SMTP_PASS || !BREVO_SENDER_EMAIL) {
  console.warn('Brevo SMTP credentials not fully configured. Please set BREVO_SMTP_USER, BREVO_SMTP_PASS, and BREVO_SENDER_EMAIL');
}

// Configure transporter with a reasonable connection timeout. Port 587 expects STARTTLS (secure: false).
const transporter = nodemailer.createTransport({
  host: BREVO_SMTP_HOST,
  port: BREVO_SMTP_PORT,
  secure: false, // use STARTTLS on port 587
  requireTLS: true,
  auth: {
    user: BREVO_SMTP_USER,
    pass: BREVO_SMTP_PASS,
  },
  connectionTimeout: 10000,
});

// helper: send via Brevo HTTP API
async function sendViaBrevoHttp(recipients, message) {
  const url = 'https://api.brevo.com/v3/smtp/email';
  const payload = {
    sender: { email: BREVO_SENDER_EMAIL },
    to: recipients.map(r => ({ email: r })),
    subject: '🚨 SOS Alert from SafeGenie',
    textContent: message || 'This is an emergency SOS alert. Immediate help needed.',
  };
  const headers = {
    'api-key': BREVO_API_KEY,
    'Content-Type': 'application/json',
  };
  const resp = await axios.post(url, payload, { headers, timeout: 10000 });
  return resp.data;
}

// API endpoint to send SOS email
router.post("/send-sos-email", async (req, res) => {
  try {
    const { recipients, message } = req.body;

    if (!recipients || recipients.length === 0) {
      return res.status(400).json({ error: "No recipients provided" });
    }

    // Prefer HTTP API if API key is configured (avoids SMTP port blocks on some hosts)
    if (BREVO_API_KEY) {
      if (!BREVO_SENDER_EMAIL) {
        return res.status(500).json({ error: 'BREVO_SENDER_EMAIL not configured' });
      }
      await sendViaBrevoHttp(recipients, message);
      return res.json({ success: true, via: 'brevo_http', message: 'SOS email sent successfully' });
    }

    // Fallback to SMTP transporter
    if (!BREVO_SMTP_USER || !BREVO_SMTP_PASS || !BREVO_SENDER_EMAIL) {
      return res.status(500).json({ error: 'Brevo SMTP credentials not configured on the server' });
    }

    const mailOptions = {
      from: BREVO_SENDER_EMAIL,
      to: recipients.join(","),
      subject: "🚨 SOS Alert from SafeGenie",
      text: message || "This is an emergency SOS alert. Immediate help needed.",
    };

    await transporter.sendMail(mailOptions);
    res.json({ success: true, via: 'smtp', message: "SOS email sent successfully" });
  } catch (error) {
    console.error("❌ Error sending email:", error);
    res.status(500).json({ error: "Failed to send SOS email" });
  }
});

export default router;

// Debug route: check basic TCP connectivity from this server to the configured SMTP host/port.
// Useful to invoke on Render to see whether the platform allows outbound connections to Brevo.
router.get('/debug/smtp-check', async (req, res) => {
  const host = BREVO_SMTP_HOST;
  const port = BREVO_SMTP_PORT;
  const socket = new net.Socket();
  let settled = false;

  const clean = (status, info) => {
    if (settled) return;
    settled = true;
    socket.destroy();
    res.json({ ok: status, info });
  };

  socket.setTimeout(8000);
  socket.once('error', (err) => clean(false, { error: err.message }));
  socket.once('timeout', () => clean(false, { error: 'timeout' }));
  socket.connect(port, host, () => {
    clean(true, { host, port, message: 'tcp_connect_ok' });
  });
});
