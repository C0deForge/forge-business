window.addEventListener('message', function(event) {
    const data = event.data;

    if (data.display) {
        const businessUI = document.getElementById('business-ui');
        const businessLabel = document.getElementById('business-label');
        const businessText = document.getElementById('business-text');
        const lockIcon = document.getElementById('lock-icon');

        // Ensure the UI is visible
        businessUI.style.display = 'flex';

        // Set the text values and icons
        businessLabel.textContent = data.businessLabel;
        businessText.textContent = data.businessText;

        // Change the lock icon based on the status (open or closed)
        lockIcon.className = data.status === 'open' ? 'fas fa-unlock' : 'fas fa-lock';

        // Add the class to start the animation
        lockIcon.classList.add('lock-animate');

        // Show the UI without interfering with the user's pointer
        businessUI.classList.remove('hidden');

        // Automatically hide the UI after the specified time
        const displayTime = data.displayTime || 5000; // Use the sent value or 5s by default
        setTimeout(() => {
            businessUI.style.display = 'none';

            // Remove the animation class when hiding the UI
            lockIcon.classList.remove('lock-animate');

            // Optional: Send a callback to the client to ensure the focus is on the game
            fetch(`https://${GetParentResourceName()}/closeUI`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json; charset=UTF-8',
                },
                body: JSON.stringify({})
            }).then(resp => resp.json()).then(resp => {
                // Handle the response if necessary
            });
        }, displayTime);
    }
});