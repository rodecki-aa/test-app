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
        $hosts = [$this->opensearchHost];

        $clientBuilder = ClientBuilder::create()
            ->setHosts($hosts);

        // Add basic auth if credentials are provided
        if ($this->opensearchUsername && $this->opensearchPassword) {
            $clientBuilder->setBasicAuthentication($this->opensearchUsername, $this->opensearchPassword);
        }

        // AWS OpenSearch VPC endpoints use self-signed certificates
        // Disable SSL verification for both dev and prod when using AWS
        $clientBuilder->setSSLVerification(false);

        // Configure timeouts to prevent hanging requests
        // Connection timeout: time to establish connection (5 seconds)
        // Request timeout: time for entire request (30 seconds)
        $clientBuilder->setConnectionParams([
            'client' => [
                'curl' => [
                    CURLOPT_CONNECTTIMEOUT => 5,  // Connection timeout in seconds
                    CURLOPT_TIMEOUT => 30,        // Total request timeout in seconds
                ]
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
        return $this->client->indices()->exists(['index' => $this->indexName]);
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

