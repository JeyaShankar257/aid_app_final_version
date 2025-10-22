import pino from 'pino';

const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  redact: {
    paths: ['req.headers.authorization', 'req.body.recipients', 'req.body.message', 'req.body.senderEmail'],
    remove: true,
  },
  base: null,
});

export default logger;
