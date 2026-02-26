<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\InterventionController;

Route::post('/login', [AuthController::class, 'login']);
Route::post('/signup', [AuthController::class, 'signup']);
Route::post('/send-otp', [AuthController::class, 'sendOtp']);
Route::post('/verify-otp', [AuthController::class, 'verifyOtp']);
Route::get('/users/pending', [AuthController::class, 'getPendingUsers']);
Route::post('/users/{id}/approve', [AuthController::class, 'approveUser']);
Route::post('/users/{id}/reject', [AuthController::class, 'rejectUser']);
Route::post('/interventions', [InterventionController::class, 'store']);
Route::get('/buildings', [InterventionController::class, 'getBuildings']);
Route::get('/syndics', [InterventionController::class, 'getSyndics']);
Route::get('/missions', [InterventionController::class, 'getMissions']);
Route::post('/missions/{id}/approve', [InterventionController::class, 'approveMission']);
Route::post('/missions/{id}/reject', [InterventionController::class, 'rejectMission']);
Route::get('/interventions', [InterventionController::class, 'getInterventions']);
Route::put('/interventions/{id}', [InterventionController::class, 'updateIntervention']);
Route::post('/check-status', [AuthController::class, 'checkStatus']);
Route::post('/profile/update', [AuthController::class, 'updateProfile']);
Route::post('/profile/details', [AuthController::class, 'getProfile']);


