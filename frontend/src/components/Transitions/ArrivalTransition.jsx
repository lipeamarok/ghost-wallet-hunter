  import React, { useEffect, useRef } from "react";
  import * as THREE from "three";

  // Parâmetros da transição
  const PARTICLE_COUNT = 850;
  const RADIUS = 280;
  const DURATION = 1.85 * 1000; // ms

  export default function ArrivalTransition({ onFinish }) {
    const canvasRef = useRef();

    useEffect(() => {
      let running = true;

      // --- Setup Three.js ---
      const scene = new THREE.Scene();
      scene.fog = new THREE.FogExp2(0x09101a, 0.0022);

      // Câmera central, campo próximo
      const camera = new THREE.PerspectiveCamera(
        65,
        window.innerWidth / window.innerHeight,
        0.1,
        2200
      );
      camera.position.z = 550;

      // Renderer
      const renderer = new THREE.WebGLRenderer({
        canvas: canvasRef.current,
        alpha: true,
        antialias: true
      });
      renderer.setClearColor(0x030614, 1);
      renderer.setSize(window.innerWidth, window.innerHeight);
      renderer.setPixelRatio(window.devicePixelRatio);

      // --- Partículas ---
      // Glow Texture
      function generateGlowTexture() {
        const canvas = document.createElement("canvas");
        canvas.width = 64;
        canvas.height = 64;
        const ctx = canvas.getContext("2d");
        const gradient = ctx.createRadialGradient(32, 32, 0, 32, 32, 32);
        gradient.addColorStop(0, "rgba(255,255,255,1)");
        gradient.addColorStop(0.5, "rgba(144,215,255,0.5)");
        gradient.addColorStop(1, "rgba(20,24,48,0)");
        ctx.fillStyle = gradient;
        ctx.fillRect(0, 0, 64, 64);
        return canvas;
      }
      const glowTexture = new THREE.CanvasTexture(generateGlowTexture());

      // Cluster alvo
      const targetCluster = new THREE.Vector3(
        (Math.random() - 0.5) * 35,
        (Math.random() - 0.5) * 35,
        -180 + Math.random() * 80
      );

      // Partículas
      const positions = new Float32Array(PARTICLE_COUNT * 3);
      const colors = new Float32Array(PARTICLE_COUNT * 3);
      const sizes = new Float32Array(PARTICLE_COUNT);

      for (let i = 0; i < PARTICLE_COUNT; i++) {
        // Distribuição esférica
        const theta = Math.random() * Math.PI * 2;
        const phi = Math.acos(2 * Math.random() - 1);
        const r = Math.pow(Math.random(), 0.84) * RADIUS + 40;
        positions[i * 3] = Math.sin(phi) * Math.cos(theta) * r;
        positions[i * 3 + 1] = Math.sin(phi) * Math.sin(theta) * r;
        positions[i * 3 + 2] = Math.cos(phi) * r - 80;

        if (i === 0) {
          // "Super partícula" (destino)
          colors[i * 3] = 1;
          colors[i * 3 + 1] = 0.89;
          colors[i * 3 + 2] = 0.31;
          sizes[i] = 56;
          positions[i * 3] = targetCluster.x;
          positions[i * 3 + 1] = targetCluster.y;
          positions[i * 3 + 2] = targetCluster.z;
        } else {
          // Resto azul/violeta
          const hue = Math.random() * 0.13 + 0.57;
          const color = new THREE.Color().setHSL(hue, 0.7, 0.69);
          colors[i * 3] = color.r;
          colors[i * 3 + 1] = color.g;
          colors[i * 3 + 2] = color.b;
          sizes[i] = Math.random() * 8 + 4.2;
        }
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

      // Luzes dramáticas
      const pt = new THREE.PointLight(0xffffff, 0.8, 800);
      pt.position.set(100, 180, 280);
      scene.add(pt);
      scene.add(new THREE.AmbientLight(0x346bd6, 1.1));
      scene.add(new THREE.HemisphereLight(0xffffff, 0x394080, 0.7));

      // --- EFEITO DE CHEGADA ---
      let start = null;
      let finished = false;

      function animate(now) {
        if (!start) start = now;
        const t = (now - start) / DURATION;
        // 0: início da transição, 1: fim
        // Câmera avança para o cluster, com easing
        const ease = t < 0.78 ? 1 - Math.pow(1 - t / 0.78, 3) : 1;
        camera.position.lerpVectors(
          new THREE.Vector3(0, 0, 550),
          new THREE.Vector3(targetCluster.x, targetCluster.y, targetCluster.z + 85),
          ease
        );
        camera.lookAt(targetCluster);

        // Todas partículas (menos a principal) são sugadas e desaparecem
        for (let i = 1; i < PARTICLE_COUNT; i++) {
          const ix = i * 3;
          // Vetor para o cluster alvo
          const toTarget = new THREE.Vector3(
            targetCluster.x - positions[ix],
            targetCluster.y - positions[ix + 1],
            targetCluster.z - positions[ix + 2]
          ).normalize();
          // Puxar para o centro: mais rápido quanto mais perto do fim da transição
          const pull = 6 + 70 * Math.pow(t, 1.5);
          positions[ix] += toTarget.x * pull * (0.9 + Math.random() * 0.1);
          positions[ix + 1] += toTarget.y * pull * (0.9 + Math.random() * 0.1);
          positions[ix + 2] += toTarget.z * pull * (0.88 + Math.random() * 0.14);

          // Diminuir tamanho/alpha
          if (sizes[i] > 0.1) sizes[i] *= 0.97 - t * 0.15;
        }
        geometry.attributes.position.needsUpdate = true;
        geometry.attributes.size.needsUpdate = true;

        // Principal cresce e brilha (flare)
        if (t > 0.81 && sizes[0] < 200) {
          sizes[0] += 5 + 80 * (t - 0.81);
          geometry.attributes.size.needsUpdate = true;
        }

        // Pequeno flash circular ao fim
        if (t > 0.94 && !finished) {
          finished = true;
          setTimeout(() => {
            running = false;
            if (onFinish) onFinish();
          }, 340);
        }

        renderer.render(scene, camera);
        if (running && t < 1.1) requestAnimationFrame(animate);
      }
      animate();

      function handleResize() {
        camera.aspect = window.innerWidth / window.innerHeight;
        camera.updateProjectionMatrix();
        renderer.setSize(window.innerWidth, window.innerHeight);
      }
      window.addEventListener("resize", handleResize);

      return () => {
        running = false;
        window.removeEventListener("resize", handleResize);
        renderer.dispose();
      };
    }, [onFinish]);

    return (
      <canvas
        ref={canvasRef}
        className="fixed top-0 left-0 w-full h-full z-[200]"
        style={{
          pointerEvents: "none",
          background: "radial-gradient(circle, #0a1640 80%, #070a16 100%)"
        }}
      />
    );
  }
