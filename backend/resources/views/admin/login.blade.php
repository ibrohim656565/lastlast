<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Log in · SafeTJ Admin</title>
    <link rel="stylesheet" href="{{ asset('admin.css') }}">
    <script>
        (function () {
            var stored = localStorage.getItem('safetj-admin-theme');
            if (stored) document.documentElement.setAttribute('data-theme', stored);
        })();
    </script>
</head>
<body>
    <div class="login-shell">
        <div class="login-card">
            <div class="flag-strip" aria-hidden="true"></div>
            <h1 style="margin-top:0; font-size:1.2rem;">SafeTJ Admin</h1>
            <p style="color:var(--color-text-muted); font-size:0.85rem; margin-top:-0.5rem;">
                Disaster-management dashboard — dispatcher &amp; admin access only.
            </p>

            @if ($errors->any())
                <div class="error-text">{{ $errors->first() }}</div>
            @endif

            <form method="POST" action="{{ route('admin.login.attempt') }}">
                @csrf
                <div class="field">
                    <label for="email">Email</label>
                    <input type="email" id="email" name="email" value="{{ old('email') }}" required autofocus>
                </div>
                <div class="field">
                    <label for="password">Password</label>
                    <input type="password" id="password" name="password" required>
                </div>
                <label style="display:flex; align-items:center; gap:0.4rem; font-size:0.85rem; margin-bottom:1rem;">
                    <input type="checkbox" name="remember" value="1" style="width:auto;"> Remember me
                </label>
                <button type="submit" class="btn" style="width:100%;">Log in</button>
            </form>
        </div>
    </div>
</body>
</html>
