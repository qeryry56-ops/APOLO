<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>@yield('title', 'لوحة التحكم') — Apolo Control</title>
    <!-- Fonts: Tajawal + JetBrains Mono for telemetry -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500&family=Tajawal:wght@400;500;700&display=swap" rel="stylesheet">
    <!-- Bootstrap 5 CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Tabler Icons Webfont -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@latest/dist/tabler-icons.min.css">
    
    <style>
        /* =========================================================
           UNSLOP CRAFT TOKENS — GRAPHITE RAMP & QUIET CHROME
           ========================================================= */
        :root {
            /* Graphite Ramp (Dark Default) */
            --bg-deep: #0f0f10;
            --bg-page: #141415;
            --bg-card: #19191b;
            --bg-raised: #232325;
            --bg-hover: #2a2a2d;

            /* Hairline Borders */
            --bdr: rgba(237, 237, 237, 0.08);
            --bdr-strong: rgba(237, 237, 237, 0.14);

            /* Typography */
            --txt-primary: #ededed;
            --txt-secondary: #a1a1a6;
            --txt-muted: #85858b;

            /* Brand Accent & Semantics */
            --acc: #E31B23;
            --acc-subtle: rgba(227, 27, 35, 0.10);
            --success: #4cc38a;
            --success-subtle: rgba(76, 195, 138, 0.10);
            --warning: #f59e0b;
            --warning-subtle: rgba(245, 158, 11, 0.10);
            --danger: #e5484d;
            --danger-subtle: rgba(229, 72, 77, 0.10);
            --info: #3b82f6;
            --info-subtle: rgba(59, 130, 246, 0.10);

            /* Radii (Nested scale: panel 16, card 12, item 8, pill 4) */
            --r-card: 12px;
            --r-item: 8px;
            --r-tag: 5px;

            /* Transitions */
            --ease: cubic-bezier(0.22, 1, 0.36, 1);
            --dur-fast: 150ms;
        }

        /* Light Mode Ramp */
        .lm {
            --bg-deep: #ffffff;
            --bg-page: #f8fafc;
            --bg-card: #ffffff;
            --bg-raised: #f1f5f9;
            --bg-hover: #e2e8f0;

            --bdr: rgba(15, 23, 42, 0.08);
            --bdr-strong: rgba(15, 23, 42, 0.14);

            --txt-primary: #0f172a;
            --txt-secondary: #475569;
            --txt-muted: #64748b;

            --acc: #E31B23;
            --acc-subtle: rgba(227, 27, 35, 0.08);
            --success: #16a34a;
            --success-subtle: rgba(22, 163, 74, 0.08);
            --warning: #d97706;
            --warning-subtle: rgba(217, 119, 6, 0.08);
            --danger: #dc2626;
            --danger-subtle: rgba(220, 38, 38, 0.08);
            --info: #2563eb;
            --info-subtle: rgba(37, 99, 235, 0.08);
        }

        /* Reset & Base Typography */
        *, *::before, *::after {
            box-sizing: border-box;
            box-shadow: none !important;
            text-shadow: none !important;
        }

        body {
            font-family: 'Tajawal', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            background-color: var(--bg-page);
            color: var(--txt-primary);
            margin: 0;
            padding: 0;
            font-weight: 400;
            line-height: 1.5;
            -webkit-font-smoothing: antialiased;
        }

        .mono-nums {
            font-family: 'JetBrains Mono', ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
            font-variant-numeric: tabular-nums;
        }

        /* Grid Shell */
        .app-shell {
            display: grid;
            grid-template-columns: 256px 1fr;
            min-height: 100vh;
            background-color: var(--bg-page);
        }

        /* Sidebar: 256px, quiet deep surface, hairline border */
        .sidebar-wrapper {
            background-color: var(--bg-deep);
            border-left: 1px solid var(--bdr);
            height: 100vh;
            position: sticky;
            top: 0;
            z-index: 1000;
            display: flex;
            flex-direction: column;
            overflow-y: auto;
        }

        .sidebar-header {
            padding: 16px 20px;
            display: flex;
            align-items: center;
            gap: 12px;
            border-bottom: 1px solid var(--bdr);
            min-height: 60px;
        }

        .sidebar-brand-mark {
            width: 32px;
            height: 32px;
            border-radius: 8px;
            background-color: var(--acc);
            color: #ffffff;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 700;
            font-size: 14px;
            letter-spacing: -0.5px;
            flex-shrink: 0;
        }

        .sidebar-brand-text {
            display: flex;
            flex-direction: column;
        }

        .sidebar-brand-name {
            font-size: 15px;
            font-weight: 500;
            color: var(--txt-primary);
            line-height: 1.2;
            letter-spacing: -0.2px;
        }

        .sidebar-brand-sub {
            font-size: 11px;
            color: var(--txt-muted);
            margin-top: 1px;
        }

        .sidebar-nav-container {
            display: flex;
            flex-direction: column;
            padding: 16px 12px;
            flex-grow: 1;
            gap: 2px;
        }

        .sidebar-section-title {
            font-size: 11px;
            font-weight: 500;
            color: var(--txt-muted);
            margin: 20px 10px 6px 10px;
            text-transform: uppercase;
            letter-spacing: 0.4px;
        }
        .sidebar-section-title:first-child {
            margin-top: 4px;
        }

        .sidebar-nav-link {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 8px 12px;
            color: var(--txt-secondary);
            text-decoration: none;
            border-radius: var(--r-item);
            font-size: 13px;
            font-weight: 400;
            height: 36px;
            transition: background var(--dur-fast) var(--ease), color var(--dur-fast) var(--ease);
        }

        .sidebar-nav-link:hover {
            background-color: var(--bg-raised);
            color: var(--txt-primary);
        }

        .sidebar-nav-link.active {
            background-color: var(--bg-raised);
            color: var(--txt-primary);
            font-weight: 500;
            border: 1px solid var(--bdr-strong);
        }

        .sidebar-nav-link .link-content {
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .sidebar-nav-link i {
            font-size: 17px;
            color: var(--txt-muted);
            transition: color var(--dur-fast) var(--ease);
        }
        .sidebar-nav-link:hover i,
        .sidebar-nav-link.active i {
            color: var(--txt-primary);
        }
        .sidebar-nav-link.active i {
            color: var(--acc);
        }

        /* Sidebar Badges (Quiet Monospace Counts) */
        .sidebar-badge {
            font-family: 'JetBrains Mono', monospace;
            font-size: 10px;
            padding: 2px 7px;
            border-radius: var(--r-tag);
            border: 1px solid transparent;
            line-height: 1;
            font-weight: 500;
        }
        .sidebar-badge-amber {
            background-color: var(--warning-subtle);
            color: var(--warning);
            border-color: rgba(245, 158, 11, 0.2);
        }
        .sidebar-badge-red {
            background-color: var(--danger-subtle);
            color: var(--danger);
            border-color: rgba(229, 72, 77, 0.2);
        }
        .sidebar-badge-blue {
            background-color: var(--info-subtle);
            color: var(--info);
            border-color: rgba(59, 130, 246, 0.2);
        }

        /* Main Content Wrapper */
        .main-wrapper {
            display: flex;
            flex-direction: column;
            min-height: 100vh;
            overflow-x: hidden;
            background-color: var(--bg-page);
        }

        /* Topbar: 56px, Quiet Hairline */
        .topbar-wrapper {
            height: 56px;
            background-color: var(--bg-deep);
            border-bottom: 1px solid var(--bdr);
            position: sticky;
            top: 0;
            z-index: 900;
            display: flex;
            align-items: center;
            padding: 0 24px;
        }

        .topbar-actions {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .topbar-btn {
            background: transparent;
            border: 1px solid transparent;
            color: var(--txt-secondary);
            padding: 6px 10px;
            border-radius: var(--r-item);
            display: inline-flex;
            align-items: center;
            gap: 6px;
            text-decoration: none;
            transition: all var(--dur-fast) var(--ease);
            font-size: 12px;
            cursor: pointer;
        }
        .topbar-btn:hover {
            background-color: var(--bg-raised);
            color: var(--txt-primary);
            border-color: var(--bdr);
        }
        .topbar-btn i {
            font-size: 16px;
        }

        .topbar-status-dot {
            width: 7px;
            height: 7px;
            border-radius: 50%;
            background-color: var(--success);
            display: inline-block;
        }

        .user-avatar-initials {
            width: 32px;
            height: 32px;
            border-radius: 8px;
            background-color: var(--bg-raised);
            border: 1px solid var(--bdr-strong);
            color: var(--txt-primary);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 12px;
            font-weight: 500;
        }

        /* Page Content Area */
        .page-content {
            padding: 24px 28px;
            flex-grow: 1;
            max-width: 1520px;
            width: 100%;
            margin: 0 auto;
        }

        /* Custom Scrollbar */
        ::-webkit-scrollbar {
            width: 6px;
            height: 6px;
        }
        ::-webkit-scrollbar-track {
            background: var(--bg-page);
        }
        ::-webkit-scrollbar-thumb {
            background: var(--bg-raised);
            border-radius: 3px;
        }
        ::-webkit-scrollbar-thumb:hover {
            background: var(--bg-hover);
        }

        /* Mobile Offcanvas Sidebar */
        @media (max-width: 991.98px) {
            .app-shell {
                grid-template-columns: 1fr;
            }
            .sidebar-wrapper {
                position: fixed !important;
                top: 0;
                right: -260px;
                width: 260px !important;
                height: 100vh !important;
                transition: transform 0.25s var(--ease);
                z-index: 1050;
            }
            .sidebar-wrapper.show {
                transform: translateX(-260px);
            }
            .sidebar-overlay {
                display: none;
                position: fixed;
                top: 0;
                left: 0;
                width: 100vw;
                height: 100vh;
                background: rgba(0, 0, 0, 0.6);
                backdrop-filter: blur(2px);
                z-index: 1040;
            }
            .sidebar-overlay.show {
                display: block;
            }
            .page-content {
                padding: 16px;
            }
            .topbar-wrapper {
                padding: 0 16px;
            }
        }
    </style>
</head>
<body>

    <!-- Mobile Sidebar Overlay -->
    <div class="sidebar-overlay" id="sidebarOverlay"></div>

    <div class="app-shell" id="app-shell">
        
        <!-- Sidebar Navigation (256px) -->
        <aside class="sidebar-wrapper" id="sidebarMenu">
            <!-- Brand Mark -->
            <div class="sidebar-header">
                <div class="sidebar-brand-mark">A</div>
                <div class="sidebar-brand-text">
                    <span class="sidebar-brand-name">Apolo Control</span>
                    <span class="sidebar-brand-sub">إدارة العمليات والمنصة</span>
                </div>
            </div>

            <!-- Navigation Sections -->
            <div class="sidebar-nav-container">
                
                <span class="sidebar-section-title">نظرة عامة</span>
                <a href="{{ route('admin.dashboard') }}" class="sidebar-nav-link {{ Route::is('admin.dashboard') || Route::is('admin.index') ? 'active' : '' }}">
                    <div class="link-content">
                        <i class="ti ti-layout-dashboard"></i>
                        <span>الإحصائيات والعمليات</span>
                    </div>
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
            
            <!-- Topbar (56px) -->
            <header class="topbar-wrapper d-flex align-items-center justify-content-between">
                
                <!-- Right Side (RTL Start) -->
                <div class="d-flex align-items-center gap-3">
                    <!-- Mobile Hamburger -->
                    <button class="topbar-btn d-lg-none" id="mobileMenuBtn" type="button" aria-label="القائمة">
                        <i class="ti ti-menu-2"></i>
                    </button>
                    <!-- System Telemetry Status -->
                    <div class="d-flex align-items-center gap-2" style="font-size: 13px; color: var(--txt-secondary);">
                        <span class="topbar-status-dot"></span>
                        <span class="d-none d-sm-inline">الخادم متصل ومستقر</span>
                        <span class="text-muted d-none d-md-inline" style="font-size: 11px;">• v2.4</span>
                    </div>
                </div>

                <!-- Left Side (RTL End) -->
                <div class="topbar-actions">
                    <!-- Date Context -->
                    <div class="d-none d-md-flex align-items-center px-3 py-1 rounded" style="background-color: var(--bg-raised); border: 1px solid var(--bdr); font-size: 11px; color: var(--txt-muted);">
                        <i class="ti ti-calendar me-1"></i>
                        {{ Carbon\Carbon::now()->locale('ar')->translatedFormat('l j F Y') }}
                    </div>

                    <!-- Theme Toggle -->
                    <button class="topbar-btn" id="theme-toggle" title="تبديل المظهر">
                        <i class="ti ti-sun" id="theme-toggle-icon"></i>
                        <span id="theme-toggle-text" class="d-none d-sm-inline">فاتح</span>
                    </button>

                    <!-- View Live Site -->
                    <a href="{{ route('home.ads.index') }}" target="_blank" class="topbar-btn" title="معاينة الموقع">
                        <i class="ti ti-external-link"></i>
                        <span class="d-none d-sm-inline">الموقع</span>
                    </a>

                    <!-- Security Audit Alerts -->
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
                            <span style="font-size: 13px; font-weight: 500; color: var(--txt-primary);">{{ auth()->user()->name }}</span>
                            <span style="font-size: 10px; color: var(--txt-muted);">مدير النظام</span>
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
        document.addEventListener('DOMContentLoaded', function() {
            const shell = document.getElementById('app-shell');
            const themeToggleBtn = document.getElementById('theme-toggle');
            const themeToggleIcon = document.getElementById('theme-toggle-icon');
            const themeToggleText = document.getElementById('theme-toggle-text');

            const savedTheme = localStorage.getItem('admin-theme') || 'dark';
            if (savedTheme === 'light') {
                shell.classList.add('lm');
                themeToggleIcon.className = 'ti ti-moon';
                themeToggleText.textContent = 'داكن';
            } else {
                shell.classList.remove('lm');
                themeToggleIcon.className = 'ti ti-sun';
                themeToggleText.textContent = 'فاتح';
            }

            themeToggleBtn.addEventListener('click', function() {
                if (shell.classList.contains('lm')) {
                    shell.classList.remove('lm');
                    localStorage.setItem('admin-theme', 'dark');
                    themeToggleIcon.className = 'ti ti-sun';
                    themeToggleText.textContent = 'فاتح';
                } else {
                    shell.classList.add('lm');
                    localStorage.setItem('admin-theme', 'light');
                    themeToggleIcon.className = 'ti ti-moon';
                    themeToggleText.textContent = 'داكن';
                }
            });

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