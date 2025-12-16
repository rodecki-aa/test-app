#!/usr/bin/env php
<?php
// Test script to verify ENCRYPTION_KEY is loaded

require_once __DIR__ . '/vendor/autoload.php';

use Symfony\Component\Dotenv\Dotenv;

echo "=== Environment Variables Test ===\n\n";

// Load .env files
$dotenv = new Dotenv();
$dotenv->loadEnv(__DIR__ . '/.env');

// Check ENCRYPTION_KEY
$encryptionKey = $_ENV['ENCRYPTION_KEY'] ?? $_SERVER['ENCRYPTION_KEY'] ?? null;

if ($encryptionKey) {
    $length = strlen($encryptionKey);
    $masked = $length > 16
        ? substr($encryptionKey, 0, 8) . '...' . substr($encryptionKey, -8)
        : str_repeat('*', $length);

    echo "✅ ENCRYPTION_KEY is configured\n";
    echo "   Masked value: {$masked}\n";
    echo "   Length: {$length} characters\n\n";
} else {
    echo "❌ ENCRYPTION_KEY is NOT set\n\n";
    exit(1);
}

// Show other environment variables (masked)
echo "Other environment variables:\n";
echo "   APP_ENV: " . ($_ENV['APP_ENV'] ?? 'NOT SET') . "\n";
echo "   DATABASE_URL: " . (isset($_ENV['DATABASE_URL']) ? 'SET' : 'NOT SET') . "\n";
echo "   OPENSEARCH_HOST: " . ($_ENV['OPENSEARCH_HOST'] ?? 'NOT SET') . "\n";
echo "\n";

echo "✅ Environment configuration is working!\n";
echo "\nYou can now use \$_ENV['ENCRYPTION_KEY'] in your PHP code.\n";

