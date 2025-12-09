<?php

namespace App\Controller;

use App\Entity\Car;
use App\Service\OpenSearchService;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Serializer\SerializerInterface;

class CarController extends AbstractController
{
    public function __construct(
        private OpenSearchService $openSearchService,
        private SerializerInterface $serializer
    ) {
    }

    public function create(Request $request): JsonResponse
    {
        try {
            $data = json_decode($request->getContent(), true);

            if (!$data) {
                return $this->json(['error' => 'Invalid JSON'], Response::HTTP_BAD_REQUEST);
            }

            // Validate required fields
            $requiredFields = ['make', 'model', 'year', 'price'];
            foreach ($requiredFields as $field) {
                if (!isset($data[$field])) {
                    return $this->json(['error' => "Missing required field: $field"], Response::HTTP_BAD_REQUEST);
                }
            }

            // Create Car entity
            $car = new Car();
            $car->setMake($data['make']);
            $car->setModel($data['model']);
            $car->setYear((int)$data['year']);
            $car->setPrice((float)$data['price']);

            if (isset($data['color'])) {
                $car->setColor($data['color']);
            }

            if (isset($data['description'])) {
                $car->setDescription($data['description']);
            }

            // Ensure index exists
            if (!$this->openSearchService->indexExists()) {
                $this->openSearchService->createIndex();
            }

            // Index the car
            $response = $this->openSearchService->indexCar($car);

            return $this->json([
                'success' => true,
                'id' => $response['_id'] ?? $car->getId(),
                'data' => $car->toArray()
            ], Response::HTTP_CREATED);

        } catch (\Exception $e) {
            return $this->json([
                'error' => 'Failed to create car: ' . $e->getMessage()
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    public function list(Request $request): JsonResponse
    {
        try {
            $size = $request->query->getInt('size', 10);
            $from = $request->query->getInt('from', 0);
            $search = $request->query->get('search');

            $query = [];
            if ($search) {
                $query = [
                    'multi_match' => [
                        'query' => $search,
                        'fields' => ['make', 'model', 'description']
                    ]
                ];
            }

            $result = $this->openSearchService->searchCars($query, $size, $from);

            $cars = array_map(function($hit) {
                return array_merge(['id' => $hit['_id']], $hit['_source']);
            }, $result['hits']['hits'] ?? []);

            return $this->json([
                'success' => true,
                'total' => $result['hits']['total']['value'] ?? 0,
                'data' => $cars
            ]);

        } catch (\Exception $e) {
            return $this->json([
                'error' => 'Failed to retrieve cars: ' . $e->getMessage()
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    public function get(string $id): JsonResponse
    {
        try {
            $car = $this->openSearchService->getCar($id);

            if (!$car) {
                return $this->json(['error' => 'Car not found'], Response::HTTP_NOT_FOUND);
            }

            return $this->json([
                'success' => true,
                'data' => array_merge(['id' => $id], $car)
            ]);

        } catch (\Exception $e) {
            return $this->json([
                'error' => 'Failed to retrieve car: ' . $e->getMessage()
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    public function delete(string $id): JsonResponse
    {
        try {
            $this->openSearchService->deleteCar($id);

            return $this->json([
                'success' => true,
                'message' => 'Car deleted successfully'
            ]);

        } catch (\Exception $e) {
            return $this->json([
                'error' => 'Failed to delete car: ' . $e->getMessage()
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    public function initIndex(): JsonResponse
    {
        try {
            $result = $this->openSearchService->createIndex();

            return $this->json([
                'success' => true,
                'message' => 'Index created successfully',
                'result' => $result
            ]);

        } catch (\Exception $e) {
            return $this->json([
                'error' => 'Failed to create index: ' . $e->getMessage()
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }
}

