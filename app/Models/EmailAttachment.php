<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class EmailAttachment extends Model
{
    protected $guarded = ['id'];

    public function email()
    {
        return $this->belongsTo(Email::class);
    }
}
