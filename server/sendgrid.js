import sgMail from '@sendgrid/mail';

// Initializes sendgrid with the API key from env
export function initSendGrid() {
  const key = process.env.SENDGRID_API_KEY;
  if (!key) {
    console.warn('SENDGRID_API_KEY not set — SendGrid disabled');
    return false;
  }
  sgMail.setApiKey(key);
  return true;
}

export async function sendEmail({ from, to, subject, text, html }) {
  // If dry run is enabled, simulate sending without calling SendGrid
  if (process.env.SENDGRID_DRY_RUN === 'true') {
    // normalize recipients to array
    const recipients = Array.isArray(to) ? to : [to];
    // create a fake response per recipient
    const simulated = recipients.map((rcpt) => ({
      statusCode: 202,
      headers: {
        'x-message-id': `dry-${Math.random().toString(36).slice(2, 12)}`,
        'x-simulated': 'true',
      },
    }));
    return simulated;
  }

  if (!process.env.SENDGRID_API_KEY) {
    throw new Error('SendGrid API key not configured');
  }

  const msg = {
    to,
    from,
    subject,
    text,
    html,
  };

  // send returns an array of response objects; return that so callers can inspect ids/status
  const res = await sgMail.send(msg);
  // map to a smaller shape: status and headers (which include 'x-message-id' for some providers)
  return res.map(r => ({ statusCode: r.statusCode, headers: r.headers }));
}
