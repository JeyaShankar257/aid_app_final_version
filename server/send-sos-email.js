import express from 'express';
import nodemailer from 'nodemailer';

const router = express.Router();

router.post('/send-sos-email', async (req, res) => {
  const { senderEmail, appPassword, recipients, message } = req.body;
  if (!senderEmail || !appPassword || !recipients || recipients.length < 2 || !message) {
    return res.status(400).json({ error: 'Missing required fields or not enough recipients' });
  }
  try {
    const transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: senderEmail,
        pass: appPassword,
      },
    });
    const mailOptions = {
      from: senderEmail,
      to: recipients,
      subject: '🚨 SOS Alert - Emergency Location Update',
      text: message,
    };
    await transporter.sendMail(mailOptions);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Failed to send email', details: err.message });
  }
});

export default router;
