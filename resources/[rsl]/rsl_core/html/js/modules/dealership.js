(function () {
    const root = document.getElementById('rsl-dealership');
    const grid = document.getElementById('rsl-dealership-grid');
    const tabsEl = document.getElementById('rsl-dealership-tabs');

    const buyRoot = document.getElementById('rsl-dealership-buy');
    const buyTitle = document.getElementById('rsl-dealership-buy-title');
    const buyChoice = document.getElementById('rsl-dealership-buy-choice');
    const buyDrive = document.getElementById('rsl-dealership-buy-drive');
    const buyGarageBtn = document.getElementById('rsl-dealership-buy-garage');
    const buyGarages = document.getElementById('rsl-dealership-buy-garages');
    const buyClose = document.getElementById('rsl-dealership-buy-close');

    let catalogAll = [];
    let activeCategory = 'all';
    let pendingVehicle = null;

    function renderTabs() {
        const categories = [...new Set(catalogAll.map((v) => v.category).filter(Boolean))];
        tabsEl.innerHTML = '';

        const makeTab = (key, label) => {
            const btn = document.createElement('button');
            btn.className = 'rsl-tab' + (key === activeCategory ? ' rsl-tab--active' : '');
            btn.textContent = label;
            btn.addEventListener('click', () => {
                activeCategory = key;
                renderTabs();
                renderGrid();
            });
            tabsEl.appendChild(btn);
        };

        makeTab('all', 'All');
        for (const cat of categories) {
            makeTab(cat, cat.charAt(0).toUpperCase() + cat.slice(1));
        }
    }

    function renderGrid() {
        grid.innerHTML = '';
        const vehicles = activeCategory === 'all'
            ? catalogAll
            : catalogAll.filter((v) => v.category === activeCategory);

        for (const vehicle of vehicles) {
            const card = document.createElement('div');
            card.className = 'rsl-catalog-card';
            card.innerHTML = `
                <div class="rsl-catalog-card__brand">${vehicle.brand}</div>
                <div class="rsl-catalog-card__label">${vehicle.label}</div>
                <div class="rsl-catalog-card__footer">
                    <div class="rsl-catalog-card__price">$${vehicle.price.toLocaleString()}</div>
                    <button class="rsl-btn">Buy</button>
                </div>
            `;
            card.querySelector('button').addEventListener('click', () => openBuyModal(vehicle));
            grid.appendChild(card);
        }
    }

    function openBuyModal(vehicle) {
        pendingVehicle = vehicle;
        buyTitle.textContent = vehicle.label;
        buyChoice.hidden = false;
        buyGarages.hidden = true;
        buyGarages.innerHTML = '';
        buyRoot.classList.add('rsl-modal--visible');
    }

    function closeBuyModal() {
        pendingVehicle = null;
        buyRoot.classList.remove('rsl-modal--visible');
    }

    function renderGarages(garages) {
        buyChoice.hidden = true;
        buyGarages.hidden = false;
        buyGarages.innerHTML = '';

        if (!garages || garages.length === 0) {
            buyGarages.innerHTML = '<div class="rsl-empty">No garages available.</div>';
            return;
        }

        for (const garage of garages) {
            const row = document.createElement('div');
            row.className = 'rsl-vehicle-card';
            row.innerHTML = `
                <div class="rsl-vehicle-card__info">
                    <div class="rsl-vehicle-card__model">${garage.name}</div>
                    <div class="rsl-vehicle-card__status ${garage.full ? 'rsl-vehicle-card__status--out' : ''}">${garage.count}/${garage.max}${garage.full ? ' · Full' : ''}</div>
                </div>
                <button class="rsl-btn" ${garage.full ? 'disabled' : ''}>Select</button>
            `;
            const btn = row.querySelector('button');
            if (!garage.full) {
                btn.addEventListener('click', () => {
                    if (!pendingVehicle) return;
                    RSL.post('dealership:buy', { model: pendingVehicle.model, mode: 'garage', garageId: garage.id });
                });
            }
            buyGarages.appendChild(row);
        }
    }

    RSL.on('dealership:show', (data) => {
        root.classList.add('rsl-modal--visible');
        catalogAll = data.vehicles || [];
        activeCategory = 'all';
        renderTabs();
        renderGrid();
    });

    RSL.on('dealership:hide', () => {
        root.classList.remove('rsl-modal--visible');
        closeBuyModal();
    });

    RSL.on('dealership:garages', (data) => {
        renderGarages(data.garages);
    });

    RSL.on('dealership:purchaseResult', () => {
        closeBuyModal();
    });

    buyDrive.addEventListener('click', () => {
        if (!pendingVehicle) return;
        RSL.post('dealership:buy', { model: pendingVehicle.model, mode: 'drive' });
    });

    buyGarageBtn.addEventListener('click', () => {
        RSL.post('dealership:requestGarages');
    });

    buyClose.addEventListener('click', closeBuyModal);

    document.getElementById('rsl-dealership-close').addEventListener('click', () => RSL.post('dealership:close'));

    document.addEventListener('keydown', (e) => {
        if (e.key !== 'Escape') return;
        if (buyRoot.classList.contains('rsl-modal--visible')) {
            closeBuyModal();
        } else if (root.classList.contains('rsl-modal--visible')) {
            RSL.post('dealership:close');
        }
    });
})();
