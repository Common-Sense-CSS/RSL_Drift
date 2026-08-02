(function () {
    const root = document.getElementById('rsl-garage');
    const list = document.getElementById('rsl-garage-list');

    function render(vehicles) {
        list.innerHTML = '';

        if (!vehicles || vehicles.length === 0) {
            list.innerHTML = '<div class="rsl-empty">No vehicles stored here yet — visit a dealership.</div>';
            return;
        }

        for (const vehicle of vehicles) {
            const stored = vehicle.stored === 1;
            const card = document.createElement('div');
            card.className = 'rsl-vehicle-card';
            card.innerHTML = `
                <div class="rsl-vehicle-card__info">
                    <div class="rsl-vehicle-card__model">${vehicle.model}</div>
                    <div class="rsl-vehicle-card__status ${stored ? '' : 'rsl-vehicle-card__status--out'}">${stored ? 'Stored' : 'Out'} · ${vehicle.plate}</div>
                </div>
                <button class="rsl-btn" data-action="${stored ? 'spawn' : 'store'}">${stored ? 'Take Out' : 'Store'}</button>
            `;
            card.querySelector('button').addEventListener('click', () => {
                RSL.post(`garage:${stored ? 'spawn' : 'store'}`, { id: vehicle.id });
            });
            list.appendChild(card);
        }
    }

    RSL.on('garage:show', (data) => {
        root.classList.add('rsl-modal--visible');
        render(data.vehicles);
    });

    RSL.on('garage:hide', () => {
        root.classList.remove('rsl-modal--visible');
    });

    document.getElementById('rsl-garage-close').addEventListener('click', () => RSL.post('garage:close'));

    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && root.classList.contains('rsl-modal--visible')) {
            RSL.post('garage:close');
        }
    });
})();
