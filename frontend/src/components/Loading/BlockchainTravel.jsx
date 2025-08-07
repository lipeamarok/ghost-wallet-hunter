import React, { useRef, useEffect } from "react";
import * as THREE from "three";

// Parâmetros do túnel
const PARTICLE_COUNT = 1800;
const TUNNEL_RADIUS = 580;
const TUNNEL_DEPTH = 3200;
const SPEED = 14;
const MAX_LINES = 7000;
const CONN_DIST = 195; // distância máxima para conectar

export default function BlockchainTravel() {
  const canvasRef = useRef();

  useEffect(() => {
    const scene = new THREE.Scene();
    scene.fog = new THREE.FogExp2(0x0a2540, 0.0005);

    const camera = new THREE.PerspectiveCamera(
      75,
      window.innerWidth / window.innerHeight,
      0.1,
      TUNNEL_DEPTH + 300
    );
    camera.position.z = 900;

    const renderer = new THREE.WebGLRenderer({
      canvas: canvasRef.current,
      alpha: true,
      antialias: true,
      powerPreference: "high-performance"
    });
    renderer.setSize(window.innerWidth, window.innerHeight);
    renderer.setPixelRatio(1);

    // Glow Texture
    function generateGlowTexture() {
      const canvas = document.createElement("canvas");
      canvas.width = 64;
      canvas.height = 64;
      const ctx = canvas.getContext("2d");
      const gradient = ctx.createRadialGradient(32, 32, 0, 32, 32, 32);
      gradient.addColorStop(0, "rgba(255,255,255,1)");
      gradient.addColorStop(0.5, "rgba(255,255,255,0.3)");
      gradient.addColorStop(1, "rgba(255,255,255,0)");
      ctx.fillStyle = gradient;
      ctx.fillRect(0, 0, 64, 64);
      return canvas;
    }
    const glowTexture = new THREE.CanvasTexture(generateGlowTexture());

    // ---- POSIÇÕES: TÚNEL ----
    const positions = new Float32Array(PARTICLE_COUNT * 3);
    const colors = new Float32Array(PARTICLE_COUNT * 3);
    const sizes = new Float32Array(PARTICLE_COUNT);
    const velocityZ = new Float32Array(PARTICLE_COUNT);

    for (let i = 0; i < PARTICLE_COUNT; i++) {
      // Túnel: x² + y² <= r², z entre -TUNNEL_DEPTH e 900
      const theta = Math.random() * Math.PI * 2;
      const r = Math.pow(Math.random(), 0.7) * TUNNEL_RADIUS;
      positions[i * 3] = Math.cos(theta) * r;
      positions[i * 3 + 1] = Math.sin(theta) * r;
      positions[i * 3 + 2] = Math.random() * -TUNNEL_DEPTH;
      velocityZ[i] = SPEED + Math.random() * 5.3;

      if (Math.random() < 0.08) {
        colors[i * 3] = 1;
        colors[i * 3 + 1] = 0.1;
        colors[i * 3 + 2] = 0.1;
      } else {
        const hue = Math.random() * 0.1 + 0.54;
        const color = new THREE.Color().setHSL(hue, 0.88, 0.75);
        colors[i * 3] = color.r;
        colors[i * 3 + 1] = color.g;
        colors[i * 3 + 2] = color.b;
      }
      sizes[i] = Math.random() * 11 + 8;
    }

    const geometry = new THREE.BufferGeometry();
    geometry.setAttribute("position", new THREE.BufferAttribute(positions, 3));
    geometry.setAttribute("color", new THREE.BufferAttribute(colors, 3));
    geometry.setAttribute("size", new THREE.BufferAttribute(sizes, 1));

    const material = new THREE.PointsMaterial({
      size: 13,
      map: glowTexture,
      vertexColors: true,
      blending: THREE.AdditiveBlending,
      transparent: true,
      depthTest: true,
      sizeAttenuation: true,
      alphaTest: 0.001
    });

    const particles = new THREE.Points(geometry, material);
    scene.add(particles);

    // --- Lines: buffer fixo, atualiza frame a frame
    const linePositions = new Float32Array(MAX_LINES * 6);
    const lineColors = new Float32Array(MAX_LINES * 6);

    const lineGeometry = new THREE.BufferGeometry();
    lineGeometry.setAttribute(
      "position",
      new THREE.BufferAttribute(linePositions, 3)
    );
    lineGeometry.setAttribute(
      "color",
      new THREE.BufferAttribute(lineColors, 3)
    );
    lineGeometry.setDrawRange(0, 0);

    const lineMaterial = new THREE.LineBasicMaterial({
      vertexColors: true,
      blending: THREE.AdditiveBlending,
      transparent: true,
      opacity: 0.14,
      linewidth: 1,
    });

    const lines = new THREE.LineSegments(lineGeometry, lineMaterial);
    scene.add(lines);

    // --- Lights
    scene.add(new THREE.AmbientLight(0x404040, 1.4));
    const hemiLight = new THREE.HemisphereLight(0xffffff, 0x444444, 1);
    hemiLight.position.set(0, 200, 0);
    scene.add(hemiLight);

    const pointLight1 = new THREE.PointLight(0x3b82f6, 3, 1700);
    pointLight1.position.set(500, 500, 500);
    scene.add(pointLight1);
    
    const pointLight2 = new THREE.PointLight(0x22c55e, 2, 900);
    pointLight2.position.set(-700, -600, -800);
    scene.add(pointLight2);
    
    const dirLight = new THREE.DirectionalLight(0xffffff, 0.65);
    dirLight.position.set(0, 900, 0);
    scene.add(dirLight);

    // --- ANIMAÇÃO
    function animate() {
      // Move as partículas no eixo Z (warp)
      const positionsAttr = geometry.attributes.position;
      for (let i = 0; i < PARTICLE_COUNT; i++) {
        positionsAttr.array[i * 3 + 2] += velocityZ[i];
        if (positionsAttr.array[i * 3 + 2] > 900) {
          // recicla para fundo do túnel, novo X/Y
          const theta = Math.random() * Math.PI * 2;
          const r = Math.pow(Math.random(), 0.7) * TUNNEL_RADIUS;
          positionsAttr.array[i * 3] = Math.cos(theta) * r;
          positionsAttr.array[i * 3 + 1] = Math.sin(theta) * r;
          positionsAttr.array[i * 3 + 2] = -TUNNEL_DEPTH + Math.random() * -400;
        }
      }
      positionsAttr.needsUpdate = true;

      // Gera linhas dinâmicas SÓ entre pares próximos no espaço, com limite de performance
      let lineIdx = 0;
      for (let i = 0; i < PARTICLE_COUNT; i++) {
        // Diminui conexões para performance
        if (i % 6 !== 0) continue;
        const x1 = positionsAttr.array[i * 3];
        const y1 = positionsAttr.array[i * 3 + 1];
        const z1 = positionsAttr.array[i * 3 + 2];
        for (let j = i + 1; j < PARTICLE_COUNT; j++) {
          const x2 = positionsAttr.array[j * 3];
          const y2 = positionsAttr.array[j * 3 + 1];
          const z2 = positionsAttr.array[j * 3 + 2];
          const dx = x1 - x2, dy = y1 - y2, dz = z1 - z2;
          const dist = Math.sqrt(dx * dx + dy * dy + dz * dz);
          if (dist < CONN_DIST && lineIdx < MAX_LINES) {
            // Só conecta se os dois estiverem razoavelmente no centro do túnel (não nas bordas extremas)
            if (Math.abs(x1) < TUNNEL_RADIUS * 1.05 && Math.abs(x2) < TUNNEL_RADIUS * 1.05) {
              linePositions[lineIdx * 6 + 0] = x1;
              linePositions[lineIdx * 6 + 1] = y1;
              linePositions[lineIdx * 6 + 2] = z1;
              linePositions[lineIdx * 6 + 3] = x2;
              linePositions[lineIdx * 6 + 4] = y2;
              linePositions[lineIdx * 6 + 5] = z2;
              let color = new THREE.Color(0x3b82f6).lerp(new THREE.Color(0x38ffe6), Math.random() * 0.32);
              for (let k = 0; k < 2; k++) {
                lineColors[lineIdx * 6 + k * 3 + 0] = color.r;
                lineColors[lineIdx * 6 + k * 3 + 1] = color.g;
                lineColors[lineIdx * 6 + k * 3 + 2] = color.b;
              }
              lineIdx++;
            }
          }
          if (lineIdx >= MAX_LINES) break;
        }
        if (lineIdx >= MAX_LINES) break;
      }
      lineGeometry.attributes.position.needsUpdate = true;
      lineGeometry.attributes.color.needsUpdate = true;
      lineGeometry.setDrawRange(0, lineIdx * 2);

      renderer.render(scene, camera);
      requestAnimationFrame(animate);
    }
    animate();

    function handleResize() {
      camera.aspect = window.innerWidth / window.innerHeight;
      camera.updateProjectionMatrix();
      renderer.setSize(window.innerWidth, window.innerHeight);
    }
    window.addEventListener("resize", handleResize);

    return () => {
      window.removeEventListener("resize", handleResize);
      renderer.dispose();
    };
  }, []);

  return (
    <canvas
      ref={canvasRef}
      className="fixed top-0 left-0 w-full h-full"
      style={{
        zIndex: 10,
        pointerEvents: "none"
      }}
    />
  );
}
