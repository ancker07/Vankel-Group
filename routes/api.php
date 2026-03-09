<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\InterventionController;
use App\Http\Controllers\EmailController;
use App\Http\Controllers\SettingController;

Route::get('/emails', [EmailController::class, 'index']);
Route::get('/emails/{id}', [EmailController::class, 'show']);
Route::delete('/emails/{id}', [EmailController::class, 'destroy']);
Route::post('/emails/sync', [EmailController::class, 'sync']);
Route::post('/emails/{id}/ingest', [EmailController::class, 'ingest']);
Route::post('/emails/ingest-all', [EmailController::class, 'ingestAll']);

Route::get('/settings/ai', [SettingController::class, 'getAiSettings']);
Route::post('/settings/ai', [SettingController::class, 'updateAiSettings']);
Route::post('/login', [AuthController::class, 'login']);
Route::post('/signup', [AuthController::class, 'signup']);
Route::post('/send-otp', [AuthController::class, 'sendOtp']);
Route::post('/verify-otp', [AuthController::class, 'verifyOtp']);
Route::get('/users/pending', [AuthController::class, 'getPendingUsers']);
Route::get('/users/all', [AuthController::class, 'getAllUsers']);
Route::get('/superadmin/stats', [AuthController::class, 'getSuperAdminStats']);
Route::post('/users/{id}/approve', [AuthController::class, 'approveUser']);
Route::post('/users/{id}/reject', [AuthController::class, 'rejectUser']);
Route::post('/interventions', [InterventionController::class, 'store']);
Route::get('/buildings', [InterventionController::class, 'getBuildings']);
Route::get('/syndics', [InterventionController::class, 'getSyndics']);
Route::get('/missions', [InterventionController::class, 'getMissions']);
Route::get('/missions/{id}', [InterventionController::class, 'getMissionById']);
Route::post('/missions/{id}/approve', [InterventionController::class, 'approveMission']);
Route::post('/missions/{id}/reject', [InterventionController::class, 'rejectMission']);
Route::get('/interventions', [InterventionController::class, 'getInterventions']);
Route::get('/interventions/{id}', [InterventionController::class, 'getInterventionById']);
Route::put('/interventions/{id}', [InterventionController::class, 'updateIntervention']);
Route::post('/interventions/{id}/send-report', [InterventionController::class, 'sendReport']);
Route::post('/check-status', [AuthController::class, 'checkStatus']);
Route::post('/profile/update', [AuthController::class, 'updateProfile']);
Route::post('/profile/details', [AuthController::class, 'getProfile']);







