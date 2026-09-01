requireSession();

// Valuation bands published with the FY2026 fee schedule. Amounts are whole dollars
// here and converted to cents on submission.
const WORK_TYPES = [
  { value: 'residential_addition', label: 'Residential addition', min: 100, max: 2500000 },
  { value: 'residential_alteration', label: 'Residential alteration', min: 100, max: 750000 },
  { value: 'commercial_tenant_improvement', label: 'Commercial tenant improvement', min: 500, max: 10000000 },
  { value: 'reroof', label: 'Re-roof', min: 100, max: 150000 },
  { value: 'solar_photovoltaic', label: 'Solar photovoltaic', min: 100, max: 500000 },
  { value: 'demolition', label: 'Demolition', min: 100, max: 1000000 },
];

const form = document.getElementById('apply-form');
const summary = document.getElementById('error-summary');
const errorList = document.getElementById('error-list');
const grid = document.getElementById('work-types');

let selectedWorkType = null;
let currentStep = 1;

function buildWorkTypes() {
  WORK_TYPES.forEach((type) => {
    const choice = document.createElement('div');
    choice.className = 'choice';
    choice.setAttribute('role', 'button');
    choice.setAttribute('tabindex', '0');
    choice.dataset.value = type.value;
    choice.dataset.selected = 'false';

    const mark = document.createElement('span');
    mark.className = 'choice-mark';
    mark.textContent = '';

    const label = document.createElement('span');
    label.textContent = type.label;

    const band = document.createElement('span');
    band.className = 'hint';
    band.textContent = `Declared value $${type.min.toLocaleString()} to $${type.max.toLocaleString()}`;

    choice.append(mark, label, band);

    const choose = () => {
      grid.querySelectorAll('.choice').forEach((node) => {
        node.dataset.selected = 'false';
        node.querySelector('.choice-mark').textContent = '';
      });
      choice.dataset.selected = 'true';
      mark.textContent = '✓ ';
      selectedWorkType = type;
    };

    choice.addEventListener('click', choose);
    choice.addEventListener('keydown', (event) => {
      if (event.key === 'Enter' || event.key === ' ') {
        event.preventDefault();
        choose();
      }
    });

    grid.append(choice);
  });
}

function clearErrors() {
  summary.hidden = true;
  errorList.replaceChildren();
  document.querySelectorAll('.field-error').forEach((node) => {
    node.hidden = true;
    node.textContent = '';
  });
}

function showErrors(errors) {
  errorList.replaceChildren();

  errors.forEach((error) => {
    const item = document.createElement('li');
    item.textContent = error.message;
    errorList.append(item);

    if (error.field) {
      const target = document.getElementById(`${error.field}_error`);
      if (target) {
        target.textContent = error.message;
        target.hidden = false;
      }
    }
  });

  summary.hidden = false;
}

function goToStep(step) {
  currentStep = step;

  document.querySelectorAll('[data-panel]').forEach((panel) => {
    panel.hidden = Number(panel.dataset.panel) !== step;
  });

  document.querySelectorAll('#steps li').forEach((item) => {
    if (Number(item.dataset.step) === step) {
      item.setAttribute('aria-current', 'step');
    } else {
      item.removeAttribute('aria-current');
    }
  });

  const heading = document.getElementById(`heading-${step}`);
  if (heading) heading.focus();

  if (step === 4) renderReview();
}

function value(id) {
  const node = document.getElementById(id);
  return node ? node.value.trim() : '';
}

function validateStep(step) {
  const errors = [];

  if (step === 1 && !value('parcel_address')) {
    errors.push({ field: 'parcel_address', message: 'Enter the property address.' });
  }

  if (step === 2) {
    if (!selectedWorkType) {
      errors.push({ field: 'work_type', message: 'Choose the type of work.' });
    }
    if (!value('scope_of_work')) {
      errors.push({ field: 'scope_of_work', message: 'Describe the work you are proposing.' });
    }

    const amount = Number(value('declared_valuation'));
    if (!amount || amount <= 0) {
      errors.push({ field: 'declared_valuation', message: 'Enter the declared value of the work.' });
    } else if (selectedWorkType && (amount < selectedWorkType.min || amount > selectedWorkType.max)) {
      errors.push({
        field: 'declared_valuation',
        message: `For ${selectedWorkType.label.toLowerCase()}, the declared value must be between `
          + `$${selectedWorkType.min.toLocaleString()} and $${selectedWorkType.max.toLocaleString()}.`,
      });
    }
  }

  if (step === 3) {
    if (!value('applicant_name')) {
      errors.push({ field: 'applicant_name', message: 'Enter your full name.' });
    }
    if (!value('applicant_email')) {
      errors.push({ field: 'applicant_email', message: 'Enter your email address.' });
    }
    if (value('contractor_license_number') && !value('contractor_license_expires_on')) {
      errors.push({
        field: 'contractor_license_expires_on',
        message: 'Enter the expiry date shown on your contractor licence.',
      });
    }
  }

  return errors;
}

function renderReview() {
  const tbody = document.querySelector('#review-table tbody');
  tbody.replaceChildren();

  const rows = [
    ['Property address', value('parcel_address')],
    ['Type of work', selectedWorkType ? selectedWorkType.label : '—'],
    ['Work described', value('scope_of_work')],
    ['Declared value', value('declared_valuation') ? `$${Number(value('declared_valuation')).toLocaleString()}` : '—'],
    ['Name', value('applicant_name')],
    ['Email', value('applicant_email')],
    ['Phone', value('applicant_phone') || 'Not given'],
    ['Contractor licence', value('contractor_license_number') || 'Not a contractor application'],
  ];

  rows.forEach(([label, content]) => {
    const tr = document.createElement('tr');
    const th = document.createElement('th');
    th.setAttribute('scope', 'row');
    th.textContent = label;
    const td = document.createElement('td');
    td.textContent = content;
    tr.append(th, td);
    tbody.append(tr);
  });
}

function submissionKey() {
  return `sk-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 10)}`;
}

document.querySelectorAll('[data-advance]').forEach((button) => {
  button.addEventListener('click', () => {
    const target = Number(button.dataset.advance);
    clearErrors();

    if (target > currentStep) {
      const errors = validateStep(currentStep);
      if (errors.length > 0) {
        showErrors(errors);
        return;
      }
    }

    goToStep(target);
  });
});

form.addEventListener('submit', async (event) => {
  event.preventDefault();
  clearErrors();

  const button = document.getElementById('submit-button');
  button.disabled = true;

  try {
    const draft = await Portal.post('/applications', {
      parcel_address: value('parcel_address'),
      work_type: selectedWorkType ? selectedWorkType.value : null,
      scope_of_work: value('scope_of_work'),
      declared_valuation_cents: Math.round(Number(value('declared_valuation')) * 100),
      applicant_name: value('applicant_name'),
      applicant_email: value('applicant_email'),
      applicant_phone: value('applicant_phone'),
      contractor_license_number: value('contractor_license_number') || null,
      contractor_license_expires_on: value('contractor_license_expires_on') || null,
    });

    if (!draft) return;

    await Portal.post(`/applications/${encodeURIComponent(draft.reference)}/submit`, {
      parcel_address: value('parcel_address'),
      submission_key: submissionKey(),
    });

    window.location.href = `/status.html?reference=${encodeURIComponent(draft.reference)}`;
  } catch (error) {
    const messages = (error.payload && error.payload.error) || ['The application could not be submitted.'];
    showErrors((Array.isArray(messages) ? messages : [messages]).map((message) => ({ message })));
    button.disabled = false;
  }
});

buildWorkTypes();
goToStep(1);
