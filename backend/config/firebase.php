<?php

return [

    'default' => env('FIREBASE_PROJECT', 'app'),

    'projects' => [

        'app' => [

            'credentials' => [
                // Path to the Firebase Admin SDK service account JSON. Used
                // by FirebaseAuthService to verify Phone Auth ID tokens on
                // login, and by NotificationService to send FCM pushes.
                'file' => env('FIREBASE_CREDENTIALS', storage_path('app/firebase-credentials.json')),
                'auto_discovery' => true,
            ],

            'auth' => [
                'tenant_id' => env('FIREBASE_AUTH_TENANT_ID'),
            ],

            'project_id' => env('FIREBASE_PROJECT_ID'),

            'dynamic_links' => [
                'default_domain' => env('FIREBASE_DYNAMIC_LINKS_DEFAULT_DOMAIN'),
            ],

            'storage' => [
                'default_bucket' => env('FIREBASE_STORAGE_DEFAULT_BUCKET'),
            ],

            'logging' => [
                'http_log_channel' => env('FIREBASE_HTTP_LOG_CHANNEL'),
                'http_debug_log_channel' => env('FIREBASE_HTTP_DEBUG_LOG_CHANNEL'),
            ],

            'http_client_options' => [
                'proxy' => env('FIREBASE_HTTP_CLIENT_PROXY'),
                'timeout' => env('FIREBASE_HTTP_CLIENT_TIMEOUT'),
                'guzzle_middlewares' => [],
            ],

            'cache_store' => env('FIREBASE_CACHE_STORE', 'file'),

        ],

    ],

];
