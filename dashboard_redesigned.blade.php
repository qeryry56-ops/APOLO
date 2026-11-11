@extends('admin.layouts.admin')

@section('title', 'مركز العمليات والإحصائيات')

@section('content')
<style>
    /* =========================================================
       PAGE TYPOGRAPHY & CRAFT STYLES
       ========================================================= */
    .dashboard-header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        margin-bottom: 24px;
        flex-wrap: wrap;
        gap: 16px;
    }
    .dashboard-title-group h1 {
        font-size: 20px;
        font-weight: 500;
        color: var(--txt-primary);
        margin: 0;
        letter-spacing: -0.3px;
        line-height: 1.2;
    }
    .dashboard-title-group p {
        font-size: 13px;
        color: var(--txt-muted);
        margin: 4px 0 0 0;
    }

    .btn-action-primary {
        background-color: var(--acc);
        color: #ffffff;
        border: 1px solid transparent;
        padding: 8px 16px;
        border-radius: var(--r-item);
        font-size: 13px;
        font-weight: 500;
        display: inline-flex;
        align-items: center;
        gap: 8px;
        text-decoration: none;
        transition: opacity var(--dur-fast) var(--ease);
    }
    .btn-action-primary:hover {
        opacity: 0.9;
        color: #ffffff;
    }

    .btn-action-secondary {
        background-color: var(--bg-card);
        color: var(--txt-primary);
        border: 1px solid var(--bdr);
        padding: 8px 14px;
        border-radius: var(--r-item);
        font-size: 13px;
        display: inline-flex;
        align-items: center;
        gap: 8px;
        text-decoration: none;
        transition: background var(--dur-fast) var(--ease), border-color var(--dur-fast) var(--ease);
    }
    .btn-action-secondary:hover {
        background-color: var(--bg-raised);
        border-color: var(--bdr-strong);
        color: var(--txt-primary);
    }

    /* Core Card System */
    .craft-card {
        background-color: var(--bg-card);
        border: 1px solid var(--bdr);
        border-radius: var(--r-card);
        padding: 20px;
        display: flex;
        flex-direction: column;
        transition: border-color var(--dur-fast) var(--ease);
    }
    .craft-card:hover {
        border-color: var(--bdr-strong);
    }

    /* Section 1: Hero Metric Cards */
    .metrics-grid {
        display: grid;
        grid-template-columns: repeat(4, 1fr);
        gap: 16px;
        margin-bottom: 20px;
    }
    .metric-card-top {
        display: flex;
        align-items: center;
        justify-content: space-between;
        margin-bottom: 12px;
    }
    .metric-label {
        font-size: 12px;
        font-weight: 500;
        color: var(--txt-muted);
        display: flex;
        align-items: center;
        gap: 6px;
    }
    .metric-tag {
        font-size: 11px;
        padding: 2px 6px;
        border-radius: var(--r-tag);
        background-color: var(--bg-raised);
        color: var(--txt-secondary);
        border: 1px solid var(--bdr);
        font-weight: 400;
    }
    .metric-tag-alert {
        background-color: var(--warning-subtle);
        color: var(--warning);
        border-color: rgba(245, 158, 11, 0.2);
    }
    .metric-num {
        font-size: 28px;
        font-weight: 500;
        color: var(--txt-primary);
        line-height: 1.1;
        letter-spacing: -0.5px;
        margin-bottom: 8px;
    }
    .metric-sub {
        font-size: 12px;
        color: var(--txt-muted);
        display: flex;
        align-items: center;
        gap: 6px;
    }

    /* Section 2: Quiet Telemetry Strip */
    .telemetry-strip {
        background-color: var(--bg-card);
        border: 1px solid var(--bdr);
        border-radius: var(--r-item);
        padding: 12px 16px;
        margin-bottom: 24px;
        display: flex;
        align-items: center;
        gap: 8px;
        overflow-x: auto;
        white-space: nowrap;
    }
    .telemetry-item {
        display: inline-flex;
        align-items: center;
        gap: 8px;
        padding: 6px 12px;
        border-radius: var(--r-tag);
        background-color: var(--bg-raised);
        color: var(--txt-secondary);
        font-size: 12px;
        text-decoration: none;
        border: 1px solid transparent;
        transition: all var(--dur-fast) var(--ease);
    }
    .telemetry-item:hover {
        background-color: var(--bg-hover);
        color: var(--txt-primary);
        border-color: var(--bdr);
    }
    .telemetry-item.alert-active {
        border-color: rgba(229, 72, 77, 0.3);
        background-color: var(--danger-subtle);
        color: var(--danger);
    }
    .telemetry-count {
        font-family: 'JetBrains Mono', monospace;
        font-size: 11px;
        font-weight: 500;
        background-color: var(--bg-card);
        padding: 1px 6px;
        border-radius: 3px;
        border: 1px solid var(--bdr);
        color: var(--txt-primary);
    }
    .telemetry-item.alert-active .telemetry-count {
        background-color: rgba(229, 72, 77, 0.15);
        border-color: rgba(229, 72, 77, 0.3);
        color: var(--danger);
    }

    /* Section 3: Data & Visualization Grid (8 cols / 4 cols) */
    .data-grid {
        display: grid;
        grid-template-columns: 2fr 1fr;
        gap: 20px;
        margin-bottom: 24px;
    }
    .card-header-clean {
        display: flex;
        align-items: center;
        justify-content: space-between;
        margin-bottom: 20px;
        padding-bottom: 12px;
        border-bottom: 1px solid var(--bdr);
    }
    .card-header-title {
        font-size: 14px;
        font-weight: 500;
        color: var(--txt-primary);
        display: flex;
        align-items: center;
        gap: 8px;
    }
    .card-header-meta {
        font-size: 12px;
        color: var(--txt-muted);
    }

    /* Dual Chart Tabs */
    .chart-toggle-group {
        display: flex;
        background-color: var(--bg-raised);
        border-radius: var(--r-tag);
        padding: 2px;
        border: 1px solid var(--bdr);
    }
    .chart-toggle-btn {
        background: transparent;
        border: none;
        padding: 4px 10px;
        border-radius: 3px;
        font-size: 11px;
        color: var(--txt-secondary);
        cursor: pointer;
        transition: all var(--dur-fast) var(--ease);
    }
    .chart-toggle-btn.active {
        background-color: var(--bg-card);
        color: var(--txt-primary);
        font-weight: 500;
    }

    /* Bar Chart Bars */
    .bar-col {
        display: flex;
        flex-direction: column;
        align-items: center;
        flex: 1;
        height: 100%;
        position: relative;
    }
    .bar-track {
        flex-grow: 1;
        width: 100%;
        display: flex;
        align-items: flex-end;
        justify-content: center;
        padding: 0 6px;
    }
    .bar-fill {
        width: 100%;
        max-width: 28px;
        background-color: var(--txt-muted);
        border-radius: 4px 4px 0 0;
        opacity: 0.6;
        transition: opacity var(--dur-fast) var(--ease), background-color var(--dur-fast) var(--ease);
    }
    .bar-col:hover .bar-fill {
        opacity: 1;
        background-color: var(--acc);
    }
    .bar-label {
        font-size: 11px;
        color: var(--txt-muted);
        margin-top: 8px;
    }

    /* Donut chart legend */
    .donut-legend-item {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 6px 0;
        border-bottom: 1px solid var(--bdr);
        font-size: 12px;
    }
    .donut-legend-item:last-child {
        border-bottom: none;
    }
    .donut-color-dot {
        width: 8px;
        height: 8px;
        border-radius: 2px;
        display: inline-block;
    }

    /* Section 4: Operational Tables (1fr 1fr) */
    .tables-grid {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 20px;
        margin-bottom: 24px;
    }

    .clean-table {
        width: 100%;
        border-collapse: collapse;
    }
    .clean-table th {
        font-size: 11px;
        font-weight: 500;
        color: var(--txt-muted);
        text-align: right;
        padding: 10px 8px;
        border-bottom: 1px solid var(--bdr);
        text-transform: uppercase;
        letter-spacing: 0.2px;
    }
    .clean-table td {
        font-size: 12px;
        color: var(--txt-secondary);
        padding: 12px 8px;
        border-bottom: 1px solid var(--bdr);
        vertical-align: middle;
    }
    .clean-table tr:last-child td {
        border-bottom: none;
    }
    .clean-table tr:hover td {
        background-color: var(--bg-raised);
    }

    /* Pending Ads Row */
    .pending-row {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 12px 0;
        border-bottom: 1px solid var(--bdr);
        gap: 12px;
    }
    .pending-row:last-child {
        border-bottom: none;
        padding-bottom: 0;
    }
    .pending-row:first-child {
        padding-top: 0;
    }
    .pending-meta {
        font-size: 11px;
        color: var(--txt-muted);
        display: flex;
        align-items: center;
        gap: 8px;
        margin-top: 3px;
    }

    .btn-approve {
        background-color: var(--success-subtle);
        color: var(--success);
        border: 1px solid rgba(76, 195, 138, 0.2);
        padding: 5px 12px;
        border-radius: var(--r-tag);
        font-size: 12px;
        font-weight: 500;
        cursor: pointer;
        transition: all var(--dur-fast) var(--ease);
    }
    .btn-approve:hover {
        background-color: var(--success);
        color: #ffffff;
    }

    .btn-block-action {
        background-color: var(--danger-subtle);
        color: var(--danger);
        border: 1px solid rgba(229, 72, 77, 0.2);
        padding: 5px 12px;
        border-radius: var(--r-tag);
        font-size: 12px;
        font-weight: 500;
        cursor: pointer;
        transition: all var(--dur-fast) var(--ease);
    }
    .btn-block-action:hover {
        background-color: var(--danger);
        color: #ffffff;
    }

    /* Referral Sources Bar */
    .referral-bar-container {
        display: flex;
        flex-direction: column;
        gap: 12px;
    }
    .referral-row {
        display: flex;
        flex-direction: column;
        gap: 4px;
    }
    .referral-row-top {
        display: flex;
        align-items: center;
        justify-content: space-between;
        font-size: 12px;
    }
    .referral-track {
        height: 6px;
        background-color: var(--bg-raised);
        border-radius: 3px;
        overflow: hidden;
    }
    .referral-progress {
        height: 100%;
        background-color: var(--txt-muted);
        border-radius: 3px;
        transition: width var(--dur-fast) var(--ease);
    }

    /* Responsive */
    @media (max-width: 1200px) {
        .metrics-grid { grid-template-columns: repeat(2, 1fr); }
        .data-grid { grid-template-columns: 1fr; }
        .tables-grid { grid-template-columns: 1fr; }
    }
    @media (max-width: 640px) {
        .metrics-grid { grid-template-columns: 1fr; }
    }
</style>

<!-- DASHBOARD HEADER -->
<div class="dashboard-header">
    <div class="dashboard-title-group">
        <h1>مركز العمليات والإحصائيات</h1>
        <p>نظرة مباشرة وفورية على المعاملات، الإعلانات، ومؤشرات نشاط منصة Apolo.ma</p>
    </div>
    <div class="d-flex align-items-center gap-2">
        <a href="{{ route('admin.ads.pending') }}" class="btn-action-secondary">
            <i class="ti ti-checkup-list"></i>
            <span>مراجعة المعلق ({{ $stats['pending_ads'] }})</span>
        </a>
        <a href="{{ route('user.add_get') }}" target="_blank" class="btn-action-primary">
            <i class="ti ti-plus"></i>
            <span>إضافة إعلان جديد</span>
        </a>
    </div>
</div>

<!-- SECTION 1: 4 HERO METRIC CARDS -->
<div class="metrics-grid">
    <!-- Card 1: Active Ads -->
    <div class="craft-card">
        <div class="metric-card-top">
            <span class="metric-label">
                <i class="ti ti-speakerphone"></i>
                الإعلانات النشطة
            </span>
            <span class="metric-tag">السوق الحي</span>
        </div>
        <div class="metric-num mono-nums">{{ number_format($stats['active_ads']) }}</div>
        <div class="metric-sub">
            <span>إجمالي الإعلانات المسجلة:</span>
            <span class="mono-nums text-white">{{ number_format($stats['total_ads']) }}</span>
        </div>
    </div>

    <!-- Card 2: Active Users -->
    <div class="craft-card">
        <div class="metric-card-top">
            <span class="metric-label">
                <i class="ti ti-users"></i>
                المستخدمون النشطون
            </span>
            <span class="metric-tag">الحسابات المفعّلة</span>
        </div>
        <div class="metric-num mono-nums">{{ number_format($stats['active_users']) }}</div>
        <div class="metric-sub">
            <span>موقوفون للمراجعة:</span>
            <span class="mono-nums text-danger">{{ number_format($stats['blocked_users']) }}</span>
        </div>
    </div>

    <!-- Card 3: Pending Ads -->
    <div class="craft-card">
        <div class="metric-card-top">
            <span class="metric-label">
                <i class="ti ti-clock-hour-4"></i>
                قيد التدقيق والمراجعة
            </span>
            @if($stats['pending_ads'] > 0)
                <span class="metric-tag metric-tag-alert">يتطلب إجراء</span>
            @else
                <span class="metric-tag">مكتمل</span>
            @endif
        </div>
        <div class="metric-num mono-nums {{ $stats['pending_ads'] > 0 ? 'text-warning' : '' }}">
            {{ number_format($stats['pending_ads']) }}
        </div>
        <div class="metric-sub">
            <span>بلاغات مستخدمين معلقة:</span>
            <span class="mono-nums {{ $stats['pending_reports'] > 0 ? 'text-danger' : '' }}">{{ $stats['pending_reports'] }}</span>
        </div>
    </div>

    <!-- Card 4: Verified Revenue -->
    <div class="craft-card">
        <div class="metric-card-top">
            <span class="metric-label">
                <i class="ti ti-receipt-2"></i>
                إيرادات الشهر
            </span>
            <span class="metric-tag">معتمدة</span>
        </div>
        <div class="metric-num mono-nums">
            {{ number_format($stats['monthly_revenue'], 2) }} <span style="font-size: 14px; font-weight: 400; color: var(--txt-muted);">MAD</span>
        </div>
        <div class="metric-sub">
            <span>طلبات دفع معلقة:</span>
            @php
                $pendingPayCount = \App\Models\AdPayment::where('status', 'payment_submitted')->count();
            @endphp
            <span class="mono-nums {{ $pendingPayCount > 0 ? 'text-warning' : '' }}">{{ $pendingPayCount }} طلبات</span>
        </div>
    </div>
</div>

<!-- SECTION 2: QUIET TELEMETRY STRIP -->
<div class="telemetry-strip">
    <a href="{{ route('admin.ads.pending') }}" class="telemetry-item {{ $stats['pending_ads'] > 0 ? 'alert-active' : '' }}">
        <span>معلقة للمراجعة</span>
        <span class="telemetry-count">{{ $stats['pending_ads'] }}</span>
    </a>
    <a href="{{ route('admin.ads.index') }}" class="telemetry-item">
        <span>إعلانات نشطة</span>
        <span class="telemetry-count">{{ $stats['active_ads'] }}</span>
    </a>
    <a href="{{ route('admin.ads.index') }}" class="telemetry-item">
        <span>منتهية الصلاحية</span>
        <span class="telemetry-count">{{ $stats['expired_ads'] }}</span>
    </a>
    <a href="{{ route('admin.ads.index') }}" class="telemetry-item">
        <span>محظورة</span>
        <span class="telemetry-count">{{ $stats['blocked_ads'] }}</span>
    </a>
    <a href="{{ route('admin.ads.index') }}" class="telemetry-item">
        <span>محذوفة</span>
        <span class="telemetry-count">{{ $stats['deleted_ads'] }}</span>
    </a>
    <a href="{{ route('admin.stores') }}" class="telemetry-item">
        <span>المتاجر المسجلة</span>
        <span class="telemetry-count">{{ $stats['total_stores'] }}</span>
    </a>
    <a href="{{ route('admin.ads.reported') }}" class="telemetry-item {{ $stats['pending_reports'] > 0 ? 'alert-active' : '' }}">
        <span>بلاغات معلقة</span>
        <span class="telemetry-count">{{ $stats['pending_reports'] }}</span>
    </a>
    <a href="{{ route('admin.message') }}" class="telemetry-item {{ $stats['unread_messages'] > 0 ? 'alert-active' : '' }}">
        <span>رسائل واردة</span>
        <span class="telemetry-count">{{ $stats['unread_messages'] }}</span>
    </a>
    <a href="{{ route('admin.blog.index') }}" class="telemetry-item">
        <span>مقالات المدونة</span>
        <span class="telemetry-count">{{ $stats['blog_count'] }}</span>
    </a>
    <a href="{{ route('admin.users.blocked') }}" class="telemetry-item">
        <span>أعضاء موقوفون</span>
        <span class="telemetry-count">{{ $stats['blocked_users'] }}</span>
    </a>
</div>

<!-- SECTION 3: VISUAL MOMENT (HERO CHARTS & TELEMETRY BREAKDOWN) -->
<div class="data-grid">
    <!-- LEFT: Main Activity Timeline Chart (2/3 width) -->
    <div class="craft-card">
        <div class="card-header-clean">
            <div class="card-header-title">
                <i class="ti ti-chart-line text-muted"></i>
                <span>معدل النشاط والنمو</span>
            </div>
            <div class="chart-toggle-group">
                <button type="button" class="chart-toggle-btn active" id="btn-chart-users" onclick="switchChart('users')">المستخدمون الجدد (30 يوم)</button>
                <button type="button" class="chart-toggle-btn" id="btn-chart-ads" onclick="switchChart('ads')">الإعلانات (آخر 7 أيام)</button>
            </div>
        </div>

        <!-- VIEW A: 30-Day User Growth (Smooth SVG Area Chart) -->
        <div id="view-chart-users" style="display: block;">
            @php
                $monthlyData = [];
                for ($i = 29; $i >= 0; $i--) {
                    $dateStr = now()->subDays($i)->format('Y-m-d');
                    $monthlyData[$dateStr] = 0;
                }
                foreach ($monthlyUsers as $mu) {
                    if (isset($monthlyData[$mu->date])) {
                        $monthlyData[$mu->date] = $mu->count;
                    }
                }
                $maxMonthlyCount = max(array_values($monthlyData)) ?: 1;
                $points = [];
                $xStep = 600 / 29;
                $index = 0;
                foreach ($monthlyData as $date => $count) {
                    $x = $index * $xStep;
                    $y = 170 - (($count / $maxMonthlyCount) * 140);
                    $points[] = round($x, 1) . "," . round($y, 1);
                    $index++;
                }
                $pathLine = "M " . implode(" L ", $points);
                $pathArea = $pathLine . " L 600,180 L 0,180 Z";
            @endphp
            <div style="height: 190px; width: 100%; position: relative;">
                <svg viewBox="0 0 600 190" preserveAspectRatio="none" style="width: 100%; height: 100%; overflow: visible;">
                    <defs>
                        <linearGradient id="userGrad" x1="0" y1="0" x2="0" y2="1">
                            <stop offset="0%" stop-color="var(--acc)" stop-opacity="0.16"/>
                            <stop offset="100%" stop-color="var(--acc)" stop-opacity="0.0"/>
                        </linearGradient>
                    </defs>
                    <!-- Hairline Grid Lines -->
                    <line x1="0" y1="30" x2="600" y2="30" stroke="var(--bdr)" stroke-width="1" stroke-dasharray="3 3"/>
                    <line x1="0" y1="100" x2="600" y2="100" stroke="var(--bdr)" stroke-width="1" stroke-dasharray="3 3"/>
                    <line x1="0" y1="170" x2="600" y2="170" stroke="var(--bdr)" stroke-width="1"/>

                    <!-- Filled Area -->
                    <path d="{{ $pathArea }}" fill="url(#userGrad)"/>
                    <!-- Crisp Stroke Line -->
                    <path d="{{ $pathLine }}" fill="none" stroke="var(--acc)" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                </svg>
            </div>
            <div class="d-flex justify-content-between text-muted mt-2" style="font-size: 11px;">
                <span>قبل 30 يوم ({{ now()->subDays(29)->locale('ar')->translatedFormat('j M') }})</span>
                <span class="mono-nums">إجمالي المسجلين هذا الشهر: {{ array_sum($monthlyData) }} مستخدم</span>
                <span>اليوم ({{ now()->locale('ar')->translatedFormat('j M') }})</span>
            </div>
        </div>

        <!-- VIEW B: 7-Day Ads Volume (Bar Graph) -->
        <div id="view-chart-ads" style="display: none;">
            @php
                $daysMap = [
                    2 => ['label' => 'الاثنين', 'count' => 0],
                    3 => ['label' => 'الثلاثاء', 'count' => 0],
                    4 => ['label' => 'الأربعاء', 'count' => 0],
                    5 => ['label' => 'الخميس', 'count' => 0],
                    6 => ['label' => 'الجمعة', 'count' => 0],
                    7 => ['label' => 'السبت', 'count' => 0],
                    1 => ['label' => 'الأحد', 'count' => 0],
                ];
                foreach($weeklyAds as $ad) {
                    if(isset($daysMap[$ad->day])) {
                        $daysMap[$ad->day]['count'] = $ad->count;
                    }
                }
                $maxWeeklyCount = 0;
                foreach($daysMap as $d) {
                    if($d['count'] > $maxWeeklyCount) {
                        $maxWeeklyCount = $d['count'];
                    }
                }
                if($maxWeeklyCount == 0) $maxWeeklyCount = 1;
            @endphp
            <div class="d-flex align-items-end justify-content-between" style="height: 190px; padding-top: 10px;">
                @foreach([2, 3, 4, 5, 6, 7, 1] as $dayNum)
                    @php
                        $d = $daysMap[$dayNum];
                        $heightPercent = ($d['count'] / $maxWeeklyCount) * 85;
                    @endphp
                    <div class="bar-col">
                        <div class="bar-track">
                            <div class="bar-fill" 
                                 style="height: {{ max(4, $heightPercent) }}%;" 
                                 title="{{ $d['label'] }}: {{ $d['count'] }} إعلان"></div>
                        </div>
                        <div class="bar-label">{{ $d['label'] }}</div>
                        <div class="mono-nums text-muted" style="font-size: 10px; margin-top: 2px;">{{ $d['count'] }}</div>
                    </div>
                @endforeach
            </div>
        </div>
    </div>

    <!-- RIGHT: Ad Distribution Donut & Referral Sources (1/3 width) -->
    <div class="craft-card">
        <div class="card-header-clean">
            <div class="card-header-title">
                <i class="ti ti-chart-pie text-muted"></i>
                <span>توزيع حالات الإعلانات</span>
            </div>
            <span class="card-header-meta mono-nums">{{ number_format($stats['total_ads']) }} إعلان</span>
        </div>

        @php
            $statusCounts = [
                'نشطة' => $adStatusStats[1] ?? 0,
                'معلقة' => $adStatusStats[0] ?? 0,
                'منتهية' => $adStatusStats[2] ?? 0,
                'محظورة' => $adStatusStats[3] ?? 0,
                'محذوفة' => $stats['deleted_ads'] ?? 0,
            ];
            $totalPie = array_sum($statusCounts) ?: 1;
        @endphp

        <!-- SVG Donut Chart with Exact Segment Gaps -->
        <div class="d-flex align-items-center justify-content-center my-2" style="position: relative;">
            <svg viewBox="0 0 100 100" style="width: 120px; height: 120px; transform: rotate(-90deg);" id="donutChartSvg"></svg>
            <div class="d-flex flex-column align-items-center justify-content-center" style="position: absolute; text-align: center; pointer-events: none;">
                <span class="mono-nums text-white" style="font-size: 17px; font-weight: 500; line-height: 1;">{{ number_format($stats['active_ads']) }}</span>
                <span style="font-size: 10px; color: var(--txt-muted); margin-top: 2px;">نشط حالياً</span>
            </div>
        </div>

        <!-- Clean Status Legend -->
        <div class="d-flex flex-column mt-3">
            @php
                $legendColors = [
                    'نشطة' => 'var(--success)',
                    'معلقة' => 'var(--warning)',
                    'منتهية' => 'var(--txt-muted)',
                    'محظورة' => 'var(--danger)',
                    'محذوفة' => '#8b5cf6',
                ];
            @endphp
            @foreach($statusCounts as $label => $val)
                @php $pct = round(($val / $totalPie) * 100); @endphp
                <div class="donut-legend-item">
                    <div class="d-flex align-items-center gap-2">
                        <span class="donut-color-dot" style="background-color: {{ $legendColors[$label] }};"></span>
                        <span style="color: var(--txt-primary);">{{ $label }}</span>
                    </div>
                    <div class="d-flex align-items-center gap-2">
                        <span class="mono-nums" style="color: var(--txt-secondary);">{{ number_format($val) }}</span>
                        <span class="mono-nums text-muted" style="font-size: 11px;">({{ $pct }}%)</span>
                    </div>
                </div>
            @endforeach
        </div>
    </div>
</div>

<!-- SECTION 4: OPERATIONAL TABLES (1fr 1fr) -->
<div class="tables-grid">
    <!-- LEFT: Recent Users & Trust Telemetry -->
    <div class="craft-card">
        <div class="card-header-clean">
            <div class="card-header-title">
                <i class="ti ti-user-check text-muted"></i>
                <span>أحدث المستخدمين المسجلين</span>
            </div>
            <a href="{{ route('admin.users') }}" class="card-header-meta text-decoration-none">عرض الكل ←</a>
        </div>

        <div class="table-responsive">
            <table class="clean-table">
                <thead>
                    <tr>
                        <th>المستخدم</th>
                        <th>الهاتف</th>
                        <th>مستوى الثقة</th>
                        <th>الحالة</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($recentUsers as $user)
                        <tr>
                            <td>
                                <div class="d-flex align-items-center gap-2">
                                    <div class="d-flex align-items-center justify-content-center" 
                                         style="width: 28px; height: 28px; border-radius: 6px; background-color: var(--bg-raised); border: 1px solid var(--bdr); font-size: 11px; font-weight: 500; color: var(--txt-primary);">
                                        {{ mb_substr($user->name, 0, 1) }}
                                    </div>
                                    <div>
                                        <div style="font-size: 12px; font-weight: 500; color: var(--txt-primary); line-height: 1.2;">{{ $user->name }}</div>
                                        <div class="mono-nums" style="font-size: 10px; color: var(--txt-muted);">{{ $user->email }}</div>
                                    </div>
                                </div>
                            </td>
                            <td>
                                @if($user->phone)
                                    <span class="mono-nums" style="font-size: 11px; color: var(--txt-secondary);">{{ $user->phone_country_code ?? '+212' }} {{ $user->phone }}</span>
                                @else
                                    <span class="text-muted" style="font-size: 11px;">—</span>
                                @endif
                            </td>
                            <td>
                                <div class="d-flex align-items-center gap-2">
                                    <div style="width: 48px; height: 4px; background-color: var(--bg-raised); border-radius: 2px; overflow: hidden;">
                                        <div style="width: {{ $user->trust_score ?? 0 }}%; height: 100%; background-color: {{ ($user->trust_score ?? 0) >= 80 ? 'var(--success)' : (($user->trust_score ?? 0) >= 40 ? 'var(--warning)' : 'var(--danger)') }};"></div>
                                    </div>
                                    <span class="mono-nums" style="font-size: 10px; color: var(--txt-muted);">{{ $user->trust_score ?? 0 }}</span>
                                </div>
                            </td>
                            <td>
                                @if($user->status == 0)
                                    <span class="sidebar-badge sidebar-badge-red">موقوف</span>
                                @elseif(($user->trust_score ?? 0) < 40)
                                    <span class="sidebar-badge sidebar-badge-amber">مراجعة</span>
                                @else
                                    <span class="sidebar-badge" style="background-color: var(--success-subtle); color: var(--success);">نشط</span>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="4" class="text-center py-4 text-muted">لا يوجد مستخدمون جدد مسجلون حالياً</td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>

    <!-- RIGHT: Pending Ads Queue & Direct Actions -->
    <div class="craft-card">
        <div class="card-header-clean">
            <div class="card-header-title">
                <i class="ti ti-clock-pause text-muted"></i>
                <span>طابور الإعلانات المعلقة</span>
            </div>
            <a href="{{ route('admin.ads.pending') }}" class="card-header-meta text-decoration-none">
                {{ $stats['pending_ads'] }} إعلان ينتظر ←
            </a>
        </div>

        <div class="d-flex flex-column">
            @forelse($pendingAds as $ad)
                @php
                    $reason = 'حساب جديد';
                    if ($ad->user) {
                        $phone = $ad->user->phone;
                        $countryCode = $ad->user->phone_country_code;
                        if ($countryCode === '+86' || str_starts_with($phone ?? '', '86') || str_starts_with($phone ?? '', '+86')) {
                            $reason = 'رقم دولي مشبوه';
                        } elseif ($ad->user->trust_score < 50) {
                            $reason = 'ثقة الحساب منخفضة';
                        } else {
                            if (preg_match('/https?:\/\/[^\s]+/', $ad->description ?? '')) {
                                $reason = 'يتضمن روابط خارجية';
                            } else {
                                $reason = 'مراجعة خوارزمية';
                            }
                        }
                    }
                    $latestReport = $ad->reports->first();
                    if ($latestReport && $latestReport->message) {
                        $reason = \Illuminate\Support\Str::limit($latestReport->message, 25);
                    }

                    $categoryIcon = 'ti-box';
                    $catName = $ad->category ? $ad->category->name : '';
                    if (str_contains($catName, 'سيارات') || str_contains($catName, 'Auto')) $categoryIcon = 'ti-car';
                    elseif (str_contains($catName, 'عقار') || str_contains($catName, 'Immobilier')) $categoryIcon = 'ti-home';
                    elseif (str_contains($catName, 'هواتف') || str_contains($catName, 'Téléphones')) $categoryIcon = 'ti-device-mobile';
                    elseif (str_contains($catName, 'وظائف') || str_contains($catName, 'Emploi')) $categoryIcon = 'ti-briefcase';
                @endphp
                <div class="pending-row">
                    <div class="d-flex align-items-center gap-3" style="min-width: 0;">
                        <div class="d-flex align-items-center justify-content-center" 
                             style="width: 32px; height: 32px; border-radius: 6px; background-color: var(--bg-raised); border: 1px solid var(--bdr); flex-shrink: 0;">
                            <i class="ti {{ $categoryIcon }} text-muted"></i>
                        </div>
                        <div style="min-width: 0;">
                            <a href="{{ route('admin.ad_detail', $ad->id) }}" style="font-size: 13px; font-weight: 500; color: var(--txt-primary); text-decoration: none; display: block; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">
                                {{ \Illuminate\Support\Str::limit($ad->title, 42) }}
                            </a>
                            <div class="pending-meta">
                                <span>السبب: {{ $reason }}</span>
                                <span>•</span>
                                <span class="mono-nums text-muted">{{ $ad->created_at ? $ad->created_at->locale('ar')->diffForHumans() : '' }}</span>
                                @if($ad->reports->count() > 0)
                                    <span>•</span>
                                    <span class="text-danger mono-nums">{{ $ad->reports->count() }} بلاغ</span>
                                @endif
                            </div>
                        </div>
                    </div>
                    <div class="d-flex align-items-center gap-2 flex-shrink-0">
                        <form action="{{ route('admin.ads.accept', $ad->id) }}" method="POST" style="margin: 0;">
                            @csrf
                            <button type="submit" class="btn-approve" title="قبول الإعلان ونشره">قبول</button>
                        </form>
                        <form action="{{ route('admin.ads.block', $ad->id) }}" method="POST" style="margin: 0;">
                            @csrf
                            <button type="submit" class="btn-block-action" title="حظر الإعلان">حظر</button>
                        </form>
                    </div>
                </div>
            @empty
                <div class="text-center py-5 text-muted">
                    <i class="ti ti-circle-check fs-2 mb-2 d-block text-success"></i>
                    <span style="font-size: 13px;">طابور المراجعة فارغ — جميع الإعلانات مدققة ومحدثة.</span>
                </div>
            @endforelse
        </div>
    </div>
</div>

<!-- SECTION 5: REFERRAL SOURCES TELEMETRY -->
<div class="craft-card mb-4">
    <div class="card-header-clean">
        <div class="card-header-title">
            <i class="ti ti-share-2 text-muted"></i>
            <span>مصادر وصول المستخدمين للمنصة (Referral Telemetry)</span>
        </div>
        <span class="card-header-meta">توزيع القنوات</span>
    </div>

    <div class="row g-3">
        @php
            $totalReferrals = $referralStats->sum('count') ?: 1;
        @endphp
        @forelse($referralStats as $stat)
            @php
                $percent = round(($stat->count / $totalReferrals) * 100);
                $icon = 'ti-link';
                if ($stat->referral_source == 'facebook') $icon = 'ti-brand-facebook';
                elseif ($stat->referral_source == 'instagram') $icon = 'ti-brand-instagram';
                elseif ($stat->referral_source == 'tiktok') $icon = 'ti-brand-tiktok';
                elseif ($stat->referral_source == 'google') $icon = 'ti-brand-google';
                elseif ($stat->referral_source == 'friend') $icon = 'ti-users';
            @endphp
            <div class="col-md-4 col-sm-6">
                <div style="background-color: var(--bg-raised); border: 1px solid var(--bdr); border-radius: var(--r-item); padding: 14px;">
                    <div class="d-flex align-items-center justify-content-between mb-2">
                        <div class="d-flex align-items-center gap-2">
                            <i class="ti {{ $icon }} text-muted"></i>
                            <span style="font-size: 13px; font-weight: 500; color: var(--txt-primary);">{{ ucfirst($stat->referral_source) }}</span>
                        </div>
                        <span class="mono-nums text-muted" style="font-size: 11px;">{{ $percent }}%</span>
                    </div>
                    <div class="d-flex align-items-baseline justify-content-between">
                        <span class="mono-nums text-white" style="font-size: 20px; font-weight: 500;">{{ number_format($stat->count) }}</span>
                        <span style="font-size: 11px; color: var(--txt-muted);">مستخدم</span>
                    </div>
                    <div class="referral-track mt-2">
                        <div class="referral-progress" style="width: {{ $percent }}%; background-color: var(--acc);"></div>
                    </div>
                </div>
            </div>
        @empty
            <div class="col-12 text-center py-3 text-muted" style="font-size: 12px;">
                لا توجد بيانات مسجلة لمصادر الإحالة حالياً.
            </div>
        @endforelse
    </div>
</div>

<!-- SCRIPTS: DONUT CHART RENDERING & CHART TOGGLE -->
<script>
    function switchChart(type) {
        const usersChart = document.getElementById('view-chart-users');
        const adsChart = document.getElementById('view-chart-ads');
        const btnUsers = document.getElementById('btn-chart-users');
        const btnAds = document.getElementById('btn-chart-ads');

        if (type === 'users') {
            usersChart.style.display = 'block';
            adsChart.style.display = 'none';
            btnUsers.classList.add('active');
            btnAds.classList.remove('active');
        } else {
            usersChart.style.display = 'none';
            adsChart.style.display = 'block';
            btnAds.classList.add('active');
            btnUsers.classList.remove('active');
        }
    }

    document.addEventListener("DOMContentLoaded", function () {
        const data = @json($statusCounts);
        const total = Object.values(data).reduce((a, b) => a + b, 0);
        const svg = document.getElementById('donutChartSvg');
        if (!svg) return;

        const colors = {
            'نشطة': '#4cc38a',
            'معلقة': '#f59e0b',
            'منتهية': '#85858b',
            'محظورة': '#e5484d',
            'محذوفة': '#8b5cf6'
        };

        if (total === 0) {
            const circle = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
            circle.setAttribute('cx', '50');
            circle.setAttribute('cy', '50');
            circle.setAttribute('r', '38');
            circle.setAttribute('fill', 'transparent');
            circle.setAttribute('stroke', 'rgba(237,237,237,0.1)');
            circle.setAttribute('stroke-width', '10');
            svg.appendChild(circle);
            return;
        }

        let accumulated = 0;
        const r = 38;
        const circ = 2 * Math.PI * r;

        Object.entries(data).forEach(([key, val]) => {
            if (val === 0) return;

            const pct = val / total;
            const gapDeg = 2.0;
            const gapStroke = (gapDeg / 360) * circ;
            const strokeLen = (circ * pct) - gapStroke;
            const offset = circ * -accumulated;

            const circle = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
            circle.setAttribute('cx', '50');
            circle.setAttribute('cy', '50');
            circle.setAttribute('r', '38');
            circle.setAttribute('fill', 'transparent');
            circle.setAttribute('stroke', colors[key] || '#85858b');
            circle.setAttribute('stroke-width', '10');
            circle.setAttribute('stroke-dasharray', `${Math.max(1, strokeLen)} ${circ}`);
            circle.setAttribute('stroke-dashoffset', offset);
            circle.setAttribute('stroke-linecap', 'round');

            const title = document.createElementNS('http://www.w3.org/2000/svg', 'title');
            title.textContent = `${key}: ${val} (${Math.round(pct * 100)}%)`;
            circle.appendChild(title);

            svg.appendChild(circle);
            accumulated += pct;
        });
    });
</script>
@endsection