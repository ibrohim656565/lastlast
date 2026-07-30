<?php

use App\Http\Controllers\Admin\AdminAuthController;
use App\Http\Controllers\Admin\AdminController;
use App\Http\Controllers\Admin\IncidentController as AdminIncidentController;
use Illuminate\Support\Facades\Route;

Route::redirect('/', '/admin/dashboard');

Route::prefix('admin')->name('admin.')->group(function () {
    Route::get('/login', [AdminAuthController::class, 'showLogin'])->name('login');
    Route::post('/login', [AdminAuthController::class, 'login'])->name('login.attempt');
    Route::post('/logout', [AdminAuthController::class, 'logout'])->name('logout');

    // EnsureIsAdmin (aliased 'admin') checks the `web` guard itself and
    // redirects to admin.login when unauthenticated, so it alone is enough
    // — chaining `auth:web` here would instead try to redirect to a plain
    // `login` named route that doesn't exist in this app.
    Route::middleware(['admin'])->group(function () {
        Route::get('/dashboard', [AdminController::class, 'dashboard'])->name('dashboard');

        Route::get('/incidents', [AdminIncidentController::class, 'index'])->name('incidents.index');
        Route::get('/incidents/{incident}', [AdminIncidentController::class, 'show'])->name('incidents.show');
        Route::patch('/incidents/{incident}/status', [AdminIncidentController::class, 'updateStatus'])->name('incidents.status');

        Route::get('/api/stats.json', [AdminController::class, 'stats'])->name('api.stats');
        Route::get('/api/incidents.json', [AdminController::class, 'incidentsJson'])->name('api.incidents');
    });
});
