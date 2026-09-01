// Shared portal transport. The bearer token lives in sessionStorage so a closed tab
// ends the session.
const TOKEN_KEY = 'permit-desk-token';
const ACCOUNT_KEY = 'permit-desk-account';

const Portal = {
  token() {
    return sessionStorage.getItem(TOKEN_KEY);
  },

  account() {
    const raw = sessionStorage.getItem(ACCOUNT_KEY);
    return raw ? JSON.parse(raw) : null;
  },

  signedIn() {
    return Boolean(this.token());
  },

  store(token, account) {
    sessionStorage.setItem(TOKEN_KEY, token);
    sessionStorage.setItem(ACCOUNT_KEY, JSON.stringify(account));
  },

  clear() {
    sessionStorage.removeItem(TOKEN_KEY);
    sessionStorage.removeItem(ACCOUNT_KEY);
  },

  async request(method, path, body) {
    const headers = { 'Content-Type': 'application/json' };
    const token = this.token();
    if (token) headers.Authorization = `Bearer ${token}`;

    const response = await fetch(`/api${path}`, {
      method,
      headers,
      body: body === undefined ? undefined : JSON.stringify(body),
    });

    if (response.status === 401) {
      Portal.clear();
      window.location.href = '/index.html';
      return null;
    }

    const text = await response.text();
    const payload = text ? JSON.parse(text) : null;

    if (!response.ok) {
      const error = new Error('request failed');
      error.status = response.status;
      error.payload = payload;
      throw error;
    }

    return payload;
  },

  get(path) { return this.request('GET', path); },
  post(path, body) { return this.request('POST', path, body); },
  patch(path, body) { return this.request('PATCH', path, body); },
  del(path) { return this.request('DELETE', path); },
};

const STATE_LABELS = {
  draft: 'Draft',
  submitted: 'Submitted',
  zoning_check: 'Zoning check',
  zoning_hold: 'Zoning hold',
  plan_review: 'In plan review',
  corrections_required: 'Corrections required',
  fees_assessed: 'Fees due',
  issued: 'Issued',
  denied: 'Denied',
  withdrawn: 'Withdrawn',
  expired: 'Expired',
};

const STATE_MARKS = {
  issued: '✓',
  denied: '✕',
  withdrawn: '✕',
  expired: '✕',
  corrections_required: '⚠',
  zoning_hold: '⚠',
};

function statusChip(state) {
  const span = document.createElement('span');
  span.className = `status status-${state}`;

  const mark = document.createElement('span');
  mark.setAttribute('aria-hidden', 'true');
  mark.textContent = STATE_MARKS[state] || '●';

  const label = document.createElement('span');
  label.textContent = STATE_LABELS[state] || state;

  span.append(mark, label);
  return span;
}

function money(cents) {
  if (cents === null || cents === undefined) return '—';
  return `$${(cents / 100).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
}

function shortDate(value) {
  if (!value) return '—';
  return new Date(value).toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });
}

function longDate(value) {
  if (!value) return '—';
  return new Date(value).toLocaleString('en-US', {
    year: 'numeric', month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit',
  });
}

function requireSession() {
  if (!Portal.signedIn()) {
    window.location.href = '/index.html';
  }
}
