(function () {
    const root = document.getElementById('rsl-character-select');
    const grid = document.getElementById('rsl-character-select-slots');

    function render(slots) {
        grid.innerHTML = '';

        for (const slot of slots) {
            const card = document.createElement('div');
            card.className = 'rcs-slot rsl-panel';

            if (slot.occupied) {
                card.innerHTML = `
                    <div class="rcs-slot__label">Slot ${slot.slotIndex}</div>
                    <div class="rcs-slot__name">${slot.name}</div>
                    <div class="rcs-slot__level">Level ${slot.level}</div>
                    <div class="rcs-slot__actions">
                        <button class="rsl-btn" data-action="play">Play</button>
                        <button class="rsl-btn rsl-btn--ghost" data-action="delete">Delete</button>
                    </div>
                `;
                card.addEventListener('mouseenter', () => RSL.post('characterSelect:preview', { slotIndex: slot.slotIndex }));
                card.querySelector('[data-action="play"]').addEventListener('click', (e) => {
                    e.stopPropagation();
                    RSL.post('characterSelect:play', { id: slot.id });
                });
                card.querySelector('[data-action="delete"]').addEventListener('click', (e) => {
                    e.stopPropagation();
                    if (confirm(`Delete "${slot.name}"? This cannot be undone.`)) {
                        RSL.post('characterSelect:delete', { id: slot.id });
                    }
                });
            } else {
                card.innerHTML = `
                    <div class="rcs-slot__empty-icon">+</div>
                    <div class="rcs-slot__label">Slot ${slot.slotIndex} · Empty</div>
                `;
                card.addEventListener('click', () => RSL.post('characterSelect:create', { slotIndex: slot.slotIndex }));
            }

            grid.appendChild(card);
        }
    }

    RSL.on('characterSelect:show', (data) => {
        root.classList.add('rsl-modal--visible');
        render(data.slots);
    });

    RSL.on('characterSelect:hide', () => {
        root.classList.remove('rsl-modal--visible');
    });

    // Tell Lua this page can actually receive characterSelect:show now —
    // on a fresh connect, Lua enters MAIN_MENU almost immediately, and
    // without this handshake the show message can arrive before this
    // script has even run, leaving the player stuck on a blank screen.
    RSL.post('characterSelect:ready');
})();
