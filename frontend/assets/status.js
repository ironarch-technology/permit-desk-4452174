requireSession();

const reference = new URLSearchParams(window.location.search).get('reference');
if (!reference) window.location.href = '/dashboard.html';

const dialog = document.getElementById('withdraw-dialog');
let application = null;

function labelled(rows, tbody) {
  tbody.replaceChildren();
  rows.forEach(([label, content]) => {
    const tr = document.createElement('tr');
    const th = document.createElement('th');
    th.setAttribute('scope', 'row');
    th.textContent = label;
    const td = document.createElement('td');
    if (content instanceof Node) td.append(content); else td.textContent = content;
    tr.append(th, td);
    tbody.append(tr);
  });
}

function renderSummary() {
  labelled([
    ['Reference', application.reference],
    ['Status', statusChip(application.state)],
    ['Property', application.address || 'No property selected'],
    ['Type of work', (application.work_type || '—').replace(/_/g, ' ')],
    ['Work described', application.scope_of_work || '—'],
    ['Declared value', money(application.declared_valuation_cents)],
    ['Submitted', shortDate(application.submitted_at)],
    ['Zoning result', application.zoning_result ? application.zoning_result.replace(/_/g, ' ') : 'Not yet returned'],
  ], document.querySelector('#summary tbody'));
}

function renderTimeline() {
  const tbody = document.querySelector('#timeline tbody');
  tbody.replaceChildren();

  application.timeline.forEach((entry) => {
    const tr = document.createElement('tr');
    [
      longDate(entry.at),
      entry.from ? entry.from.replace(/_/g, ' ') : '—',
      entry.to.replace(/_/g, ' '),
      `${entry.actor} (${entry.source})`,
      entry.reason || '—',
    ].forEach((text) => {
      const td = document.createElement('td');
      td.textContent = text;
      tr.append(td);
    });
    tbody.append(tr);
  });
}

function renderCorrections() {
  if (application.state !== 'corrections_required' || application.corrections.length === 0) return;

  const card = document.getElementById('corrections-card');
  const list = document.getElementById('corrections-list');
  list.replaceChildren();

  application.corrections.forEach((item) => {
    const li = document.createElement('li');

    const code = document.createElement('p');
    const strong = document.createElement('strong');
    strong.textContent = `${item.code}`;
    code.append(strong);

    const narrative = document.createElement('p');
    narrative.textContent = item.narrative;

    const citation = document.createElement('p');
    citation.className = 'muted';
    citation.textContent = item.citation ? `Code reference: ${item.citation}` : '';

    li.append(code, narrative, citation);
    list.append(li);
  });

  document.getElementById('respond-link').href =
    `/corrections.html?reference=${encodeURIComponent(application.reference)}`;
  card.hidden = false;
}

function renderFees() {
  if (!application.fee_quote || application.state !== 'fees_assessed') return;

  const quote = application.fee_quote;
  const tbody = document.querySelector('#fees tbody');
  tbody.replaceChildren();

  Object.entries(quote.breakdown || {}).forEach(([key, amount]) => {
    const tr = document.createElement('tr');
    const th = document.createElement('th');
    th.setAttribute('scope', 'row');
    th.textContent = key.replace(/_cents$/, '').replace(/_/g, ' ');
    const td = document.createElement('td');
    td.textContent = money(amount);
    tr.append(th, td);
    tbody.append(tr);
  });

  const total = document.createElement('tr');
  const totalTh = document.createElement('th');
  totalTh.setAttribute('scope', 'row');
  totalTh.textContent = 'Total due';
  const totalTd = document.createElement('td');
  const totalStrong = document.createElement('strong');
  totalStrong.textContent = money(quote.amount_cents);
  totalTd.append(totalStrong);
  total.append(totalTh, totalTd);
  tbody.append(total);

  document.getElementById('fee-expiry').textContent =
    `This quote is valid until ${shortDate(quote.expires_at)}.`;
  document.getElementById('fees-card').hidden = false;

  document.getElementById('pay-button').addEventListener('click', async () => {
    const button = document.getElementById('pay-button');
    button.disabled = true;
    await Portal.post(`/applications/${encodeURIComponent(application.reference)}/payment`, {
      amount_cents: quote.amount_cents,
    });
    button.textContent = 'Payment submitted — the permit will issue shortly';
  });
}

function renderPermit() {
  if (application.state !== 'issued') return;

  document.getElementById('permit-details').textContent =
    `Permit ${application.permit_number} was issued on ${shortDate(application.issued_at)} `
    + `and is valid until ${shortDate(application.valid_until)}.`;
  document.getElementById('inspections-link').href =
    `/inspections.html?reference=${encodeURIComponent(application.reference)}`;
  document.getElementById('permit-card').hidden = false;
}

function wireWithdraw() {
  const terminal = ['denied', 'withdrawn', 'expired'];
  if (terminal.includes(application.state)) return;

  document.getElementById('withdraw-card').hidden = false;

  document.getElementById('withdraw-button').addEventListener('click', () => dialog.showModal());
  document.getElementById('withdraw-cancel').addEventListener('click', () => dialog.close());
  document.getElementById('withdraw-confirm').addEventListener('click', async () => {
    const reason = document.getElementById('withdraw-reason').value.trim();
    dialog.close();
    await Portal.post(`/applications/${encodeURIComponent(application.reference)}/withdraw`, { reason });
    window.location.reload();
  });
}

(async () => {
  application = await Portal.get(`/applications/${encodeURIComponent(reference)}`);
  if (!application) return;

  document.title = `${application.reference} — Mountport Building Permit Portal`;
  document.getElementById('page-title').textContent = `Application ${application.reference}`;
  document.getElementById('subtitle').textContent = application.address || '';

  renderSummary();
  renderCorrections();
  renderFees();
  renderPermit();
  renderTimeline();
  wireWithdraw();
})();
