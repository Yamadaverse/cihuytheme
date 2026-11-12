@if(!empty($musicFile))
<div id="pteroGlobalMusic" style="
    position:fixed;
    left:16px;
    bottom:16px;
    z-index:999999;
    display:flex;
    align-items:center;
    gap:10px;
    padding:10px 12px;
    background:#ffb000;
    color:#111;
    border:3px solid #111;
    box-shadow:4px 4px 0 #111;
    border-radius:5px;
    font-family:Arial,sans-serif;
">
    <audio id="pteroGlobalAudio" preload="auto" loop>
        <source src="{{ $musicFile }}">
    </audio>

    <button type="button" id="pteroGlobalPlay" aria-label="Putar musik"
        style="border:2px solid #111;background:#fff;color:#111;font-weight:bold;padding:7px 11px;cursor:pointer;">
        ▶
    </button>

    <span style="font-size:12px;font-weight:bold;">MUSIC</span>

    <input id="pteroGlobalVolume" type="range" min="0" max="1" step="0.05"
        value="0.5" aria-label="Volume musik" style="width:75px;cursor:pointer;">
</div>

<script>
(function () {
    var audio = document.getElementById('pteroGlobalAudio');
    var playButton = document.getElementById('pteroGlobalPlay');
    var volumeSlider = document.getElementById('pteroGlobalVolume');

    if (!audio || !playButton || !volumeSlider || audio.dataset.initialized) return;
    audio.dataset.initialized = '1';

    var storage = {
        playing: 'ptero_global_music_playing',
        time: 'ptero_global_music_time',
        volume: 'ptero_global_music_volume'
    };

    function read(key, fallback) {
        try {
            var value = localStorage.getItem(key);
            return value === null ? fallback : value;
        } catch (e) {
            return fallback;
        }
    }

    function save(key, value) {
        try {
            localStorage.setItem(key, String(value));
        } catch (e) {}
    }

    audio.volume = Math.max(0, Math.min(1, Number(read(storage.volume, '0.5')) || 0));
    volumeSlider.value = audio.volume;

    function updateButton() {
        playButton.textContent = audio.paused ? '▶' : 'Ⅱ';
        playButton.setAttribute('aria-label', audio.paused ? 'Putar musik' : 'Jeda musik');
    }

    function savePosition() {
        if (Number.isFinite(audio.currentTime)) {
            save(storage.time, audio.currentTime);
        }
    }

    audio.addEventListener('loadedmetadata', function () {
        var savedTime = Number(read(storage.time, '0'));

        if (Number.isFinite(savedTime) && savedTime > 0 && savedTime < audio.duration) {
            audio.currentTime = savedTime;
        }

        if (read(storage.playing, 'false') === 'true') {
            audio.play().catch(function () {
                updateButton();
            });
        }
    });

    playButton.addEventListener('click', function () {
        if (audio.paused) {
            audio.play().then(function () {
                save(storage.playing, 'true');
            }).catch(function () {
                save(storage.playing, 'false');
                alert('Browser menolak pemutaran. Silakan tekan Play sekali lagi.');
            });
        } else {
            audio.pause();
            save(storage.playing, 'false');
        }
    });

    volumeSlider.addEventListener('input', function () {
        audio.volume = Number(volumeSlider.value);
        save(storage.volume, audio.volume);
    });

    audio.addEventListener('play', updateButton);
    audio.addEventListener('pause', function () {
        updateButton();
        savePosition();
    });

    audio.addEventListener('timeupdate', function () {
        if (!audio.paused) savePosition();
    });

    window.addEventListener('pagehide', savePosition);
    updateButton();
})();
</script>
@endif
