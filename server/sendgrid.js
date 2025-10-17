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
  return sgMail.send(msg);
}
