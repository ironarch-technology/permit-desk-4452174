// Plan Review Service double.
//
// Submissions arrive on the bus and are queued to a reviewer. Small jobs clear on the
// first pass; anything larger picks up corrections on its first cycle, which is what
// the counter sees in practice.
const { TOPICS, connect, serve, wait } = require('../lib/bus');

const PORT = Number(process.env.PORT || 4020);
const REVIEW_MS = Number(process.env.REVIEW_DURATION_MS || 12000);
const FIRST_PASS_CEILING_CENTS = Number(process.env.REVIEW_FIRST_PASS_CEILING_CENTS || 5000000);

const CORRECTION_SETS = [
  {
    code: 'ACC-04',
    narrative: 'Restroom clear floor space at the water closet is dimensioned at 54 inches. '
      + 'Provide 60 inches minimum and revise the plan sheet.',
    citation: 'ICC A117.1 604.3.1',
  },
  {
    code: 'EGR-11',
    narrative: 'Exit sign locations are not shown on the reflected ceiling plan. Add locations '
      + 'and photometric coverage for the rear corridor.',
    citation: 'IBC 1013.1',
  },
];

const queue = new Map();
let bus;

function decide(payload) {
  const cycle = Number(payload.cycle || 0);
  const valuation = Number(payload.valuation_cents || 0);

  if (cycle > 0 || payload.resubmission) {
    return { outcome: 'approved', reason: 'corrections satisfied' };
  }

  if (valuation > 0 && valuation <= FIRST_PASS_CEILING_CENTS) {
    return { outcome: 'approved', reason: 'reviewed and approved as submitted' };
  }

  return { outcome: 'corrections_required', items: CORRECTION_SETS };
}

async function review(payload) {
  queue.set(payload.reference, { cycle: payload.cycle, received_at: new Date().toISOString() });

  await wait(REVIEW_MS);

  const decision = decide(payload);
  queue.delete(payload.reference);

  await bus.publish(TOPICS.REVIEW_DECISIONS, payload.reference, {
    reference: payload.reference,
    cycle: payload.cycle,
    ...decision,
  });
}

const routes = [
  {
    method: 'GET',
    pattern: /^\/queue$/,
    handler: () => ({ status: 200, body: { depth: queue.size } }),
  },
  {
    method: 'GET',
    pattern: /^\/submissions\/([\w-]+)$/,
    handler: ({ params }) => {
      const entry = queue.get(params[0]);
      if (!entry) return { status: 404, body: { error: 'not in the review queue' } };
      return { status: 200, body: { reference: params[0], ...entry } };
    },
  },
];

async function main() {
  bus = await connect('review', {
    consume: [TOPICS.REVIEW_SUBMISSIONS],
    groupId: 'mountport-review',
  });

  await bus.listen(async (_topic, payload) => { await review(payload); });

  serve(PORT, routes);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
