<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class BugReport extends Model
{
    use HasFactory;

    public const STATUS_OPEN = 'open';
    public const STATUS_IN_REVIEW = 'in_review';
    public const STATUS_RESOLVED = 'resolved';
    public const STATUS_CLOSED = 'closed';

    public const STATUSES = [
        self::STATUS_OPEN,
        self::STATUS_IN_REVIEW,
        self::STATUS_RESOLVED,
        self::STATUS_CLOSED,
    ];

    protected $fillable = [
        'user_id',
        'status',
        'description',
        'include_logs',
        'screenshot_path',
        'app_version',
        'platform',
        'locale',
        'route_name',
        'device_meta',
        'diagnostics_logs',
    ];

    protected $hidden = [
        'screenshot_path',
    ];

    protected $casts = [
        'user_id' => 'integer',
        'include_logs' => 'boolean',
        'device_meta' => 'array',
        'diagnostics_logs' => 'array',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
