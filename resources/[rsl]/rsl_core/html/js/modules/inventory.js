(function () {
    const root = document.getElementById('rsl-inventory');
    const grid = document.getElementById('rsl-inventory-grid');
    const weightEl = document.getElementById('rsl-inventory-weight');

    const detail = document.getElementById('rsl-inventory-detail');
    const detailLabel = document.getElementById('rsl-inventory-detail-label');
    const detailDesc = document.getElementById('rsl-inventory-detail-desc');
    const detailMeta = document.getElementById('rsl-inventory-detail-meta');
    const detailUse = document.getElementById('rsl-inventory-detail-use');
    const detailDrop = document.getElementById('rsl-inventory-detail-drop');

    let itemsBySlot = {};
    let totalSlots = 0;
    let selectedSlot = null;
    let dragSlot = null;

    function renderDetail() {
        const item = selectedSlot ? itemsBySlot[selectedSlot] : null;
        if (!item) {
            detail.hidden = true;
            return;
        }
        detail.hidden = false;
        detailLabel.textContent = item.label;
        detailDesc.textContent = item.description;
        detailMeta.textContent = `x${item.quantity} · ${item.weight.toFixed(1)} kg each`;
        detailUse.style.display = item.usable ? '' : 'none';
    }

    function renderGrid() {
        grid.innerHTML = '';
        for (let slot = 1; slot <= totalSlots; slot++) {
            const item = itemsBySlot[slot];
            const cell = document.createElement('div');
            cell.className = 'rsl-inventory__cell'
                + (item ? ' rsl-inventory__cell--filled' : '')
                + (slot === selectedSlot ? ' rsl-inventory__cell--selected' : '');
            cell.dataset.slot = String(slot);

            if (item) {
                cell.draggable = true;
                cell.innerHTML = `
                    <div class="rsl-inventory__cell-label">${item.label}</div>
                    ${item.quantity > 1 ? `<div class="rsl-inventory__cell-qty">x${item.quantity}</div>` : ''}
                `;
            }

            cell.addEventListener('click', () => {
                selectedSlot = item ? slot : null;
                renderDetail();
                renderGrid();
            });

            cell.addEventListener('dragstart', () => {
                dragSlot = slot;
            });

            cell.addEventListener('dragover', (e) => {
                e.preventDefault();
                cell.classList.add('rsl-inventory__cell--dragover');
            });

            cell.addEventListener('dragleave', () => {
                cell.classList.remove('rsl-inventory__cell--dragover');
            });

            cell.addEventListener('drop', (e) => {
                e.preventDefault();
                cell.classList.remove('rsl-inventory__cell--dragover');
                if (dragSlot && dragSlot !== slot) {
                    RSL.post('inventory:move', { from: dragSlot, to: slot });
                }
                dragSlot = null;
            });

            grid.appendChild(cell);
        }
    }

    RSL.on('inventory:show', (data) => {
        root.classList.add('rsl-modal--visible');
        totalSlots = data.slots;
        itemsBySlot = {};
        for (const item of data.items) itemsBySlot[item.slot] = item;
        if (selectedSlot && !itemsBySlot[selectedSlot]) selectedSlot = null;
        weightEl.textContent = `${data.weight.toFixed(1)} / ${data.maxWeight.toFixed(1)} kg`;
        renderGrid();
        renderDetail();
    });

    RSL.on('inventory:hide', () => {
        root.classList.remove('rsl-modal--visible');
        selectedSlot = null;
    });

    detailUse.addEventListener('click', () => {
        if (!selectedSlot) return;
        RSL.post('inventory:use', { slot: selectedSlot });
    });

    detailDrop.addEventListener('click', () => {
        if (!selectedSlot) return;
        RSL.post('inventory:drop', { slot: selectedSlot });
        selectedSlot = null;
    });

    document.getElementById('rsl-inventory-close').addEventListener('click', () => RSL.post('inventory:close'));

    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && root.classList.contains('rsl-modal--visible')) {
            RSL.post('inventory:close');
        }
    });
})();
