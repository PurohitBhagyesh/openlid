// OpenLid Live Telemetry & Control Bridge

document.addEventListener('DOMContentLoaded', () => {
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

        statusHeading.textContent = isEnabled ? 'Engine Active: Awake' : 'Engine Inactive: Sleep Allowed';
        statusHeading.style.color = isEnabled ? 'var(--accent-emerald)' : 'var(--text-dim)';
        statusSub.textContent = 'Connected to local OpenLid process';
        toggleEngineBtn.textContent = isEnabled ? 'Disengage Bypass' : 'Engage Sleep Bypass';
        
        if (eyeStatusBadge) {
          eyeStatusBadge.style.color = isEnabled ? 'var(--accent-emerald)' : 'var(--text-muted)';
        }

        valLid.textContent = data.isLidClosed ? 'Closed' : 'Open';
        valPower.textContent = `${data.isOnACPower ? 'AC Power' : 'Battery'} (${data.batteryPercent}%${data.isCharging ? ' ⚡️' : ''})`;
        valThermal.textContent = data.thermalState || 'Nominal';
        valAssertion.textContent = isEnabled ? 'Active (Sleep Disabled)' : 'Inactive';
        valAssertion.style.color = isEnabled ? 'var(--accent-emerald)' : 'var(--text-muted)';
      }
    } catch (e) {
      // Local engine not running, show standby
      if (!isConnected) {
        statusHeading.textContent = 'Engine Standby';
        statusSub.textContent = 'Run OpenLid in menu bar to connect';
        valLid.textContent = 'Open';
        valPower.textContent = 'Battery (58%)';
        valThermal.textContent = 'Nominal (Cool)';
        valAssertion.textContent = 'Standby';
      }
    }
  }

  // Toggle button handler
  if (toggleEngineBtn) {
    toggleEngineBtn.addEventListener('click', async () => {
      try {
        await fetch('http://127.0.0.1:31415/api/toggle', { method: 'POST' });
        setTimeout(fetchTelemetry, 300);
      } catch (e) {
        isEnabled = !isEnabled;
        statusHeading.textContent = isEnabled ? 'Simulated: Awake' : 'Simulated: Sleep Allowed';
        valAssertion.textContent = isEnabled ? 'Active' : 'Inactive';
      }
    });
  }

  // Initial fetch and 2.5s poll
  fetchTelemetry();
  setInterval(fetchTelemetry, 2500);
});
