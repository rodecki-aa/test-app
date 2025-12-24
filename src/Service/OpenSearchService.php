<?php

namespace App\Service;

use App\Entity\Car;
use OpenSearch\Client;
use OpenSearch\ClientBuilder;

class OpenSearchService
{
    private Client $client;
    private string $indexName = 'cars';

    public function __construct(
        private string $opensearchHost,
        private ?string $opensearchUsername = null,
        private ?string $opensearchPassword = null
    ) {
        $this->initializeClient();
    }

    private function initializeClient(): void
    {
        // Normalize the host URL
        $host = $this->opensearchHost;

        // Check if it's an AWS VPC endpoint
        $isVpcEndpoint = strpos($host, 'vpc-') !== false || strpos($host, '.es.amazonaws.com') !== false;

        // Check if it's localhost/local development
        $isLocalhost = strpos($host, 'localhost') !== false || strpos($host, '127.0.0.1') !== false;

        // Add scheme if not present
        if (!preg_match('/^https?:\/\//', $host)) {
            if ($isVpcEndpoint) {
                $host = 'https://' . $host;
            } elseif ($isLocalhost) {
                $host = 'http://' . $host;
            } else {
                // Default to https for other hosts
                $host = 'https://' . $host;
            }
        }

        // For AWS VPC endpoints, ensure port 443 is specified
        if ($isVpcEndpoint && !preg_match('/:\d+$/', $host)) {
            $parsedUrl = parse_url($host);
            $host = $parsedUrl['scheme'] . '://' . $parsedUrl['host'] . ':443';
            if (isset($parsedUrl['path'])) {
                $host .= $parsedUrl['path'];
            }
        }

        $hosts = [$host];

        $clientBuilder = ClientBuilder::create()
            ->setHosts($hosts);

        // AWS OpenSearch VPC endpoints: When AdvancedSecurityOptions is disabled,
        // authentication is not required. Skip auth for VPC endpoints.
        $shouldUseAuth = !empty($this->opensearchUsername)
            && !empty($this->opensearchPassword)
            && !$isVpcEndpoint;

        if ($shouldUseAuth) {
            $clientBuilder->setBasicAuthentication($this->opensearchUsername, $this->opensearchPassword);
        }

        // Disable SSL verification for AWS VPC endpoints and localhost
        if ($isVpcEndpoint || $isLocalhost) {
            $clientBuilder->setSSLVerification(false);
        }

        // Configure timeouts to prevent hanging requests
        $clientBuilder->setConnectionParams([
            'client' => [
                'curl' => [
                    CURLOPT_CONNECTTIMEOUT => 10,  // Connection timeout in seconds
                    CURLOPT_TIMEOUT => 30,         // Total request timeout in seconds
                ],
                'timeout' => 30,
                'connect_timeout' => 10,
            ]
        ]);

        $this->client = $clientBuilder->build();
    }

    public function createIndex(): array
    {
        $params = [
            'index' => $this->indexName,
            'body' => [
                'settings' => [
                    'number_of_shards' => 1,
                    'number_of_replicas' => 0
                ],
                'mappings' => [
                    'properties' => [
                        'make' => ['type' => 'keyword'],
                        'model' => ['type' => 'text'],
                        'year' => ['type' => 'integer'],
                        'price' => ['type' => 'float'],
                        'color' => ['type' => 'keyword'],
                        'description' => ['type' => 'text'],
                        'created_at' => ['type' => 'date', 'format' => 'yyyy-MM-dd HH:mm:ss']
                    ]
                ]
            ]
        ];

        try {
            if ($this->indexExists()) {
                return ['message' => 'Index already exists'];
            }
            return $this->client->indices()->create($params);
        } catch (\Exception $e) {
            throw new \RuntimeException('Failed to create index: ' . $e->getMessage());
        }
    }

    public function indexExists(): bool
    {
        try {
            return $this->client->indices()->exists(['index' => $this->indexName]);
        } catch (\Exception $e) {
            // Log the full error for debugging
            error_log('OpenSearch indexExists error: ' . $e->getMessage());
            error_log('OpenSearch host: ' . $this->opensearchHost);
            error_log('Exception class: ' . get_class($e));
            if ($e->getPrevious()) {
                error_log('Previous exception: ' . $e->getPrevious()->getMessage());
            }
            throw $e;
        }
    }

    public function indexCar(Car $car): array
    {
        $params = [
            'index' => $this->indexName,
            'body' => $car->toArray()
        ];

        if ($car->getId()) {
            $params['id'] = $car->getId();
        }

        try {
            $response = $this->client->index($params);

            // Set the ID from the response if not already set
            if (!$car->getId() && isset($response['_id'])) {
                $car->setId($response['_id']);
            }

            return $response;
        } catch (\Exception $e) {
            throw new \RuntimeException('Failed to index car: ' . $e->getMessage());
        }
    }

    public function searchCars(array $query = [], int $size = 10, int $from = 0): array
    {
        $params = [
            'index' => $this->indexName,
            'body' => [
                'query' => empty($query) ? ['match_all' => new \stdClass()] : $query,
                'size' => $size,
                'from' => $from
            ]
        ];

        try {
            return $this->client->search($params);
        } catch (\Exception $e) {
            throw new \RuntimeException('Failed to search cars: ' . $e->getMessage());
        }
    }

    public function getCar(string $id): ?array
    {
        $params = [
            'index' => $this->indexName,
            'id' => $id
        ];

        try {
            $response = $this->client->get($params);
            return $response['_source'] ?? null;
        } catch (\Exception $e) {
            return null;
        }
    }

    public function deleteCar(string $id): array
    {
        $params = [
            'index' => $this->indexName,
            'id' => $id
        ];

        try {
            return $this->client->delete($params);
        } catch (\Exception $e) {
            throw new \RuntimeException('Failed to delete car: ' . $e->getMessage());
        }
    }

    public function getClient(): Client
    {
        return $this->client;
    }
}

