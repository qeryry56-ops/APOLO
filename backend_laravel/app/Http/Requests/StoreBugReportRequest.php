<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Validator;

class StoreBugReportRequest extends FormRequest
{
    private ?string $deviceMetaDecodeError = null;
    private ?string $diagnosticsDecodeError = null;

    public function authorize(): bool
    {
        if ((bool) config('support.allow_guests', true)) {
            return true;
        }

        return $this->user('sanctum') !== null;
    }

    protected function prepareForValidation(): void
    {
        $normalized = [];

        if ($this->has('description') && is_string($this->input('description'))) {
            $normalized['description'] = trim($this->input('description'));
        }

        if ($this->has('include_logs')) {
            $rawInclude = $this->input('include_logs');
            if (is_string($rawInclude)) {
                $parsed = filter_var($rawInclude, FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE);
                if ($parsed !== null) {
                    $normalized['include_logs'] = $parsed;
                }
            }
        }

        if ($this->has('platform') && is_string($this->input('platform'))) {
            $normalized['platform'] = strtolower(trim($this->input('platform')));
        }

        if ($this->has('route_name') && is_string($this->input('route_name'))) {
            $normalized['route_name'] = trim($this->input('route_name'));
        }

        if ($this->has('app_version') && is_string($this->input('app_version'))) {
            $normalized['app_version'] = trim($this->input('app_version'));
        }

        if ($this->has('locale') && is_string($this->input('locale'))) {
            $normalized['locale'] = trim($this->input('locale'));
        }

        // Decode JSON strings when submitted via multipart/form-data.
        if (is_string($this->input('device_meta'))) {
            $rawMeta = trim($this->input('device_meta'));
            if ($rawMeta === '') {
                $normalized['device_meta'] = null;
            } elseif (strlen($rawMeta) > (int) config('support.max_device_meta_bytes', 16384)) {
                $this->deviceMetaDecodeError = 'The device_meta payload exceeds the maximum allowed size.';
                $normalized['device_meta'] = null;
            } else {
                $decoded = json_decode($rawMeta, true);
                if (json_last_error() !== JSON_ERROR_NONE || !is_array($decoded)) {
                    $this->deviceMetaDecodeError = 'The device_meta field must contain valid JSON.';
                    $normalized['device_meta'] = null;
                } else {
                    $normalized['device_meta'] = $decoded;
                }
            }
        }

        if (is_string($this->input('diagnostics_logs'))) {
            $rawLogs = trim($this->input('diagnostics_logs'));
            if ($rawLogs === '') {
                $normalized['diagnostics_logs'] = null;
            } elseif (strlen($rawLogs) > (int) config('support.max_diagnostics_bytes', 131072)) {
                $this->diagnosticsDecodeError = 'The diagnostics_logs payload exceeds the maximum allowed size.';
                $normalized['diagnostics_logs'] = null;
            } else {
                $decoded = json_decode($rawLogs, true);
                if (json_last_error() !== JSON_ERROR_NONE || !is_array($decoded)) {
                    $this->diagnosticsDecodeError = 'The diagnostics_logs field must contain valid JSON.';
                    $normalized['diagnostics_logs'] = null;
                } else {
                    $normalized['diagnostics_logs'] = $decoded;
                }
            }
        }

        if ($normalized !== []) {
            $this->merge($normalized);
        }
    }

    public function rules(): array
    {
        $maxKb = (int) config('support.max_screenshot_kb', 5120);

        return [
            'description' => ['required', 'string', 'min:5', 'max:2000'],
            'include_logs' => ['required', 'boolean'],
            'screenshot' => [
                'nullable',
                'file',
                'image',
                'mimes:jpeg,jpg,png,webp',
                'mimetypes:image/jpeg,image/png,image/webp',
                "max:{$maxKb}",
                'dimensions:max_width=6000,max_height=6000',
            ],
            'app_version' => ['nullable', 'string', 'max:64'],
            'platform' => ['nullable', 'string', 'in:ios,android,web,macos,windows,linux,unknown'],
            'locale' => ['nullable', 'string', 'max:16', 'regex:/^[a-zA-Z]{2,3}([_-][a-zA-Z0-9]{2,8})*$/'],
            'route_name' => ['nullable', 'string', 'max:191'],
            'device_meta' => ['nullable', 'array', 'max:40'],
            'diagnostics_logs' => ['nullable', 'array'],
        ];
    }

    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator) {
            if ($this->deviceMetaDecodeError !== null) {
                $validator->errors()->add('device_meta', $this->deviceMetaDecodeError);
            }
            if ($this->diagnosticsDecodeError !== null) {
                $validator->errors()->add('diagnostics_logs', $this->diagnosticsDecodeError);
            }
        });
    }
}
