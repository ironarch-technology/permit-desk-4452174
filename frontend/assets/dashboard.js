requireSession();

const tbody = document.querySelector('#applications tbody');
const empty = document.getElementById('empty');
const greeting = document.getElementById('greeting');

function row(application) {
  const tr = document.createElement('tr');

  const ref = document.createElement('td');
  const link = document.createElement('a');
  link.href = `/status.html?reference=${encodeURIComponent(application.reference)}`;
  link.textContent = application.reference;
  ref.append(link);

  const address = document.createElement('td');
  address.textContent = application.address || 'No property selected';

  const work = document.createElement('td');
  work.textContent = (application.work_type || '—').replace(/_/g, ' ');

  const state = document.createElement('td');
  state.append(statusChip(application.state));

  const updated = document.createElement('td');
  updated.textContent = shortDate(application.updated_at);

  tr.append(ref, address, work, state, updated);
  return tr;
}

(async () => {
  const account = Portal.account();
  if (account) greeting.textContent = `Signed in as ${account.name}.`;

  const applications = await Portal.get('/applications');
  if (!applications) return;

  if (applications.length === 0) {
    document.getElementById('applications').hidden = true;
    empty.hidden = false;
    return;
  }

  applications.forEach((application) => tbody.append(row(application)));
})();
