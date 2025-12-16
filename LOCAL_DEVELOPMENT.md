# Local Development Setup

## Configuring ENCRYPTION_KEY Locally

The `ENCRYPTION_KEY` environment variable is configured in your `.env.local` file, which is ignored by git for security.

### Current Configuration

Your `.env.local` file now includes:

```dotenv
###> Encryption ###
ENCRYPTION_KEY=local-dev-encryption-key-12345678901234567890
###< Encryption ###
```

### Generate a Custom Key (Optional)

If you want to use a different encryption key for local development:

```bash
# Generate a secure random key
openssl rand -base64 32

# Or generate a hex key
openssl rand -hex 32
```

Then update `.env.local`:

```dotenv
ENCRYPTION_KEY=your-generated-key-here
```

### Using ENCRYPTION_KEY in Your Code

The encryption key is available as a standard environment variable:

```php
<?php
// Direct access
$encryptionKey = $_ENV['ENCRYPTION_KEY'];

// Or using Symfony's getenv()
$encryptionKey = getenv('ENCRYPTION_KEY');

// In a Symfony service with DI
use Symfony\Component\DependencyInjection\Attribute\Autowire;

class MyService
{
    public function __construct(
        #[Autowire(env: 'ENCRYPTION_KEY')]
        private string $encryptionKey
    ) {}
}
```

### Verify Configuration

Check if the variable is loaded:

```bash
# Using Symfony console
php bin/console debug:container --env-vars | grep ENCRYPTION

# Or create a simple test script
php -r "require 'vendor/autoload.php'; \$dotenv = Symfony\Component\Dotenv\Dotenv::createImmutable(__DIR__); \$dotenv->load(); echo \$_ENV['ENCRYPTION_KEY'] ?? 'NOT SET';"
```

### Environment File Priority

Symfony loads environment variables in this order (later files override earlier):

1. `.env` - Committed defaults for all environments
2. `.env.local` - Local overrides (NOT committed to git) ⭐
3. `.env.[environment]` - Environment-specific (e.g., `.env.dev`, `.env.prod`)
4. `.env.[environment].local` - Local environment overrides (NOT committed)

Your `.env.local` file is the right place for local development secrets.

### Important Notes

⚠️ **Do NOT commit `.env.local`** - This file is in `.gitignore` and should remain there  
⚠️ **Different keys for different environments** - Local dev key should differ from production  
✅ **Production uses AWS Secrets Manager** - The CloudFormation stack handles production secrets  

### Example Usage

Here's a simple encryption service example:

```php
<?php
namespace App\Service;

use Symfony\Component\DependencyInjection\Attribute\Autowire;

class EncryptionService
{
    public function __construct(
        #[Autowire(env: 'ENCRYPTION_KEY')]
        private string $encryptionKey
    ) {
        if (empty($this->encryptionKey)) {
            throw new \RuntimeException('ENCRYPTION_KEY is not configured');
        }
    }

    public function encrypt(string $data): string
    {
        $iv = openssl_random_pseudo_bytes(16);
        $encrypted = openssl_encrypt(
            $data,
            'aes-256-cbc',
            hash('sha256', $this->encryptionKey, true),
            OPENSSL_RAW_DATA,
            $iv
        );
        
        return base64_encode($iv . $encrypted);
    }

    public function decrypt(string $encrypted): string
    {
        $data = base64_decode($encrypted);
        $iv = substr($data, 0, 16);
        $encrypted = substr($data, 16);
        
        return openssl_decrypt(
            $encrypted,
            'aes-256-cbc',
            hash('sha256', $this->encryptionKey, true),
            OPENSSL_RAW_DATA,
            $iv
        );
    }
}
```

### Quick Test

Test that your encryption key is loaded:

```bash
# Run Symfony server
symfony server:start

# Or PHP built-in server
php -S localhost:8000 -t public/

# Create a test endpoint in your controller
```

```php
<?php
namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Annotation\Route;

class TestController extends AbstractController
{
    #[Route('/test/encryption-key', name: 'test_encryption_key')]
    public function testEncryptionKey(): Response
    {
        $key = $_ENV['ENCRYPTION_KEY'] ?? 'NOT SET';
        $masked = substr($key, 0, 8) . '***' . substr($key, -8);
        
        return new Response("Encryption key is configured: $masked");
    }
}
```

Visit: `http://localhost:8000/test/encryption-key`

### Troubleshooting

**Key not found:**
- Check `.env.local` exists and has `ENCRYPTION_KEY=...`
- Clear cache: `php bin/console cache:clear`
- Restart development server

**Permission denied:**
- Check file permissions: `chmod 600 .env.local`

**Wrong value:**
- Values are loaded at application bootstrap
- Restart server after changing `.env.local`

## Complete Local Setup

Your `.env.local` should look like:

```dotenv
###> symfony/framework-bundle ###
APP_ENV=dev
APP_SECRET=ba385594e003b47ad7eb6b2abd76501a
###< symfony/framework-bundle ###

###> doctrine/doctrine-bundle ###
DATABASE_URL="mysql://vcars:password123@127.0.0.1:3306/symfony_db?serverVersion=8.0&charset=utf8mb4"
###< doctrine/doctrine-bundle ###

###> OpenSearch ###
OPENSEARCH_HOST=http://localhost:9200
OPENSEARCH_USERNAME=admin
OPENSEARCH_PASSWORD=admin
###< OpenSearch ###

###> Encryption ###
ENCRYPTION_KEY=local-dev-encryption-key-12345678901234567890
###< Encryption ###
```

## Summary

✅ `ENCRYPTION_KEY` is now configured in `.env.local`  
✅ Available as `$_ENV['ENCRYPTION_KEY']` in your code  
✅ File is gitignored (won't be committed)  
✅ Different from production (which uses AWS Secrets Manager)  

You're all set for local development! 🚀

