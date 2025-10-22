// Express.js server setup for SOS API
// Save as server/index.js
import 'dotenv/config';
import express from 'express';
import bodyParser from 'body-parser';
import cors from 'cors';
import rateLimit from 'express-rate-limit';
import * as Sentry from '@sentry/node';
import logger from './logger.js';
import crypto from 'crypto';

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(bodyParser.json());

// Initialize Sentry if DSN provided
if (process.env.SENTRY_DSN) {
  Sentry.init({
    dsn: process.env.SENTRY_DSN,
    environment: process.env.NODE_ENV || 'development',
    tracesSampleRate: parseFloat(process.env.SENTRY_TRACES_RATE || '0.0'),
  });
  // request handler must be the first middleware for Sentry
  app.use(Sentry.Handlers.requestHandler());
  app.use(Sentry.Handlers.tracingHandler());
}

// request id middleware
app.use((req, res, next) => {
  req.id = req.headers['x-request-id'] || crypto.randomUUID();
  res.setHeader('X-Request-Id', req.id);
  next();
});

// request logging
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    logger.info({ method: req.method, path: req.path, status: res.statusCode, durationMs: Date.now() - start, requestId: req.id }, 'request_finished');
  });
  next();
});

// Basic rate limiter for API endpoints to prevent abuse (adjust window/max as needed)
const apiLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: process.env.RATE_LIMIT_MAX ? parseInt(process.env.RATE_LIMIT_MAX, 10) : 20,
  standardHeaders: true,
  legacyHeaders: false,
});

// Placeholder for the removed send-sos-email route.
// We keep a simple endpoint so the server does not break after deleting the old file.

//import sendSosSendGrid from './send-sos-sendgrid.js';
import sendSosBrevo from './send-sos-brevo.js';


// Mount the SendGrid-backed send-sos route with rate limiting
//app.use('/api', apiLimiter, sendSosSendGrid);
app.use('/api', apiLimiter, sendSosBrevo);

app.get('/', (req, res) => {
  res.send('SOS API is running');
});

// Health check for cloud platforms
app.get('/health', (req, res) => {
  res.json({ ok: true, uptime: process.uptime() });
});

// error handler (capture to Sentry and redact sensitive fields)
app.use((err, req, res, next) => {
  const safeBody = {
    messageLength: req.body?.message?.length ?? 0,
    recipientsCount: Array.isArray(req.body?.recipients) ? req.body.recipients.length : 0,
  };

  logger.error({ err, req: { method: req.method, path: req.path, id: req.id }, body: safeBody }, 'unhandled_error');

  if (process.env.SENTRY_DSN) {
    Sentry.withScope(scope => {
      scope.setTag('route', req.path);
      scope.setExtra('body', safeBody);
      Sentry.captureException(err);
    });
  }

  res.status(500).json({ error: 'Internal Server Error', requestId: req.id });
});

app.listen(PORT, '0.0.0.0', () => {
  logger.info({ port: PORT }, 'server_started');
});
