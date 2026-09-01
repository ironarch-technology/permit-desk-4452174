# Permit Desk

Orchestration service behind the Mountport public permit portal. Development Services
staff call it "the desk". It takes a building permit application from intake through
zoning, plan review, corrections, fee calculation and payment, and issues the permit.

Permit Desk does not make any of the decisions. Four other city systems do that, and
this service is the thing that remembers where an application is and what happens next.

## What is in here

| Path | What it is |
|---|---|
| `api/` | Rails BFF. Owns the application record, the state machine, and the audit trail. |
| `frontend/` | The public portal and the front-counter screens. Static, served by nginx. |
| `services/` | Local stand-ins for the four city systems. Not deployed anywhere. |

## Running it

```
docker compose up --build
```

That brings up Postgres, a single-broker Kafka, the API, the bus worker, the portal, and
the four service doubles. First build takes a few minutes because the Ruby image compiles
the Kafka client.

The portal is at <http://localhost:8080>. Sign in with one of the development accounts:

| Account | Password | Role |
|---|---|---|
| `r.nakamura@example.com` | `portal-demo-2025` | Applicant |
| `ops@baywoodbuilders.example` | `portal-demo-2025` | Applicant (contractor) |
| `t.arriaga@mountport.gov.example` | `counter-demo-2025` | Permit technician |

Load the parcel fixtures and the example applications:

```
docker compose exec api rake db:seed
```

Tests:

```
docker compose run --rm api bundle exec rspec
```

Logs for the orchestration worker:

```
docker compose logs -f permit-desk-jobs
```

## Service topology

```
                    ┌──────────────┐
   browser ────────▶│  web (nginx) │
                    └──────┬───────┘
                           │ /api/*
                    ┌──────▼───────┐        ┌──────────────┐
                    │     api      │───────▶│  Postgres    │
                    └──────┬───────┘        └──────────────┘
                           │
                     Amazon MSK (Kafka)
                           │
          ┌────────────┬───┴────┬─────────────┬──────────────┐
          ▼            ▼        ▼             ▼              ▼
      bus-worker    zoning   review     scheduling      cashiering
```

Anything long-running goes over the bus. Anything the portal needs an answer to inside a
request goes over HTTP.

### Topics

| Topic | Produced by | Consumed by |
|---|---|---|
| `mountport.zoning.checks.requested` | api | zoning |
| `mountport.review.submissions` | api | review |
| `mountport.review.decisions` | review | bus-worker |
| `mountport.scheduling.bookings.settled` | scheduling | bus-worker |

Zoning and cashiering also call back over HTTP, because both were integrated before the
bus existed and neither team has moved yet.

### Ports

| Service | Port |
|---|---|
| portal | 8088 |
| api | 3000 (internal) |
| zoning | 4001 |
| review | 4020 |
| scheduling | 4030 |
| cashiering | 4040 |
| kafka | 9092 (internal) |
| postgres | 5432 (internal) |

## Application lifecycle

```
draft ──submit──────────────▶ submitted
submitted ──dispatch────────▶ zoning_check
zoning_check ──pass─────────▶ plan_review
zoning_check ──fail─────────▶ denied
zoning_check ──indeterminate▶ zoning_hold
zoning_hold ──resolve───────▶ plan_review | denied
plan_review ──approve───────▶ fees_assessed
plan_review ──deny──────────▶ denied
plan_review ──corrections───▶ corrections_required
corrections_required ──resubmit──▶ plan_review
fees_assessed ──payment─────▶ issued
issued ──validity lapsed────▶ expired

any non-terminal ──withdraw──▶ withdrawn
```

Every move is written to `transitions`, which is what the applicant sees as their status
history and what the department exports for its records.

## API

All routes are JSON. Applicant routes need a bearer token from `POST /sessions`.

### Sessions

```
POST   /sessions                      { email, password } -> { token, account }
```

### Applications

```
GET    /applications                            list your own applications
POST   /applications                            create a draft
GET    /applications/:reference                 full detail with timeline
PATCH  /applications/:reference                 edit a draft
DELETE /applications/:reference                 delete a draft
POST   /applications/:reference/submit          submit for review
POST   /applications/:reference/withdraw        withdraw
```

`submit` takes a `submission_key`. Send the same key again and you get the same
application back rather than a second one.

### Corrections, fees, inspections

```
GET    /applications/:reference/corrections     outstanding items for the current cycle
POST   /applications/:reference/corrections     { responses: [{ correction_item_id, body }] }
POST   /applications/:reference/payment         start payment against the current quote
GET    /applications/:reference/inspections     search slots
POST   /applications/:reference/inspections     request a booking
```

### Parcels and counter

```
GET    /parcels/lookup?q=                       address autocomplete
GET    /staff/searches?parcel=&applicant_name=&state=&from=&to=
POST   /staff/zoning_holds/:reference/resolve   { outcome: pass|fail, notes }
```

### Callbacks

```
POST   /hooks/zoning                            zoning check outcome
POST   /hooks/cashiering                        payment capture
```

### Health

```
GET    /health                                  database and bus reachability
```

## Working on the service doubles

The doubles reproduce the behaviour that actually causes trouble in integration, so
leave it in place:

- **zoning** takes several seconds to answer and returns `indeterminate` for parcels
  whose records conflict. It rebuilds its parcel index at 02:00 and returns `503` for
  ten minutes while it does.
- **review** returns corrections on the first cycle for anything over $50,000 and
  approves on the second.
- **scheduling** returns `409` when a slot is taken between search and booking.
- **cashiering** calculates against the FY2026 schedule and confirms capture on the
  callback a few seconds later.

Timings are compressed for local work. Override with `ZONING_EVALUATION_MS`,
`REVIEW_DURATION_MS`, `SCHEDULING_CONFIRM_MS`, and `CASHIERING_CAPTURE_MS`.

## Fee schedule

Ordinance 2025-14, effective FY2026. Base fee by work type, plus 0.65% plan check on
declared value, plus a district surcharge where one applies, plus a 3% technology fee.
Quotes expire after 30 days because the schedule changes by ordinance each fiscal year.
