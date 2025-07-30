// ThreeBackground.jsx
import React, { useRef, useEffect } from "react";
import * as THREE from "three";
import { OrbitControls } from "three/addons/controls/OrbitControls.js";

export default function ThreeBackground() {
  const canvasRef = useRef();

  useEffect(() => {
    const scene = new THREE.Scene();
    scene.fog = new THREE.FogExp2(0x0a2540, 0.0005);

    const camera = new THREE.PerspectiveCamera(
      75,
      window.innerWidth / window.innerHeight,
      0.1,
      3000
    );
    camera.position.z = 1000;

    const renderer = new THREE.WebGLRenderer({
      canvas: canvasRef.current,
      alpha: true,
      antialias: true,
      powerPreference: "high-performance"
    });
    renderer.setSize(window.innerWidth, window.innerHeight);

    // >>> OTIMIZAÇÃO: pixelRatio baixo (deixa tudo MUITO mais leve)
    renderer.setPixelRatio(1);

    // --- Partículas ---
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

    // Mantém os 2000 pontos!
    const particleCount = 2000;
    const positions = new Float32Array(particleCount * 3);
    const colors = new Float32Array(particleCount * 3);
    const sizes = new Float32Array(particleCount);

    for (let i = 0; i < particleCount; i++) {
  positions[i * 3] = (Math.random() - 0.5) * 2000;
  positions[i * 3 + 1] = (Math.random() - 0.5) * 2000;
  positions[i * 3 + 2] = (Math.random() - 0.5) * 2000;

  // 8% vermelhos (corrompidos)
  if (Math.random() < 0.08) {
    colors[i * 3] = 1;
    colors[i * 3 + 1] = 0;
    colors[i * 3 + 2] = 0;
  } else {
    const hue = Math.random() * 0.1 + 0.5;
    const color = new THREE.Color().setHSL(hue, 0.8, 0.7);
    colors[i * 3] = color.r;
    colors[i * 3 + 1] = color.g;
    colors[i * 3 + 2] = color.b;
  }
  sizes[i] = Math.random() * 10 + 5;
}

    const geometry = new THREE.BufferGeometry();
    geometry.setAttribute("position", new THREE.BufferAttribute(positions, 3));
    geometry.setAttribute("color", new THREE.BufferAttribute(colors, 3));
    geometry.setAttribute("size", new THREE.BufferAttribute(sizes, 1));

    const material = new THREE.PointsMaterial({
      size: 10,
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

    // --- Conexões ---
    const lineGeometry = new THREE.BufferGeometry();
    const linePositions = [];
    const lineColors = [];

    for (let i = 0; i < particleCount; i++) {
      for (let j = i + 1; j < particleCount; j++) {
        const p1 = new THREE.Vector3(
          positions[i * 3],
          positions[i * 3 + 1],
          positions[i * 3 + 2]
        );
        const p2 = new THREE.Vector3(
          positions[j * 3],
          positions[j * 3 + 1],
          positions[j * 3 + 2]
        );
        const dist = p1.distanceTo(p2);

        if (dist < 250 && Math.random() > 0.85) {
          linePositions.push(p1.x, p1.y, p1.z);
          linePositions.push(p2.x, p2.y, p2.z);

          const color = new THREE.Color(0x3b82f6).multiplyScalar(0.4 + Math.random() * 0.2);
          lineColors.push(color.r, color.g, color.b, color.r, color.g, color.b);
        }
      }
    }

    lineGeometry.setAttribute(
      "position",
      new THREE.Float32BufferAttribute(linePositions, 3)
    );
    lineGeometry.setAttribute(
      "color",
      new THREE.Float32BufferAttribute(lineColors, 3)
    );

    const lineMaterial = new THREE.LineBasicMaterial({
      vertexColors: true,
      blending: THREE.AdditiveBlending,
      transparent: true,
      opacity: 0.6,
      linewidth: 1,
    });

    const lines = new THREE.LineSegments(lineGeometry, lineMaterial);
    scene.add(lines);

    // --- Luzes ---
    const ambientLight = new THREE.AmbientLight(0x404040, 1.5);
    scene.add(ambientLight);
    const hemiLight = new THREE.HemisphereLight(0xffffff, 0x444444, 1);
    hemiLight.position.set(0, 200, 0);
    scene.add(hemiLight);

    const pointLight1 = new THREE.PointLight(0x3b82f6, 3, 2000);
    pointLight1.position.set(500, 500, 500);
    pointLight1.castShadow = true;
    scene.add(pointLight1);

    const pointLight2 = new THREE.PointLight(0x22c55e, 2, 1500);
    pointLight2.position.set(-500, -500, -500);
    pointLight2.castShadow = true;
    scene.add(pointLight2);

    const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
    directionalLight.position.set(0, 1000, 0);
    directionalLight.castShadow = true;
    scene.add(directionalLight);

    // --- Orbit Controls ---
    const controls = new OrbitControls(camera, renderer.domElement);
    controls.enableDamping = true;
    controls.dampingFactor = 0.1;
    controls.screenSpacePanning = false;
    controls.minDistance = 300;
    controls.maxDistance = 2000;

    // --- ANIMAÇÃO: throttle update ---
    let frame = 0;
    function animate(time) {
      // Move os pontos a cada 2 frames só
      if (frame % 2 === 0) {
        const positionsAttr = geometry.attributes.position;
        for (let i = 0; i < particleCount; i++) {
          positionsAttr.array[i * 3] += Math.sin(time * 0.0005 + i * 0.1) * 0.03;
          positionsAttr.array[i * 3 + 1] += Math.cos(time * 0.0007 + i * 0.2) * 0.02;
          positionsAttr.array[i * 3 + 2] += Math.sin(time * 0.0006 + i * 0.3) * 0.03;
        }
        positionsAttr.needsUpdate = true;
      }
      frame++;

      particles.rotation.y += 0.00015;
      particles.rotation.z += 0.00005;
      lines.rotation.y += 0.00015;
      lines.rotation.z += 0.00005;
      lineMaterial.opacity = 0.4 + Math.sin(time * 0.001) * 0.3;
      controls.update();
      renderer.render(scene, camera);
      requestAnimationFrame(animate);
    }
    animate(0);

    function handleResize() {
      camera.aspect = window.innerWidth / window.innerHeight;
      camera.updateProjectionMatrix();
      renderer.setSize(window.innerWidth, window.innerHeight);
    }
    window.addEventListener("resize", handleResize);

    function handleMouseMove(event) {
      const mouseX = (event.clientX / window.innerWidth) * 2 - 1;
      const mouseY = -(event.clientY / window.innerHeight) * 2 + 1;
      camera.position.x = mouseX * 150;
      camera.position.y = mouseY * 150;
      camera.lookAt(scene.position);
    }
    document.addEventListener("mousemove", handleMouseMove);

    return () => {
      window.removeEventListener("resize", handleResize);
      document.removeEventListener("mousemove", handleMouseMove);
      renderer.dispose();
    };
  }, []);

  return (
    <canvas
      ref={canvasRef}
      className="fixed top-0 left-0 w-full h-full"
      style={{
        zIndex: 1,
        pointerEvents: 'none'
      }}
    />
  );
}
