requireSession();

const reference = new URLSearchParams(window.location.search).get('reference');
if (!reference) window.location.href = '/dashboard.html';

const tray = document.getElementById('slot-tray');
const dropzone = document.getElementById('dropzone');
const dropzoneLabel = document.getElementById('dropzone-label');
const confirmButton = document.getElementById('confirm-button');

let chosen = null;

function slotLabel(slot) {
  const starts = new Date(slot.starts_at);
  return starts.toLocaleString('en-US', {
    weekday: 'short', month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit',
  });
}

function renderSlots(slots) {
  tray.replaceChildren();

  slots.forEach((slot) => {
    const node = document.createElement('div');
    node.className = 'slot';
    node.draggable = true;
    node.dataset.slotId = slot.slot_id;
    node.dataset.label = slotLabel(slot);
    node.textContent = slotLabel(slot);

    node.addEventListener('dragstart', (event) => {
      event.dataTransfer.setData('text/plain', slot.slot_id);
      event.dataTransfer.setData('application/x-slot-label', slotLabel(slot));
    });

    tray.append(node);
  });

  document.getElementById('picker').hidden = false;
}

dropzone.addEventListener('dragover', (event) => {
  event.preventDefault();
});

dropzone.addEventListener('drop', (event) => {
  event.preventDefault();
  const slotId = event.dataTransfer.getData('text/plain');
  const label = event.dataTransfer.getData('application/x-slot-label');
  if (!slotId) return;

  chosen = slotId;
  dropzone.dataset.filled = 'true';
  dropzoneLabel.textContent = label || slotId;
  confirmButton.disabled = false;
});

document.getElementById('search-button').addEventListener('click', async () => {
  const inspectionType = document.getElementById('inspection_type').value;
  const payload = await Portal.get(
    `/applications/${encodeURIComponent(reference)}/inspections?inspection_type=${encodeURIComponent(inspectionType)}`,
  );
  if (!payload) return;
  renderSlots(payload.slots || []);
});

confirmButton.addEventListener('click', async () => {
  confirmButton.disabled = true;
  const inspectionType = document.getElementById('inspection_type').value;

  const payload = await Portal.post(`/applications/${encodeURIComponent(reference)}/inspections`, {
    slot_id: chosen,
    inspection_type: inspectionType,
  });

  const result = document.getElementById('result');
  const text = document.getElementById('result-text');

  if (payload && payload.status === 'slot_unavailable') {
    text.textContent = payload.message;
    renderSlots(payload.alternatives || []);
    chosen = null;
    dropzone.dataset.filled = 'false';
    dropzoneLabel.textContent = 'Drop an appointment here';
  } else if (payload && payload.booking) {
    text.textContent = `Appointment requested. The scheduler will confirm it shortly.`;
  }

  result.hidden = false;
});

(async () => {
  const application = await Portal.get(`/applications/${encodeURIComponent(reference)}`);
  if (!application) return;
  document.getElementById('subtitle').textContent =
    `Permit ${application.permit_number || application.reference} — ${application.address || ''}`;
})();
