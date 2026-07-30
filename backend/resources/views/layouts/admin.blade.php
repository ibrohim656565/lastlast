<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>@yield('title', 'Dashboard') · SafeTJ Admin</title>
    <link rel="stylesheet" href="{{ asset('admin.css') }}">
    {{-- UI strings below are English-only for now. In production these
         would be routed through Laravel's translation files
         (resources/lang/{tg,ru,en}) keyed the same way the mobile app's
         tg/ru/en strings are, per API_CONTRACT.md's `language` enum. --}}
    <script>
        (function () {
            var stored = localStorage.getItem('safetj-admin-theme');
            if (stored) document.documentElement.setAttribute('data-theme', stored);
        })();
    </script>
    @stack('head')
</head>
<body>
    <div class="app-shell">
        <aside class="sidebar">
            <div class="brand">
                <span class="flag-bar" aria-hidden="true"></span>
                SafeTJ Admin
            </div>
            <nav>
                <a href="{{ route('admin.dashboard') }}" class="{{ request()->routeIs('admin.dashboard') ? 'active' : '' }}">Dashboard</a>
                <a href="{{ route('admin.incidents.index') }}" class="{{ request()->routeIs('admin.incidents.*') ? 'active' : '' }}">Incidents</a>
            </nav>
            <div class="sidebar-footer">
                Signed in as<br>
                <strong>{{ optional(auth('web')->user())->name ?? optional(auth('web')->user())->email }}</strong>
            </div>
        </aside>

        <div class="main">
            <header class="topbar">
                <h1>@yield('title', 'Dashboard')</h1>
                <div style="display:flex; gap:0.6rem; align-items:center;">
                    <button type="button" class="theme-toggle" id="theme-toggle" aria-label="Toggle dark/light theme">🌓 Theme</button>
                    <form method="POST" action="{{ route('admin.logout') }}" style="margin:0;">
                        @csrf
                        <button type="submit" class="logout-btn">Log out</button>
                    </form>
                </div>
            </header>

            <main class="content">
                @if (session('status'))
                    <div class="flash-status">{{ session('status') }}</div>
                @endif

                @yield('content')
            </main>
        </div>
    </div>

    <script>
        document.getElementById('theme-toggle').addEventListener('click', function () {
            var root = document.documentElement;
            var current = root.getAttribute('data-theme')
                || (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
            var next = current === 'dark' ? 'light' : 'dark';
            root.setAttribute('data-theme', next);
            localStorage.setItem('safetj-admin-theme', next);
        });
    </script>
    @stack('scripts')
</body>
</html>
