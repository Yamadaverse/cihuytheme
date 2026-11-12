@extends('layouts.admin')

@section('title')
    Theme Settings
@endsection

@section('content-header')
    <h1>Theme Settings <small>Atur background gambar, video, dan musik.</small></h1>
    <ol class="breadcrumb">
        <li><a href="{{ route('admin.index') }}">Admin</a></li>
        <li class="active">Theme Settings</li>
    </ol>
@endsection

@section('content')
    <form action="{{ route('admin.theme-settings.update') }}" method="POST" enctype="multipart/form-data">
        @csrf
        @method('PATCH')

        @if($errors->any())
            <div class="alert alert-danger">
                <strong>Pengaturan gagal disimpan:</strong>
                <ul>
                    @foreach($errors->all() as $error)
                        <li>{{ $error }}</li>
                    @endforeach
                </ul>
            </div>
        @endif

        <div class="box">
            <div class="box-header with-border">
                <h3 class="box-title">Background Light Mode</h3>
            </div>
            <div class="box-body">
                @if($settings && $settings->background_light)
                    <p><strong>Gambar saat ini:</strong></p>
                    <img src="{{ $settings->background_light }}" alt="Light background preview"
                         style="display:block;max-width:100%;max-height:220px;object-fit:contain;margin-bottom:15px;border:1px solid #ddd;">
                @endif

                @if($settings && $settings->background_light_video)
                    <p><strong>Video saat ini:</strong></p>
                    <video controls muted playsinline preload="metadata"
                           style="display:block;width:100%;max-width:500px;max-height:240px;margin-bottom:15px;background:#111;">
                        <source src="{{ $settings->background_light_video }}">
                    </video>
                @endif

                <div class="form-group">
                    <label for="background_light">URL gambar Light (opsional)</label>
                    <input class="form-control" type="url" id="background_light" name="background_light"
                           value="{{ old('background_light') }}" placeholder="https://contoh.com/background-light.jpg">
                </div>

                <div class="form-group">
                    <label for="background_light_file">Upload gambar Light</label>
                    <input class="form-control" type="file" id="background_light_file" name="background_light_file"
                           accept="image/jpeg,image/png,image/webp,image/gif">
                    <p class="text-muted small">JPG, PNG, WEBP, atau GIF. Maksimal 10 MB.</p>
                </div>

                <hr>

                <div class="form-group">
                    <label for="background_light_video_file">Upload video Light Mode</label>
                    <input class="form-control" type="file" id="background_light_video_file"
                           name="background_light_video_file" accept="video/mp4,video/webm">
                    <p class="text-muted small">MP4 atau WEBM. Maksimal 200 MB. Video otomatis diputar tanpa suara dan berulang.</p>
                </div>
            </div>
        </div>

        <div class="box">
            <div class="box-header with-border">
                <h3 class="box-title">Background Dark Mode</h3>
            </div>
            <div class="box-body">
                @if($settings && $settings->background_dark)
                    <p><strong>Gambar saat ini:</strong></p>
                    <img src="{{ $settings->background_dark }}" alt="Dark background preview"
                         style="display:block;max-width:100%;max-height:220px;object-fit:contain;margin-bottom:15px;border:1px solid #ddd;">
                @endif

                @if($settings && $settings->background_dark_video)
                    <p><strong>Video saat ini:</strong></p>
                    <video controls muted playsinline preload="metadata"
                           style="display:block;width:100%;max-width:500px;max-height:240px;margin-bottom:15px;background:#111;">
                        <source src="{{ $settings->background_dark_video }}">
                    </video>
                @endif

                <div class="form-group">
                    <label for="background_dark">URL gambar Dark (opsional)</label>
                    <input class="form-control" type="url" id="background_dark" name="background_dark"
                           value="{{ old('background_dark') }}" placeholder="https://contoh.com/background-dark.jpg">
                </div>

                <div class="form-group">
                    <label for="background_dark_file">Upload gambar Dark</label>
                    <input class="form-control" type="file" id="background_dark_file" name="background_dark_file"
                           accept="image/jpeg,image/png,image/webp,image/gif">
                    <p class="text-muted small">JPG, PNG, WEBP, atau GIF. Maksimal 10 MB.</p>
                </div>

                <hr>

                <div class="form-group">
                    <label for="background_dark_video_file">Upload video Dark Mode</label>
                    <input class="form-control" type="file" id="background_dark_video_file"
                           name="background_dark_video_file" accept="video/mp4,video/webm">
                    <p class="text-muted small">MP4 atau WEBM. Maksimal 200 MB. Video otomatis diputar tanpa suara dan berulang.</p>
                </div>
            </div>
        </div>

        <div class="box">
            <div class="box-header with-border">
                <h3 class="box-title">Background Music</h3>
            </div>
            <div class="box-body">
                @if($settings && $settings->music_file)
                    <p><strong>Musik saat ini:</strong></p>
                    <audio controls preload="metadata" style="display:block;width:100%;max-width:500px;margin-bottom:15px;">
                        <source src="{{ $settings->music_file }}">
                        Browser tidak mendukung pemutar audio.
                    </audio>
                @endif

                <div class="form-group">
                    <label for="music_file">Upload musik dari perangkat</label>
                    <input class="form-control" type="file" id="music_file" name="music_file"
                           accept="audio/mpeg,audio/mp3,audio/ogg,audio/wav">
                    <p class="text-muted small">MP3, OGG, atau WAV. Maksimal 20 MB.</p>
                </div>
            </div>
        </div>

        <div class="box-footer">
            <button type="submit" class="btn btn-primary">Simpan Pengaturan Tema</button>
        </div>
    </form>
@endsection
