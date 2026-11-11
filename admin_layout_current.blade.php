<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>@yield('title', 'لوحة التحكم') — Apolo Control 2026</title>
    <!-- Fonts: Tajawal + JetBrains Mono for telemetry + Apple SF Pro system fallback -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;600&family=Tajawal:wght@400;500;700&display=swap" rel="stylesheet">
    <!-- Bootstrap 5 CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Tabler Icons Webfont -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@latest/dist/tabler-icons.min.css">
    
    <style>
        /* =========================================================
           UNIVERSAL DUAL-THEME ENGINE (DARK & LIGHT MODE 2026)
           ========================================================= */
        :root {
            /* 1. DARK MODE (DEFAULT) — APPLE DEEP SAPPHIRE & APOLO BRAND */
            --bg1: #07111E;                  /* Deep sapphire page background */
            --bg2: #0E1E32;                  /* Frosted card / panel surface */
            --bg3: #162C48;                  /* Raised / table headers / hover rows */
            --bg4: #1E3A5C;                  /* Elevated inputs / borders */

            --txt1: #F8FAFC;                 /* High-contrast crisp primary text */
            --txt2: #94A3B8;                 /* Clean readable secondary slate */
            --txt3: #64748B;                 /* Muted metadata / timestamps */

            --bdr: rgba(255, 255, 255, 0.09);
            --bdr-strong: rgba(255, 255, 255, 0.16);
            --bdr-glass: rgba(255, 255, 255, 0.05);

            /* Official Apolo Crimson Red */
            --acc: #E31B23;
            --acc-subtle: rgba(227, 27, 35, 0.12);
            --acc-hover: #c8141b;

            /* Semantics */
            --danger: #F87171;
            --danger-subtle: rgba(248, 113, 113, 0.12);
            --success: #34D399;
            --success-subtle: rgba(52, 211, 153, 0.12);
            --warning: #FBBF24;
            --warning-subtle: rgba(251, 191, 36, 0.12);
            --info: #38BDF8;
            --info-subtle: rgba(56, 189, 248, 0.12);
            --purple: #A78BFA;
            --purple-subtle: rgba(167, 139, 250, 0.12);

            /* Backward-Compatibility & Apple Theme Aliases */
            --brand-navy: #0D233E;
            --brand-navy-deep: var(--bg1);
            --brand-navy-surface: var(--bg2);
            --brand-navy-card: var(--bg2);
            --brand-navy-raised: var(--bg3);
            --brand-navy-hover: var(--bg4);

            --txt-primary: var(--txt1);
            --txt-secondary: var(--txt2);
            --txt-muted: var(--txt3);

            /* Apple Squircle Continuous Corners */
            --r-card: 18px;
            --r-item: 12px;
            --r-tag: 6px;
            --r-pill: 9999px;

            /* Apple Timing Curves */
            --ease-apple: cubic-bezier(0.16, 1, 0.3, 1);
            --dur-fast: 180ms;
        }

        /* 2. LIGHT MODE OVERRIDES (.lm) — APPLE CUPERTINO & APOLO WEBSITE PALETTE */
        html.lm, body.lm, .app-shell.lm {
            --bg1: #F4F7FB;                  /* Crisp light canvas, matches Apolo.ma public site */
            --bg2: #FFFFFF;                  /* Pure white card surface */
            --bg3: #EDF2F9;                  /* Soft light grey for table headers & hovers */
            --bg4: #E2E8F0;                  /* Border dividers & raised inputs */

            --txt1: #0D233E;                 /* Deep rich brand navy — crystal clear on white */
            --txt2: #475569;                 /* High-contrast slate for labels & subtitles */
            --txt3: #64748B;                 /* Clean muted slate for captions */

            --bdr: rgba(13, 35, 62, 0.09);
            --bdr-strong: rgba(13, 35, 62, 0.18);
            --bdr-glass: rgba(13, 35, 62, 0.04);

            --acc: #E31B23;
            --acc-subtle: rgba(227, 27, 35, 0.08);
            --acc-hover: #c8141b;

            --danger: #DC2626;
            --danger-subtle: rgba(220, 38, 38, 0.10);
            --success: #10B981;
            --success-subtle: rgba(16, 185, 129, 0.10);
            --warning: #D97706;
            --warning-subtle: rgba(217, 119, 6, 0.10);
            --info: #0284C7;
            --info-subtle: rgba(2, 132, 199, 0.10);
            --purple: #7C3AED;
            --purple-subtle: rgba(124, 58, 237, 0.10);

            --brand-navy-deep: var(--bg1);
            --brand-navy-surface: var(--bg2);
            --brand-navy-card: var(--bg2);
            --brand-navy-raised: var(--bg3);
            --brand-navy-hover: var(--bg4);

            --txt-primary: var(--txt1);
            --txt-secondary: var(--txt2);
            --txt-muted: var(--txt3);
        }

        /* Reset & Base Typography */
        *, *::before, *::after {
            box-sizing: border-box;
            box-shadow: none !important;
            text-shadow: none !important;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Tajawal', "SF Pro Text", "Segoe UI", Roboto, sans-serif;
            background-color: var(--bg1);
            color: var(--txt1);
            margin: 0;
            padding: 0;
            font-weight: 400;
            line-height: 1.5;
            -webkit-font-smoothing: antialiased;
            letter-spacing: -0.15px;
            transition: background-color var(--dur-fast) var(--ease-apple), color var(--dur-fast) var(--ease-apple);
        }

        .mono-nums {
            font-family: 'JetBrains Mono', ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
            font-variant-numeric: tabular-nums;
            letter-spacing: -0.3px;
        }

        /* Universal Typography Across All Admin Pages */
        h1, h2, h3, h4, h5, h6, .page-title, .section-title, .card-title, .stat-val {
            color: var(--txt1) !important;
            font-weight: 600 !important;
        }
        p, .page-subtitle, .stat-lbl, .text-muted {
            color: var(--txt2);
        }
        strong, b {
            color: var(--txt1) !important;
            font-weight: 600 !important;
        }

        /* Universal Card & Container System Across All Pages */
        .card, .stat-card, .card-table-section, .table-card, .apple-card, .craft-card {
            background-color: var(--bg2) !important;
            border: 1px solid var(--bdr) !important;
            border-radius: var(--r-card);
            color: var(--txt1);
            transition: all var(--dur-fast) var(--ease-apple);
        }

        /* Universal Tables (email-stats, users, ads, orders, reviews) */
        table, .table {
            color: var(--txt1) !important;
            background-color: transparent !important;
            border-collapse: collapse;
            width: 100%;
        }
        table th, .table th {
            color: var(--txt2) !important;
            background-color: var(--bg3) !important;
            border-bottom: 1px solid var(--bdr) !important;
            border-top: none !important;
            padding: 12px 14px !important;
            font-size: 11px !important;
            font-weight: 600 !important;
            text-transform: uppercase;
            letter-spacing: 0.2px;
            text-align: right;
        }
        table td, .table td {
            color: var(--txt1) !important;
            border-bottom: 1px solid var(--bdr) !important;
            border-top: none !important;
            padding: 12px 14px !important;
            vertical-align: middle;
            font-size: 12px !important;
            text-align: right;
        }
        table tr:last-child td, .table tr:last-child td {
            border-bottom: none !important;
        }
        table tbody tr:hover, .table tbody tr:hover {
            background-color: var(--bg3) !important;
        }

        /* Universal Form Controls (inputs, selects, textareas) */
        .form-control, .form-select, input, select, textarea {
            background-color: var(--bg2) !important;
            color: var(--txt1) !important;
            border: 1px solid var(--bdr) !important;
            border-radius: var(--r-item);
            padding: 9px 14px;
            font-size: 13px;
            outline: none !important;
            transition: border-color var(--dur-fast) var(--ease-apple);
        }
        .form-control:focus, .form-select:focus, input:focus, select:focus, textarea:focus {
            border-color: var(--acc) !important;
            background-color: var(--bg2) !important;
            color: var(--txt1) !important;
        }

        /* Universal Status Badges */
        .status-badge, .badge {
            font-weight: 500;
            border-radius: var(--r-tag);
        }
        .status-badge-success, .badge.bg-success, .badge-success {
            background-color: var(--success-subtle) !important;
            color: var(--success) !important;
            border: 1px solid rgba(16, 185, 129, 0.25) !important;
        }
        .status-badge-warning, .badge.bg-warning, .badge-warning {
            background-color: var(--warning-subtle) !important;
            color: var(--warning) !important;
            border: 1px solid rgba(245, 158, 11, 0.25) !important;
        }
        .status-badge-danger, .badge.bg-danger, .badge-danger {
            background-color: var(--danger-subtle) !important;
            color: var(--danger) !important;
            border: 1px solid rgba(220, 38, 38, 0.25) !important;
        }
        .status-badge-info, .badge.bg-info, .badge-info, .badge.bg-primary {
            background-color: var(--info-subtle) !important;
            color: var(--info) !important;
            border: 1px solid rgba(2, 132, 199, 0.25) !important;
        }

        /* Grid Layout Shell */
        .app-shell {
            display: grid;
            grid-template-columns: 260px 1fr;
            min-height: 100vh;
            background-color: var(--bg1);
        }

        /* Sidebar: macOS Style, Frosted Translucent Material */
        .sidebar-wrapper {
            background-color: var(--bg2);
            border-left: 1px solid var(--bdr);
            height: 100vh;
            position: sticky;
            top: 0;
            z-index: 1000;
            display: flex;
            flex-direction: column;
            overflow-y: auto;
            backdrop-filter: blur(20px);
            -webkit-backdrop-filter: blur(20px);
        }

        .sidebar-header {
            padding: 18px 20px;
            display: flex;
            align-items: center;
            gap: 12px;
            border-bottom: 1px solid var(--bdr);
            min-height: 64px;
        }

        .sidebar-brand-mark {
            width: 34px;
            height: 34px;
            border-radius: 9px;
            background: linear-gradient(135deg, #E31B23 0%, #B8141B 100%);
            color: #ffffff;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 700;
            font-size: 15px;
            flex-shrink: 0;
            border: 1px solid rgba(255, 255, 255, 0.2);
        }

        .sidebar-brand-text {
            display: flex;
            flex-direction: column;
        }

        .sidebar-brand-name {
            font-size: 15px;
            font-weight: 600;
            color: var(--txt1);
            line-height: 1.2;
            letter-spacing: -0.2px;
        }

        .sidebar-brand-sub {
            font-size: 11px;
            color: var(--txt3);
            margin-top: 1px;
        }

        .sidebar-nav-container {
            display: flex;
            flex-direction: column;
            padding: 16px 14px;
            flex-grow: 1;
            gap: 3px;
        }

        .sidebar-section-title {
            font-size: 11px;
            font-weight: 600;
            color: var(--txt3);
            margin: 20px 10px 8px 10px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .sidebar-section-title:first-child {
            margin-top: 4px;
        }

        .sidebar-nav-link {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 9px 12px;
            color: var(--txt2);
            text-decoration: none;
            border-radius: var(--r-item);
            font-size: 13px;
            font-weight: 400;
            height: 38px;
            transition: all var(--dur-fast) var(--ease-apple);
        }

        .sidebar-nav-link:hover {
            background-color: var(--bg3);
            color: var(--txt1);
        }

        .sidebar-nav-link.active {
            background-color: var(--bg3);
            color: var(--txt1);
            font-weight: 600;
            border: 1px solid var(--bdr-strong);
        }

        .sidebar-nav-link .link-content {
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .sidebar-nav-link i {
            font-size: 17px;
            color: var(--txt3);
            transition: color var(--dur-fast) var(--ease-apple);
        }
        .sidebar-nav-link:hover i,
        .sidebar-nav-link.active i {
            color: var(--txt1);
        }
        .sidebar-nav-link.active i {
            color: var(--acc);
        }

        /* Sidebar Badges */
        .sidebar-badge {
            font-family: 'JetBrains Mono', monospace;
            font-size: 10px;
            padding: 2px 7px;
            border-radius: var(--r-tag);
            border: 1px solid transparent;
            line-height: 1;
            font-weight: 600;
        }
        .sidebar-badge-amber {
            background-color: var(--warning-subtle);
            color: var(--warning);
            border-color: rgba(245, 158, 11, 0.25);
        }
        .sidebar-badge-red {
            background-color: var(--danger-subtle);
            color: var(--danger);
            border-color: rgba(229, 72, 77, 0.25);
        }
        .sidebar-badge-blue {
            background-color: var(--info-subtle);
            color: var(--info);
            border-color: rgba(56, 189, 248, 0.25);
        }

        /* Main Content Wrapper */
        .main-wrapper {
            display: flex;
            flex-direction: column;
            min-height: 100vh;
            overflow-x: hidden;
            background-color: var(--bg1);
        }

        /* Topbar: 60px, Apple Glass Material */
        .topbar-wrapper {
            height: 60px;
            background-color: var(--bg2);
            border-bottom: 1px solid var(--bdr);
            position: sticky;
            top: 0;
            z-index: 900;
            display: flex;
            align-items: center;
            padding: 0 28px;
            backdrop-filter: blur(20px);
            -webkit-backdrop-filter: blur(20px);
        }

        .topbar-actions {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .topbar-btn {
            background: transparent;
            border: 1px solid transparent;
            color: var(--txt2);
            padding: 6px 12px;
            border-radius: var(--r-item);
            display: inline-flex;
            align-items: center;
            gap: 6px;
            text-decoration: none;
            transition: all var(--dur-fast) var(--ease-apple);
            font-size: 12px;
            cursor: pointer;
        }
        .topbar-btn:hover {
            background-color: var(--bg3);
            color: var(--txt1);
            border-color: var(--bdr);
        }
        .topbar-btn i {
            font-size: 17px;
        }

        .live-pulse-dot {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            background-color: var(--success);
            display: inline-block;
            position: relative;
        }
        .live-pulse-dot::after {
            content: '';
            position: absolute;
            width: 100%;
            height: 100%;
            border-radius: 50%;
            background-color: var(--success);
            opacity: 0.5;
            animation: pulse-ring 2s infinite var(--ease-apple);
        }
        @keyframes pulse-ring {
            0% { transform: scale(1); opacity: 0.8; }
            100% { transform: scale(2.4); opacity: 0; }
        }

        .user-avatar-initials {
            width: 34px;
            height: 34px;
            border-radius: 10px;
            background-color: var(--bg3);
            border: 1px solid var(--bdr-strong);
            color: var(--txt1);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 13px;
            font-weight: 600;
        }

        /* Page Content Area */
        .page-content {
            padding: 28px 32px;
            flex-grow: 1;
            max-width: 1560px;
            width: 100%;
            margin: 0 auto;
        }

        /* Custom Scrollbar */
        ::-webkit-scrollbar {
            width: 6px;
            height: 6px;
        }
        ::-webkit-scrollbar-track {
            background: var(--bg1);
        }
        ::-webkit-scrollbar-thumb {
            background: var(--bg3);
            border-radius: 3px;
        }
        ::-webkit-scrollbar-thumb:hover {
            background: var(--bg4);
        }

        /* Responsive Mobile Settings */
        @media (max-width: 991.98px) {
            .app-shell { grid-template-columns: 1fr; }
            .sidebar-wrapper {
                position: fixed !important;
                top: 0;
                right: -260px;
                width: 260px !important;
                height: 100vh !important;
                transition: transform 0.28s var(--ease-apple);
                z-index: 1050;
            }
            .sidebar-wrapper.show { transform: translateX(-260px); }
            .sidebar-overlay {
                display: none;
                position: fixed;
                top: 0;
                left: 0;
                width: 100vw;
                height: 100vh;
                background: rgba(0, 0, 0, 0.65);
                backdrop-filter: blur(4px);
                z-index: 1040;
            }
            .sidebar-overlay.show { display: block; }
            .page-content { padding: 18px 16px; }
            .topbar-wrapper { padding: 0 16px; }
        }
    </style>
</head>
<body>

    <!-- Mobile Sidebar Overlay -->
    <div class="sidebar-overlay" id="sidebarOverlay"></div>

    <div class="app-shell" id="app-shell">
        
        <!-- Sidebar Navigation (260px) -->
        <aside class="sidebar-wrapper" id="sidebarMenu">
            <!-- Brand Mark -->
            <div class="sidebar-header">
                <div class="sidebar-brand-mark">A</div>
                <div class="sidebar-brand-text">
                    <span class="sidebar-brand-name">Apolo Control</span>
                    <span class="sidebar-brand-sub">مركز العمليات وإدارة التطبيق</span>
                </div>
            </div>

            <!-- Navigation Sections -->
            <div class="sidebar-nav-container">
                
                <span class="sidebar-section-title">نظرة عامة</span>
                <a href="{{ route('admin.dashboard') }}" class="sidebar-nav-link {{ Route::is('admin.dashboard') || Route::is('admin.index') ? 'active' : '' }}">
                    <div class="link-content">
                        <i class="ti ti-layout-dashboard"></i>
                        <span>الداشبورد المباشر</span>
                    </div>
                </a>

                <span class="sidebar-section-title">تطبيق الموبايل</span>
                <a href="{{ route('admin.dashboard') }}#app-control" class="sidebar-nav-link" onclick="if(window.switchMainTab){ switchMainTab('app'); }">
                    <div class="link-content">
                        <i class="ti ti-device-mobile"></i>
                        <span>التحكم في التطبيق</span>
                    </div>
                    @if(($deviceTokensCount ?? 0) > 0)
                        <span class="sidebar-badge sidebar-badge-blue">{{ $deviceTokensCount }} هاتف</span>
                    @endif
                </a>

                <span class="sidebar-section-title">الإعلانات والمحتوى</span>
                <a href="{{ route('admin.ads.index') }}" class="sidebar-nav-link {{ Route::is('admin.ads.index') || Route::is('admin.ad_active') ? 'active' : '' }}">
                    <div class="link-content">
                        <i class="ti ti-speakerphone"></i>
                        <span>جميع الإعلانات</span>
                    </div>
                </a>
                <a href="{{ route('admin.ads.pending') }}" class="sidebar-nav-link {{ Route::is('admin.ads.pending') || Route::is('admin.ad_pending') ? 'active' : '' }}">
                    <div class="link-content">
                        <i class="ti ti-clock-hour-4"></i>
                        <span>قيد المراجعة</span>
                    </div>
                    @if(($stats['pending_ads'] ?? 0) > 0)
                        <span class="sidebar-badge sidebar-badge-amber">{{ $stats['pending_ads'] }}</span>
                    @endif
                </a>
                <a href="{{ route('admin.ads.reported') }}" class="sidebar-nav-link {{ Route::is('admin.ads.reported') || Route::is('admin.ad_reported') ? 'active' : '' }}">
                    <div class="link-content">
                        <i class="ti ti-flag"></i>
                        <span>البلاغات المعلقة</span>
                    </div>
                    @if(($stats['pending_reports'] ?? 0) > 0)
                        <span class="sidebar-badge sidebar-badge-red">{{ $stats['pending_reports'] }}</span>
                    @endif
                </a>
                <a href="{{ route('admin.ads.vip') }}" class="sidebar-nav-link {{ Route::is('admin.ads.vip') ? 'active' : '' }}">
                    <div class="link-content">
                        <i class="ti ti-sparkles"></i>
                        <span>إعلانات VIP</span>
                    </div>
                </a>

                <span class="sidebar-section-title">المستخدمون والمتاجر</span>
                <a href="{{ route('admin.users') }}" class="sidebar-nav-link {{ Route::is('admin.users') ? 'active' : '' }}">
                    <div class="link-content">
                        <i class="ti ti-users"></i>
                        <span>سجل المستخدمين</span>
                    </div>
                </a>
                <a href="{{ route('admin.users.blocked') }}" class="sidebar-nav-link {{ Route::is('admin.users.blocked') ? 'active' : '' }}">
                    <div class="link-content">
                        <i class="ti ti-user-x"></i>
                        <span>الحسابات الموقوفة</span>
                    </div>
                </a>
                <a href="{{ route('admin.stores') }}" class="sidebar-nav-link {{ Route::is('admin.stores') ? 'active' : '' }}">
                    <div class="link-content">
                        <i class="ti ti-building-store"></i>
                        <span>المتاجر المسجلة</span>
                    </div>
                </a>

                <span class="sidebar-section-title">المعاملات والتجارة</span>
                <a href="{{ route('admin.orders') }}" class="sidebar-nav-link {{ Route::is('admin.orders') ? 'active' : '' }}">
                    <div class="link-content">
                        <i class="ti ti-shopping-cart"></i>
                        <span>الطلبات</span>
                    </div>
                </a>
                <a href="{{ route('admin.payments.index') }}" class="sidebar-nav-link {{ Route::is('admin.payments.index') ? 'active' : '' }}">
                    <div class="link-content">
                        <i class="ti ti-receipt-2"></i>
                        <span>مدفوعات الإعلانات</span>
                    </div>
                    @php
                        $pendingPayments = \App\Models\AdPayment::where('status', 'payment_submitted')->count();
                    @endphp
                    @if($pendingPayments > 0)
                        <span class="sidebar-badge sidebar-badge-blue">{{ $pendingPayments }}</span>
                    @endif
                </a>

                <span class="sidebar-section-title">التواصل والنشر</span>
                <a href="{{ route('admin.message') }}" class="sidebar-nav-link {{ Route::is('admin.message') ? 'active' : '' }}">
                    <div class="link-content">
                        <i class="ti ti-inbox"></i>
                        <span>الرسائل والاتصال</span>
                    </div>
                    @if(($stats['unread_messages'] ?? 0) > 0)
                        <span class="sidebar-badge sidebar-badge-red">{{ $stats['unread_messages'] }}</span>
                    @endif
                </a>
                <a href="{{ route('admin.email.stats') }}" class="sidebar-nav-link {{ Route::is('admin.email.stats') ? 'active' : '' }}">
                    <div class="link-content">
                        <i class="ti ti-chart-arrows"></i>
                        <span>سجل البريد</span>
                    </div>
                </a>
                <a href="{{ route('admin.blog.index') }}" class="sidebar-nav-link {{ Route::is('admin.blog.*') ? 'active' : '' }}">
                    <div class="link-content">
                        <i class="ti ti-article"></i>
                        <span>المدونة</span>
                    </div>
                </a>
                <a href="{{ route('admin.reviews.index') }}" class="sidebar-nav-link {{ Route::is('admin.reviews.*') ? 'active' : '' }}">
                    <div class="link-content">
                        <i class="ti ti-star"></i>
                        <span>التقييمات</span>
                    </div>
                </a>

                <span class="sidebar-section-title">إدارة النظام</span>
                <a href="{{ route('admin.audit') }}" class="sidebar-nav-link {{ Route::is('admin.audit') ? 'active' : '' }}">
                    <div class="link-content">
                        <i class="ti ti-shield-check"></i>
                        <span>الأمان والتدقيق</span>
                    </div>
                </a>
                <a href="{{ route('admin.settings') }}" class="sidebar-nav-link {{ Route::is('admin.settings') ? 'active' : '' }}">
                    <div class="link-content">
                        <i class="ti ti-adjustments"></i>
                        <span>إعدادات المنصة</span>
                    </div>
                </a>

                <!-- Bottom Logout Link -->
                <div class="mt-auto pt-3 border-top" style="border-color: var(--bdr);">
                    <a href="#" onclick="event.preventDefault(); document.getElementById('logout-form').submit();" class="sidebar-nav-link text-danger">
                        <div class="link-content">
                            <i class="ti ti-logout text-danger"></i>
                            <span>تسجيل الخروج</span>
                        </div>
                    </a>
                </div>
            </div>
        </aside>

        <!-- Hidden form for Laravel logout -->
        <form id="logout-form" action="{{ route('logout') }}" method="POST" class="d-none">
            @csrf
        </form>

        <!-- Main Content (1fr) -->
        <main class="main-wrapper">
            
            <!-- Topbar (60px) -->
            <header class="topbar-wrapper d-flex align-items-center justify-content-between">
                
                <!-- Right Side (RTL Start) -->
                <div class="d-flex align-items-center gap-3">
                    <!-- Mobile Hamburger -->
                    <button class="topbar-btn d-lg-none" id="mobileMenuBtn" type="button" aria-label="القائمة">
                        <i class="ti ti-menu-2"></i>
                    </button>
                    <!-- Apple Style Telemetry Indicator -->
                    <div class="d-flex align-items-center gap-2" style="font-size: 13px; color: var(--txt2);">
                        <span class="live-pulse-dot"></span>
                        <span class="d-none d-sm-inline fw-medium" style="color: var(--txt1);">النظام متصل ومستقر</span>
                        <span class="text-muted d-none d-md-inline" style="font-size: 11px;">• Apolo v2.4</span>
                    </div>
                </div>

                <!-- Left Side (RTL End) -->
                <div class="topbar-actions">
                    <!-- Date Pill -->
                    <div class="d-none d-md-flex align-items-center px-3 py-1 rounded-pill" style="background-color: var(--bg3); border: 1px solid var(--bdr); font-size: 11px; color: var(--txt2);">
                        <i class="ti ti-calendar me-1"></i>
                        {{ Carbon\Carbon::now()->locale('ar')->translatedFormat('l j F Y') }}
                    </div>

                    <!-- Theme Toggle -->
                    <button class="topbar-btn" id="theme-toggle" title="تبديل المظهر">
                        <i class="ti ti-sun" id="theme-toggle-icon"></i>
                        <span id="theme-toggle-text" class="d-none d-sm-inline">فاتح</span>
                    </button>

                    <!-- View Live Site -->
                    <a href="{{ route('home.ads.index') }}" target="_blank" class="topbar-btn" title="معاينة الموقع الحي">
                        <i class="ti ti-external-link"></i>
                        <span class="d-none d-sm-inline">الموقع</span>
                    </a>

                    <!-- Security Notifications -->
                    <a href="{{ route('admin.audit') }}" class="topbar-btn position-relative" title="سجل الأمان">
                        <i class="ti ti-bell"></i>
                        @php
                            $unreadNotifsCount = auth()->user()->unreadNotifications->count() ?? 0;
                        @endphp
                        @if(($stats['pending_reports'] ?? 0) > 0 || ($stats['unread_messages'] ?? 0) > 0 || $unreadNotifsCount > 0)
                            <span class="position-absolute top-0 start-100 translate-middle p-1 bg-danger rounded-circle" style="width: 7px; height: 7px;"></span>
                        @endif
                    </a>

                    <!-- Admin Profile / Initials -->
                    <div class="d-flex align-items-center gap-2 ps-2 border-start" style="border-color: var(--bdr);">
                        <div class="user-avatar-initials">
                            {{ mb_substr(auth()->user()->name, 0, 1) }}
                        </div>
                        <div class="d-none d-xl-flex flex-column" style="line-height: 1.2;">
                            <span style="font-size: 13px; font-weight: 600; color: var(--txt1);">{{ auth()->user()->name }}</span>
                            <span style="font-size: 10px; color: var(--txt3);">مدير المنصة</span>
                        </div>
                    </div>
                </div>

            </header>

            <!-- Page Content Container -->
            <section class="page-content">
                @yield('content')
            </section>

        </main>
    </div>

    <!-- Bootstrap 5 JS Bundle -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>

    <!-- Theme Toggler and Mobile Menu Script -->
    <script>
        (function() {
            // Apply saved theme immediately to prevent flashing
            const savedTheme = localStorage.getItem('admin-theme') || 'dark';
            if (savedTheme === 'light') {
                document.documentElement.classList.add('lm');
                document.body && document.body.classList.add('lm');
            } else {
                document.documentElement.classList.remove('lm');
                document.body && document.body.classList.remove('lm');
            }
        })();

        document.addEventListener('DOMContentLoaded', function() {
            const shell = document.getElementById('app-shell');
            const htmlEl = document.documentElement;
            const bodyEl = document.body;
            const themeToggleBtn = document.getElementById('theme-toggle');
            const themeToggleIcon = document.getElementById('theme-toggle-icon');
            const themeToggleText = document.getElementById('theme-toggle-text');

            function applyTheme(theme) {
                if (theme === 'light') {
                    htmlEl.classList.add('lm');
                    bodyEl.classList.add('lm');
                    if (shell) shell.classList.add('lm');
                    if (themeToggleIcon) themeToggleIcon.className = 'ti ti-moon';
                    if (themeToggleText) themeToggleText.textContent = 'داكن';
                } else {
                    htmlEl.classList.remove('lm');
                    bodyEl.classList.remove('lm');
                    if (shell) shell.classList.remove('lm');
                    if (themeToggleIcon) themeToggleIcon.className = 'ti ti-sun';
                    if (themeToggleText) themeToggleText.textContent = 'فاتح';
                }
            }

            // Sync with current state
            const currentTheme = localStorage.getItem('admin-theme') || 'dark';
            applyTheme(currentTheme);

            if (themeToggleBtn) {
                themeToggleBtn.addEventListener('click', function() {
                    const isLight = htmlEl.classList.contains('lm');
                    const nextTheme = isLight ? 'dark' : 'light';
                    localStorage.setItem('admin-theme', nextTheme);
                    applyTheme(nextTheme);
                });
            }

            // Mobile Hamburger
            const mobileMenuBtn = document.getElementById('mobileMenuBtn');
            const sidebarMenu = document.getElementById('sidebarMenu');
            const sidebarOverlay = document.getElementById('sidebarOverlay');

            if (mobileMenuBtn && sidebarMenu && sidebarOverlay) {
                mobileMenuBtn.addEventListener('click', function() {
                    sidebarMenu.classList.add('show');
                    sidebarOverlay.classList.add('show');
                });

                sidebarOverlay.addEventListener('click', function() {
                    sidebarMenu.classList.remove('show');
                    sidebarOverlay.classList.remove('show');
                });
            }
        });
    </script>
</body>
</html>