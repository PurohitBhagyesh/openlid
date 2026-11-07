// OpenLid Interactive 3D MacBook & Clamshell Physics Engine
// Powered by Three.js

(function() {
  'use strict';

  let scene, camera, renderer, laptopGroup, baseMesh, lidGroup, screenMesh, screenCanvas, screenCtx, screenTexture;
  let particles, particleGeo, glowRing;
  let isDragging = false;
  let prevMousePos = { x: 0, y: 0 };
  let targetRotation = { x: 0.35, y: -0.6 };
  let currentRotation = { x: 0.35, y: -0.6 };
  let targetLidAngle = 1.95; // ~112 degrees open (in radians)
  let currentLidAngle = 1.95;
  let isOpenLidAwake = true;
  let pulsePhase = 0;

  const container = document.getElementById('threeContainer');
  if (!container) return;

  function initThree() {
    if (typeof THREE === 'undefined') {
      console.warn('Three.js not loaded yet. Waiting...');
      setTimeout(initThree, 100);
      return;
    }

    const width = container.clientWidth || 800;
    const height = container.clientHeight || 480;

    // 1. Scene & Camera
    scene = new THREE.Scene();
    camera = new THREE.PerspectiveCamera(38, width / height, 0.1, 100);
    camera.position.set(0, 1.8, 6.2);

    // 2. Renderer
    renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true, powerPreference: 'high-performance' });
    renderer.setSize(width, height);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    renderer.toneMapping = THREE.ACESFilmicToneMapping;
    renderer.toneMappingExposure = 1.15;
    container.appendChild(renderer.domElement);

    // 3. Lighting
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.65);
    scene.add(ambientLight);

    const dirLight1 = new THREE.DirectionalLight(0xffffff, 1.4);
    dirLight1.position.set(5, 8, 5);
    dirLight1.castShadow = true;
    dirLight1.shadow.mapSize.width = 1024;
    dirLight1.shadow.mapSize.height = 1024;
    scene.add(dirLight1);

    const dirLight2 = new THREE.DirectionalLight(0x10b981, 0.85); // Emerald accent fill
    dirLight2.position.set(-6, 3, -4);
    scene.add(dirLight2);

    const cyanPoint = new THREE.PointLight(0x06b6d4, 1.2, 8);
    cyanPoint.position.set(0, 0.5, 2.5);
    scene.add(cyanPoint);

    // 4. Construct MacBook Pro Model
    laptopGroup = new THREE.Group();
    laptopGroup.position.set(0, -0.25, 0);
    scene.add(laptopGroup);

    // Materials
    const spaceGrayMat = new THREE.MeshStandardMaterial({
      color: 0x1f232b,
      metalness: 0.88,
      roughness: 0.28
    });

    const darkTrimMat = new THREE.MeshStandardMaterial({
      color: 0x0a0c10,
      metalness: 0.5,
      roughness: 0.7
    });

    const keyboardWellMat = new THREE.MeshStandardMaterial({
      color: 0x14161a,
      metalness: 0.8,
      roughness: 0.4
    });

    const keyCapMat = new THREE.MeshStandardMaterial({
      color: 0x1a1d24,
      metalness: 0.2,
      roughness: 0.6
    });

    const trackpadMat = new THREE.MeshStandardMaterial({
      color: 0x222630,
      metalness: 0.82,
      roughness: 0.2
    });

    // A. Bottom Chassis (Base)
    const baseGeo = new THREE.BoxGeometry(3.6, 0.12, 2.45);
    baseMesh = new THREE.Mesh(baseGeo, spaceGrayMat);
    baseMesh.castShadow = true;
    baseMesh.receiveShadow = true;
    laptopGroup.add(baseMesh);

    // Keyboard recess
    const kbWellGeo = new THREE.BoxGeometry(3.0, 0.02, 1.15);
    const kbWellMesh = new THREE.Mesh(kbWellGeo, keyboardWellMat);
    kbWellMesh.position.set(0, 0.055, -0.4);
    laptopGroup.add(kbWellMesh);

    // Simulated Keys (staggered key grid block)
    const keysGeo = new THREE.BoxGeometry(2.9, 0.03, 1.08);
    const keysMesh = new THREE.Mesh(keysGeo, keyCapMat);
    keysMesh.position.set(0, 0.065, -0.4);
    laptopGroup.add(keysMesh);

    // Trackpad
    const trackpadGeo = new THREE.BoxGeometry(1.28, 0.015, 0.76);
    const trackpadMesh = new THREE.Mesh(trackpadGeo, trackpadMat);
    trackpadMesh.position.set(0, 0.062, 0.68);
    laptopGroup.add(trackpadMesh);

    // Rubber feet (4 corners)
    const footGeo = new THREE.CylinderGeometry(0.08, 0.08, 0.02, 16);
    const footMat = new THREE.MeshBasicMaterial({ color: 0x050608 });
    const footPositions = [
      [-1.5, -0.065, -1.0],
      [1.5, -0.065, -1.0],
      [-1.5, -0.065, 1.0],
      [1.5, -0.065, 1.0]
    ];
    footPositions.forEach(pos => {
      const foot = new THREE.Mesh(footGeo, footMat);
      foot.position.set(...pos);
      laptopGroup.add(foot);
    });

    // Front Notch (lid thumb opener)
    const notchGeo = new THREE.BoxGeometry(0.5, 0.04, 0.04);
    const notch = new THREE.Mesh(notchGeo, darkTrimMat);
    notch.position.set(0, 0.04, 1.22);
    laptopGroup.add(notch);

    // B. Display Lid (Pivoted Group at the rear hinge)
    lidGroup = new THREE.Group();
    // Hinge line: rear top edge of base
    lidGroup.position.set(0, 0.06, -1.22);
    laptopGroup.add(lidGroup);

    // Cylindrical Hinge
    const hingeGeo = new THREE.CylinderGeometry(0.045, 0.045, 3.2, 16);
    hingeGeo.rotateZ(Math.PI / 2);
    const hingeMesh = new THREE.Mesh(hingeGeo, darkTrimMat);
    hingeMesh.position.set(0, 0, 0);
    lidGroup.add(hingeMesh);

    // Display Outer Shell (Lid Back)
    const lidShellGeo = new THREE.BoxGeometry(3.6, 0.08, 2.45);
    const lidShellMesh = new THREE.Mesh(lidShellGeo, spaceGrayMat);
    // Position offset from hinge so bottom edge meets hinge
    lidShellMesh.position.set(0, 0.04, 1.22);
    lidShellMesh.castShadow = true;
    lidGroup.add(lidShellMesh);

    // Apple/OpenLid Logo on Lid Exterior
    const logoCanvas = document.createElement('canvas');
    logoCanvas.width = 128;
    logoCanvas.height = 128;
    const lCtx = logoCanvas.getContext('2d');
    lCtx.clearRect(0, 0, 128, 128);
    // Draw glowing eye logo
    lCtx.strokeStyle = '#10b981';
    lCtx.lineWidth = 8;
    lCtx.beginPath();
    lCtx.ellipse(64, 64, 46, 26, 0, 0, Math.PI * 2);
    lCtx.stroke();
    lCtx.fillStyle = '#10b981';
    lCtx.beginPath();
    lCtx.arc(64, 64, 14, 0, Math.PI * 2);
    lCtx.fill();
    const logoTexture = new THREE.CanvasTexture(logoCanvas);
    const logoGeo = new THREE.PlaneGeometry(0.55, 0.55);
    logoGeo.rotateX(Math.PI / 2); // on back of lid
    const logoMat = new THREE.MeshStandardMaterial({
      map: logoTexture,
      transparent: true,
      emissive: 0x10b981,
      emissiveIntensity: 0.8
    });
    const logoMesh = new THREE.Mesh(logoGeo, logoMat);
    logoMesh.position.set(0, 0.082, 1.22);
    lidGroup.add(logoMesh);

    // Display Inner Bezel (Black Glass)
    const bezelGeo = new THREE.BoxGeometry(3.54, 0.01, 2.38);
    const bezelMesh = new THREE.Mesh(bezelGeo, darkTrimMat);
    bezelMesh.position.set(0, 0, 1.22);
    lidGroup.add(bezelMesh);

    // Camera Notch on Bezel
    const camGeo = new THREE.BoxGeometry(0.18, 0.02, 0.05);
    const camMesh = new THREE.Mesh(camGeo, new THREE.MeshBasicMaterial({ color: 0x000000 }));
    camMesh.position.set(0, -0.005, 2.38);
    lidGroup.add(camMesh);

    // C. Dynamic macOS Screen Texture
    screenCanvas = document.createElement('canvas');
    screenCanvas.width = 1024;
    screenCanvas.height = 680;
    screenCtx = screenCanvas.getContext('2d');
    drawScreenContent(screenCtx, 1024, 680, true);

    screenTexture = new THREE.CanvasTexture(screenCanvas);
    screenTexture.generateMipmaps = true;
    screenTexture.minFilter = THREE.LinearMipmapLinearFilter;

    const screenMat = new THREE.MeshBasicMaterial({
      map: screenTexture,
      side: THREE.FrontSide
    });
    const screenGeo = new THREE.PlaneGeometry(3.38, 2.22);
    screenGeo.rotateX(-Math.PI / 2); // face upwards towards keyboard when folded
    screenMesh = new THREE.Mesh(screenGeo, screenMat);
    screenMesh.position.set(0, -0.008, 1.22);
    lidGroup.add(screenMesh);

    // D. Emerald Clamshell Awake Pulse Glow Ring
    const ringGeo = new THREE.RingGeometry(0.2, 2.4, 32);
    ringGeo.rotateX(-Math.PI / 2);
    const ringMat = new THREE.MeshBasicMaterial({
      color: 0x10b981,
      transparent: true,
      opacity: 0.35,
      side: THREE.DoubleSide
    });
    glowRing = new THREE.Mesh(ringGeo, ringMat);
    glowRing.position.set(0, -0.06, 0);
    laptopGroup.add(glowRing);

    // E. Floating Cybernetic Particle Field
    const pCount = 140;
    particleGeo = new THREE.BufferGeometry();
    const pPositions = new Float32Array(pCount * 3);
    for (let i = 0; i < pCount; i++) {
      pPositions[i * 3] = (Math.random() - 0.5) * 6;
      pPositions[i * 3 + 1] = (Math.random() - 0.5) * 3 + 0.5;
      pPositions[i * 3 + 2] = (Math.random() - 0.5) * 5;
    }
    particleGeo.setAttribute('position', new THREE.BufferAttribute(pPositions, 3));
    const pMat = new THREE.PointsMaterial({
      color: 0x10b981,
      size: 0.045,
      transparent: true,
      opacity: 0.6,
      blending: THREE.AdditiveBlending
    });
    particles = new THREE.Points(particleGeo, pMat);
    scene.add(particles);

    // 5. Events: Drag to Rotate 3D
    container.addEventListener('mousedown', onMouseDown);
    window.addEventListener('mousemove', onMouseMove);
    window.addEventListener('mouseup', onMouseUp);

    container.addEventListener('touchstart', onTouchStart, { passive: true });
    window.addEventListener('touchmove', onTouchMove, { passive: true });
    window.addEventListener('touchend', onTouchEnd);

    window.addEventListener('resize', onWindowResize);

    // Wire Up Interactive DOM Controls
    setupControlButtons();

    // Start Animation Loop
    animate();
  }

  function drawScreenContent(ctx, w, h, isAwake) {
    if (!isAwake) {
      // Screen off (asleep)
      ctx.fillStyle = '#050608';
      ctx.fillRect(0, 0, w, h);
      ctx.fillStyle = '#334155';
      ctx.font = '24px -apple-system, sans-serif';
      ctx.textAlign = 'center';
      ctx.fillText('System Sleeping (Default macOS behavior)', w / 2, h / 2);
      return;
    }

    // Dynamic macOS Desktop with vibrant dark wallpaper
    const grad = ctx.createLinearGradient(0, 0, w, h);
    grad.addColorStop(0, '#070b14');
    grad.addColorStop(0.4, '#0d1829');
    grad.addColorStop(0.7, '#082522');
    grad.addColorStop(1, '#051318');
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, w, h);

    // Subtle neon curves in wallpaper
    ctx.strokeStyle = 'rgba(16, 185, 129, 0.18)';
    ctx.lineWidth = 120;
    ctx.beginPath();
    ctx.arc(w * 0.7, h * 0.9, 360, 0, Math.PI * 2);
    ctx.stroke();

    ctx.strokeStyle = 'rgba(6, 182, 212, 0.15)';
    ctx.lineWidth = 80;
    ctx.beginPath();
    ctx.arc(w * 0.3, h * 0.1, 280, 0, Math.PI * 2);
    ctx.stroke();

    // Menu Bar (Top)
    ctx.fillStyle = 'rgba(15, 23, 42, 0.88)';
    ctx.fillRect(0, 0, w, 38);
    ctx.fillStyle = 'rgba(255, 255, 255, 0.1)';
    ctx.fillRect(0, 38, w, 1);

    // Left Menu items
    ctx.fillStyle = '#f8fafc';
    ctx.font = '600 15px -apple-system, BlinkMacSystemFont, sans-serif';
    ctx.textAlign = 'left';
    ctx.fillText('', 18, 24);
    ctx.font = '500 13px -apple-system, sans-serif';
    ctx.fillStyle = 'rgba(255, 255, 255, 0.85)';
    ctx.fillText('OpenLid', 44, 24);
    ctx.fillText('File', 108, 24);
    ctx.fillText('Edit', 142, 24);
    ctx.fillText('View', 176, 24);
    ctx.fillText('Window', 216, 24);
    ctx.fillText('Help', 274, 24);

    // Right Menu bar items: Battery, Wifi, Time, and OPENLID EYE
    const rx = w - 24;
    ctx.textAlign = 'right';
    ctx.fillStyle = '#f8fafc';
    ctx.font = '500 12px -apple-system, sans-serif';
    ctx.fillText('Sat 7 Nov  7:15 PM', rx, 24);

    // Draw OpenLid Vigilant Eye Icon in Menu Bar!
    const eyeX = rx - 180;
    ctx.fillStyle = '#10b981';
    ctx.strokeStyle = '#10b981';
    ctx.lineWidth = 2.4;
    ctx.beginPath();
    ctx.ellipse(eyeX, 22, 11, 6, 0, 0, Math.PI * 2);
    ctx.stroke();
    ctx.beginPath();
    ctx.arc(eyeX, 22, 3.2, 0, Math.PI * 2);
    ctx.fill();

    // Pulse dot next to eye
    ctx.fillStyle = '#06b6d4';
    ctx.beginPath();
    ctx.arc(eyeX + 16, 22, 2.5, 0, Math.PI * 2);
    ctx.fill();

    // Floating Terminal Window on Desktop
    const tw = 620;
    const th = 360;
    const tx = (w - tw) / 2;
    const ty = 90;

    // Window shadow & body
    ctx.fillStyle = 'rgba(10, 12, 16, 0.92)';
    ctx.strokeStyle = 'rgba(255, 255, 255, 0.12)';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.roundRect ? ctx.roundRect(tx, ty, tw, th, 10) : ctx.rect(tx, ty, tw, th);
    ctx.fill();
    ctx.stroke();

    // Title bar
    ctx.fillStyle = 'rgba(20, 24, 32, 0.95)';
    ctx.beginPath();
    ctx.roundRect ? ctx.roundRect(tx, ty, tw, 36, [10, 10, 0, 0]) : ctx.rect(tx, ty, tw, 36);
    ctx.fill();

    // Traffic lights
    ctx.fillStyle = '#ef4444'; ctx.beginPath(); ctx.arc(tx + 20, ty + 18, 6, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = '#f59e0b'; ctx.beginPath(); ctx.arc(tx + 38, ty + 18, 6, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = '#10b981'; ctx.beginPath(); ctx.arc(tx + 56, ty + 18, 6, 0, Math.PI * 2); ctx.fill();

    // Title
    ctx.fillStyle = 'rgba(255, 255, 255, 0.6)';
    ctx.font = '500 12px "SF Mono", Menlo, monospace';
    ctx.textAlign = 'center';
    ctx.fillText('bash — openlid status (PID: 6087)', tx + tw / 2, ty + 22);

    // Terminal Text
    ctx.textAlign = 'left';
    ctx.font = '13px "SF Mono", Menlo, monospace';
    let lineY = ty + 68;
    const lh = 22;

    ctx.fillStyle = '#38bdf8';
    ctx.fillText('$ openlid --status --live', tx + 24, lineY); lineY += lh;

    ctx.fillStyle = '#10b981';
    ctx.fillText('● SYSTEM STATUS: 🟢 AWAKE (Clamshell Bypass Active)', tx + 24, lineY); lineY += lh;

    ctx.fillStyle = '#94a3b8';
    ctx.fillText('├─ IOPMrootDomain: kIOPMAssertionTypePreventSystemSleep', tx + 24, lineY); lineY += lh;
    ctx.fillText('├─ Clamshell State: 🔒 CLOSED (Lid sensor overridden)', tx + 24, lineY); lineY += lh;
    ctx.fillText('├─ Thermal Sentinel: Nominal (Cool • 42°C)', tx + 24, lineY); lineY += lh;
    ctx.fillText('├─ Battery Threshold: AC Connected (96% • Safe margin)', tx + 24, lineY); lineY += lh;
    ctx.fillText('└─ Background Processes: Claude Agent + Ollama Running', tx + 24, lineY); lineY += lh + 10;

    // Glowing active pill in terminal
    ctx.fillStyle = 'rgba(16, 185, 129, 0.15)';
    ctx.strokeStyle = 'rgba(16, 185, 129, 0.4)';
    ctx.beginPath();
    ctx.roundRect ? ctx.roundRect(tx + 24, lineY, tw - 48, 40, 6) : ctx.rect(tx + 24, lineY, tw - 48, 40);
    ctx.fill(); ctx.stroke();

    ctx.fillStyle = '#34d399';
    ctx.font = '600 13px -apple-system, sans-serif';
    ctx.fillText('⚡️ Unsleeping Eye Active: Your MacBook will not sleep when closed', tx + 40, lineY + 25);
  }

  function setupControlButtons() {
    const btnOpen = document.getElementById('btnLidOpen');
    const btnHalf = document.getElementById('btnLidHalf');
    const btnClose = document.getElementById('btnLidClose');
    const lidSlider = document.getElementById('lidSlider');
    const toggleEngine = document.getElementById('btn3dEngineToggle');
    const lidAngleLabel = document.getElementById('lidAngleDisplay');

    if (btnOpen) {
      btnOpen.addEventListener('click', () => {
        targetLidAngle = 1.95; // ~112 deg
        if (lidSlider) lidSlider.value = 112;
        updateLidAngleDisplay(112);
      });
    }

    if (btnHalf) {
      btnHalf.addEventListener('click', () => {
        targetLidAngle = 0.85; // ~48 deg
        if (lidSlider) lidSlider.value = 48;
        updateLidAngleDisplay(48);
      });
    }

    if (btnClose) {
      btnClose.addEventListener('click', () => {
        targetLidAngle = 0.01; // ~0 deg (closed clamshell)
        if (lidSlider) lidSlider.value = 0;
        updateLidAngleDisplay(0);
      });
    }

    if (lidSlider) {
      lidSlider.addEventListener('input', (e) => {
        const deg = parseFloat(e.target.value);
        targetLidAngle = (deg / 180) * Math.PI;
        updateLidAngleDisplay(deg);
      });
    }

    if (toggleEngine) {
      toggleEngine.addEventListener('click', () => {
        isOpenLidAwake = !isOpenLidAwake;
        toggleEngine.textContent = isOpenLidAwake ? 'OpenLid Engine: ACTIVE 🟢' : 'Default macOS Sleep: ACTIVE 🟡';
        toggleEngine.classList.toggle('active', isOpenLidAwake);
        drawScreenContent(screenCtx, 1024, 680, isOpenLidAwake);
        if (screenTexture) screenTexture.needsUpdate = true;
      });
    }

    function updateLidAngleDisplay(deg) {
      if (lidAngleLabel) {
        if (deg < 5) {
          lidAngleLabel.innerHTML = `Lid: <strong>0° (Closed Clamshell)</strong>`;
        } else if (deg > 100) {
          lidAngleLabel.innerHTML = `Lid: <strong>${Math.round(deg)}° (Fully Open)</strong>`;
        } else {
          lidAngleLabel.innerHTML = `Lid: <strong>${Math.round(deg)}° (Partially Closed)</strong>`;
        }
      }
    }
  }

  // Mouse / Touch Drag Handlers
  function onMouseDown(e) {
    isDragging = true;
    prevMousePos = { x: e.clientX, y: e.clientY };
  }

  function onMouseMove(e) {
    if (!isDragging) return;
    const deltaX = e.clientX - prevMousePos.x;
    const deltaY = e.clientY - prevMousePos.y;
    targetRotation.y += deltaX * 0.007;
    targetRotation.x = Math.max(-0.2, Math.min(1.2, targetRotation.x + deltaY * 0.007));
    prevMousePos = { x: e.clientX, y: e.clientY };
  }

  function onMouseUp() {
    isDragging = false;
  }

  function onTouchStart(e) {
    if (e.touches.length === 1) {
      isDragging = true;
      prevMousePos = { x: e.touches[0].clientX, y: e.touches[0].clientY };
    }
  }

  function onTouchMove(e) {
    if (!isDragging || e.touches.length !== 1) return;
    const deltaX = e.touches[0].clientX - prevMousePos.x;
    const deltaY = e.touches[0].clientY - prevMousePos.y;
    targetRotation.y += deltaX * 0.008;
    targetRotation.x = Math.max(-0.2, Math.min(1.2, targetRotation.x + deltaY * 0.008));
    prevMousePos = { x: e.touches[0].clientX, y: e.touches[0].clientY };
  }

  function onTouchEnd() {
    isDragging = false;
  }

  function onWindowResize() {
    if (!container || !renderer || !camera) return;
    const w = container.clientWidth;
    const h = container.clientHeight || 480;
    camera.aspect = w / h;
    camera.updateProjectionMatrix();
    renderer.setSize(w, h);
  }

  // Animation Loop
  function animate() {
    requestAnimationFrame(animate);

    // Smooth inertia interpolation for rotation
    currentRotation.x += (targetRotation.x - currentRotation.x) * 0.08;
    currentRotation.y += (targetRotation.y - currentRotation.y) * 0.08;
    if (laptopGroup) {
      laptopGroup.rotation.x = currentRotation.x;
      laptopGroup.rotation.y = currentRotation.y;
    }

    // Smooth hinge lid opening/closing physics
    currentLidAngle += (targetLidAngle - currentLidAngle) * 0.12;
    if (lidGroup) {
      // 0 rad = closed flat over keyboard
      // Positive rotation tilts lid back up and away
      lidGroup.rotation.x = -currentLidAngle;
    }

    // Floating idle bobbing motion
    pulsePhase += 0.035;
    if (laptopGroup && !isDragging) {
      laptopGroup.position.y = -0.25 + Math.sin(pulsePhase * 0.8) * 0.04;
    }

    // Particles slow orbit
    if (particles) {
      particles.rotation.y += 0.0015;
    }

    // Emerald Clamshell Awake Glow Effect
    const isLidClosed = currentLidAngle < 0.15;
    if (glowRing) {
      if (isLidClosed && isOpenLidAwake) {
        glowRing.visible = true;
        glowRing.scale.setScalar(1 + Math.sin(pulsePhase * 2) * 0.08);
        glowRing.material.opacity = 0.45 + Math.sin(pulsePhase * 2) * 0.2;
      } else if (!isLidClosed) {
        glowRing.visible = true;
        glowRing.scale.setScalar(1);
        glowRing.material.opacity = 0.18;
      } else {
        // Closed without OpenLid awake (sleeping)
        glowRing.visible = false;
      }
    }

    // Dynamic HUD Status readout update in DOM
    const hudState = document.getElementById('hudLidState');
    if (hudState) {
      if (isLidClosed) {
        if (isOpenLidAwake) {
          hudState.innerHTML = `<span class="badge-emerald">🔒 CLAMSHELL CLOSED</span> • <span class="text-awake">🟢 Awake & Vigilant</span>`;
        } else {
          hudState.innerHTML = `<span class="badge-amber">🔒 CLAMSHELL CLOSED</span> • <span class="text-asleep">🟡 Sleeping (Default)</span>`;
        }
      } else {
        hudState.innerHTML = `<span class="badge-blue">📖 SCREEN OPEN</span> • <span class="text-awake">Display Active</span>`;
      }
    }

    renderer.render(scene, camera);
  }

  // Scroll Parallax and Angle Influence
  window.addEventListener('scroll', () => {
    const scrollY = window.scrollY || window.pageYOffset;
    if (!isDragging && laptopGroup) {
      // Gentle parallax shift as user scrolls down the page
      targetRotation.y = -0.6 + (scrollY * 0.0006);
    }
  }, { passive: true });

  // Initialize once DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initThree);
  } else {
    initThree();
  }
})();
