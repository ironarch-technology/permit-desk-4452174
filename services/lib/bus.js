const { Kafka, logLevel } = require('kafkajs');

const TOPICS = {
  ZONING_CHECKS_REQUESTED: 'mountport.zoning.checks.requested',
  REVIEW_SUBMISSIONS: 'mountport.review.submissions',
  REVIEW_DECISIONS: 'mountport.review.decisions',
  QUOTE_REQUESTS: 'mountport.cashiering.quotes.requested',
  QUOTES_ISSUED: 'mountport.cashiering.quotes.issued',
  BOOKING_REQUESTS: 'mountport.scheduling.bookings.requested',
  BOOKING_RESULTS: 'mountport.scheduling.bookings.settled',
};

function client(serviceName) {
  return new Kafka({
    clientId: `mountport-${serviceName}`,
    brokers: (process.env.KAFKA_BROKERS || 'kafka:9092').split(','),
    logLevel: logLevel.NOTHING,
    retry: { initialRetryTime: 500, retries: 12 },
  });
}

// Every service declares the whole topic set at boot. createTopics is a no-op for
// topics that already exist, so whichever service starts first wins.
async function ensureTopics(kafka) {
  const admin = kafka.admin();
  await admin.connect();
  await admin.createTopics({
    topics: Object.values(TOPICS).map((topic) => ({
      topic,
      numPartitions: 3,
      replicationFactor: 1,
    })),
    waitForLeaders: true,
  });
  await admin.disconnect();
}

async function connect(serviceName, { consume = [], groupId = null } = {}) {
  const kafka = client(serviceName);
  await ensureTopics(kafka);

  const producer = kafka.producer();
  await producer.connect();

  let consumer = null;
  if (consume.length > 0) {
    consumer = kafka.consumer({ groupId: groupId || `mountport-${serviceName}` });
    await consumer.connect();
    for (const topic of consume) {
      await consumer.subscribe({ topic, fromBeginning: false });
    }
  }

  return {
    async publish(topic, key, payload) {
      await producer.send({
        topic,
        messages: [{ key: String(key), value: JSON.stringify(payload) }],
      });
      console.log(`published topic=${topic} key=${key}`);
    },
    async listen(handler) {
      if (!consumer) return;
      await consumer.run({
        eachMessage: async ({ topic, message }) => {
          const payload = JSON.parse(message.value.toString());
          console.log(`consumed topic=${topic} key=${message.key}`);
          await handler(topic, payload);
        },
      });
    },
  };
}

function serve(port, routes) {
  const http = require('http');

  const server = http.createServer((req, res) => {
    const url = new URL(req.url, `http://localhost:${port}`);
    let body = '';
    req.on('data', (chunk) => { body += chunk; });
    req.on('end', () => {
      const send = (status, payload) => {
        res.writeHead(status, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(payload));
      };

      const match = routes.find((route) => route.method === req.method && route.pattern.test(url.pathname));
      if (!match) return send(404, { error: 'no such route' });

      const params = url.pathname.match(match.pattern).slice(1);
      let parsed = {};
      if (body) {
        try { parsed = JSON.parse(body); } catch (e) { return send(400, { error: 'malformed json' }); }
      }

      Promise.resolve(match.handler({ params, query: url.searchParams, body: parsed }))
        .then((result) => send(result.status || 200, result.body))
        .catch((error) => {
          console.error(error);
          send(500, { error: 'internal error' });
        });
    });
  });

  server.listen(port, () => console.log(`listening on ${port}`));
  return server;
}

async function postJson(url, payload) {
  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });
  console.log(`callback ${url} -> ${response.status}`);
  return response.status;
}

const wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

module.exports = { TOPICS, connect, serve, postJson, wait, ensureTopics };
