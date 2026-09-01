// Cashiering Service double.
//
// Fee calculation is synchronous against the published schedule. Payment capture is
// asynchronous and confirmed on the callback; card data never leaves this service.
const { TOPICS, connect, serve, postJson, wait } = require('../lib/bus');

const PORT = Number(process.env.PORT || 4040);
const PERMIT_DESK_URL = process.env.PERMIT_DESK_URL || 'http://api:3000';
const CAPTURE_MS = Number(process.env.CASHIERING_CAPTURE_MS || 4000);
const QUOTE_VALIDITY_DAYS = Number(process.env.CASHIERING_QUOTE_VALIDITY_DAYS || 30);

// FY2026 schedule, ordinance 2025-14.
const PLAN_CHECK_RATE = 0.0065;
const BASE_FEES = {
  residential_addition: 42500,
  residential_alteration: 28500,
  commercial_tenant_improvement: 96000,
  reroof: 14500,
  solar_photovoltaic: 18000,
  demolition: 33000,
};
const DISTRICT_SURCHARGE = {
  waterfront: 12500,
  central: 4500,
};

const quotes = new Map();
const payments = new Map();
let bus;

function calculate(workType, valuationCents, district) {
  const base = BASE_FEES[workType] || 25000;
  const planCheck = Math.round(valuationCents * PLAN_CHECK_RATE);
  const surcharge = DISTRICT_SURCHARGE[district] || 0;
  const technology = Math.round((base + planCheck) * 0.03);

  return {
    breakdown: {
      base_permit_fee_cents: base,
      plan_check_fee_cents: planCheck,
      district_surcharge_cents: surcharge,
      technology_fee_cents: technology,
    },
    amount_cents: base + planCheck + surcharge + technology,
  };
}

async function capture(paymentReference) {
  const payment = payments.get(paymentReference);
  if (!payment) return;

  await wait(CAPTURE_MS);
  payment.status = 'captured';

  await postJson(`${PERMIT_DESK_URL}/hooks/cashiering`, {
    reference: payment.reference,
    payment_reference: paymentReference,
    quote_reference: payment.quote_reference,
    status: 'captured',
    amount_cents: payment.amount_cents,
  });
}

const routes = [
  {
    method: 'POST',
    pattern: /^\/quotes$/,
    handler: ({ body }) => {
      const { breakdown, amount_cents: amountCents } = calculate(
        body.work_type,
        Number(body.valuation_cents || 0),
        body.district,
      );

      const reference = `FQ-${Math.floor(Math.random() * 900000) + 100000}`;
      const expiresAt = new Date(Date.now() + QUOTE_VALIDITY_DAYS * 86400000);

      quotes.set(reference, { application_reference: body.reference, amount_cents: amountCents });

      return {
        status: 201,
        body: {
          quote_reference: reference,
          amount_cents: amountCents,
          breakdown,
          expires_at: expiresAt.toISOString(),
        },
      };
    },
  },
  {
    method: 'POST',
    pattern: /^\/payments$/,
    handler: ({ body }) => {
      const quote = quotes.get(body.quote_reference);
      if (!quote) return { status: 404, body: { error: 'unknown quote' } };

      const reference = `PMT-${Math.floor(Math.random() * 900000) + 100000}`;
      payments.set(reference, {
        reference: quote.application_reference,
        quote_reference: body.quote_reference,
        amount_cents: body.amount_cents,
        status: 'pending',
      });

      capture(reference);

      return { status: 201, body: { payment_reference: reference, status: 'pending' } };
    },
  },
  {
    method: 'GET',
    pattern: /^\/payments\/([\w-]+)$/,
    handler: ({ params }) => {
      const payment = payments.get(params[0]);
      if (!payment) return { status: 404, body: { error: 'unknown payment' } };
      return { status: 200, body: { payment_reference: params[0], status: payment.status } };
    },
  },
];

async function main() {
  bus = await connect('cashiering', { consume: [], groupId: 'mountport-cashiering' });
  serve(PORT, routes);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
