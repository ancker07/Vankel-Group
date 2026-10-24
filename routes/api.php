<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\InterventionController;
use App\Http\Controllers\EmailController;
use App\Http\Controllers\SettingController;
use App\Http\Controllers\MaintenanceController;
use App\Http\Controllers\ContactController;
use App\Http\Controllers\NotificationController;
use App\Http\Controllers\TeamController;
use App\Http\Controllers\RoleController;

// ---------------------------------------------------------------------
// Access control: every route needs a login (Sanctum token) and, where
// listed, a permission. Permissions come from the user's role (see
// App\Support\PermissionCatalog and the Roles & permissions page).
// The super admin has every permission.
// ---------------------------------------------------------------------

// Public
Route::post('/login', [AuthController::class, 'login']);
Route::post('/contacts', [ContactController::class, 'store']); // public website contact form
// Public self-registration is disabled: accounts are created by users with users.create.

// Any logged-in user (own account only)
Route::middleware('permission')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/check-status', [AuthController::class, 'checkStatus']);
    Route::post('/profile/update', [AuthController::class, 'updateProfile']);
    Route::post('/profile/details', [AuthController::class, 'getProfile']);
    Route::post('/change-password', [AuthController::class, 'changePassword']);
    Route::post('/update-fcm-token', [AuthController::class, 'updateFcmToken']);
    Route::get('/notifications', [NotificationController::class, 'getUserNotifications']);
    Route::post('/notifications/{id}/read', [NotificationController::class, 'markAsRead']);
    Route::post('/notifications/read-all', [NotificationController::class, 'markAllAsRead']);
});

// Missions
Route::get('/missions', [InterventionController::class, 'getMissions'])->middleware('permission:missions.view');
Route::get('/missions/{id}', [InterventionController::class, 'getMissionById'])->middleware('permission:missions.view');
Route::put('/missions/{id}', [InterventionController::class, 'updateMission'])->middleware('permission:missions.update');
Route::post('/missions/{id}/approve', [InterventionController::class, 'approveMission'])->middleware('permission:missions.approve');
Route::post('/missions/{id}/reject', [InterventionController::class, 'rejectMission'])->middleware('permission:missions.approve');

// Interventions (POST creates a mission request or an intervention; the controller checks which)
Route::post('/interventions', [InterventionController::class, 'store'])->middleware('permission:missions.create,interventions.create');
Route::get('/interventions', [InterventionController::class, 'getInterventions'])->middleware('permission:interventions.view');
Route::get('/interventions/{id}', [InterventionController::class, 'getInterventionById'])->middleware('permission:interventions.view');
Route::put('/interventions/{id}', [InterventionController::class, 'updateIntervention'])->middleware('permission:interventions.update');
Route::post('/interventions/{id}/send-report', [InterventionController::class, 'sendReport'])->middleware('permission:interventions.send_report');
Route::get('/interventions/{id}/assignments', [TeamController::class, 'interventionAssignments'])->middleware('permission:interventions.view');
Route::get('/interventions/{id}/tracking', [TeamController::class, 'interventionTracking'])->middleware('permission:team.view');

// Buildings & syndic companies
Route::get('/buildings', [InterventionController::class, 'getBuildings'])->middleware('permission:buildings.view');
Route::get('/syndics', [InterventionController::class, 'getSyndics'])->middleware('permission:buildings.view');

// Maintenance
Route::get('/maintenance-plans', [MaintenanceController::class, 'index'])->middleware('permission:maintenance.view');
Route::middleware('permission:maintenance.manage')->group(function () {
    Route::post('/maintenance-plans', [MaintenanceController::class, 'store']);
    Route::put('/maintenance-plans/{id}', [MaintenanceController::class, 'update']);
    Route::delete('/maintenance-plans/{id}', [MaintenanceController::class, 'destroy']);
});

// Emails
Route::middleware('permission:emails.view')->group(function () {
    Route::get('/emails', [EmailController::class, 'index']);
    Route::get('/emails/{id}', [EmailController::class, 'show']);
    Route::get('/emails/threads/{id}', [EmailController::class, 'getThread']);
});
Route::middleware('permission:emails.manage')->group(function () {
    Route::delete('/emails/{id}', [EmailController::class, 'destroy']);
    Route::post('/emails/{id}/reply', [EmailController::class, 'reply']);
    Route::post('/emails/sync', [EmailController::class, 'sync']);
    Route::post('/emails/{id}/ingest', [EmailController::class, 'ingest']);
    Route::post('/emails/ingest-all', [EmailController::class, 'ingestAll']);
});

// Website contact requests
Route::get('/contacts', [ContactController::class, 'index'])->middleware('permission:contacts.view');
Route::delete('/contacts/{id}', [ContactController::class, 'destroy'])->middleware('permission:contacts.manage');

// AI
Route::get('/settings/ai', [SettingController::class, 'getAiSettings'])->middleware('permission:settings.ai');
Route::post('/settings/ai', [SettingController::class, 'updateAiSettings'])->middleware('permission:settings.ai');
Route::post('/ai/improve', [SettingController::class, 'improveNote'])->middleware('permission:ai.use');

// Team & location
Route::get('/team', [TeamController::class, 'index'])->middleware('permission:team.view');
Route::post('/location', [TeamController::class, 'updateLocation'])->middleware('permission:location.share');

// Users
Route::get('/users/pending', [AuthController::class, 'getPendingUsers'])->middleware('permission:users.view');
Route::get('/users/all', [AuthController::class, 'getAllUsers'])->middleware('permission:users.view');
Route::post('/users', [AuthController::class, 'storeUser'])->middleware('permission:users.create');
Route::post('/superadmin/admins', [AuthController::class, 'storeAdmin'])->middleware('permission:users.create');
Route::post('/users/{id}/approve', [AuthController::class, 'approveUser'])->middleware('permission:users.update');
Route::post('/users/{id}/reject', [AuthController::class, 'rejectUser'])->middleware('permission:users.update');
Route::put('/users/{id}/role', [AuthController::class, 'updateUserRole'])->middleware('permission:users.update');

// Roles & permissions (the role list is also needed by the "create user" form)
Route::get('/roles', [RoleController::class, 'index'])->middleware('permission:roles.manage,users.create,users.update');
Route::middleware('permission:roles.manage')->group(function () {
    Route::get('/permissions', [RoleController::class, 'permissions']);
    Route::post('/roles', [RoleController::class, 'store']);
    Route::put('/roles/{id}', [RoleController::class, 'update']);
    Route::delete('/roles/{id}', [RoleController::class, 'destroy']);
});

// System
Route::get('/superadmin/stats', [AuthController::class, 'getSuperAdminStats'])->middleware('permission:stats.view');
Route::middleware('permission:notifications.broadcast')->group(function () {
    Route::post('/superadmin/send-notification', [NotificationController::class, 'sendBroadcast']);
    Route::post('/superadmin/test-notification', [NotificationController::class, 'sendTestNotification']);
    Route::get('/superadmin/notifications/history', [NotificationController::class, 'getHistory']);
});
