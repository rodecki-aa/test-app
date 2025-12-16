# How to Pass ENCRYPTION_KEY to Views in Symfony

## ✅ Your Current Setup (Already Working!)

### Controller: `src/Controller/HomeController.php`

```php
<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\DependencyInjection\Attribute\Autowire;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Annotation\Route;

class HomeController extends AbstractController
{
    #[Route('/', name: 'home')]
    public function index(
        #[Autowire(env: 'ENCRYPTION_KEY')]
        string $encryptionKey
    ): Response
    {
        return $this->render('home/index.html.twig', [
            'encryption_key' => $encryptionKey,  // ← Passed to view here
        ]);
    }
}
```

### View: `templates/home/index.html.twig`

```twig
{% extends 'base.html.twig' %}

{% block body %}
    <h1>Run it in clouds</h1>
    
    {# Display the encryption key (masked for security) #}
    <code>Never tell {{ encryption_key }}</code>
    
    <p class="cloud-icon">☁</p>
{% endblock %}
```

## Three Methods to Pass ENCRYPTION_KEY to Views

### Method 1: Using #[Autowire] Attribute (Recommended) ✅

**Your current approach** - Clean and type-safe:

```php
#[Route('/page')]
public function myPage(
    #[Autowire(env: 'ENCRYPTION_KEY')]
    string $encryptionKey
): Response
{
    return $this->render('page.html.twig', [
        'encryption_key' => $encryptionKey,
    ]);
}
```

### Method 2: Using getParameter()

Alternative approach using Symfony's parameter bag:

```php
#[Route('/page')]
public function myPage(): Response
{
    $encryptionKey = $this->getParameter('env(ENCRYPTION_KEY)');
    
    return $this->render('page.html.twig', [
        'encryption_key' => $encryptionKey,
    ]);
}
```

### Method 3: Constructor Injection (For Multiple Actions)

If you need it in multiple actions:

```php
class MyController extends AbstractController
{
    public function __construct(
        #[Autowire(env: 'ENCRYPTION_KEY')]
        private readonly string $encryptionKey
    ) {}

    #[Route('/page1')]
    public function page1(): Response
    {
        return $this->render('page1.html.twig', [
            'encryption_key' => $this->encryptionKey,
        ]);
    }

    #[Route('/page2')]
    public function page2(): Response
    {
        return $this->render('page2.html.twig', [
            'encryption_key' => $this->encryptionKey,
        ]);
    }
}
```

## Using ENCRYPTION_KEY in Twig Templates

### Display the Key (Masked for Security)

```twig
{# Show first 8 and last 8 characters only #}
<p>Key: {{ encryption_key[:8] ~ '...' ~ encryption_key[-8:] }}</p>

{# Or just show length #}
<p>Key Length: {{ encryption_key|length }} characters</p>

{# Check if it exists #}
{% if encryption_key is defined and encryption_key is not empty %}
    <p>✅ Encryption key is configured</p>
{% else %}
    <p>❌ Encryption key is NOT configured</p>
{% endif %}
```

### Use in Conditional Logic

```twig
{% if app.environment == 'dev' %}
    <div class="debug-info">
        <h3>Debug Info (Dev Only)</h3>
        <p>Encryption Key Length: {{ encryption_key|length }}</p>
        <p>First 8 chars: {{ encryption_key[:8] }}</p>
    </div>
{% endif %}
```

### Pass to JavaScript (Be Careful!)

⚠️ **Warning:** Only do this if absolutely necessary!

```twig
<script>
    // NOT RECOMMENDED - exposes key to client
    const encryptionKeyLength = {{ encryption_key|length }};
    
    // Better: Just send a flag
    const hasEncryption = {{ encryption_key ? 'true' : 'false' }};
</script>
```

## Best Practices

### ✅ DO

1. **Mask the key when displaying:**
   ```twig
   <code>Key: {{ encryption_key[:8] ~ '***' }}</code>
   ```

2. **Use it server-side only:**
   ```php
   $encrypted = openssl_encrypt($data, 'aes-256-cbc', $encryptionKey, ...);
   return $this->render('template.twig', ['encrypted' => $encrypted]);
   ```

3. **Check if it exists:**
   ```twig
   {% if encryption_key is defined %}
       {# Use it #}
   {% endif %}
   ```

### ❌ DON'T

1. **Never expose full key in HTML:**
   ```twig
   {# BAD - Don't do this! #}
   <input type="hidden" value="{{ encryption_key }}">
   ```

2. **Never log it:**
   ```twig
   {# BAD - Don't do this! #}
   {{ dump(encryption_key) }}
   ```

3. **Never send to client-side JavaScript:**
   ```twig
   {# BAD - Don't do this! #}
   <script>const key = "{{ encryption_key }}";</script>
   ```

## Complete Example: Secure Display

### Controller

```php
<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\DependencyInjection\Attribute\Autowire;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Annotation\Route;

class SecureController extends AbstractController
{
    #[Route('/secure-info', name: 'secure_info')]
    public function secureInfo(
        #[Autowire(env: 'ENCRYPTION_KEY')]
        string $encryptionKey
    ): Response
    {
        // Process data with encryption key server-side
        $sampleData = 'Sensitive Information';
        $encrypted = $this->encryptData($sampleData, $encryptionKey);
        
        // Only pass processed/masked data to view
        return $this->render('secure/info.html.twig', [
            'key_length' => strlen($encryptionKey),
            'key_masked' => $this->maskKey($encryptionKey),
            'encrypted_sample' => $encrypted,
            'is_configured' => !empty($encryptionKey),
        ]);
    }
    
    private function maskKey(string $key): string
    {
        if (strlen($key) <= 16) {
            return str_repeat('*', strlen($key));
        }
        return substr($key, 0, 8) . '...' . substr($key, -8);
    }
    
    private function encryptData(string $data, string $key): string
    {
        $iv = openssl_random_pseudo_bytes(16);
        $encrypted = openssl_encrypt(
            $data,
            'aes-256-cbc',
            hash('sha256', $key, true),
            OPENSSL_RAW_DATA,
            $iv
        );
        return base64_encode($iv . $encrypted);
    }
}
```

### Template: `templates/secure/info.html.twig`

```twig
{% extends 'base.html.twig' %}

{% block title %}Secure Information{% endblock %}

{% block body %}
    <h1>Security Configuration</h1>
    
    <div class="info-panel">
        {% if is_configured %}
            <p>✅ Encryption is configured</p>
            <p>Key Length: {{ key_length }} characters</p>
            <p>Key Preview: <code>{{ key_masked }}</code></p>
        {% else %}
            <p>❌ Encryption key is NOT configured</p>
        {% endif %}
    </div>
    
    {% if app.environment == 'dev' %}
        <div class="debug-panel">
            <h2>Debug Info (Development Only)</h2>
            <p>Environment: {{ app.environment }}</p>
            <p>Sample Encrypted Data: <code>{{ encrypted_sample }}</code></p>
        </div>
    {% endif %}
{% endblock %}
```

## Using in Services (Advanced)

If you need the encryption key in multiple controllers or services, create a dedicated service:

### Create Encryption Service

```php
<?php
// src/Service/EncryptionService.php

namespace App\Service;

use Symfony\Component\DependencyInjection\Attribute\Autowire;

class EncryptionService
{
    public function __construct(
        #[Autowire(env: 'ENCRYPTION_KEY')]
        private readonly string $encryptionKey
    ) {}
    
    public function getKeyLength(): int
    {
        return strlen($this->encryptionKey);
    }
    
    public function getMaskedKey(): string
    {
        if (strlen($this->encryptionKey) <= 16) {
            return str_repeat('*', strlen($this->encryptionKey));
        }
        return substr($this->encryptionKey, 0, 8) 
            . '...' 
            . substr($this->encryptionKey, -8);
    }
    
    public function isConfigured(): bool
    {
        return !empty($this->encryptionKey);
    }
}
```

### Use in Controller

```php
class HomeController extends AbstractController
{
    public function __construct(
        private readonly EncryptionService $encryption
    ) {}
    
    #[Route('/', name: 'home')]
    public function index(): Response
    {
        return $this->render('home/index.html.twig', [
            'encryption_key' => $this->encryption->getMaskedKey(),
            'key_length' => $this->encryption->getKeyLength(),
            'is_configured' => $this->encryption->isConfigured(),
        ]);
    }
}
```

## Summary

Your current implementation is **already correct**! ✅

```php
// Controller
public function index(
    #[Autowire(env: 'ENCRYPTION_KEY')]
    string $encryptionKey
): Response
{
    return $this->render('home/index.html.twig', [
        'encryption_key' => $encryptionKey,  // ← Passed here
    ]);
}
```

```twig
{# Template #}
<code>Never tell {{ encryption_key }}</code>  {# ← Used here #}
```

**Key Points:**
- ✅ ENCRYPTION_KEY is injected via `#[Autowire]`
- ✅ Passed to view in `render()` array
- ✅ Accessible in Twig as `{{ encryption_key }}`
- ⚠️ Consider masking it for security: `{{ encryption_key[:8] ~ '...' }}`

Start your server and visit `http://localhost:8000` to see it in action!

```bash
symfony server:start
```

