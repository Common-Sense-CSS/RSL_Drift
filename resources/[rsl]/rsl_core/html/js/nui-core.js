/*
 * RSL NUI core — tiny message router shared by every module in this page.
 * Lua sends SendNUIMessage({ action = 'namespace:event', ...payload }) and
 * modules register a handler for that action here.
 */

window.RSL = (function () {
    const handlers = {};

    window.addEventListener('message', (event) => {
        const data = event.data || {};
        if (!data.action) return;
        const handler = handlers[data.action];
        if (handler) handler(data);
    });

    function on(action, handler) {
        handlers[action] = handler;
    }

    function post(callbackName, payload) {
        const resourceName = window.GetParentResourceName ? window.GetParentResourceName() : 'rsl_core';
        return fetch(`https://${resourceName}/${callbackName}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(payload || {}),
        }).catch(() => {});
    }

    return { on, post };
})();
