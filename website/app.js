// OpenLid Client Engine & Aesthetic Scroll Interaction

document.addEventListener('DOMContentLoaded', () => {
  'use strict';

  // 1. Top Aesthetic Scroll Progress Bar
  const progressBar = document.getElementById('scrollProgressBar');
  window.addEventListener('scroll', () => {
    const scrollTop = window.scrollY || document.documentElement.scrollTop;
    const docHeight = document.documentElement.scrollHeight - window.innerHeight;
    if (docHeight > 0 && progressBar) {
      const percent = Math.min(100, Math.max(0, (scrollTop / docHeight) * 100));
      progressBar.style.width = percent + '%';
    }
  }, { passive: true });

  // 2. IntersectionObserver for Silky Scroll Reveals
  const revealElements = document.querySelectorAll('.reveal-on-scroll');
  if ('IntersectionObserver' in window) {
    const revealObserver = new IntersectionObserver((entries, obs) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('is-revealed');
          obs.unobserve(entry.target);
        }
      });
    }, {
      threshold: 0.08,
      rootMargin: '0px 0px -50px 0px'
    });

    revealElements.forEach(el => revealObserver.observe(el));
  } else {
    revealElements.forEach(el => el.classList.add('is-revealed'));
  }

  // 3. Dynamic Mouse Spotlight Glow on Cards
  const interactiveCards = document.querySelectorAll('.download-card, .spec-card, .three-card, .live-status-card');
  interactiveCards.forEach(card => {
    card.addEventListener('mousemove', (e) => {
      const rect = card.getBoundingClientRect();
      const x = e.clientX - rect.left;
      const y = e.clientY - rect.top;
      card.style.background = `radial-gradient(450px circle at ${x}px ${y}px, rgba(16, 185, 129, 0.07), var(--bg-card) 75%)`;
    });

    card.addEventListener('mouseleave', () => {
      card.style.background = '';
    });
  });

  // 4. Local Menu Bar Engine Bridge (127.0.0.1:31415)
  const statusHeading = document.getElementById('statusHeading');
  const statusSub = document.getElementById('statusSub');
  const toggleEngineBtn = document.getElementById('toggleEngineBtn');
  const eyeStatusBadge = document.getElementById('eyeStatusBadge');
  const valLid = document.getElementById('valLid');
  const valPower = document.getElementById('valPower');
  const valThermal = document.getElementById('valThermal');
  const valAssertion = document.getElementById('valAssertion');

  let isEnabled = true;
  let isConnected = false;

  async function fetchTelemetry() {
    try {
      const res = await fetch('http://127.0.0.1:31415/api/status');
      if (res.ok) {
        const data = await res.json();
        isConnected = true;
        isEnabled = data.isEnabled;

        if (statusHeading) {
          statusHeading.textContent = isEnabled ? 'Engine Active: Awake' : 'Engine Inactive: Sleep Allowed';
          statusHeading.style.color = isEnabled ? 'var(--accent-emerald-bright)' : 'var(--text-dim)';
        }
        if (statusSub) statusSub.textContent = 'Connected to local OpenLid menu bar app';
        if (toggleEngineBtn) toggleEngineBtn.textContent = isEnabled ? 'Disengage Bypass' : 'Engage Sleep Bypass';
        
        if (eyeStatusBadge) {
          eyeStatusBadge.style.color = isEnabled ? 'var(--accent-emerald)' : 'var(--text-muted)';
        }

        if (valLid) valLid.textContent = data.isLidClosed ? 'Closed' : 'Open';
        if (valPower) valPower.textContent = `${data.isOnACPower ? 'AC Power' : 'Battery'} (${data.batteryPercent}%${data.isCharging ? ' ⚡️' : ''})`;
        if (valThermal) valThermal.textContent = data.thermalState || 'Nominal (Cool)';
        if (valAssertion) {
          valAssertion.textContent = isEnabled ? 'Active (Sleep Disabled)' : 'Inactive';
          valAssertion.style.color = isEnabled ? 'var(--accent-emerald-bright)' : 'var(--text-muted)';
        }
      }
    } catch (e) {
      if (!isConnected) {
        if (statusHeading) statusHeading.textContent = 'Engine Standby';
        if (statusSub) statusSub.textContent = 'Run OpenLid in menu bar to connect';
        if (valLid) valLid.textContent = 'Open';
        if (valPower) valPower.textContent = 'Battery (58%)';
        if (valThermal) valThermal.textContent = 'Nominal (Cool)';
        if (valAssertion) valAssertion.textContent = 'Standby';
      }
    }
  }

  if (toggleEngineBtn) {
    toggleEngineBtn.addEventListener('click', async () => {
      try {
        await fetch('http://127.0.0.1:31415/api/toggle', { method: 'POST' });
        setTimeout(fetchTelemetry, 250);
      } catch (e) {
        isEnabled = !isEnabled;
        if (statusHeading) {
          statusHeading.textContent = isEnabled ? 'Simulated: Awake' : 'Simulated: Sleep Allowed';
          statusHeading.style.color = isEnabled ? 'var(--accent-emerald-bright)' : 'var(--text-dim)';
        }
        if (valAssertion) valAssertion.textContent = isEnabled ? 'Active' : 'Inactive';
      }
    });
  }

  fetchTelemetry();
  setInterval(fetchTelemetry, 2500);
});
