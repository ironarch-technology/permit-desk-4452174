// Parcel & Zoning Service double.
//
// Submission is asynchronous: the caller gets a handle straight away and the result
// is delivered on the callback once the parcel evaluation finishes. The index rebuild
// window is reproduced because integrations need to see it before they meet it.
const { TOPICS, connect, serve, postJson, wait } = require('../lib/bus');

const PORT = Number(process.env.PORT || 4010);
const PERMIT_DESK_URL = process.env.PERMIT_DESK_URL || 'http://api:3000';
const EVALUATION_MS = Number(process.env.ZONING_EVALUATION_MS || 6000);
const REBUILD_HOUR = Number(process.env.ZONING_REBUILD_HOUR || 2);
const REBUILD_MINUTES = Number(process.env.ZONING_REBUILD_MINUTES || 10);

// Parcels whose records the department knows are contested. Everything not listed
// here evaluates against the current zoning designation and passes.
const PARCEL_OUTCOMES = {
  '027-882-141': 'indeterminate',
  '019-455-023': 'not_permissible',
};

const REASONS = {
  permissible: 'work permissible under current zoning designation',
  not_permissible: 'proposed work is not permitted in this zoning district',
  indeterminate: 'parcel records conflict on the recorded lot line',
};

const checks = new Map();
let bus;

function rebuilding() {
  const now = new Date();
  return now.getHours() === REBUILD_HOUR && now.getMinutes() < REBUILD_MINUTES;
}

function outcomeFor(apn) {
  return PARCEL_OUTCOMES[apn] || 'permissible';
}

async function evaluate(handle) {
  const check = checks.get(handle);
  if (!check) return;

  await wait(EVALUATION_MS);

  check.status = 'complete';
  check.outcome = outcomeFor(check.apn);
  check.reason = REASONS[check.outcome];

  await postJson(`${PERMIT_DESK_URL}/hooks/zoning`, {
    reference: check.reference,
    handle,
    outcome: check.outcome,
    reason: check.reason,
  });
}

const routes = [
  {
    method: 'POST',
    pattern: /^\/checks$/,
    handler: ({ body }) => {
      if (rebuilding()) {
        return { status: 503, body: { error: 'parcel index rebuild in progress' } };
      }

      const handle = `zc-${Math.floor(Math.random() * 9000000) + 1000000}`;
      checks.set(handle, {
        reference: body.reference,
        apn: body.apn,
        work_type: body.work_type,
        status: 'pending',
      });

      evaluate(handle);
      return { status: 202, body: { handle, status: 'pending' } };
    },
  },
  {
    method: 'GET',
    pattern: /^\/checks\/([\w-]+)$/,
    handler: ({ params }) => {
      if (rebuilding()) {
        return { status: 503, body: { error: 'parcel index rebuild in progress' } };
      }

      const check = checks.get(params[0]);
      if (!check) return { status: 404, body: { error: 'unknown handle' } };

      return {
        status: 200,
        body: {
          handle: params[0],
          status: check.status,
          outcome: check.outcome || null,
          reason: check.reason || null,
        },
      };
    },
  },
];

async function main() {
  bus = await connect('zoning', {
    consume: [TOPICS.ZONING_CHECKS_REQUESTED],
    groupId: 'mountport-zoning',
  });

  await bus.listen(async (_topic, payload) => {
    if (!checks.has(payload.handle)) {
      checks.set(payload.handle, {
        reference: payload.reference,
        apn: payload.apn,
        work_type: payload.work_type,
        status: 'pending',
      });
    }
  });

  serve(PORT, routes);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
