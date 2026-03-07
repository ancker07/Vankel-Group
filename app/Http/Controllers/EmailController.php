<?php

namespace App\Http\Controllers;

use App\Models\Email;
use Illuminate\Http\Request;

class EmailController extends Controller
{
    public function index()
    {
        return response()->json([
            'emails' => Email::orderBy('received_at', 'desc')->get()
        ]);
    }
}
