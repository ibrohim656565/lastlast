<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureIsAdmin
{
    /**
     * Restricts the `web` guard (admin dashboard) to users with role
     * admin|dispatcher. Anyone else is redirected to the admin login.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user('web');

        if (! $user || ! $user->canAccessAdmin()) {
            return redirect()->route('admin.login');
        }

        return $next($request);
    }
}
