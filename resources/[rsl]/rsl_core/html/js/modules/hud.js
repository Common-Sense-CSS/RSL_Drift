(function () {
    const root = document.getElementById('rsl-hud');
    const speedEl = document.getElementById('rsl-hud-speed');
    const gearEl = document.getElementById('rsl-hud-gear');
    const unitEl = document.getElementById('rsl-hud-unit');

    RSL.on('hud:show', () => root.classList.add('rsl-hud--visible'));
    RSL.on('hud:hide', () => root.classList.remove('rsl-hud--visible'));

    RSL.on('hud:update', (data) => {
        const speed = Math.max(0, Math.round(data.speed || 0));
        const maxSpeed = data.maxSpeed || 200;
        speedEl.textContent = speed;
        gearEl.textContent = data.gear === 0 ? 'R' : (data.gear || 'N');
        unitEl.textContent = (data.unit || 'mph').toUpperCase();
        root.style.setProperty('--rsl-hud-pct', String(Math.min(100, (speed / maxSpeed) * 100)));
    });
})();
