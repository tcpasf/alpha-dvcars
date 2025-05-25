let isActive = true;
let currentInterval = 10;
let hideTimeout = null;
let totalSeconds = 0;
let lastTimeRemaining = 0;
let isCountdownUrgent = false;
let isCleanupInProgress = false;

const container = document.getElementById('container');
const statusText = document.getElementById('statusText');
const countdownText = document.getElementById('countdownText');
const intervalText = document.getElementById('intervalText');
const progressBar = document.getElementById('progressBar');

// Arabic text mappings
const arabicText = {
    active: 'نشط',
    inactive: 'غير نشط',
    minutes: 'دقيقة'
};

function formatTime(seconds) {
    if (seconds <= 0) return '--:--';
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    return `${minutes.toString().padStart(2, '0')}:${remainingSeconds.toString().padStart(2, '0')}`;
}

function showUITemporarily(duration = 10000) {
    // Clear any existing timeout
    if (hideTimeout) {
        clearTimeout(hideTimeout);
    }
    
    // Show the UI with animation
    container.style.display = 'block';
    container.classList.remove('fade-out');
    container.classList.add('fade-in');
    
    // Set timeout to hide UI after duration
    hideTimeout = setTimeout(() => {
        container.classList.remove('fade-in');
        container.classList.add('fade-out');
        
        // After animation completes, hide the element
        setTimeout(() => {
            container.style.display = 'none';
            
            // Reset cleanup status when UI is hidden
            if (isCleanupInProgress) {
                isCleanupInProgress = false;
            }
        }, 400); // Match the animation duration
    }, duration);
}

function updateProgressBar(timeRemaining) {
    if (totalSeconds === 0) {
        // If we don't have the total, estimate it from the interval
        totalSeconds = currentInterval * 60;
    }
    
    // Calculate percentage remaining
    const percentRemaining = (timeRemaining / totalSeconds) * 100;
    progressBar.style.width = `${percentRemaining}%`;
    
    // Add urgent class for last 30 seconds
    if (timeRemaining <= 30 && !isCountdownUrgent) {
        countdownText.classList.add('urgent');
        isCountdownUrgent = true;
    } else if (timeRemaining > 30 && isCountdownUrgent) {
        countdownText.classList.remove('urgent');
        isCountdownUrgent = false;
    }
}

function updateUI(data) {
    if (data.active !== undefined) {
        isActive = data.active;
        statusText.textContent = isActive ? arabicText.active : arabicText.inactive;
        statusText.className = isActive ? 'status-text active' : 'status-text inactive';
    }

    if (data.interval !== undefined) {
        currentInterval = data.interval;
        intervalText.textContent = `${currentInterval} ${arabicText.minutes}`;
        totalSeconds = currentInterval * 60;
    }

    if (data.timeRemaining !== undefined) {
        lastTimeRemaining = data.timeRemaining;
        countdownText.textContent = formatTime(data.timeRemaining);
        updateProgressBar(data.timeRemaining);
    }
    
    if (data.cleanup !== undefined) {
        isCleanupInProgress = data.cleanup;
    }
}

function updateCountdown(timeRemaining) {
    lastTimeRemaining = timeRemaining;
    countdownText.textContent = formatTime(timeRemaining);
    updateProgressBar(timeRemaining);
    
    // Show UI only in the last 30 seconds before cleanup
    if (timeRemaining <= 30 && container.style.display !== 'block' && !isCleanupInProgress) {
        showUITemporarily(timeRemaining * 1000 + 2000); // Show until 2 seconds after cleanup
    }
    
    // Hide UI when time is up (cleanup will show it again)
    if (timeRemaining === 0 && !isCleanupInProgress) {
        if (container.style.display === 'block') {
            container.classList.remove('fade-in');
            container.classList.add('fade-out');
            
            setTimeout(() => {
                container.style.display = 'none';
            }, 400);
        }
    }
}

// Handle visibility when countdown is updated
window.addEventListener('message', (event) => {
    const data = event.data;

    switch (data.type) {
        case 'showUI':
            updateUI(data);
            break;

        case 'updateCountdown':
            updateCountdown(data.time);
            break;
            
        case 'temporaryShow':
            updateUI({...data, cleanup: true});
            showUITemporarily(data.duration || 10000);
            break;
            
        case 'hideUI':
            if (container.style.display === 'block') {
                container.classList.remove('fade-in');
                container.classList.add('fade-out');
                
                setTimeout(() => {
                    container.style.display = 'none';
                }, 400);
            }
            break;
    }
});
