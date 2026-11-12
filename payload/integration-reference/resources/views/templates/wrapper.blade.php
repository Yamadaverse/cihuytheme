<!DOCTYPE html>
<html>
    <head>
        <title>{{ config('app.name', 'Pterodactyl') }}</title>

        @section('meta')
            <meta charset="utf-8">
            <meta http-equiv="X-UA-Compatible" content="IE=edge">
            <meta content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" name="viewport">
            <meta name="csrf-token" content="{{ csrf_token() }}">
            <meta name="robots" content="noindex">
            <link rel="apple-touch-icon" sizes="180x180" href="/favicons/apple-touch-icon.png">
            <link rel="icon" type="image/png" href="/favicons/favicon-32x32.png" sizes="32x32">
            <link rel="icon" type="image/png" href="/favicons/favicon-16x16.png" sizes="16x16">
            <link rel="manifest" href="/favicons/manifest.json">
            <link rel="mask-icon" href="/favicons/safari-pinned-tab.svg" color="#bc6e3c">
            <link rel="shortcut icon" href="/favicons/favicon.ico">
            <meta name="msapplication-config" content="/favicons/browserconfig.xml">
            <meta name="theme-color" content="#0e4688">
        @show

        @section('user-data')
            @if(!is_null(Auth::user()))
                <script>
                    window.PterodactylUser = {!! json_encode(Auth::user()->toVueObject()) !!};
                </script>
            @endif
            @if(!empty($siteConfiguration))
                <script>
                    window.SiteConfiguration = {!! json_encode($siteConfiguration) !!};
                </script>
            @endif
        @show

        @yield('assets')

        @include('layouts.scripts')

        @php
            $themeSettings = \Illuminate\Support\Facades\DB::table('theme_settings')->where('id', 1)->first();
            $lightBackground = $themeSettings?->background_light;
            $darkBackground = $themeSettings?->background_dark;
            $lightVideo = $themeSettings?->background_light_video;
            $darkVideo = $themeSettings?->background_dark_video;
            $musicFile = $themeSettings?->music_file;
        @endphp
        <style>
            :root {
                --brutal-bg-image: @if($lightBackground) url({!! json_encode($lightBackground) !!}) @else none @endif;
            }
            html.dark {
                --brutal-bg-image: @if($darkBackground) url({!! json_encode($darkBackground) !!}) @else none @endif;
            }

            #pteroThemeBackgroundVideo {
                display: none;
                position: fixed;
                inset: 0;
                width: 100vw;
                height: 100vh;
                object-fit: cover;
                z-index: 0;
                pointer-events: none;
            }

            #app {
                position: relative;
                z-index: 1;
            }
        </style>
        <script>
            (function () {
                try {
                    document.documentElement.classList.toggle(
                        'dark',
                        localStorage.getItem('ptero_brutal_theme') === 'dark'
                    );
                } catch (e) {}
            })();
        </script>

    </head>
    <body class="{{ $css['body'] ?? 'bg-neutral-50' }}">
        <video
            id="pteroThemeBackgroundVideo"
            muted
            autoplay
            loop
            playsinline
            preload="none"
            aria-hidden="true"
            tabindex="-1"
            data-light-src="{{ $lightVideo ?? '' }}"
            data-dark-src="{{ $darkVideo ?? '' }}"
        ></video>

        <script>
            (function () {
                var video = document.getElementById('pteroThemeBackgroundVideo');
                if (!video) return;

                video.addEventListener('canplay', function () {
                    video.style.display = 'block';
                });

                video.addEventListener('error', function () {
                    video.style.display = 'none';
                });

                function syncBackgroundVideo() {
                    var dark = document.documentElement.classList.contains('dark');
                    var source = video.getAttribute(dark ? 'data-dark-src' : 'data-light-src');

                    if (!source) {
                        video.pause();
                        video.removeAttribute('src');
                        video.load();
                        video.style.display = 'none';
                        return;
                    }

                    if (video.getAttribute('src') === source) return;

                    video.style.display = 'none';
                    video.pause();
                    video.src = source;
                    video.load();

                    var playback = video.play();
                    if (playback && typeof playback.catch === 'function') {
                        playback.catch(function () {
                            video.style.display = 'none';
                        });
                    }
                }

                syncBackgroundVideo();

                new MutationObserver(syncBackgroundVideo).observe(
                    document.documentElement,
                    { attributes: true, attributeFilter: ['class'] }
                );
            })();
        </script>

        <script>
            document.body.classList.toggle(
                'darkmode',
                document.documentElement.classList.contains('dark')
            );
        </script>
        <button
            type="button"
            id="pteroBrutalThemeToggle"
            aria-label="Ganti Light/Dark Mode"
            title="Ganti Light/Dark Mode"
            style="position:fixed;right:20px;bottom:20px;z-index:99999;width:48px;height:48px;border:3px solid currentColor;border-radius:4px;background:#ff6b00;color:#000;font-size:22px;font-weight:bold;box-shadow:4px 4px 0 #000;cursor:pointer;"
        >☾</button>
        <script>
            (function () {
                var button = document.getElementById('pteroBrutalThemeToggle');
                if (!button) return;

                function updateButton() {
                    var dark = document.documentElement.classList.contains('dark');
                    button.textContent = dark ? '☀' : '☾';
                    button.setAttribute('aria-label', dark ? 'Aktifkan Light Mode' : 'Aktifkan Dark Mode');
                }

                button.addEventListener('click', function () {
                    var dark = !document.documentElement.classList.contains('dark');
                    document.documentElement.classList.toggle('dark', dark);
                    document.body.classList.toggle('darkmode', dark);

                    try {
                        localStorage.setItem('ptero_brutal_theme', dark ? 'dark' : 'light');
                    } catch (e) {}

                    updateButton();
                });

                updateButton();
            })();
        </script>

        @section('content')
            @yield('above-container')
            @yield('container')
            @yield('below-container')
        @show
        @section('scripts')
            {!! $asset->js('main.js') !!}
        @show
        @include('layouts.partials.theme-audio-player', ['musicFile' => $musicFile])
    </body>
</html>
