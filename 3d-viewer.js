// OpenLid Whole-Page 3D Experience & Clamshell Physics Engine
// Powered by Three.js

(function() {
  'use strict';

  let scene, camera, renderer, laptopGroup, baseMesh, lidGroup, screenMesh, screenCanvas, screenCtx, screenTexture;
  let particles, particleGeo, glowRing, beamMesh;
  let isDragging = false;
  let userHasInteracted = false;
  let prevMousePos = { x: 0, y: 0 };
  let targetRotation = { x: 0.25, y: -0.45 };
  let currentRotation = { x: 0.25, y: -0.45 };
  let targetPosition = { x: 0, y: -0.15, z: 0 };
  let currentPosition = { x: 0, y: -0.15, z: 0 };
  let targetLidAngle = 1.95; // ~112 deg open
  let currentLidAngle = 1.95;
  let isOpenLidAwake = true;
  let pulsePhase = 0;
  let scrollProgress = 0;

  const container = document.getElementById('threeContainer');
  if (!container) return;

  function initThree() {
    if (typeof THREE === 'undefined') {
      setTimeout(initThree, 100);
      return;
    }

    const width = container.clientWidth || window.innerWidth;
    const height = container.clientHeight || 560;

    // 1. Scene & Camera
    scene = new THREE.Scene();
    camera = new THREE.PerspectiveCamera(36, width / height, 0.1, 100);
    camera.position.set(0, 1.6, 6.4);

    // 2. Renderer with PBR tone mapping
    renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true, powerPreference: 'high-performance' });
    renderer.setSize(width, height);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    renderer.toneMapping = THREE.ACESFilmicToneMapping;
    renderer.toneMappingExposure = 1.2;
    container.appendChild(renderer.domElement);

    // 3. Lights
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.7);
    scene.add(ambientLight);

    const dirLight1 = new THREE.DirectionalLight(0xffffff, 1.5);
    dirLight1.position.set(5, 9, 6);
    dirLight1.castShadow = true;
    scene.add(dirLight1);

    const emeraldLight = new THREE.DirectionalLight(0x10b981, 1.2);
    emeraldLight.position.set(-6, 4, -4);
    scene.add(emeraldLight);

    const cyanLight = new THREE.PointLight(0x06b6d4, 1.4, 9);
    cyanLight.position.set(0, 0.8, 2.5);
    scene.add(cyanLight);

    // 4. Construct MacBook Pro & Cross-Platform Laptop Geometry
    laptopGroup = new THREE.Group();
    laptopGroup.position.set(0, -0.15, 0);
    scene.add(laptopGroup);

    // Materials
    const spaceGrayMat = new THREE.MeshStandardMaterial({
      color: 0x1c2027,
      metalness: 0.88,
      roughness: 0.28
    });

    const darkTrimMat = new THREE.MeshStandardMaterial({
      color: 0x090b0e,
      metalness: 0.6,
      roughness: 0.65
    });

    const keyboardWellMat = new THREE.MeshStandardMaterial({
      color: 0x121419,
      metalness: 0.75,
      roughness: 0.45
    });

    const keyCapMat = new THREE.MeshStandardMaterial({
      color: 0x181a20,
      metalness: 0.2,
      roughness: 0.55
    });

    const trackpadMat = new THREE.MeshStandardMaterial({
      color: 0x222630,
      metalness: 0.82,
      roughness: 0.2
    });

    // Base Chassis
    const baseGeo = new THREE.BoxGeometry(3.6, 0.12, 2.45);
    baseMesh = new THREE.Mesh(baseGeo, spaceGrayMat);
    baseMesh.castShadow = true;
    baseMesh.receiveShadow = true;
    laptopGroup.add(baseMesh);

    // Keyboard well
    const kbWellGeo = new THREE.BoxGeometry(3.0, 0.02, 1.15);
    const kbWellMesh = new THREE.Mesh(kbWellGeo, keyboardWellMat);
    kbWellMesh.position.set(0, 0.055, -0.4);
    laptopGroup.add(kbWellMesh);

    // Keys block
    const keysGeo = new THREE.BoxGeometry(2.9, 0.03, 1.08);
    const keysMesh = new THREE.Mesh(keysGeo, keyCapMat);
    keysMesh.position.set(0, 0.065, -0.4);
    laptopGroup.add(keysMesh);

    // Trackpad
    const trackpadGeo = new THREE.BoxGeometry(1.3, 0.015, 0.78);
    const trackpadMesh = new THREE.Mesh(trackpadGeo, trackpadMat);
    trackpadMesh.position.set(0, 0.062, 0.68);
    laptopGroup.add(trackpadMesh);

    // Rubber feet
    const footGeo = new THREE.CylinderGeometry(0.08, 0.08, 0.02, 16);
    const footMat = new THREE.MeshBasicMaterial({ color: 0x040507 });
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

    // Display Lid Group (hinged at rear top edge)
    lidGroup = new THREE.Group();
    lidGroup.position.set(0, 0.06, -1.22);
    laptopGroup.add(lidGroup);

    // Cylindrical Hinge
    const hingeGeo = new THREE.CylinderGeometry(0.045, 0.045, 3.2, 16);
    hingeGeo.rotateZ(Math.PI / 2);
    const hingeMesh = new THREE.Mesh(hingeGeo, darkTrimMat);
    lidGroup.add(hingeMesh);

    // Display Outer Shell (Lid Back)
    const lidShellGeo = new THREE.BoxGeometry(3.6, 0.08, 2.45);
    const lidShellMesh = new THREE.Mesh(lidShellGeo, spaceGrayMat);
    lidShellMesh.position.set(0, 0.04, 1.22);
    lidShellMesh.castShadow = true;
    lidGroup.add(lidShellMesh);

    // Glowing OpenLid Eye Emblem on Lid Back
    const logoCanvas = document.createElement('canvas');
    logoCanvas.width = 128;
    logoCanvas.height = 128;
    const lCtx = logoCanvas.getContext('2d');
    lCtx.clearRect(0, 0, 128, 128);
    lCtx.strokeStyle = '#10b981';
    lCtx.lineWidth = 9;
    lCtx.beginPath();
    lCtx.ellipse(64, 64, 46, 26, 0, 0, Math.PI * 2);
    lCtx.stroke();
    lCtx.fillStyle = '#10b981';
    lCtx.beginPath();
    lCtx.arc(64, 64, 15, 0, Math.PI * 2);
    lCtx.fill();
    const logoTexture = new THREE.CanvasTexture(logoCanvas);
    const logoGeo = new THREE.PlaneGeometry(0.55, 0.55);
    logoGeo.rotateX(Math.PI / 2);
    const logoMat = new THREE.MeshStandardMaterial({
      map: logoTexture,
      transparent: true,
      emissive: 0x10b981,
      emissiveIntensity: 0.95
    });
    const logoMesh = new THREE.Mesh(logoGeo, logoMat);
    logoMesh.position.set(0, 0.082, 1.22);
    lidGroup.add(logoMesh);

    // Display Inner Bezel
    const bezelGeo = new THREE.BoxGeometry(3.54, 0.01, 2.38);
    const bezelMesh = new THREE.Mesh(bezelGeo, darkTrimMat);
    bezelMesh.position.set(0, 0, 1.22);
    lidGroup.add(bezelMesh);

    // Dynamic High-Res Screen Texture
    screenCanvas = document.createElement('canvas');
    screenCanvas.width = 1024;
    screenCanvas.height = 680;
    screenCtx = screenCanvas.getContext('2d');
    drawScreenContent(screenCtx, 1024, 680, true);

    screenTexture = new THREE.CanvasTexture(screenCanvas);
    screenTexture.generateMipmaps = true;
    screenTexture.minFilter = THREE.LinearMipmapLinearFilter;

    const screenMat = new THREE.MeshBasicMaterial({ map: screenTexture });
    const screenGeo = new THREE.PlaneGeometry(3.38, 2.22);
    screenGeo.rotateX(-Math.PI / 2);
    screenMesh = new THREE.Mesh(screenGeo, screenMat);
    screenMesh.position.set(0, -0.008, 1.22);
    lidGroup.add(screenMesh);

    // Radiant Emerald Clamshell Energy Beam
    const ringGeo = new THREE.RingGeometry(0.3, 2.6, 48);
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

    // Floating Cybernetic 3D Particle Field across whole viewport
    const pCount = 200;
    particleGeo = new THREE.BufferGeometry();
    const pPositions = new Float32Array(pCount * 3);
    for (let i = 0; i < pCount; i++) {
      pPositions[i * 3] = (Math.random() - 0.5) * 8;
      pPositions[i * 3 + 1] = (Math.random() - 0.5) * 4.5 + 0.5;
      pPositions[i * 3 + 2] = (Math.random() - 0.5) * 6;
    }
    particleGeo.setAttribute('position', new THREE.BufferAttribute(pPositions, 3));
    const pMat = new THREE.PointsMaterial({
      color: 0x10b981,
      size: 0.05,
      transparent: true,
      opacity: 0.65,
      blending: THREE.AdditiveBlending
    });
    particles = new THREE.Points(particleGeo, pMat);
    scene.add(particles);

    // Events: 3D Drag Orbit
    container.addEventListener('mousedown', onMouseDown);
    window.addEventListener('mousemove', onMouseMove);
    window.addEventListener('mouseup', onMouseUp);

    container.addEventListener('touchstart', onTouchStart, { passive: true });
    window.addEventListener('touchmove', onTouchMove, { passive: true });
    window.addEventListener('touchend', onTouchEnd);

    window.addEventListener('resize', onWindowResize);
    window.addEventListener('scroll', onScrollUpdate, { passive: true });

    setupControlButtons();
    animate();
  }

  function drawScreenContent(ctx, w, h, isAwake) {
    if (!isAwake) {
      ctx.fillStyle = '#06070a';
      ctx.fillRect(0, 0, w, h);
      ctx.fillStyle = '#475569';
      ctx.font = '600 22px -apple-system, sans-serif';
      ctx.textAlign = 'center';
      ctx.fillText('Default System Sleep (Lid Closed)', w / 2, h / 2);
      return;
    }

    // High-contrast dark desktop wallpaper
    const grad = ctx.createLinearGradient(0, 0, w, h);
    grad.addColorStop(0, '#060a12');
    grad.addColorStop(0.5, '#0b1625');
    grad.addColorStop(0.8, '#062520');
    grad.addColorStop(1, '#041014');
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, w, h);

    // Radiant wallpaper curves
    ctx.strokeStyle = 'rgba(16, 185, 129, 0.2)';
    ctx.lineWidth = 140;
    ctx.beginPath();
    ctx.arc(w * 0.72, h * 0.88, 380, 0, Math.PI * 2);
    ctx.stroke();

    ctx.strokeStyle = 'rgba(6, 182, 212, 0.16)';
    ctx.lineWidth = 90;
    ctx.beginPath();
    ctx.arc(w * 0.28, h * 0.12, 300, 0, Math.PI * 2);
    ctx.stroke();

    // Top Menu Bar
    ctx.fillStyle = 'rgba(15, 23, 42, 0.9)';
    ctx.fillRect(0, 0, w, 38);
    ctx.fillStyle = 'rgba(255, 255, 255, 0.1)';
    ctx.fillRect(0, 38, w, 1);

    // Left items
    ctx.fillStyle = '#f8fafc';
    ctx.font = '600 15px -apple-system, sans-serif';
    ctx.textAlign = 'left';
    ctx.fillText('', 18, 24);
    ctx.font = '500 13px -apple-system, sans-serif';
    ctx.fillText('OpenLid', 44, 24);
    ctx.fillText('File', 110, 24);
    ctx.fillText('View', 148, 24);
    ctx.fillText('Window', 190, 24);
    ctx.fillText('Help', 250, 24);

    // Right Menu Bar: OpenLid Unsleeping Eye
    const rx = w - 24;
    ctx.textAlign = 'right';
    ctx.fillStyle = '#f8fafc';
    ctx.font = '500 12px -apple-system, sans-serif';
    ctx.fillText('Sat 7 Nov  7:45 PM', rx, 24);

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

    // Center Hero Text on Screen
    ctx.textAlign = 'center';
    ctx.fillStyle = '#ffffff';
    ctx.font = '700 28px -apple-system, BlinkMacSystemFont, sans-serif';
    ctx.fillText('OpenLid Clamshell Sentinel', w / 2, h / 2 - 20);

    ctx.fillStyle = '#10b981';
    ctx.font = '600 15px "SF Mono", Menlo, monospace';
    ctx.fillText('● KERNEL POWER ASSERTIONS ENGAGED • AWAKE & VIGILANT', w / 2, h / 2 + 16);

    ctx.fillStyle = 'rgba(255, 255, 255, 0.6)';
    ctx.font = '400 13px -apple-system, sans-serif';
    ctx.fillText('Zero dropped frames • macOS 13+ & Windows 11/10', w / 2, h / 2 + 45);
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
        userHasInteracted = true;
        targetLidAngle = 1.95;
        if (lidSlider) lidSlider.value = 112;
        updateLidAngleDisplay(112);
      });
    }

    if (btnHalf) {
      btnHalf.addEventListener('click', () => {
        userHasInteracted = true;
        targetLidAngle = 0.85;
        if (lidSlider) lidSlider.value = 48;
        updateLidAngleDisplay(48);
      });
    }

    if (btnClose) {
      btnClose.addEventListener('click', () => {
        userHasInteracted = true;
        targetLidAngle = 0.01;
        if (lidSlider) lidSlider.value = 0;
        updateLidAngleDisplay(0);
      });
    }

    if (lidSlider) {
      lidSlider.addEventListener('input', (e) => {
        userHasInteracted = true;
        const deg = parseFloat(e.target.value);
        targetLidAngle = (deg / 180) * Math.PI;
        updateLidAngleDisplay(deg);
      });
    }

    if (toggleEngine) {
      toggleEngine.addEventListener('click', () => {
        isOpenLidAwake = !isOpenLidAwake;
        toggleEngine.textContent = isOpenLidAwake ? 'OpenLid Engine: ACTIVE 🟢' : 'Default OS Sleep: ACTIVE 🟡';
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

  // Scroll Progression across the whole page
  function onScrollUpdate() {
    const scrollTop = window.scrollY || document.documentElement.scrollTop;
    const docHeight = document.documentElement.scrollHeight - window.innerHeight;
    scrollProgress = docHeight > 0 ? (scrollTop / docHeight) : 0;

    // If the user hasn't manually overridden the lid angle, let the scroll naturally drive the storytelling:
    if (!userHasInteracted) {
      if (scrollProgress < 0.22) {
        // Stage 1: Hero (Open 112°)
        targetLidAngle = 1.95;
        targetRotation.y = -0.45 + (scrollProgress * 0.8);
        targetRotation.x = 0.25;
        targetPosition.y = -0.15;
      } else if (scrollProgress < 0.5) {
        // Stage 2: Clamshell Close (Folds to 0°)
        const t = (scrollProgress - 0.22) / 0.28;
        targetLidAngle = 1.95 * (1 - t);
        targetRotation.y = -0.25 + (t * 0.4);
        targetRotation.x = 0.35;
        targetPosition.y = -0.1;
      } else if (scrollProgress < 0.75) {
        // Stage 3: Architecture & Safety Side Profile
        targetLidAngle = 0.01;
        targetRotation.y = 0.85;
        targetRotation.x = 0.4;
      } else {
        // Stage 4: Cross-Platform Downloads Isometric Stance
        targetLidAngle = 0.85; // half open
        targetRotation.y = -0.55;
        targetRotation.x = 0.32;
      }

      const lidSlider = document.getElementById('lidSlider');
      if (lidSlider) lidSlider.value = Math.round((targetLidAngle / Math.PI) * 180);
      const lidAngleDisplay = document.getElementById('lidAngleDisplay');
      if (lidAngleDisplay) {
        const deg = Math.round((targetLidAngle / Math.PI) * 180);
        lidAngleDisplay.innerHTML = deg < 5 ? `Lid: <strong>0° (Closed Clamshell)</strong>` : `Lid: <strong>${deg}°</strong>`;
      }
    } else {
      // Gentle parallax if user has interacted
      if (!isDragging) {
        targetRotation.y = targetRotation.y + (scrollTop * 0.0001);
      }
    }
  }

  // Mouse / Touch Drag Orbit
  function onMouseDown(e) {
    isDragging = true;
    userHasInteracted = true;
    prevMousePos = { x: e.clientX, y: e.clientY };
  }

  function onMouseMove(e) {
    if (!isDragging) return;
    const deltaX = e.clientX - prevMousePos.x;
    const deltaY = e.clientY - prevMousePos.y;
    targetRotation.y += deltaX * 0.007;
    targetRotation.x = Math.max(-0.25, Math.min(1.2, targetRotation.x + deltaY * 0.007));
    prevMousePos = { x: e.clientX, y: e.clientY };
  }

  function onMouseUp() {
    isDragging = false;
  }

  function onTouchStart(e) {
    if (e.touches.length === 1) {
      isDragging = true;
      userHasInteracted = true;
      prevMousePos = { x: e.touches[0].clientX, y: e.touches[0].clientY };
    }
  }

  function onTouchMove(e) {
    if (!isDragging || e.touches.length !== 1) return;
    const deltaX = e.touches[0].clientX - prevMousePos.x;
    const deltaY = e.touches[0].clientY - prevMousePos.y;
    targetRotation.y += deltaX * 0.008;
    targetRotation.x = Math.max(-0.25, Math.min(1.2, targetRotation.x + deltaY * 0.008));
    prevMousePos = { x: e.touches[0].clientX, y: e.touches[0].clientY };
  }

  function onTouchEnd() {
    isDragging = false;
  }

  function onWindowResize() {
    if (!container || !renderer || !camera) return;
    const w = container.clientWidth;
    const h = container.clientHeight || 560;
    camera.aspect = w / h;
    camera.updateProjectionMatrix();
    renderer.setSize(w, h);
  }

  // Animation Loop
  function animate() {
    requestAnimationFrame(animate);

    // Smooth inertia
    currentRotation.x += (targetRotation.x - currentRotation.x) * 0.08;
    currentRotation.y += (targetRotation.y - currentRotation.y) * 0.08;
    if (laptopGroup) {
      laptopGroup.rotation.x = currentRotation.x;
      laptopGroup.rotation.y = currentRotation.y;
    }

    currentPosition.y += (targetPosition.y - currentPosition.y) * 0.08;
    if (laptopGroup) {
      laptopGroup.position.y = currentPosition.y;
    }

    // Smooth Hinge Physics
    currentLidAngle += (targetLidAngle - currentLidAngle) * 0.12;
    if (lidGroup) {
      lidGroup.rotation.x = -currentLidAngle;
    }

    // Ambient floating idle bob
    pulsePhase += 0.035;
    if (laptopGroup && !isDragging) {
      laptopGroup.position.y = currentPosition.y + Math.sin(pulsePhase * 0.8) * 0.035;
    }

    // Particles slow galaxy rotation
    if (particles) {
      particles.rotation.y += 0.0018;
    }

    // Radiant Emerald Clamshell Beam
    const isLidClosed = currentLidAngle < 0.15;
    if (glowRing) {
      if (isLidClosed && isOpenLidAwake) {
        glowRing.visible = true;
        glowRing.scale.setScalar(1 + Math.sin(pulsePhase * 2.2) * 0.08);
        glowRing.material.opacity = 0.45 + Math.sin(pulsePhase * 2.2) * 0.2;
      } else if (!isLidClosed) {
        glowRing.visible = true;
        glowRing.scale.setScalar(1);
        glowRing.material.opacity = 0.15;
      } else {
        glowRing.visible = false;
      }
    }

    // Live HUD readout in DOM
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

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initThree);
  } else {
    initThree();
  }
})();
