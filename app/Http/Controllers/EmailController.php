<?php

namespace App\Http\Controllers;

use App\Models\Email;
use Illuminate\Http\Request;

class EmailController extends Controller
{
    public function index()
    {
        return response()->json([
            'emails' => Email::with('attachments')->orderBy('received_at', 'desc')->get()
        ]);
    }

    public function show($id)
    {
        $email = Email::with('attachments')->findOrFail($id);
        return response()->json($email);
    }
}
