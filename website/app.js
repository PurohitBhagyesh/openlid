// OpenLid Web Engine — Eye Theme Switcher & System Integration

document.addEventListener('DOMContentLoaded', () => {
  'use strict';

  // 1. The Eye Symbol Theme Switcher (Dark & Light Mode)
  const themeToggleBtn = document.getElementById('themeToggleBtn');
  const themeLabel = document.getElementById('themeLabel');
  const currentTheme = localStorage.getItem('openlid_theme') || 
                       (window.matchMedia('(prefers-color-scheme: light)').matches ? 'light' : 'dark');

  function applyTheme(theme) {
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem('openlid_theme', theme);
    if (themeLabel) {
      themeLabel.textContent = theme === 'dark' ? 'Dark Mode' : 'Light Mode';
    }
  }

  // Initial Theme
  applyTheme(currentTheme);

  if (themeToggleBtn) {
    themeToggleBtn.addEventListener('click', () => {
      const activeTheme = document.documentElement.getAttribute('data-theme') || 'dark';
      const newTheme = activeTheme === 'dark' ? 'light' : 'dark';
      
      // Animate eye blink
      themeToggleBtn.style.transform = 'scale(0.92)';
      setTimeout(() => {
        applyTheme(newTheme);
        themeToggleBtn.style.transform = 'scale(1)';
      }, 100);
    });
  }

  // 2. Top Scroll Progress Bar
  const progressBar = document.getElementById('scrollProgressBar');
  window.addEventListener('scroll', () => {
    const scrollTop = window.scrollY || document.documentElement.scrollTop;
    const docHeight = document.documentElement.scrollHeight - window.innerHeight;
    if (docHeight > 0 && progressBar) {
      const percent = Math.min(100, Math.max(0, (scrollTop / docHeight) * 100));
      progressBar.style.width = percent + '%';
    }
  }, { passive: true });

  // 3. Cross-Platform OS Switcher (macOS vs Windows)
  const btnTabMac = document.getElementById('btnTabMac');
  const btnTabWin = document.getElementById('btnTabWin');
  const panelMac = document.getElementById('panelMac');
  const panelWin = document.getElementById('panelWin');

  if (btnTabMac && btnTabWin && panelMac && panelWin) {
    btnTabMac.addEventListener('click', () => {
      btnTabMac.classList.add('active');
      btnTabWin.classList.remove('active');
      panelMac.classList.add('active');
      panelWin.classList.remove('active');
    });

    btnTabWin.addEventListener('click', () => {
      btnTabWin.classList.add('active');
      btnTabMac.classList.remove('active');
      panelWin.classList.add('active');
      panelMac.classList.remove('active');
    });

    // Auto-detect OS
    if ((navigator.userAgent || '').includes('Win')) {
      btnTabWin.click();
    }
  }

  // 4. Live Connection to Local OpenLid Engine (127.0.0.1:31415)
  const statusHeading = document.getElementById('statusHeading');
  const statusSub = document.getElementById('statusSub');
  const toggleEngineBtn = document.getElementById('toggleEngineBtn');
  const valLid = document.getElementById('valLid');
  const valPower = document.getElementById('valPower');
  const valThermal = document.getElementById('valThermal');
  const valAssertion = document.getElementById('valAssertion');

  let isEnabled = true;

  async function fetchTelemetry() {
    try {
      const res = await fetch('http://127.0.0.1:31415/api/status');
      if (res.ok) {
        const data = await res.json();
        isEnabled = data.isEnabled;

        if (statusHeading) {
          statusHeading.textContent = isEnabled ? 'Engine Active: Awake' : 'Engine Standby: Sleep Allowed';
          statusHeading.style.color = isEnabled ? 'var(--accent-emerald)' : 'var(--text-dim)';
        }
        if (statusSub) statusSub.textContent = 'Connected to local OpenLid menu bar app';
        if (toggleEngineBtn) toggleEngineBtn.textContent = isEnabled ? 'Disengage Bypass' : 'Engage Sleep Bypass';
        
        if (valLid) valLid.textContent = data.isLidClosed ? 'Closed 🔒' : 'Open 📖';
        if (valPower) valPower.textContent = `${data.isOnACPower ? 'AC Connected' : 'Battery'} (${data.batteryPercent}%${data.isCharging ? ' ⚡️' : ''})`;
        if (valThermal) valThermal.textContent = data.thermalState || 'Nominal';
        if (valAssertion) {
          valAssertion.textContent = isEnabled ? 'Active (Awake)' : 'Inactive';
          valAssertion.style.color = isEnabled ? 'var(--accent-emerald)' : 'var(--text-muted)';
        }
      }
    } catch (e) {
      // Local engine standby
      if (statusHeading) statusHeading.textContent = 'Local Engine Standby';
      if (statusSub) statusSub.textContent = 'Launch OpenLid in menu bar to connect';
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
          statusHeading.textContent = isEnabled ? 'Engine Active: Awake' : 'Engine Standby: Sleep Allowed';
        }
        if (valAssertion) valAssertion.textContent = isEnabled ? 'Active' : 'Inactive';
      }
    });
  }

  fetchTelemetry();
  setInterval(fetchTelemetry, 2000);
});
