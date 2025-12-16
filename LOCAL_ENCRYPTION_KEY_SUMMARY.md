# ✅ ENCRYPTION_KEY Configured for Local Development

## What Was Done

### 1. Updated `.env.local` File

Added the following configuration to `/home/tomasz/projects/test-cloud-app/.env.local`:

```dotenv
###> Encryption ###
ENCRYPTION_KEY=local-dev-encryption-key-12345678901234567890
###< Encryption ###
```

### 2. Created Documentation

- **LOCAL_DEVELOPMENT.md** - Complete guide for local development setup
- **test-env.php** - Test script to verify environment variables

## How to Use ENCRYPTION_KEY in Your Code

### Method 1: Direct Access (Simple)

```php
<?php
$encryptionKey = $_ENV['ENCRYPTION_KEY'];
```

### Method 2: Symfony Parameters (Your Current Approach)

Your `HomeController.php` already uses this:

```php
$encryptionKey = $this->getParameter('env(ENCRYPTION_KEY)');
```

### Method 3: Dependency Injection (Recommended)

```php
use Symfony\Component\DependencyInjection\Attribute\Autowire;

class MyService
{
    public function __construct(
        #[Autowire(env: 'ENCRYPTION_KEY')]
        private string $encryptionKey
    ) {}
}
```

## Verify Configuration

### Quick Verification

```bash
# Check if the value is in .env.local
cat .env.local | grep ENCRYPTION_KEY

# Should show:
# ENCRYPTION_KEY=local-dev-encryption-key-12345678901234567890
```

### Test in Browser

1. Start your Symfony server:
   ```bash
   symfony server:start
   # OR
   php -S localhost:8000 -t public/
   ```

2. Visit your homepage: `http://localhost:8000`

3. Your `HomeController` already accesses the encryption key:
   ```php
   $encryptionKey = $this->getParameter('env(ENCRYPTION_KEY)');
   ```

### Clear Cache (if needed)

If the variable doesn't load, clear Symfony's cache:

```bash
php bin/console cache:clear
```

## Important Security Notes

✅ **`.env.local` is in `.gitignore`** - It won't be committed to git  
✅ **Different key for production** - AWS uses Secrets Manager for production  
✅ **Local development only** - This key is for your local environment only  

## File Structure

```
/home/tomasz/projects/test-cloud-app/
├── .env                    # Default values (committed to git)
├── .env.local              # Local overrides (NOT in git) ⭐ ENCRYPTION_KEY here
├── LOCAL_DEVELOPMENT.md    # Documentation for local setup
├── test-env.php            # Test script
└── src/
    └── Controller/
        └── HomeController.php  # Already using ENCRYPTION_KEY!
```

## Your Current HomeController

Your `HomeController.php` is already configured to use the encryption key:

```php
public function index(): Response
{
    $encryptionKey = $this->getParameter('env(ENCRYPTION_KEY)');
    return $this->render('home/index.html.twig', [
        'encryption_key' => $encryptionKey,
    ]);
}
```

This means:
- ✅ The key is already being accessed
- ✅ It's passed to your Twig template
- ✅ You can use it in your application logic

## Example Usage: Encryption Service

Create a service to use the encryption key:

```php
<?php
// src/Service/EncryptionService.php

namespace App\Service;

use Symfony\Component\DependencyInjection\Attribute\Autowire;

class EncryptionService
{
    public function __construct(
        #[Autowire(env: 'ENCRYPTION_KEY')]
        private string $encryptionKey
    ) {
        if (empty($this->encryptionKey)) {
            throw new \RuntimeException('ENCRYPTION_KEY not configured');
        }
    }

    public function encrypt(string $data): string
    {
        $iv = openssl_random_pseudo_bytes(16);
        $key = hash('sha256', $this->encryptionKey, true);
        
        $encrypted = openssl_encrypt(
            $data,
            'aes-256-cbc',
            $key,
            OPENSSL_RAW_DATA,
            $iv
        );
        
        return base64_encode($iv . $encrypted);
    }

    public function decrypt(string $encryptedData): string
    {
        $data = base64_decode($encryptedData);
        $iv = substr($data, 0, 16);
        $encrypted = substr($data, 16);
        $key = hash('sha256', $this->encryptionKey, true);
        
        return openssl_decrypt(
            $encrypted,
            'aes-256-cbc',
            $key,
            OPENSSL_RAW_DATA,
            $iv
        );
    }
}
```

Use in your controller:

```php
use App\Service\EncryptionService;

class MyController extends AbstractController
{
    public function __construct(
        private EncryptionService $encryptionService
    ) {}

    #[Route('/encrypt-test')]
    public function test(): Response
    {
        $original = 'Sensitive data';
        $encrypted = $this->encryptionService->encrypt($original);
        $decrypted = $this->encryptionService->decrypt($encrypted);
        
        return new Response("Original: $original | Decrypted: $decrypted");
    }
}
```

## Generate a Custom Key (Optional)

If you want a different encryption key:

```bash
# Generate a 32-byte random key (base64 encoded)
openssl rand -base64 32

# Or generate a hex key
openssl rand -hex 32

# Or use PHP
php -r "echo base64_encode(random_bytes(32)) . PHP_EOL;"
```

Then update `.env.local`:

```dotenv
ENCRYPTION_KEY=your-new-generated-key-here
```

## Comparison: Local vs Production

| Aspect | Local Development | Production (AWS) |
|--------|------------------|------------------|
| **Storage** | `.env.local` file | AWS Secrets Manager |
| **Security** | File permissions | KMS encryption |
| **Access** | Direct file read | IAM role permissions |
| **Committed** | ❌ No (in .gitignore) | ❌ No (parameter only) |
| **Updates** | Edit `.env.local` | Update Secrets Manager |

## Troubleshooting

### Key not loading?

1. **Check file exists:**
   ```bash
   cat .env.local | grep ENCRYPTION_KEY
   ```

2. **Clear cache:**
   ```bash
   php bin/console cache:clear
   ```

3. **Restart server:**
   ```bash
   # Ctrl+C to stop, then restart
   symfony server:start
   ```

### Permission denied?

```bash
chmod 600 .env.local
```

### Want to test without running the app?

```bash
php test-env.php
```

## Summary

✅ **ENCRYPTION_KEY is configured** in `.env.local`  
✅ **Value:** `local-dev-encryption-key-12345678901234567890`  
✅ **Already used in HomeController** via `$this->getParameter('env(ENCRYPTION_KEY)')`  
✅ **Not committed to git** (`.env.local` is in `.gitignore`)  
✅ **Production uses AWS Secrets Manager** (different, more secure approach)  

## Next Steps

1. **Start your development server:**
   ```bash
   symfony server:start
   ```

2. **Visit your app:**
   ```bash
   open http://localhost:8000
   ```

3. **Use the encryption key in your code** as shown in the examples above

You're all set! The `ENCRYPTION_KEY` is now available for local development. 🎉

For more details, see:
- `LOCAL_DEVELOPMENT.md` - Complete local setup guide
- `ENCRYPTION_KEY_SETUP.md` - Production AWS setup guide
- `QUICKSTART_ENCRYPTION_KEY.md` - Quick reference

