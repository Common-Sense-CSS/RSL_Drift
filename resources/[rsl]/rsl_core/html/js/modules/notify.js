(function () {
    const container = document.getElementById('rsl-notify-container');

    RSL.on('notify:show', (data) => {
        const toast = document.createElement('div');
        const type = ['success', 'error', 'warning', 'info'].includes(data.type) ? data.type : 'info';
        toast.className = `rsl-toast rsl-toast--${type}`;
        toast.innerHTML = `<div class="rsl-toast__dot"></div><div class="rsl-toast__title"></div>`;
        toast.querySelector('.rsl-toast__title').textContent = data.title || '';
        container.appendChild(toast);

        const duration = typeof data.duration === 'number' ? data.duration : 3500;
        setTimeout(() => {
            toast.classList.add('rsl-toast--leaving');
            setTimeout(() => toast.remove(), 220);
        }, duration);
    });
})();
