requireSession();

const form = document.getElementById('search-form');
const tbody = document.querySelector('#results tbody');
const count = document.getElementById('result-count');
const holds = document.getElementById('holds');

function row(result) {
  const tr = document.createElement('tr');

  const ref = document.createElement('td');
  ref.textContent = result.reference;

  const applicant = document.createElement('td');
  applicant.textContent = `${result.applicant_name || '—'} (${result.applicant_email || 'no email'})`;

  const address = document.createElement('td');
  address.textContent = result.address || '—';

  const state = document.createElement('td');
  state.append(statusChip(result.state));

  const created = document.createElement('td');
  created.textContent = shortDate(result.created_at);

  tr.append(ref, applicant, address, state, created);
  return tr;
}

async function search() {
  const params = new URLSearchParams();
  ['parcel', 'applicant_name', 'state', 'from', 'to'].forEach((id) => {
    const value = document.getElementById(id).value.trim();
    if (value) params.set(id, value);
  });

  const payload = await Portal.get(`/staff/searches?${params.toString()}`);
  if (!payload) return;

  tbody.replaceChildren();
  payload.results.forEach((result) => tbody.append(row(result)));
  count.textContent = `${payload.count} application${payload.count === 1 ? '' : 's'} found.`;

  renderHolds(payload.results.filter((result) => result.state === 'zoning_hold'));
}

function renderHolds(rows) {
  holds.replaceChildren();

  if (rows.length === 0) {
    const li = document.createElement('li');
    li.textContent = 'No applications are waiting on a zoning decision.';
    holds.append(li);
    return;
  }

  rows.forEach((result) => {
    const li = document.createElement('li');

    const heading = document.createElement('p');
    const strong = document.createElement('strong');
    strong.textContent = result.reference;
    heading.append(strong);

    const address = document.createElement('p');
    address.textContent = result.address || '—';

    const field = document.createElement('div');
    field.className = 'field';
    const label = document.createElement('label');
    label.setAttribute('for', `notes-${result.reference}`);
    label.textContent = 'Decision notes';
    const notes = document.createElement('input');
    notes.type = 'text';
    notes.id = `notes-${result.reference}`;
    field.append(label, notes);

    const actions = document.createElement('div');
    actions.className = 'row';

    const pass = document.createElement('button');
    pass.type = 'button';
    pass.textContent = 'Clear to plan review';
    pass.addEventListener('click', () => resolve(result.reference, 'pass', notes.value));

    const fail = document.createElement('button');
    fail.type = 'button';
    fail.className = 'secondary';
    fail.textContent = 'Deny';
    fail.addEventListener('click', () => resolve(result.reference, 'fail', notes.value));

    actions.append(pass, fail);
    li.append(heading, address, field, actions);
    holds.append(li);
  });
}

async function resolve(reference, outcome, notes) {
  await Portal.post(`/staff/zoning_holds/${encodeURIComponent(reference)}/resolve`, { outcome, notes });
  search();
}

form.addEventListener('submit', (event) => {
  event.preventDefault();
  search();
});

search();
