(function () {
    const root = document.getElementById('rsl-dealership');
    const grid = document.getElementById('rsl-dealership-grid');

    function render(vehicles) {
        grid.innerHTML = '';

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
            card.querySelector('button').addEventListener('click', () => {
                RSL.post('dealership:buy', { model: vehicle.model });
            });
            grid.appendChild(card);
        }
    }

    RSL.on('dealership:show', (data) => {
        root.classList.add('rsl-modal--visible');
        render(data.vehicles);
    });

    RSL.on('dealership:hide', () => {
        root.classList.remove('rsl-modal--visible');
    });

    document.getElementById('rsl-dealership-close').addEventListener('click', () => RSL.post('dealership:close'));

    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && root.classList.contains('rsl-modal--visible')) {
            RSL.post('dealership:close');
        }
    });
})();
