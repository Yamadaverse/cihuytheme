<?php

namespace Pterodactyl\Http\Controllers\Admin;

use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;
use Prologue\Alerts\AlertsMessageBag;
use Pterodactyl\Http\Controllers\Controller;

class ThemeSettingsController extends Controller
{
    public function __construct(private AlertsMessageBag $alert)
    {
    }

    public function index(): View
    {
        return view('admin.theme-settings.index', [
            'settings' => DB::table('theme_settings')->where('id', 1)->first(),
        ]);
    }

    public function update(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'background_light' => 'nullable|url:http,https|max:2048',
            'background_dark' => 'nullable|url:http,https|max:2048',
            'background_light_file' => 'nullable|image|mimes:jpg,jpeg,png,webp,gif|max:10240',
            'background_dark_file' => 'nullable|image|mimes:jpg,jpeg,png,webp,gif|max:10240',
            'background_light_video_file' => 'nullable|file|mimes:mp4,webm|max:204800',
            'background_dark_video_file' => 'nullable|file|mimes:mp4,webm|max:204800',
            'music_file' => 'nullable|file|mimes:mp3,mpeg,ogg,wav|max:20480',
        ]);

        $current = DB::table('theme_settings')->where('id', 1)->first();

        $light = $current?->background_light;
        $dark = $current?->background_dark;
        $lightVideo = $current?->background_light_video;
        $darkVideo = $current?->background_dark_video;
        $music = $current?->music_file;

        if (!empty($validated['background_light'])) {
            $light = $validated['background_light'];
        }

        if (!empty($validated['background_dark'])) {
            $dark = $validated['background_dark'];
        }

        if ($request->hasFile('background_light_file')) {
            $light = '/storage/' . $request->file('background_light_file')
                ->store('theme/backgrounds', 'public');
        }

        if ($request->hasFile('background_dark_file')) {
            $dark = '/storage/' . $request->file('background_dark_file')
                ->store('theme/backgrounds', 'public');
        }

        if ($request->hasFile('background_light_video_file')) {
            $lightVideo = '/storage/' . $request->file('background_light_video_file')
                ->store('theme/videos', 'public');
        }

        if ($request->hasFile('background_dark_video_file')) {
            $darkVideo = '/storage/' . $request->file('background_dark_video_file')
                ->store('theme/videos', 'public');
        }

        if ($request->hasFile('music_file')) {
            $music = '/storage/' . $request->file('music_file')
                ->store('theme/music', 'public');
        }

        DB::table('theme_settings')->updateOrInsert(
            ['id' => 1],
            [
                'background_light' => $light,
                'background_dark' => $dark,
                'background_light_video' => $lightVideo,
                'background_dark_video' => $darkVideo,
                'music_file' => $music,
                'created_at' => $current?->created_at ?? now(),
                'updated_at' => now(),
            ]
        );

        $this->alert->success('Pengaturan tema berhasil diperbarui.')->flash();

        return redirect()->route('admin.theme-settings');
    }
}
