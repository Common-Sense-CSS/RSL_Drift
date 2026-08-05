(function () {
    const root = document.getElementById('rsl-garage');
    const list = document.getElementById('rsl-garage-list');
    const titleEl = document.getElementById('rsl-garage-title');
    const countEl = document.getElementById('rsl-garage-count');
    const renameBtn = document.getElementById('rsl-garage-rename-btn');
    const renameRow = document.getElementById('rsl-garage-rename-row');
    const renameInput = document.getElementById('rsl-garage-rename-input');
    const renameSave = document.getElementById('rsl-garage-rename-save');
    const renameCancel = document.getElementById('rsl-garage-rename-cancel');

    let currentGarageId = null;

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

    function closeRename() {
        renameRow.hidden = true;
    }

    RSL.on('garage:show', (data) => {
        root.classList.add('rsl-modal--visible');
        currentGarageId = data.garageId;
        closeRename();
        render(data.vehicles);
        if (data.meta) {
            titleEl.textContent = data.meta.name;
            countEl.textContent = `${data.meta.count}/${data.meta.max}`;
            renameInput.value = data.meta.name;
        }
    });

    RSL.on('garage:hide', () => {
        root.classList.remove('rsl-modal--visible');
        closeRename();
    });

    RSL.on('garage:renamed', (data) => {
        if (data.garageId !== currentGarageId) return;
        titleEl.textContent = data.name;
        renameInput.value = data.name;
        closeRename();
    });

    renameBtn.addEventListener('click', () => {
        renameRow.hidden = !renameRow.hidden;
        if (!renameRow.hidden) renameInput.focus();
    });

    renameSave.addEventListener('click', () => {
        if (!currentGarageId) return;
        RSL.post('garage:rename', { garageId: currentGarageId, name: renameInput.value });
    });

    renameCancel.addEventListener('click', closeRename);

    document.getElementById('rsl-garage-close').addEventListener('click', () => RSL.post('garage:close'));

    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && root.classList.contains('rsl-modal--visible')) {
            RSL.post('garage:close');
        }
    });
})();
