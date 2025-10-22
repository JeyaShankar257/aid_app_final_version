import express from "express";
import nodemailer from "nodemailer";

const router = express.Router();

// Configure Brevo SMTP transporter using environment variables
const BREVO_SMTP_HOST = process.env.BREVO_SMTP_HOST || "smtp-relay.brevo.com";
const BREVO_SMTP_PORT = process.env.BREVO_SMTP_PORT ? parseInt(process.env.BREVO_SMTP_PORT, 10) : 587;
const BREVO_SMTP_USER = process.env.BREVO_SMTP_USER;
const BREVO_SMTP_PASS = process.env.BREVO_SMTP_PASS;
const BREVO_SENDER_EMAIL = process.env.BREVO_SENDER_EMAIL;

// basic runtime validation to give clearer errors
if (!BREVO_SMTP_USER || !BREVO_SMTP_PASS || !BREVO_SENDER_EMAIL) {
  console.warn('Brevo SMTP credentials not fully configured. Please set BREVO_SMTP_USER, BREVO_SMTP_PASS, and BREVO_SENDER_EMAIL');
}

const transporter = nodemailer.createTransport({
  host: BREVO_SMTP_HOST,
  port: BREVO_SMTP_PORT,
  auth: {
    user: BREVO_SMTP_USER,
    pass: BREVO_SMTP_PASS,
  },
});

// API endpoint to send SOS email
router.post("/send-sos-email", async (req, res) => {
  try {
    const { recipients, message } = req.body;

    if (!recipients || recipients.length === 0) {
      return res.status(400).json({ error: "No recipients provided" });
    }

    if (!BREVO_SMTP_USER || !BREVO_SMTP_PASS || !BREVO_SENDER_EMAIL) {
      return res.status(500).json({ error: 'Brevo credentials not configured on the server' });
    }

    const mailOptions = {
      from: BREVO_SENDER_EMAIL,
      to: recipients.join(","),
      subject: "🚨 SOS Alert from SafeGenie",
      text: message || "This is an emergency SOS alert. Immediate help needed.",
    };

    await transporter.sendMail(mailOptions);
    res.json({ success: true, message: "SOS email sent successfully" });
  } catch (error) {
    console.error("❌ Error sending email:", error);
    res.status(500).json({ error: "Failed to send SOS email" });
  }
});

export default router;
