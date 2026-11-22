<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreBugReportRequest;
use App\Models\BugReport;
use App\Services\DiagnosticsSanitizer;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Symfony\Component\HttpFoundation\StreamedResponse;

class BugReportController extends Controller
{
    /**
     * Store a newly created technical bug report (supports authenticated
     * Sanctum users as well as optional guest reports).
     */
    public function store(
        StoreBugReportRequest $request,
        DiagnosticsSanitizer $sanitizer
    ): JsonResponse {
        $validated = $request->validated();
        $user = $request->user('sanctum');
        $includeLogs = (bool) $validated['include_logs'];

        $rawDeviceMeta = $validated['device_meta'] ?? null;
        $deviceMeta = $includeLogs
            ? $sanitizer->sanitize(
                $rawDeviceMeta,
                (int) config('support.max_device_meta_bytes', 16384)
            )
            : $sanitizer->filterBasicDeviceMeta(
                is_array($rawDeviceMeta) ? $rawDeviceMeta : null
            );

        // Hard server-side privacy rule: never persist diagnostics_logs unless
        // the user explicitly opted into include_logs = true.
        $diagnosticsLogs = null;
        if ($includeLogs && isset($validated['diagnostics_logs'])) {
            $diagnosticsLogs = $sanitizer->sanitize(
                $validated['diagnostics_logs'],
                (int) config('support.max_diagnostics_bytes', 131072)
            );
        }

        $disk = (string) config('support.bug_reports_disk', 'local');
        $screenshotPath = null;

        if ($request->hasFile('screenshot')) {
            /** @var UploadedFile $file */
            $file = $request->file('screenshot');
            $screenshotPath = $this->storePrivateScreenshot($file, $disk);
        }

        try {
            $report = BugReport::create([
                'user_id' => $user?->id,
                'status' => BugReport::STATUS_OPEN,
                'description' => $validated['description'],
                'include_logs' => $includeLogs,
                'screenshot_path' => $screenshotPath,
                'app_version' => $validated['app_version'] ?? null,
                'platform' => $validated['platform'] ?? null,
                'locale' => $validated['locale'] ?? null,
                'route_name' => $validated['route_name'] ?? null,
                'device_meta' => is_array($deviceMeta) ? $deviceMeta : null,
                'diagnostics_logs' => is_array($diagnosticsLogs) ? $diagnosticsLogs : null,
            ]);
        } catch (\Throwable $e) {
            if ($screenshotPath !== null) {
                Storage::disk($disk)->delete($screenshotPath);
            }
            throw $e;
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Bug report submitted successfully.',
            'data' => [
                'id' => $report->id,
                'status' => $report->status,
                'include_logs' => $report->include_logs,
                'has_screenshot' => $report->screenshot_path !== null,
                'created_at' => $report->created_at?->toIso8601String(),
            ],
        ], 201);
    }

    /**
     * Controlled admin-only download/preview for private bug-report screenshots.
     */
    public function showScreenshot(Request $request, BugReport $bugReport): StreamedResponse
    {
        $user = $request->user('sanctum');
        abort_unless($user && (bool) $user->is_admin, 403, 'Forbidden');

        $disk = (string) config('support.bug_reports_disk', 'local');
        $path = $bugReport->screenshot_path;

        abort_unless(
            is_string($path) && $path !== '' && Storage::disk($disk)->exists($path),
            404,
            'Screenshot not found'
        );

        return Storage::disk($disk)->response($path, null, [
            'X-Content-Type-Options' => 'nosniff',
            'Cache-Control' => 'private, no-store',
        ]);
    }

    private function storePrivateScreenshot(UploadedFile $file, string $disk): string
    {
        $mime = $file->getMimeType();
        $ext = match ($mime) {
            'image/png' => 'png',
            'image/webp' => 'webp',
            default => 'jpg',
        };

        $baseDir = trim((string) config('support.bug_reports_dir', 'private/bug-reports'), '/');
        $directory = $baseDir . '/' . now()->format('Y/m');
        $filename = Str::uuid()->toString() . '.' . $ext;

        $stored = Storage::disk($disk)->putFileAs($directory, $file, $filename);
        if (!is_string($stored) || $stored === '') {
            throw new \RuntimeException('Failed to persist bug report screenshot.');
        }

        return $stored;
    }
}
