const form = document.getElementById('signin-form');
const errorBox = document.getElementById('signin-error');
const errorText = document.getElementById('signin-error-text');

if (Portal.signedIn()) {
  window.location.href = '/dashboard.html';
}

form.addEventListener('submit', async (event) => {
  event.preventDefault();
  errorBox.hidden = true;

  const email = document.getElementById('email');
  const password = document.getElementById('password');

  if (!email.value.trim() || !password.value) {
    errorText.textContent = 'Enter both your email address and your password.';
    errorBox.hidden = false;
    errorBox.focus();
    return;
  }

  try {
    const response = await fetch('/api/sessions', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: email.value.trim(), password: password.value }),
    });

    if (!response.ok) {
      errorText.textContent = 'That email address and password do not match an account.';
      errorBox.hidden = false;
      errorBox.focus();
      return;
    }

    const payload = await response.json();
    Portal.store(payload.token, payload.account);
    window.location.href = '/dashboard.html';
  } catch (error) {
    errorText.textContent = 'The portal is not responding. Try again in a few minutes.';
    errorBox.hidden = false;
  }
});
