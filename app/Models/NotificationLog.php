<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class NotificationLog extends Model
{
    protected $fillable = [
        'title',
        'title_en',
        'title_fr',
        'title_nl',
        'body',
        'body_en',
        'body_fr',
        'body_nl',
        'target',
        'total_recipients',
        'success_count',
        'data',
    ];

    protected $casts = [
        'data' => 'array',
    ];

    public static function createWithTranslation(array $attributes)
    {
        if (!isset($attributes['title_en']) && isset($attributes['title'])) {
            $aiService = new \App\Services\AiService();
            $translated = $aiService->translateToFill($attributes['title'], $attributes['body'] ?? '');
            
            $attributes['title_en'] = $translated['title']['en'] ?? null;
            $attributes['title_fr'] = $translated['title']['fr'] ?? null;
            $attributes['title_nl'] = $translated['title']['nl'] ?? null;
            
            $attributes['body_en'] = $translated['description']['en'] ?? null;
            $attributes['body_fr'] = $translated['description']['fr'] ?? null;
            $attributes['body_nl'] = $translated['description']['nl'] ?? null;
        }

        return static::create($attributes);
    }
}
