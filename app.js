// OpenLid Client Engine, OS Switcher & Kinetic Scroll Interaction

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

  // 2. IntersectionObserver for Scroll Reveals
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
      rootMargin: '0px 0px -40px 0px'
    });

    revealElements.forEach(el => revealObserver.observe(el));
  } else {
    revealElements.forEach(el => el.classList.add('is-revealed'));
  }

  // 3. Dynamic Mouse Spotlight Glow on Cards
  const interactiveCards = document.querySelectorAll('.download-card, .spec-card, .three-panoramic-card, .safety-item');
  interactiveCards.forEach(card => {
    card.addEventListener('mousemove', (e) => {
      const rect = card.getBoundingClientRect();
      const x = e.clientX - rect.left;
      const y = e.clientY - rect.top;
      card.style.background = `radial-gradient(500px circle at ${x}px ${y}px, rgba(16, 185, 129, 0.08), var(--bg-card) 75%)`;
    });

    card.addEventListener('mouseleave', () => {
      card.style.background = '';
    });
  });

  // 4. Cross-Platform OS Switcher (macOS vs Windows)
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

    // Auto-detect OS from navigator
    const ua = navigator.userAgent || '';
    if (ua.includes('Win')) {
      btnTabWin.click();
    }
  }
});
