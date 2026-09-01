// Inspection Scheduler double.
//
// Slot search is a synchronous read against contended capacity, so a search result
// can be stale by the time a booking is attempted.
const { TOPICS, connect, serve, wait } = require('../lib/bus');

const PORT = Number(process.env.PORT || 4030);
const CONFIRM_MS = Number(process.env.SCHEDULING_CONFIRM_MS || 3000);

const CAPACITY = {
  central: 6,
  north: 4,
  south: 4,
  west: 3,
  waterfront: 2,
};

const taken = new Set();
let bus;

function slotsFor(inspectionType, district) {
  const perDay = CAPACITY[district] || 3;
  const slots = [];

  for (let day = 2; day <= 9; day += 1) {
    for (let index = 0; index < perDay; index += 1) {
      const start = new Date();
      start.setDate(start.getDate() + day);
      start.setHours(8 + index * 2, 0, 0, 0);

      const id = `slot-${district}-${start.toISOString().slice(0, 10)}-${8 + index * 2}`;
      if (taken.has(id)) continue;

      slots.push({
        slot_id: id,
        inspection_type: inspectionType,
        district,
        starts_at: start.toISOString(),
      });
    }
  }

  return slots.slice(0, 12);
}

async function confirm(slotId, reference, inspectionType) {
  await wait(CONFIRM_MS);

  await bus.publish(TOPICS.BOOKING_RESULTS, reference, {
    reference,
    slot_id: slotId,
    inspection_type: inspectionType,
    status: 'confirmed',
    scheduled_for: slotId.split('-').slice(2, 5).join('-'),
  });
}

const routes = [
  {
    method: 'GET',
    pattern: /^\/slots$/,
    handler: ({ query }) => {
      const inspectionType = query.get('inspection_type') || 'framing';
      const district = query.get('district') || 'central';
      return { status: 200, body: { slots: slotsFor(inspectionType, district) } };
    },
  },
  {
    method: 'POST',
    pattern: /^\/bookings$/,
    handler: ({ body }) => {
      if (taken.has(body.slot_id)) {
        return { status: 409, body: { error: 'slot already allocated' } };
      }

      taken.add(body.slot_id);
      confirm(body.slot_id, body.reference, body.inspection_type);

      return {
        status: 201,
        body: { slot_id: body.slot_id, status: 'requested' },
      };
    },
  },
];

async function main() {
  bus = await connect('scheduling', { consume: [], groupId: 'mountport-scheduling' });
  serve(PORT, routes);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
