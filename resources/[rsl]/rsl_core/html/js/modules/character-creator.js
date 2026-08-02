(function () {
    const root = document.getElementById('rsl-character-creator');
    const panels = {
        identity: document.getElementById('rcc-panel-identity'),
        heritage: document.getElementById('rcc-panel-heritage'),
        structure: document.getElementById('rcc-panel-structure'),
        hair: document.getElementById('rcc-panel-hair'),
        makeup: document.getElementById('rcc-panel-makeup'),
        clothing: document.getElementById('rcc-panel-clothing'),
    };

    const FACE_FEATURE_LABELS = [
        'Nose Width', 'Nose Height', 'Nose Length', 'Nose Bridge Depth', 'Nose Tip Height', 'Nose Bend',
        'Eyebrow Height', 'Eyebrow Depth', 'Cheekbone Height', 'Cheekbone Width', 'Cheek Width',
        'Eye Squint', 'Lips Thickness', 'Jaw Width', 'Jaw Length', 'Chin Height', 'Chin Length',
        'Chin Width', 'Chin Dimple', 'Neck Thickness',
    ];

    const HERITAGE_FIELDS = [
        { path: 'headBlend.shapeFirst', label: 'Parent 1 (Shape)', min: 0, max: 20, step: 1 },
        { path: 'headBlend.shapeSecond', label: 'Parent 2 (Shape)', min: 0, max: 20, step: 1 },
        { path: 'headBlend.shapeMix', label: 'Resemblance', min: 0, max: 1, step: 0.01 },
        { path: 'headBlend.skinFirst', label: 'Parent 1 (Skin)', min: 0, max: 20, step: 1 },
        { path: 'headBlend.skinSecond', label: 'Parent 2 (Skin)', min: 0, max: 20, step: 1 },
        { path: 'headBlend.skinMix', label: 'Skin Tone Blend', min: 0, max: 1, step: 0.01 },
    ];

    const HAIR_FIELDS = [
        { path: 'hair.style', label: 'Hair Style', min: 0, max: 37, step: 1 },
        { path: 'hair.color', label: 'Hair Color', min: 0, max: 63, step: 1 },
        { path: 'hair.highlight', label: 'Hair Highlight', min: 0, max: 63, step: 1 },
        { path: 'eyebrows.style', label: 'Eyebrow Style', min: 0, max: 33, step: 1 },
        { path: 'eyebrows.color', label: 'Eyebrow Color', min: 0, max: 63, step: 1 },
        { path: 'facialHair.style', label: 'Facial Hair (-1 = none)', min: -1, max: 28, step: 1 },
        { path: 'facialHair.color', label: 'Facial Hair Color', min: 0, max: 63, step: 1 },
        { path: 'eyeColor', label: 'Eye Color', min: 0, max: 31, step: 1 },
    ];

    const MAKEUP_FIELDS = [
        { path: 'overlays.blemishes.index', label: 'Blemishes (-1 = none)', min: -1, max: 23, step: 1 },
        { path: 'overlays.blemishes.opacity', label: 'Blemishes Opacity', min: 0, max: 1, step: 0.01 },
        { path: 'overlays.ageing.index', label: 'Ageing (-1 = none)', min: -1, max: 14, step: 1 },
        { path: 'overlays.ageing.opacity', label: 'Ageing Opacity', min: 0, max: 1, step: 0.01 },
        { path: 'overlays.complexion.index', label: 'Complexion (-1 = none)', min: -1, max: 11, step: 1 },
        { path: 'overlays.complexion.opacity', label: 'Complexion Opacity', min: 0, max: 1, step: 0.01 },
        { path: 'overlays.sunDamage.index', label: 'Sun Damage (-1 = none)', min: -1, max: 10, step: 1 },
        { path: 'overlays.sunDamage.opacity', label: 'Sun Damage Opacity', min: 0, max: 1, step: 0.01 },
    ];

    const CLOTHING_FIELDS = [
        { path: 'clothing.top.drawable', label: 'Top', min: 0, max: 200, step: 1 },
        { path: 'clothing.top.texture', label: 'Top Color', min: 0, max: 20, step: 1 },
        { path: 'clothing.under.drawable', label: 'Undershirt', min: 0, max: 200, step: 1 },
        { path: 'clothing.under.texture', label: 'Undershirt Color', min: 0, max: 20, step: 1 },
        { path: 'clothing.legs.drawable', label: 'Legs', min: 0, max: 200, step: 1 },
        { path: 'clothing.legs.texture', label: 'Legs Color', min: 0, max: 20, step: 1 },
        { path: 'clothing.shoes.drawable', label: 'Shoes', min: 0, max: 200, step: 1 },
        { path: 'clothing.shoes.texture', label: 'Shoes Color', min: 0, max: 20, step: 1 },
    ];

    function getPath(obj, path) {
        return path.split('.').reduce((node, key) => (node == null ? undefined : node[key]), obj);
    }

    function fieldHtml(field, value) {
        return `
            <div class="rcc-field" data-path="${field.path}">
                <div class="rcc-field__row">
                    <span class="rcc-field__label">${field.label}</span>
                    <span class="rcc-field__value">${value}</span>
                </div>
                <input type="range" min="${field.min}" max="${field.max}" step="${field.step}" value="${value}" />
            </div>
        `;
    }

    function renderFields(container, fields, appearance) {
        container.innerHTML = fields.map((f) => fieldHtml(f, getPath(appearance, f.path))).join('');
        container.querySelectorAll('.rcc-field').forEach((el, i) => {
            const field = fields[i];
            const input = el.querySelector('input');
            const valueLabel = el.querySelector('.rcc-field__value');
            input.addEventListener('input', () => {
                const value = field.step < 1 ? parseFloat(input.value) : parseInt(input.value, 10);
                valueLabel.textContent = value;
                RSL.post('creator:update', { path: field.path, value });
            });
        });
    }

    function renderStructure(appearance) {
        const container = panels.structure;
        container.innerHTML = FACE_FEATURE_LABELS.map((label, i) =>
            fieldHtml({ path: `faceFeatures.${i + 1}`, label, min: -1, max: 1, step: 0.01 }, appearance.faceFeatures[i + 1])
        ).join('');
        container.querySelectorAll('.rcc-field').forEach((el, i) => {
            const path = `faceFeatures.${i + 1}`;
            const input = el.querySelector('input');
            const valueLabel = el.querySelector('.rcc-field__value');
            input.addEventListener('input', () => {
                const value = parseFloat(input.value);
                valueLabel.textContent = value;
                RSL.post('creator:update', { path, value });
            });
        });
    }

    function renderAll(appearance) {
        renderFields(panels.heritage, HERITAGE_FIELDS, appearance);
        renderStructure(appearance);
        renderFields(panels.hair, HAIR_FIELDS, appearance);
        renderFields(panels.makeup, MAKEUP_FIELDS, appearance);
        renderFields(panels.clothing, CLOTHING_FIELDS, appearance);
    }

    function setActiveTab(tab) {
        document.querySelectorAll('.rcc-tab').forEach((el) => el.classList.toggle('active', el.dataset.tab === tab));
        Object.entries(panels).forEach(([key, el]) => el.classList.toggle('active', key === tab));
    }

    document.querySelectorAll('.rcc-tab').forEach((el) => {
        el.addEventListener('click', () => setActiveTab(el.dataset.tab));
    });

    // Identity tab
    const nameInput = document.getElementById('rcc-name');
    nameInput.addEventListener('input', () => RSL.post('creator:setName', { name: nameInput.value }));

    document.getElementById('rcc-gender-male').addEventListener('click', () => setGender('male'));
    document.getElementById('rcc-gender-female').addEventListener('click', () => setGender('female'));

    function setGender(gender) {
        document.getElementById('rcc-gender-male').classList.toggle('rcc-active', gender === 'male');
        document.getElementById('rcc-gender-female').classList.toggle('rcc-active', gender === 'female');
        RSL.post('creator:setGender', { gender });
    }

    // Framing + rotate
    document.getElementById('rcc-framing-face').addEventListener('click', () => setFraming('face'));
    document.getElementById('rcc-framing-body').addEventListener('click', () => setFraming('body'));

    function setFraming(framing) {
        document.getElementById('rcc-framing-face').classList.toggle('rcc-active', framing === 'face');
        document.getElementById('rcc-framing-body').classList.toggle('rcc-active', framing === 'body');
        RSL.post('creator:setFraming', { framing });
    }

    function bindHold(buttonId, delta) {
        const btn = document.getElementById(buttonId);
        let interval = null;
        const fire = () => RSL.post('creator:rotate', { delta });
        btn.addEventListener('mousedown', () => {
            fire();
            interval = setInterval(fire, 60);
        });
        ['mouseup', 'mouseleave'].forEach((evt) => btn.addEventListener(evt, () => {
            if (interval) { clearInterval(interval); interval = null; }
        }));
    }
    bindHold('rcc-rotate-left', -6);
    bindHold('rcc-rotate-right', 6);

    document.getElementById('rcc-back').addEventListener('click', () => RSL.post('creator:back'));
    document.getElementById('rcc-confirm').addEventListener('click', () => RSL.post('creator:confirm'));

    RSL.on('characterCreator:show', (data) => {
        root.classList.add('rsl-modal--visible');
        nameInput.value = '';
        setActiveTab('identity');
        setFraming('face');
        setGender(data.gender);
        renderAll(data.appearance);
    });

    RSL.on('characterCreator:resetControls', (data) => {
        renderAll(data.appearance);
    });

    RSL.on('characterCreator:hide', () => {
        root.classList.remove('rsl-modal--visible');
    });
})();
