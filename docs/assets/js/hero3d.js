// Lumina hero — floating panels of the real app UI drifting among slow stars.
// Mirrors the native app's motion language (slow gyroscope star parallax, no
// spring bounce). Built defensively: reduced-motion, no-WebGL, or a blocked
// CDN all fall back to a single static screenshot — nothing ever breaks.

const PANELS = [
  { src: "assets/img/screenshots/chart-wheel.png", x: 0, z: 0, scale: 0.74, phase: 0 },
  { src: "assets/img/screenshots/today.png", x: -2.5, z: -1.6, scale: 0.55, phase: 2.1 },
  { src: "assets/img/screenshots/synastry.png", x: 2.5, z: -1.8, scale: 0.55, phase: 4.2 },
];
// The headline text sits vertically centered in the hero, so the whole panel
// cluster is pushed down into the lower stage to stay clear of it — the two
// layers occupy visually distinct bands instead of overlapping.
const PANEL_RIG_Y_OFFSET = -2.35;

function prefersReducedMotion() {
  return window.matchMedia("(prefers-reduced-motion: reduce)").matches;
}

function supportsWebGL() {
  try {
    const test = document.createElement("canvas");
    return !!(window.WebGLRenderingContext && (test.getContext("webgl") || test.getContext("experimental-webgl")));
  } catch {
    return false;
  }
}

function showFallback(wrap) {
  wrap.classList.add("is-static");
  const img = wrap.querySelector(".hero-static-fallback");
  if (img) img.hidden = false;
}

function loadImage(src) {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => resolve(img);
    img.onerror = reject;
    img.src = src;
  });
}

// Draws the screenshot into a rounded-rect-clipped canvas so it reads as a
// screen, not a pasted rectangle — without needing a modeled phone chassis.
function roundedTexture(THREE, image, radius = 56) {
  const canvas = document.createElement("canvas");
  canvas.width = image.naturalWidth;
  canvas.height = image.naturalHeight;
  const ctx = canvas.getContext("2d");
  const w = canvas.width;
  const h = canvas.height;
  ctx.beginPath();
  ctx.moveTo(radius, 0);
  ctx.arcTo(w, 0, w, h, radius);
  ctx.arcTo(w, h, 0, h, radius);
  ctx.arcTo(0, h, 0, 0, radius);
  ctx.arcTo(0, 0, w, 0, radius);
  ctx.closePath();
  ctx.clip();
  ctx.drawImage(image, 0, 0, w, h);
  const texture = new THREE.CanvasTexture(canvas);
  texture.colorSpace = THREE.SRGBColorSpace;
  texture.anisotropy = 4;
  return texture;
}

function softDotTexture(THREE) {
  const canvas = document.createElement("canvas");
  canvas.width = 64;
  canvas.height = 64;
  const ctx = canvas.getContext("2d");
  const g = ctx.createRadialGradient(32, 32, 0, 32, 32, 32);
  g.addColorStop(0, "rgba(255,255,255,1)");
  g.addColorStop(0.4, "rgba(255,250,240,0.7)");
  g.addColorStop(1, "rgba(255,250,240,0)");
  ctx.fillStyle = g;
  ctx.fillRect(0, 0, 64, 64);
  return new THREE.CanvasTexture(canvas);
}

// A 4-point sparkle echoing the app's own icon/glyph motif, not a generic star.
function sparkleTexture(THREE, color) {
  const canvas = document.createElement("canvas");
  canvas.width = 64;
  canvas.height = 64;
  const ctx = canvas.getContext("2d");
  ctx.translate(32, 32);
  ctx.fillStyle = color;
  const r = 27;
  ctx.beginPath();
  ctx.moveTo(0, -r);
  ctx.quadraticCurveTo(5, -5, r, 0);
  ctx.quadraticCurveTo(5, 5, 0, r);
  ctx.quadraticCurveTo(-5, 5, -r, 0);
  ctx.quadraticCurveTo(-5, -5, 0, -r);
  ctx.closePath();
  ctx.fill();
  return new THREE.CanvasTexture(canvas);
}

async function buildScene(THREE, canvas, wrap) {
  const images = await Promise.all(PANELS.map((p) => loadImage(p.src)));

  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(38, 1, 0.1, 100);
  camera.position.set(0, 0.15, 9.2);

  const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: true });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
  renderer.outputColorSpace = THREE.SRGBColorSpace;

  // ---- Lighting: warm gold key + cool blue rim, matching the brand palette ----
  scene.add(new THREE.AmbientLight(0xffffff, 0.55));
  const key = new THREE.DirectionalLight(0xc9a96e, 1.1);
  key.position.set(3, 4, 5);
  scene.add(key);
  const rim = new THREE.DirectionalLight(0x3d5a8c, 0.9);
  rim.position.set(-4, -2, -3);
  scene.add(rim);

  // ---- Starfield ----
  const starRig = new THREE.Group();
  scene.add(starRig);

  const starGeo = new THREE.BufferGeometry();
  const STAR_COUNT = 420;
  const positions = new Float32Array(STAR_COUNT * 3);
  for (let i = 0; i < STAR_COUNT; i++) {
    const radius = 6 + Math.random() * 9;
    const theta = Math.random() * Math.PI * 2;
    const phi = Math.acos(Math.random() * 2 - 1);
    positions[i * 3] = radius * Math.sin(phi) * Math.cos(theta);
    positions[i * 3 + 1] = radius * Math.sin(phi) * Math.sin(theta);
    positions[i * 3 + 2] = radius * Math.cos(phi) - 4;
  }
  starGeo.setAttribute("position", new THREE.BufferAttribute(positions, 3));
  const starMat = new THREE.PointsMaterial({
    size: 0.05,
    map: softDotTexture(THREE),
    transparent: true,
    depthWrite: false,
    opacity: 0.85,
  });
  starRig.add(new THREE.Points(starGeo, starMat));

  // A handful of larger gold sparkles echoing the app icon's star mark.
  const sparkleMat = new THREE.SpriteMaterial({
    map: sparkleTexture(THREE, "#C9A96E"),
    transparent: true,
    depthWrite: false,
  });
  const sparkles = [];
  for (let i = 0; i < 10; i++) {
    const sprite = new THREE.Sprite(sparkleMat.clone());
    const radius = 4.5 + Math.random() * 4;
    const theta = Math.random() * Math.PI * 2;
    const y = (Math.random() - 0.5) * 6;
    sprite.position.set(Math.cos(theta) * radius, y, Math.sin(theta) * radius - 3);
    const scale = 0.12 + Math.random() * 0.16;
    sprite.scale.set(scale, scale, scale);
    sprite.userData.phase = Math.random() * Math.PI * 2;
    starRig.add(sprite);
    sparkles.push(sprite);
  }

  // ---- Floating interface panels ----
  const panelRig = new THREE.Group();
  panelRig.position.y = PANEL_RIG_Y_OFFSET;
  scene.add(panelRig);
  const panels = [];

  PANELS.forEach((cfg, i) => {
    const image = images[i];
    const aspect = image.naturalWidth / image.naturalHeight;
    const height = 3.1 * cfg.scale;
    const width = height * aspect;

    const group = new THREE.Group();

    // Bezel — a slightly larger dark plate behind the screenshot, giving it
    // screen-like presence without modeling a full device chassis.
    const bezelGeo = new THREE.PlaneGeometry(width + 0.14, height + 0.14);
    const bezelMat = new THREE.MeshStandardMaterial({ color: 0x14141a, roughness: 0.6, metalness: 0.2 });
    const bezel = new THREE.Mesh(bezelGeo, bezelMat);
    bezel.position.z = -0.03;
    group.add(bezel);

    const screenGeo = new THREE.PlaneGeometry(width, height);
    const screenMat = new THREE.MeshBasicMaterial({ map: roundedTexture(THREE, image), toneMapped: false });
    const screen = new THREE.Mesh(screenGeo, screenMat);
    group.add(screen);

    group.position.set(cfg.x, 0, cfg.z);
    group.rotation.y = i === 0 ? 0 : (cfg.x < 0 ? 0.32 : -0.32);
    group.userData = { baseY: 0, baseZ: cfg.z, phase: cfg.phase };
    panelRig.add(group);
    panels.push(group);
  });

  // ---- Resize ----
  function resize() {
    const rect = wrap.getBoundingClientRect();
    camera.aspect = rect.width / Math.max(rect.height, 1);
    camera.updateProjectionMatrix();
    renderer.setSize(rect.width, rect.height, false);
  }
  const resizeObserver = new ResizeObserver(resize);
  resizeObserver.observe(wrap);
  resize();

  // ---- Pointer parallax (desktop only — no permission prompts on touch) ----
  let targetYaw = 0;
  let targetPitch = 0;
  window.addEventListener("pointermove", (e) => {
    targetYaw = ((e.clientX / window.innerWidth) * 2 - 1) * 0.22;
    targetPitch = ((e.clientY / window.innerHeight) * 2 - 1) * 0.1;
  });

  // ---- Visibility gating — pause rendering off-screen or in a hidden tab ----
  let isVisible = true;
  new IntersectionObserver(([entry]) => { isVisible = entry.isIntersecting; }, { threshold: 0.05 }).observe(wrap);

  const clock = new THREE.Clock();

  function tick() {
    requestAnimationFrame(tick);
    if (document.hidden || !isVisible) return;
    const t = clock.getElapsedTime();

    panelRig.rotation.y += (targetYaw - panelRig.rotation.y) * 0.04;
    panelRig.rotation.x += (-targetPitch - panelRig.rotation.x) * 0.04;
    starRig.rotation.y = t * 0.015;

    panels.forEach((p) => {
      const { baseY, baseZ, phase } = p.userData;
      p.position.y = baseY + Math.sin(t * 0.5 + phase) * 0.14;
      p.position.z = baseZ + Math.cos(t * 0.35 + phase) * 0.08;
      p.rotation.z = Math.sin(t * 0.3 + phase) * 0.015;
    });

    sparkles.forEach((s) => {
      const flicker = 0.55 + Math.sin(t * 1.4 + s.userData.phase) * 0.45;
      s.material.opacity = Math.max(0, flicker);
    });

    renderer.render(scene, camera);
  }

  tick();
}

async function init() {
  const wrap = document.getElementById("hero-canvas-wrap");
  const canvas = document.getElementById("hero-canvas");
  if (!wrap || !canvas) return;

  if (prefersReducedMotion() || !supportsWebGL()) {
    showFallback(wrap);
    return;
  }

  try {
    const THREE = await import("three");
    await buildScene(THREE, canvas, wrap);
  } catch (err) {
    console.warn("Lumina hero: 3D scene unavailable, showing static fallback.", err);
    showFallback(wrap);
  }
}

init();
