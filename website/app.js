// OpenLid Interactive Web Simulator & Remote Awake Controller

document.addEventListener('DOMContentLoaded', () => {
  // State
  let isEyeActive = true;
  let isLidClosed = false;

  // DOM Elements - Simulator
  const simEyeBtn = document.getElementById('simEyeBtn');
  const simEyeText = document.getElementById('simEyeText');
  const macbookVisual = document.getElementById('macbookVisual');
  const laptopGraphic = document.getElementById('laptopGraphic');
  const lidBadge = document.getElementById('lidBadge');
  const macbookStatusTitle = document.getElementById('macbookStatusTitle');
  const macbookStatusDesc = document.getElementById('macbookStatusDesc');
  const toggleLidBtn = document.getElementById('toggleLidBtn');
  const termLogs = document.getElementById('termLogs');
  const heroTrySimulatorBtn = document.getElementById('heroTrySimulatorBtn');

  // DOM Elements - Modal & Login
  const loginModal = document.getElementById('loginModal');
  const openLoginBtn = document.getElementById('openLoginBtn');
  const closeModalBtn = document.getElementById('closeModalBtn');
  const loginFormView = document.getElementById('loginFormView');
  const remoteDashboardView = document.getElementById('remoteDashboardView');
  const authForm = document.getElementById('authForm');
  const signOutBtn = document.getElementById('signOutBtn');
  const remoteEyeBtn = document.getElementById('remoteEyeBtn');
  const remoteStatusText = document.getElementById('remoteStatusText');

  // Append terminal line helper
  function addTermLog(text, colorClass = '') {
    const line = document.createElement('div');
    line.className = `term-line ${colorClass}`;
    line.textContent = text;
    termLogs.appendChild(line);
    termLogs.scrollTop = termLogs.scrollHeight;
  }

  // Live Engine Synchronization (if local OpenLid app is running)
  let liveEngineConnected = false;
  async function syncWithLocalEngine() {
    try {
      const res = await fetch('http://127.0.0.1:31415/api/status', { method: 'GET' });
      if (res.ok) {
        const data = await res.json();
        if (!liveEngineConnected) {
          liveEngineConnected = true;
          addTermLog('🔗 Connected to local OpenLid engine (127.0.0.1:31415)', 'green');
        }
        isEyeActive = data.isEnabled;
        isLidClosed = data.isLidClosed;
        updateSimulator();
      }
    } catch (e) {
      liveEngineConnected = false;
    }
  }

  syncWithLocalEngine();
  setInterval(syncWithLocalEngine, 2500);

  async function sendEngineToggle() {
    try {
      await fetch('http://127.0.0.1:31415/api/toggle', { method: 'POST' });
      setTimeout(syncWithLocalEngine, 300);
    } catch (e) {}
  }

  // Update simulator UI based on state
  function updateSimulator() {
    // 1. Eye Button state
    if (isEyeActive) {
      simEyeBtn.classList.add('active');
      simEyeText.textContent = 'Eye Vigilant';
    } else {
      simEyeBtn.classList.remove('active');
      simEyeText.textContent = 'Eye Asleep';
    }

    // 2. MacBook state
    if (isLidClosed) {
      toggleLidBtn.textContent = 'Open MacBook Lid';
      macbookVisual.classList.add('lid-closed');

      if (isEyeActive) {
        laptopGraphic.textContent = '🔒⚡️';
        lidBadge.className = 'lid-state-badge badge-closed-awake';
        lidBadge.textContent = '🔒 Lid Closed (Awake & Running)';
        macbookStatusTitle.textContent = 'MacBook Awake in Clamshell Mode';
        macbookStatusDesc.textContent = 'Display is off to save power, but CPU & network remain active.';
        addTermLog('⚡️ [IOPMrootDomain] Lid closed: Sleep bypassed by OpenLid. All processes continuing.', 'green');
      } else {
        laptopGraphic.textContent = '💤';
        lidBadge.className = 'lid-state-badge badge-closed-asleep';
        lidBadge.textContent = '💤 Lid Closed (Asleep)';
        macbookStatusTitle.textContent = 'MacBook in Sleep Mode';
        macbookStatusDesc.textContent = 'Normal macOS sleep active. Background tasks paused.';
        addTermLog('💤 [Kernel] Lid closed without OpenLid: Entering standard system sleep (S3).', 'muted');
      }
    } else {
      toggleLidBtn.textContent = 'Close MacBook Lid';
      macbookVisual.classList.remove('lid-closed');
      laptopGraphic.textContent = '💻';
      lidBadge.className = 'lid-state-badge badge-open';
      lidBadge.textContent = '📖 Lid Open';
      macbookStatusTitle.textContent = 'MacBook Running';
      macbookStatusDesc.textContent = 'Display is on, tasks running normally.';
      addTermLog('📖 [IOPMrootDomain] Clamshell opened: Display back on.', 'cyan');
    }
  }

  // Event Listeners - Simulator
  simEyeBtn.addEventListener('click', () => {
    isEyeActive = !isEyeActive;
    sendEngineToggle();
    if (isEyeActive) {
      addTermLog('▶ OpenLid Eye symbol engaged: macOS sleep prevention active', 'green');
    } else {
      addTermLog('⏸ OpenLid Eye symbol disengaged: Restored default macOS sleep', 'muted');
    }
    updateSimulator();
  });

  toggleLidBtn.addEventListener('click', () => {
    isLidClosed = !isLidClosed;
    updateSimulator();
  });

  if (heroTrySimulatorBtn) {
    heroTrySimulatorBtn.addEventListener('click', () => {
      document.getElementById('simulator').scrollIntoView({ behavior: 'smooth' });
    });
  }

  // Modal Controls
  function openModal() {
    loginModal.classList.add('open');
  }

  function closeModal() {
    loginModal.classList.remove('open');
  }

  openLoginBtn.addEventListener('click', openModal);
  closeModalBtn.addEventListener('click', closeModal);
  loginModal.addEventListener('click', (e) => {
    if (e.target === loginModal) closeModal();
  });

  // Auth Form Submit -> Open Remote Dashboard
  authForm.addEventListener('submit', (e) => {
    e.preventDefault();
    loginFormView.style.display = 'none';
    remoteDashboardView.classList.add('visible');
    addTermLog('🔑 User authenticated via Web Portal. Connected to Bhagyesh’s MacBook Pro.', 'cyan');
  });

  signOutBtn.addEventListener('click', () => {
    remoteDashboardView.classList.remove('visible');
    loginFormView.style.display = 'block';
  });

  // Remote Eye Toggle in Cloud Dashboard
  remoteEyeBtn.addEventListener('click', () => {
    isEyeActive = !isEyeActive;
    sendEngineToggle();
    if (isEyeActive) {
      remoteEyeBtn.classList.add('active');
      remoteStatusText.textContent = 'Mac is AWAKE';
      remoteStatusText.style.color = 'var(--accent-green)';
      addTermLog('🌐 [Remote Portal] Awaken signal delivered to MacBook Pro! Eye engaged.', 'green');
    } else {
      remoteEyeBtn.classList.remove('active');
      remoteStatusText.textContent = 'Mac is ASLEEP';
      remoteStatusText.style.color = 'var(--text-muted)';
      addTermLog('🌐 [Remote Portal] Sleep signal delivered to MacBook Pro! Eye disengaged.', 'muted');
    }
    updateSimulator();
  });
});

