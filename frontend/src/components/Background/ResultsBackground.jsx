// src/components/Background/ResultsBackground.jsx
import React, { useRef, useEffect } from "react";
import * as THREE from "three";

export default function ResultsBackground() {
  const canvasRef = useRef();

  useEffect(() => {
    const scene = new THREE.Scene();
    scene.fog = new THREE.FogExp2(0x0a2540, 0.0006);

    const camera = new THREE.PerspectiveCamera(
      75,
      window.innerWidth / window.innerHeight,
      0.1,
      2200
    );
    camera.position.z = 850;

    const renderer = new THREE.WebGLRenderer({
      canvas: canvasRef.current,
      alpha: true,
      antialias: true,
      powerPreference: "high-performance",
    });
    renderer.setSize(window.innerWidth, window.innerHeight);
    renderer.setPixelRatio(1);

    // Glow Texture para pontos
    function generateGlowTexture() {
      const canvas = document.createElement("canvas");
      canvas.width = 48;
      canvas.height = 48;
      const ctx = canvas.getContext("2d");
      const gradient = ctx.createRadialGradient(24, 24, 0, 24, 24, 24);
      gradient.addColorStop(0, "rgba(255,255,255,0.9)");
      gradient.addColorStop(0.5, "rgba(124,207,255,0.25)");
      gradient.addColorStop(1, "rgba(100,185,255,0)");
      ctx.fillStyle = gradient;
      ctx.fillRect(0, 0, 48, 48);
      return canvas;
    }
    const glowTexture = new THREE.CanvasTexture(generateGlowTexture());

    // Partículas espaçadas (bem menos do que a viagem)
    const PARTICLE_COUNT = 340;
    const positions = new Float32Array(PARTICLE_COUNT * 3);
    const colors = new Float32Array(PARTICLE_COUNT * 3);

    for (let i = 0; i < PARTICLE_COUNT; i++) {
      const theta = Math.random() * Math.PI * 2;
      const r = Math.pow(Math.random(), 0.75) * 720;
      positions[i * 3] = Math.cos(theta) * r;
      positions[i * 3 + 1] = Math.sin(theta) * r;
      positions[i * 3 + 2] = Math.random() * -1600;

      const hue = Math.random() * 0.13 + 0.58;
      const color = new THREE.Color().setHSL(hue, 0.52, 0.82);
      colors[i * 3] = color.r;
      colors[i * 3 + 1] = color.g;
      colors[i * 3 + 2] = color.b;
    }

    const geometry = new THREE.BufferGeometry();
    geometry.setAttribute("position", new THREE.BufferAttribute(positions, 3));
    geometry.setAttribute("color", new THREE.BufferAttribute(colors, 3));

    const material = new THREE.PointsMaterial({
      size: 13,
      map: glowTexture,
      vertexColors: true,
      blending: THREE.AdditiveBlending,
      transparent: true,
      depthTest: true,
      sizeAttenuation: true,
      alphaTest: 0.001,
    });

    const particles = new THREE.Points(geometry, material);
    scene.add(particles);

    // Lights
    scene.add(new THREE.AmbientLight(0x404040, 1.2));
    const hemiLight = new THREE.HemisphereLight(0xffffff, 0x444444, 1);
    hemiLight.position.set(0, 200, 0);
    scene.add(hemiLight);

    scene.add(new THREE.PointLight(0x3b82f6, 1.6, 1400).position.set(600, 700, 800));
    scene.add(new THREE.DirectionalLight(0xffffff, 0.4).position.set(0, 800, 0));

    // Animação lenta, sutil (somente rotação do grupo)
    function animate() {
      particles.rotation.y += 0.00017;
      particles.rotation.z += 0.00003;
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
        zIndex: 0,
        pointerEvents: "none",
      }}
    />
  );
}
