<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Notification extends Model
{
    protected $fillable = [
        'user_id',
        'role',
        'title',
        'title_en',
        'title_fr',
        'title_nl',
        'body',
        'body_en',
        'body_fr',
        'body_nl',
        'type',
        'data',
        'is_read',
    ];

    protected $casts = [
        'data' => 'array',
        'is_read' => 'boolean',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

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