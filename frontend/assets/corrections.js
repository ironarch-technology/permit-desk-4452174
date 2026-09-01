requireSession();

const reference = new URLSearchParams(window.location.search).get('reference');
if (!reference) window.location.href = '/dashboard.html';

const form = document.getElementById('corrections-form');
const list = document.getElementById('items');
const summary = document.getElementById('error-summary');
const errorList = document.getElementById('error-list');

let items = [];

function render() {
  list.replaceChildren();

  items.forEach((item) => {
    const li = document.createElement('li');

    const heading = document.createElement('h2');
    heading.style.fontSize = '1.05rem';
    heading.style.marginTop = '0';
    heading.textContent = item.code;

    const narrative = document.createElement('p');
    narrative.textContent = item.narrative;

    const citation = document.createElement('p');
    citation.className = 'muted';
    citation.textContent = item.citation ? `Code reference: ${item.citation}` : '';

    const field = document.createElement('div');
    field.className = 'field';

    const label = document.createElement('label');
    label.setAttribute('for', `response-${item.id}`);
    label.textContent = 'How you have addressed this';

    const textarea = document.createElement('textarea');
    textarea.id = `response-${item.id}`;
    textarea.dataset.itemId = item.id;
    if (item.response) textarea.value = item.response;

    field.append(label, textarea);
    li.append(heading, narrative, citation, field);
    list.append(li);
  });
}

form.addEventListener('submit', async (event) => {
  event.preventDefault();
  summary.hidden = true;
  errorList.replaceChildren();

  const responses = Array.from(list.querySelectorAll('textarea'))
    .map((node) => ({ correction_item_id: Number(node.dataset.itemId), body: node.value.trim() }));

  const blank = responses.filter((entry) => !entry.body);
  if (blank.length > 0) {
    const li = document.createElement('li');
    li.textContent = 'Respond to every correction item before sending.';
    errorList.append(li);
    summary.hidden = false;
    summary.setAttribute('tabindex', '-1');
    summary.focus();
    return;
  }

  await Portal.post(`/applications/${encodeURIComponent(reference)}/corrections`, { responses });
  window.location.href = `/status.html?reference=${encodeURIComponent(reference)}`;
});

(async () => {
  const payload = await Portal.get(`/applications/${encodeURIComponent(reference)}/corrections`);
  if (!payload) return;

  document.getElementById('subtitle').textContent =
    `Application ${payload.reference} — review cycle ${payload.cycle + 1}`;
  items = payload.items;
  render();
})();
