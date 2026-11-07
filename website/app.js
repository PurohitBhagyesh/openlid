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
  const progressBar = document.getElementById('scrollLine') || document.getElementById('scrollProgressBar');
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

  // 4. Live Connection & Demonstration of OpenLid Engine
  const statusHeading = document.getElementById('statusHeading');
  const statusSub = document.getElementById('statusSub');
  const toggleEngineBtn = document.getElementById('toggleEngineBtn');
  const monitorEyeWrap = document.getElementById('monitorEyeWrap');
  const valLid = document.getElementById('valLid');
  const valPower = document.getElementById('valPower');
  const valThermal = document.getElementById('valThermal');
  const valAssertion = document.getElementById('valAssertion');

  let isEnabled = true;

  async function fetchTelemetry() {
    // Only attempt localhost HTTP fetch on localhost or plain HTTP to avoid browser mixed-content blocks
    if (window.location.protocol === 'http:' && (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1')) {
      try {
        const res = await fetch('http://127.0.0.1:31415/api/status');
        if (res.ok) {
          const data = await res.json();
          isEnabled = data.isEnabled;

          if (statusHeading) {
            statusHeading.textContent = isEnabled ? 'Engine Active: Awake' : 'Engine Standby: Sleep Allowed';
            statusHeading.style.color = isEnabled ? 'var(--accent-emerald)' : 'var(--text-dim)';
          }
          if (monitorEyeWrap) monitorEyeWrap.classList.toggle('asleep', !isEnabled);
          if (statusSub) statusSub.textContent = 'Connected to local OpenLid process';
          if (toggleEngineBtn) toggleEngineBtn.textContent = isEnabled ? 'Disengage Bypass' : 'Engage Sleep Bypass';
          
          if (valLid) valLid.textContent = data.isLidClosed ? 'Closed' : 'Open';
          if (valPower) valPower.textContent = `${data.isOnACPower ? 'AC Connected' : 'Battery'} (${data.batteryPercent}%${data.isCharging ? ' Charging' : ''})`;
          if (valThermal) valThermal.textContent = data.thermalState || 'Nominal';
          if (valAssertion) {
            valAssertion.textContent = isEnabled ? 'Active (Awake)' : 'Inactive';
            valAssertion.style.color = isEnabled ? 'var(--accent)' : 'var(--text-muted)';
          }
          return;
        }
      } catch (e) {
        // Fall through to display simulated active telemetry
      }
    }

    // Default active engine status for HTTPS / Web preview
    if (statusHeading) {
      statusHeading.textContent = isEnabled ? 'Engine Active: Awake' : 'Engine Standby: Sleep Allowed';
      statusHeading.style.color = isEnabled ? 'var(--accent-emerald)' : 'var(--text-dim)';
    }
    if (monitorEyeWrap) monitorEyeWrap.classList.toggle('asleep', !isEnabled);
    if (statusSub) statusSub.textContent = 'Native menu bar utility • Clamshell sleep prevention enabled';
    if (toggleEngineBtn) toggleEngineBtn.textContent = isEnabled ? 'Disengage Bypass' : 'Engage Sleep Bypass';
    if (valLid) valLid.textContent = 'Monitored (Closed Bypass)';
    if (valPower) valPower.textContent = 'AC & Battery Guard Active';
    if (valThermal) valThermal.textContent = 'Nominal (Cool)';
    if (valAssertion) {
      valAssertion.textContent = isEnabled ? 'Active (Awake)' : 'Inactive';
      valAssertion.style.color = isEnabled ? 'var(--accent)' : 'var(--text-muted)';
    }
  }

  if (toggleEngineBtn) {
    toggleEngineBtn.addEventListener('click', async () => {
      if (window.location.protocol === 'http:' && (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1')) {
        try {
          await fetch('http://127.0.0.1:31415/api/toggle', { method: 'POST' });
          setTimeout(fetchTelemetry, 250);
          return;
        } catch (e) {}
      }
      
      isEnabled = !isEnabled;
      fetchTelemetry();
    });
  }

  // 5. Buy me a Coffee / Support Widget Logic (Bottom-Left Corner)
  const snackWidget = document.getElementById('snackWidget');
  const snackPillBtn = document.getElementById('snackPillBtn');
  const snackCard = document.getElementById('snackCard');
  const snackCloseBtn = document.getElementById('snackCloseBtn');
  const snackAmountInput = document.getElementById('snackAmountInput');
  const snackPresets = document.getElementById('snackPresets');
  const snackQrImg = document.getElementById('snackQrImg');
  const snackUpiLink = document.getElementById('snackUpiLink');
  const snackUpiCopyBtn = document.getElementById('snackUpiCopyBtn');
  const snackUpiText = document.getElementById('snackUpiText');

  const UPI_ID = 'Purohit2009@fam';
  const PAYEE_NAME = 'Shivam';

  function updateSnackQr(amount) {
    const amt = Math.max(1, parseInt(amount, 10) || 50);
    const upiUri = `upi://pay?pa=${UPI_ID}&pn=${encodeURIComponent(PAYEE_NAME)}&am=${amt}&cu=INR`;
    if (snackQrImg) {
      snackQrImg.src = `https://api.qrserver.com/v1/create-qr-code/?size=180x180&format=svg&data=${encodeURIComponent(upiUri)}`;
    }
    if (snackUpiLink) {
      snackUpiLink.href = upiUri;
    }
  }

  let snackHoverTimer = null;
  function openSnack() {
    clearTimeout(snackHoverTimer);
    if (snackCard) {
      snackCard.classList.add('active');
      snackPillBtn.setAttribute('aria-expanded', 'true');
      if (snackAmountInput) updateSnackQr(snackAmountInput.value || 50);
    }
  }

  function closeSnackWithDelay() {
    snackHoverTimer = setTimeout(() => {
      if (snackCard && !snackCard.matches(':hover') && !snackPillBtn.matches(':hover')) {
        snackCard.classList.remove('active');
        snackPillBtn.setAttribute('aria-expanded', 'false');
      }
    }, 280);
  }

  if (snackPillBtn && snackCard) {
    // Hover-to-open on desktop fine pointer devices
    if (snackWidget) {
      snackWidget.addEventListener('mouseenter', openSnack);
      snackWidget.addEventListener('mouseleave', closeSnackWithDelay);
    }

    // Click/tap toggle for mobile and keyboard
    snackPillBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      const isActive = snackCard.classList.toggle('active');
      snackPillBtn.setAttribute('aria-expanded', String(isActive));
      if (isActive && snackAmountInput) {
        updateSnackQr(snackAmountInput.value || 50);
      }
    });

    if (snackCloseBtn) {
      snackCloseBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        snackCard.classList.remove('active');
        snackPillBtn.setAttribute('aria-expanded', 'false');
      });
    }

    // Close when clicking outside
    document.addEventListener('click', (e) => {
      if (snackWidget && !snackWidget.contains(e.target) && snackCard.classList.contains('active')) {
        snackCard.classList.remove('active');
        snackPillBtn.setAttribute('aria-expanded', 'false');
      }
    });

    // Close on Escape
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && snackCard.classList.contains('active')) {
        snackCard.classList.remove('active');
        snackPillBtn.setAttribute('aria-expanded', 'false');
      }
    });
  }

  // Quick Preset Chips
  if (snackPresets && snackAmountInput) {
    snackPresets.addEventListener('click', (e) => {
      const chip = e.target.closest('.preset-chip');
      if (!chip) return;
      const amt = chip.getAttribute('data-amt');
      snackAmountInput.value = amt;
      snackPresets.querySelectorAll('.preset-chip').forEach(b => b.classList.remove('active'));
      chip.classList.add('active');
      updateSnackQr(amt);
    });

    snackAmountInput.addEventListener('input', () => {
      const currentVal = snackAmountInput.value;
      if (snackPresets) {
        snackPresets.querySelectorAll('.preset-chip').forEach(b => {
          b.classList.toggle('active', b.getAttribute('data-amt') === currentVal);
        });
      }
      updateSnackQr(currentVal);
    });
  }

  // Copy UPI ID
  if (snackUpiCopyBtn && snackUpiText) {
    snackUpiCopyBtn.addEventListener('click', async (e) => {
      e.stopPropagation();
      try {
        await navigator.clipboard.writeText(UPI_ID);
        const originalText = snackUpiText.textContent;
        snackUpiText.textContent = 'Copied!';
        setTimeout(() => {
          snackUpiText.textContent = originalText;
        }, 1500);
      } catch (err) {
        console.error('Clipboard copy failed:', err);
      }
    });
  }

  // Initial QR render
  updateSnackQr(50);

  // Handle UPI Payments & Multi-App Chooser
  const btnPayViaUpi = document.getElementById('btnPayViaUpi');
  const noUpiAlert = document.getElementById('noUpiAlert');
  const noUpiDesc = document.getElementById('noUpiDesc');
  const btnCloseNoUpi = document.getElementById('btnCloseNoUpi');
  const upiAppButtons = document.querySelectorAll('.upi-app-btn');

  if (btnCloseNoUpi && noUpiAlert) {
    btnCloseNoUpi.addEventListener('click', () => {
      noUpiAlert.style.display = 'none';
    });
  }

  function launchSpecificUpi(scheme, appName) {
    const amt = Math.max(1, parseInt(snackAmountInput ? snackAmountInput.value : 50, 10) || 50);
    const query = `pa=${UPI_ID}&pn=${encodeURIComponent(PAYEE_NAME)}&am=${amt}&cu=INR`;
    let targetUri = '';

    switch (scheme) {
      case 'fampay':
        targetUri = `fampay://upi/pay?${query}`;
        break;
      case 'amazonpay':
        targetUri = `amazonpay://upi/pay?${query}`;
        break;
      case 'phonepe':
        targetUri = `phonepe://pay?${query}`;
        break;
      case 'gpay':
        targetUri = `tez://upi/pay?${query}`;
        break;
      case 'paytm':
        targetUri = `paytmmp://pay?${query}`;
        break;
      case 'whatsapp':
        targetUri = `whatsapp://pay?${query}`;
        break;
      default:
        targetUri = `upi://pay?${query}`;
        break;
    }

    if (noUpiAlert) noUpiAlert.style.display = 'none';

    const isMobile = /Android|iPhone|iPad|iPod/i.test(navigator.userAgent || '');

    if (!isMobile) {
      if (noUpiAlert && noUpiDesc) {
        noUpiDesc.textContent = `No ${appName} is installed on this computer. Please scan the QR code above with ${appName} or Google Pay on your phone, or copy the UPI ID.`;
        noUpiAlert.style.display = 'flex';
        noUpiAlert.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
      }
      return;
    }

    let appOpened = false;
    let fallbackTimer = null;

    const onAppOpen = () => {
      appOpened = true;
      clearTimeout(fallbackTimer);
      window.removeEventListener('blur', onAppOpen);
      document.removeEventListener('visibilitychange', onVisibilityChange);
      window.removeEventListener('pagehide', onAppOpen);
    };

    const onVisibilityChange = () => {
      if (document.hidden) onAppOpen();
    };

    window.addEventListener('blur', onAppOpen);
    window.addEventListener('pagehide', onAppOpen);
    document.addEventListener('visibilitychange', onVisibilityChange);

    // Trigger specific app URL scheme
    window.location.href = targetUri;

    fallbackTimer = setTimeout(() => {
      window.removeEventListener('blur', onAppOpen);
      window.removeEventListener('pagehide', onAppOpen);
      document.removeEventListener('visibilitychange', onVisibilityChange);

      if (!appOpened && !document.hidden && document.hasFocus()) {
        if (noUpiAlert && noUpiDesc) {
          noUpiDesc.textContent = `Could not open ${appName}. If it is not installed on your phone, please try another app above or scan the QR code.`;
          noUpiAlert.style.display = 'flex';
          noUpiAlert.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
        }
      }
    }, 1800);
  }

  upiAppButtons.forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.preventDefault();
      const scheme = btn.getAttribute('data-scheme');
      const name = btn.getAttribute('data-name') || 'UPI App';
      launchSpecificUpi(scheme, name);
    });
  });

  if (btnPayViaUpi) {
    btnPayViaUpi.addEventListener('click', () => {
      launchSpecificUpi('upi', 'UPI App');
    });
  }

  // 6. Mobile Navigation Drawer Toggle
  const navToggleBtn = document.getElementById('navToggleBtn');
  const mobileDrawer = document.getElementById('mobileDrawer');

  if (navToggleBtn && mobileDrawer) {
    navToggleBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      const isOpen = mobileDrawer.classList.toggle('open');
      navToggleBtn.setAttribute('aria-expanded', String(isOpen));
    });

    mobileDrawer.querySelectorAll('.mobile-nav-item').forEach(link => {
      link.addEventListener('click', () => {
        mobileDrawer.classList.remove('open');
        navToggleBtn.setAttribute('aria-expanded', 'false');
      });
    });

    document.addEventListener('click', (e) => {
      if (!navToggleBtn.contains(e.target) && !mobileDrawer.contains(e.target)) {
        mobileDrawer.classList.remove('open');
        navToggleBtn.setAttribute('aria-expanded', 'false');
      }
    });
  }

  // 7. Mobile Device Compatibility Detection & Native Share
  const mobileCompatCard = document.getElementById('mobileCompatCard');
  const btnShareMobileLink = document.getElementById('btnShareMobileLink');
  const shareMobileText = document.getElementById('shareMobileText');

  const isMobileDevice = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) || 
                         (window.innerWidth <= 768 && 'ontouchstart' in window);

  if (mobileCompatCard && isMobileDevice) {
    mobileCompatCard.classList.add('visible');
  }

  if (btnShareMobileLink) {
    btnShareMobileLink.addEventListener('click', async () => {
      const shareData = {
        title: 'OpenLid — Keep Laptop Running with Lid Closed',
        text: 'Open this link on your Mac or Windows laptop to download OpenLid:',
        url: 'https://openlid.devs.li/'
      };

      if (navigator.share) {
        try {
          await navigator.share(shareData);
        } catch (err) {
          // User dismissed share dialog
        }
      } else {
        try {
          await navigator.clipboard.writeText('https://openlid.devs.li/');
          if (shareMobileText) {
            const original = shareMobileText.textContent;
            shareMobileText.textContent = 'Link copied to clipboard!';
            setTimeout(() => {
              shareMobileText.textContent = original;
            }, 2000);
          }
        } catch (e) {
          window.open('https://openlid.devs.li/', '_blank');
        }
      }
    });
  }

  // 8. Report a Problem Modal Logic
  const reportModal = document.getElementById('reportModal');
  const btnCloseReportModal = document.getElementById('btnCloseReportModal');
  const btnFooterReport = document.getElementById('btnFooterReport');
  const btnCoffeeReport = document.getElementById('btnCoffeeReport');
  const mobileNavReport = document.getElementById('mobileNavReport');

  function openReportModal(e) {
    if (e) e.preventDefault();
    if (reportModal) {
      reportModal.classList.add('open');
      reportModal.style.display = 'flex';
    }
  }

  function closeReportModal() {
    if (reportModal) {
      reportModal.classList.remove('open');
      reportModal.style.display = 'none';
    }
  }

  if (btnFooterReport) btnFooterReport.addEventListener('click', openReportModal);
  if (btnCoffeeReport) btnCoffeeReport.addEventListener('click', openReportModal);
  if (mobileNavReport) {
    mobileNavReport.addEventListener('click', (e) => {
      openReportModal(e);
      if (mobileDrawer) mobileDrawer.classList.remove('open');
    });
  }
  if (btnCloseReportModal) btnCloseReportModal.addEventListener('click', closeReportModal);

  if (reportModal) {
    reportModal.addEventListener('click', (e) => {
      if (e.target === reportModal) closeReportModal();
    });
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && reportModal.classList.contains('open')) {
        closeReportModal();
      }
    });
  }

  // 9. Floating Share Widget Logic (Bottom-Right Corner)
  const shareWidget = document.getElementById('shareWidget');
  const sharePillBtn = document.getElementById('sharePillBtn');
  const shareCard = document.getElementById('shareCard');
  const shareCloseBtn = document.getElementById('shareCloseBtn');
  const btnShareCopy = document.getElementById('btnShareCopy');
  const shareCopyBadge = document.getElementById('shareCopyBadge');
  const btnNativeShare = document.getElementById('btnNativeShare');

  if (sharePillBtn && shareCard) {
    // Tap / Click toggle (Mobile & Touch)
    sharePillBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      const isActive = shareCard.classList.toggle('active');
      sharePillBtn.setAttribute('aria-expanded', String(isActive));
      if (isActive && snackCard) {
        snackCard.classList.remove('active');
        if (snackPillBtn) snackPillBtn.setAttribute('aria-expanded', 'false');
      }
    });

    // Hover open/close on desktop devices
    if (shareWidget && window.matchMedia('(hover: hover) and (pointer: fine)').matches) {
      let shareHoverTimer = null;
      shareWidget.addEventListener('mouseenter', () => {
        clearTimeout(shareHoverTimer);
        shareCard.classList.add('active');
        sharePillBtn.setAttribute('aria-expanded', 'true');
      });
      shareWidget.addEventListener('mouseleave', () => {
        shareHoverTimer = setTimeout(() => {
          shareCard.classList.remove('active');
          sharePillBtn.setAttribute('aria-expanded', 'false');
        }, 220);
      });
    }

    if (shareCloseBtn) {
      shareCloseBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        shareCard.classList.remove('active');
        sharePillBtn.setAttribute('aria-expanded', 'false');
      });
    }

    // Close when clicking outside
    document.addEventListener('click', (e) => {
      if (shareWidget && !shareWidget.contains(e.target) && shareCard.classList.contains('active')) {
        shareCard.classList.remove('active');
        sharePillBtn.setAttribute('aria-expanded', 'false');
      }
    });

    // Close on Escape
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && shareCard.classList.contains('active')) {
        shareCard.classList.remove('active');
        sharePillBtn.setAttribute('aria-expanded', 'false');
      }
    });
  }

  // 1. Copy Link Action
  if (btnShareCopy) {
    btnShareCopy.addEventListener('click', async (e) => {
      e.preventDefault();
      try {
        await navigator.clipboard.writeText('https://openlid.devs.li/');
        if (shareCopyBadge) {
          const original = shareCopyBadge.textContent;
          shareCopyBadge.textContent = 'Copied!';
          shareCopyBadge.style.color = 'var(--accent)';
          setTimeout(() => {
            shareCopyBadge.textContent = original;
            shareCopyBadge.style.color = '';
          }, 2000);
        }
      } catch (err) {
        window.open('https://openlid.devs.li/', '_blank');
      }
    });
  }

  // 2. More Sharing Options (Native System Sheet for iPhone / Android / Desktop)
  if (btnNativeShare) {
    btnNativeShare.addEventListener('click', async (e) => {
      e.preventDefault();
      const shareData = {
        title: 'OpenLid — Keep Laptop Running with Lid Closed',
        text: 'Keep your MacBook or Windows laptop awake and running smoothly even with the lid closed without an external display:',
        url: 'https://openlid.devs.li/'
      };

      if (navigator.share) {
        try {
          await navigator.share(shareData);
        } catch (err) {
          // User dismissed or aborted
        }
      } else {
        try {
          await navigator.clipboard.writeText(shareData.url);
          const titleSpan = btnNativeShare.querySelector('.share-item-title');
          if (titleSpan) {
            const original = titleSpan.textContent;
            titleSpan.textContent = 'Link copied to clipboard!';
            setTimeout(() => {
              titleSpan.textContent = original;
            }, 2000);
          }
        } catch (err) {
          window.open(shareData.url, '_blank');
        }
      }
    });
  }

  fetchTelemetry();
  setInterval(fetchTelemetry, 2000);
});
