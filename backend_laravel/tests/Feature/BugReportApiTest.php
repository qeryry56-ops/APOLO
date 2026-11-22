<?php

namespace Tests\Feature;

use App\Models\BugReport;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class BugReportApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_guest_can_submit_bug_report_without_optional_logs(): void
    {
        $response = $this->postJson('/api/support/bug-reports', [
            'description' => 'Search filters freeze after selecting Casablanca.',
            'include_logs' => false,
            'app_version' => '1.0.0+1',
            'platform' => 'web',
            'locale' => 'fr',
            'route_name' => 'main_shell/explore',
            'device_meta' => [
                'is_rtl' => false,
                'authenticated' => false,
                'viewport_width' => 1440, // must be stripped when include_logs=false
            ],
            'diagnostics_logs' => [
                'logs' => [['message' => 'should not be stored']],
            ],
        ]);

        $response->assertCreated()
            ->assertJsonPath('status', 'success')
            ->assertJsonPath('data.status', 'open')
            ->assertJsonPath('data.include_logs', false)
            ->assertJsonPath('data.has_screenshot', false);

        $report = BugReport::firstOrFail();
        $this->assertNull($report->user_id);
        $this->assertNull($report->diagnostics_logs);
        $this->assertSame(['is_rtl' => false, 'authenticated' => false], $report->device_meta);
    }

    public function test_authenticated_user_report_sanitizes_secrets_and_stores_private_screenshot(): void
    {
        Storage::fake('local');
        Storage::fake('public');

        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $screenshot = UploadedFile::fake()->image('screen.png', 720, 1280);

        $response = $this->post('/api/support/bug-reports', [
            'description' => 'Checkout button clipped on RTL Arabic layout.',
            'include_logs' => '1',
            'app_version' => '1.0.0+1',
            'platform' => 'ios',
            'locale' => 'ar',
            'route_name' => '/ad/123',
            'device_meta' => json_encode([
                'is_rtl' => true,
                'authenticated' => true,
                'viewport_width' => 390,
                'api_token' => 'secret-leak-123',
            ]),
            'diagnostics_logs' => json_encode([
                'logs' => [
                    [
                        'message' => 'Header Authorization: Bearer super-secret-token-value',
                        'password' => 'my-pass-999',
                    ],
                ],
            ]),
            'screenshot' => $screenshot,
        ], ['Accept' => 'application/json']);

        $response->assertCreated()
            ->assertJsonPath('data.include_logs', true)
            ->assertJsonPath('data.has_screenshot', true);

        $report = BugReport::firstOrFail();
        $this->assertSame($user->id, $report->user_id);
        $this->assertNotNull($report->screenshot_path);
        $this->assertStringStartsWith('private/bug-reports/', $report->screenshot_path);
        Storage::disk('local')->assertExists($report->screenshot_path);
        $this->assertSame([], Storage::disk('public')->allFiles());

        $this->assertSame('[REDACTED]', $report->device_meta['api_token']);
        $this->assertSame('[REDACTED]', $report->diagnostics_logs['logs'][0]['password']);
        $this->assertStringNotContainsString(
            'super-secret-token-value',
            $report->diagnostics_logs['logs'][0]['message']
        );
    }

    public function test_validation_rejects_empty_description_and_invalid_attachment(): void
    {
        $badFile = UploadedFile::fake()->create('exploit.svg', 10, 'image/svg+xml');

        $response = $this->post('/api/support/bug-reports', [
            'description' => '   ',
            'include_logs' => '0',
            'screenshot' => $badFile,
        ], ['Accept' => 'application/json']);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['description', 'screenshot']);
    }

    public function test_guest_requests_are_rate_limited(): void
    {
        for ($i = 0; $i < 2; $i++) {
            $this->postJson('/api/support/bug-reports', [
                'description' => "Valid bug report message #$i",
                'include_logs' => false,
            ])->assertCreated();
        }

        $this->postJson('/api/support/bug-reports', [
            'description' => 'Third bug report within the same minute',
            'include_logs' => false,
        ])->assertStatus(429);
    }
}
