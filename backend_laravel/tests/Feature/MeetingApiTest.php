<?php

namespace Tests\Feature;

use App\Models\User;
use App\Services\Meetings\LiveKitTokenService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class MeetingApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        config([
            'meetings.ws_url' => 'wss://rtc.apolo.ma',
            'meetings.http_url' => 'https://rtc.apolo.ma',
            'meetings.api_key' => 'APOLO_LK_TEST_KEY',
            'meetings.api_secret' => 'apolo_super_secret_livekit_signing_key_2026_test',
            'meetings.turn_domain' => 'turn.apolo.ma',
            'meetings.turn_shared_secret' => 'turn_hmac_secret_test_2026',
            'meetings.default_max_participants' => 25,
        ]);

        Http::fake([
            'https://rtc.apolo.ma/twirp/*' => Http::response(['name' => 'ok'], 200),
        ]);
    }

    public function test_host_can_create_and_join_sfu_meeting_with_svc_turn_and_e2ee_metadata(): void
    {
        $host = User::factory()->create(['name' => 'أمين المضيف']);
        Sanctum::actingAs($host);

        $createRes = $this->postJson('/api/v1/meetings', [
            'title' => 'معاينة جماعية للعقار - الدار البيضاء',
            'max_participants' => 20,
            'e2ee_enabled' => true,
            'e2ee_key_hint' => 'sha256:9f86d081884c7d65',
            'mute_on_entry' => true,
            'region' => 'ma-casablanca',
        ]);

        $createRes->assertCreated()
            ->assertJsonPath('status', 'success')
            ->assertJsonPath('data.max_participants', 20)
            ->assertJsonPath('data.e2ee_enabled', true)
            ->assertJsonPath('data.my_role', 'host');

        $roomCode = $createRes->json('data.room_code');
        $this->assertMatchesRegularExpression('/^apo-[a-z0-9]{4}-[a-z0-9]{4}$/', $roomCode);

        $joinRes = $this->postJson("/api/v1/meetings/{$roomCode}/join");
        $joinRes->assertOk()
            ->assertJsonPath('data.sfu.provider', 'livekit')
            ->assertJsonPath('data.sfu.topology', 'sfu')
            ->assertJsonPath('data.sfu.ws_url', 'wss://rtc.apolo.ma')
            ->assertJsonPath('data.sfu.media_policy.svc_scalability_mode', 'L3T3_KEY')
            ->assertJsonPath('data.sfu.media_policy.simulcast_enabled', true);

        // Verify TURN UDP + TURNS TLS 443 fallback credentials are generated
        $iceServers = $joinRes->json('data.sfu.ice_servers');
        $this->assertCount(2, $iceServers);
        $this->assertContains('turns:turn.apolo.ma:443?transport=tcp', $iceServers[1]['urls']);

        // Decode and verify JWT grants without leaking API secret
        $jwt = $joinRes->json('data.sfu.access_token');
        $parts = explode('.', $jwt);
        $this->assertCount(3, $parts);
        $tokenService = app(LiveKitTokenService::class);
        $claims = json_decode($tokenService->base64UrlDecode($parts[1]), true);
        $this->assertSame('APOLO_LK_TEST_KEY', $claims['iss']);
        $this->assertSame("user_{$host->id}", $claims['sub']);
        $this->assertTrue($claims['video']['roomJoin']);
        $this->assertTrue($claims['video']['roomAdmin']);
    }

    public function test_group_call_enforces_participant_cap_and_host_kick_triggers_e2ee_ratchet(): void
    {
        $host = User::factory()->create();
        $guest1 = User::factory()->create();
        $guest2 = User::factory()->create();

        Sanctum::actingAs($host);
        $roomCode = $this->postJson('/api/v1/meetings', [
            'max_participants' => 2,
            'e2ee_enabled' => true,
        ])->json('data.room_code');

        $this->postJson("/api/v1/meetings/{$roomCode}/join")->assertOk();

        Sanctum::actingAs($guest1);
        $this->postJson("/api/v1/meetings/{$roomCode}/join")->assertOk();

        // 3rd user exceeds 2-participant cap
        Sanctum::actingAs($guest2);
        $this->postJson("/api/v1/meetings/{$roomCode}/join")->assertStatus(429);

        // Host kicks guest1 -> response flags E2EE ratchet requirement & blocks guest1 from rejoining
        Sanctum::actingAs($host);
        $this->postJson("/api/v1/meetings/{$roomCode}/moderate", [
            'action' => 'kick',
            'target_user_id' => $guest1->id,
        ])->assertOk()
            ->assertJsonPath('e2ee_ratchet_required', true);

        Sanctum::actingAs($guest1);
        $this->postJson("/api/v1/meetings/{$roomCode}/join")->assertStatus(403);
    }

    public function test_signed_livekit_webhook_updates_room_state_and_rejects_forged_signatures(): void
    {
        $host = User::factory()->create();
        Sanctum::actingAs($host);
        $roomCode = $this->postJson('/api/v1/meetings')->json('data.room_code');
        $this->postJson("/api/v1/meetings/{$roomCode}/join")->assertOk();

        $roomRow = \Illuminate\Support\Facades\DB::table('meeting_rooms')->where('room_code', $roomCode)->first();
        $body = json_encode([
            'event' => 'room_finished',
            'room' => ['name' => $roomRow->livekit_room_name],
        ], JSON_UNESCAPED_SLASHES);

        // Forged webhook must fail with 401
        $this->call('POST', '/api/v1/meetings/webhook', [], [], [], [
            'HTTP_AUTHORIZATION' => 'Bearer invalid.jwt.token',
            'CONTENT_TYPE' => 'application/json',
        ], $body)->assertStatus(401);

        // Properly signed LiveKit webhook marks room ended
        $tokenService = app(LiveKitTokenService::class);
        $validWebhookJwt = $tokenService->encodeHs256Jwt([
            'iss' => 'APOLO_LK_TEST_KEY',
            'iat' => time(),
            'nbf' => time() - 5,
            'exp' => time() + 60,
            'sha256' => base64_encode(hash('sha256', $body, true)),
        ], 'apolo_super_secret_livekit_signing_key_2026_test');

        $this->call('POST', '/api/v1/meetings/webhook', [], [], [], [
            'HTTP_AUTHORIZATION' => "Bearer {$validWebhookJwt}",
            'CONTENT_TYPE' => 'application/json',
        ], $body)->assertOk();

        $this->assertSame(
            'ended',
            \Illuminate\Support\Facades\DB::table('meeting_rooms')->where('id', $roomRow->id)->value('status')
        );
    }
}
