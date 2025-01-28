window.addEventListener('message', function(event) {
    const data = event.data;

    if (data.display) {
        const businessUI = document.getElementById('business-ui');
        const businessLabel = document.getElementById('business-label');
        const businessText = document.getElementById('business-text');
        const lockIcon = document.getElementById('lock-icon');

        // Resetear cualquier animación previa
        businessUI.classList.remove('fadeOut');
        businessUI.style.display = 'flex';
        businessLabel.textContent = data.businessLabel;
        businessText.textContent = data.businessText;
        lockIcon.className = data.status === 'open' ? 'fas fa-unlock' : 'fas fa-lock';
        lockIcon.classList.add('lock-animate');
        businessUI.classList.remove('hidden');

        // Manejar la salida después del tiempo configurado
        setTimeout(() => {
            businessUI.classList.add('fadeOut');
            // Ocultar después de la animación
            setTimeout(() => {
                businessUI.style.display = 'none';
                lockIcon.classList.remove('lock-animate');
            }, 500);
        }, data.displayTime);
    }
});
