<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AdsModel;
use App\Models\User;
use App\Models\StoreModel;
use App\Models\AdPayment;
use App\Models\ReportModel;
use App\Models\ContactModel;
use App\Models\BlogPost;
use App\Models\CityModel;
use App\Models\DeviceToken;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

class AdminDashboardController extends Controller
{
    public function index()
    {
        // 1. Single GROUP BY query for all ad status counts
        $adStatusCounts = Cache::remember('admin_ad_status_counts', 120, function () {
            return AdsModel::withTrashed()
                ->selectRaw('
                    COUNT(*) as total,
                    SUM(CASE WHEN deleted_at IS NULL AND status = 0 THEN 1 ELSE 0 END) as pending,
                    SUM(CASE WHEN deleted_at IS NULL AND status = 1 THEN 1 ELSE 0 END) as active,
                    SUM(CASE WHEN deleted_at IS NULL AND status = 2 THEN 1 ELSE 0 END) as expired,
                    SUM(CASE WHEN deleted_at IS NULL AND status = 3 THEN 1 ELSE 0 END) as blocked,
                    SUM(CASE WHEN deleted_at IS NOT NULL THEN 1 ELSE 0 END) as deleted
                ')
                ->first();
        });

        // 2. Single GROUP BY query for user counts
        $userCounts = Cache::remember('admin_user_counts', 120, function () {
            return User::selectRaw('
                COUNT(*) as total,
                SUM(CASE WHEN status = 1 THEN 1 ELSE 0 END) as active,
                SUM(CASE WHEN status = 0 THEN 1 ELSE 0 END) as blocked
            ')->first();
        });

        // 3. Misc operational stats in a single cached block
        $miscStats = Cache::remember('admin_misc_stats', 120, function () {
            return [
                'total_stores'    => StoreModel::count(),
                'monthly_revenue' => AdPayment::whereMonth('created_at', now()->month)
                                        ->whereIn('status', ['paid', 'approved'])
                                        ->sum('amount'),
                'pending_reports' => ReportModel::where('status', 0)
                                        ->distinct('ads_id')
                                        ->count('ads_id'),
                'unread_messages' => ContactModel::where('status', 0)->count(),
                'blog_count'      => BlogPost::count(),
            ];
        });

        // 4. Assemble stats array
        $stats = [
            'total_ads'       => ($adStatusCounts->total ?? 0) - ($adStatusCounts->deleted ?? 0),
            'active_ads'      => $adStatusCounts->active ?? 0,
            'pending_ads'     => $adStatusCounts->pending ?? 0,
            'expired_ads'     => $adStatusCounts->expired ?? 0,
            'blocked_ads'     => $adStatusCounts->blocked ?? 0,
            'deleted_ads'     => $adStatusCounts->deleted ?? 0,
            'active_users'    => $userCounts->active ?? 0,
            'blocked_users'   => $userCounts->blocked ?? 0,
            'total_stores'    => $miscStats['total_stores'],
            'monthly_revenue' => $miscStats['monthly_revenue'],
            'pending_reports' => $miscStats['pending_reports'],
            'unread_messages' => $miscStats['unread_messages'],
            'blog_count'      => $miscStats['blog_count'],
        ];

        // 5. Chart data
        $weeklyAds = Cache::remember('admin_weekly_ads', 300, function () {
            return AdsModel::selectRaw('DAYOFWEEK(created_at) as day, COUNT(*) as count')
                ->whereBetween('created_at', [now()->subDays(6), now()])
                ->groupBy('day')->orderBy('day')->get();
        });

        $monthlyUsers = Cache::remember('admin_monthly_users', 300, function () {
            return User::selectRaw('DATE(created_at) as date, COUNT(*) as count')
                ->whereBetween('created_at', [now()->subDays(29), now()])
                ->groupBy('date')->orderBy('date')->get();
        });

        $adStatusStats = Cache::remember('admin_ad_status_stats', 120, function () {
            return AdsModel::selectRaw('status, COUNT(*) as count')
                ->groupBy('status')->get()
                ->mapWithKeys(fn($r) => [$r->status => $r->count]);
        });

        // 6. Recent users and pending ads
        $recentUsers = User::with('store')->latest()->limit(5)->get();
        $pendingAds  = AdsModel::with(['user', 'reports'])
            ->where('status', 0)->latest()->limit(5)->get();

        // 7. Referral stats
        $referralStats = Cache::remember('admin_referral_stats', 300, function () {
            return User::whereNotNull('referral_source')
                ->selectRaw('referral_source, COUNT(*) as count')
                ->groupBy('referral_source')
                ->orderByDesc('count')
                ->get();
        });

        // 8. Mobile App Control & Telemetry data
        $deviceTokensCount = Cache::remember('admin_device_tokens_count', 120, function () {
            return class_exists(DeviceToken::class) ? DeviceToken::count() : 0;
        });

        // 9. Top cities by active ads count
        $topCities = Cache::remember('admin_top_cities', 300, function () {
            return CityModel::withCount(['ads' => function($q) {
                $q->where('status', 1);
            }])->orderByDesc('ads_count')->limit(6)->get();
        });

        // 10. Security Shield stats (Chinese numbers & low trust users)
        $suspiciousUsersCount = Cache::remember('admin_suspicious_users', 120, function () {
            return User::where(function($q) {
                $q->where('phone_country_code', '+86')
                  ->orWhere('phone', 'like', '86%')
                  ->orWhere('phone', 'like', '+86%')
                  ->orWhere('trust_score', '<', 30);
            })->count();
        });

        // 11. Mobile App Remote Config settings
        $appConfig = [
            'maintenance_mode'      => (bool) Cache::get('app_maintenance_mode', false),
            'maintenance_message'   => Cache::get('app_maintenance_message', 'تطبيق Apolo.ma يخضع لصيانة دورية مجدولة. سنعود للعمل قريباً!'),
            'min_version'           => Cache::get('app_min_version', '1.0.0'),
            'latest_version'        => Cache::get('app_latest_version', '2.0.0'),
            'force_update'          => (bool) Cache::get('app_force_update', false),
            'announcement_banner'   => Cache::get('app_announcement_banner', 'مرحباً بكم في تطبيق Apolo.ma الجديد! تصفح آلاف الإعلانات الحصرية في المغرب.'),
            'announcement_active'   => (bool) Cache::get('app_announcement_active', true),
            'section_vip_enabled'   => (bool) Cache::get('app_section_vip_enabled', true),
            'section_stores_enabled'=> (bool) Cache::get('app_section_stores_enabled', true),
            'app_store_url'         => Cache::get('app_store_url', 'https://apps.apple.com/app/apolo-ma'),
            'play_store_url'        => Cache::get('app_play_store_url', 'https://play.google.com/store/apps/details?id=ma.apolo.app'),
        ];

        return view('admin.dashboard', compact(
            'stats', 'weeklyAds', 'monthlyUsers',
            'adStatusStats', 'recentUsers', 'pendingAds', 'referralStats',
            'deviceTokensCount', 'topCities', 'suspiciousUsersCount', 'appConfig'
        ));
    }

    public function saveAppControl(Request $request)
    {
        $request->validate([
            'min_version'         => 'nullable|string|max:20',
            'latest_version'      => 'nullable|string|max:20',
            'maintenance_message' => 'nullable|string|max:255',
            'announcement_banner' => 'nullable|string|max:255',
            'app_store_url'       => 'nullable|url|max:255',
            'play_store_url'      => 'nullable|url|max:255',
        ]);

        Cache::forever('app_maintenance_mode', $request->has('maintenance_mode'));
        Cache::forever('app_maintenance_message', $request->input('maintenance_message', 'تطبيق Apolo.ma يخضع لصيانة دورية مجدولة.'));
        Cache::forever('app_min_version', $request->input('min_version', '1.0.0'));
        Cache::forever('app_latest_version', $request->input('latest_version', '2.0.0'));
        Cache::forever('app_force_update', $request->has('force_update'));
        Cache::forever('app_announcement_banner', $request->input('announcement_banner', ''));
        Cache::forever('app_announcement_active', $request->has('announcement_active'));
        Cache::forever('app_section_vip_enabled', $request->has('section_vip_enabled'));
        Cache::forever('app_section_stores_enabled', $request->has('section_stores_enabled'));
        if ($request->filled('app_store_url')) Cache::forever('app_store_url', $request->input('app_store_url'));
        if ($request->filled('play_store_url')) Cache::forever('app_play_store_url', $request->input('play_store_url'));

        return redirect()->route('admin.dashboard')->with('success', 'تم حفظ إعدادات تطبيق الموبايل بنجاح، وتطبيقها فورياً على جميع الأجهزة.');
    }

    public function broadcastPush(Request $request)
    {
        $request->validate([
            'push_title' => 'required|string|max:100',
            'push_body'  => 'required|string|max:250',
            'push_link'  => 'nullable|string|max:255',
        ]);

        $title = $request->input('push_title');
        $body = $request->input('push_body');
        $link = $request->input('push_link');

        // Log push broadcast in database / cache
        $tokensCount = class_exists(DeviceToken::class) ? DeviceToken::count() : 0;

        // Save last broadcast notification
        Cache::forever('last_push_broadcast', [
            'title'     => $title,
            'body'      => $body,
            'link'      => $link,
            'sent_at'   => now()->toDateTimeString(),
            'recipients'=> $tokensCount,
        ]);

        return redirect()->route('admin.dashboard')->with('success', "تم جدولة وبث الإشعار الفوري بنجاح إلى {$tokensCount} جهاز متصل عبر تطبيق الموبايل.");
    }
}
