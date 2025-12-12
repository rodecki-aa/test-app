<?php

namespace App\Controller;

use App\Entity\Car;
use App\Service\OpenSearchService;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Annotation\Route;

#[Route('/api', name: 'api_')]
class ApiController extends AbstractController
{
    public function __construct(
        private OpenSearchService $openSearchService
    ) {
    }

    #[Route('/cars', name: 'cars_index', methods: ['GET'])]
    public function index(Request $request): JsonResponse
    {
        $size = $request->query->getInt('size', 10);
        $from = $request->query->getInt('from', 0);
        $search = $request->query->get('search', '');

        $query = [];
        if ($search) {
            $query = [
                'multi_match' => [
                    'query' => $search,
                    'fields' => ['make', 'model', 'description']
                ]
            ];
        }

        try {
            $result = $this->openSearchService->searchCars($query, $size, $from);

            return $this->json([
                'total' => $result['hits']['total']['value'] ?? 0,
                'cars' => array_map(function($hit) {
                    return array_merge(['id' => $hit['_id']], $hit['_source']);
                }, $result['hits']['hits'] ?? [])
            ]);
        } catch (\Exception $e) {
            return $this->json([
                'error' => $e->getMessage()
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    #[Route('/cars', name: 'cars_create', methods: ['POST'])]
    public function create(Request $request): JsonResponse
    {
        $data = json_decode($request->getContent(), true);

        if (!$data) {
            return $this->json([
                'error' => 'Invalid JSON data'
            ], Response::HTTP_BAD_REQUEST);
        }

        // Validate required fields
        $requiredFields = ['make', 'model', 'year', 'price'];
        foreach ($requiredFields as $field) {
            if (!isset($data[$field])) {
                return $this->json([
                    'error' => "Missing required field: $field"
                ], Response::HTTP_BAD_REQUEST);
            }
        }

        try {
            $car = new Car();
            $car->setMake($data['make']);
            $car->setModel($data['model']);
            $car->setYear($data['year']);
            $car->setPrice($data['price']);

            if (isset($data['color'])) {
                $car->setColor($data['color']);
            }
            if (isset($data['description'])) {
                $car->setDescription($data['description']);
            }

            $result = $this->openSearchService->indexCar($car);

            return $this->json([
                'message' => 'Car indexed successfully',
                'id' => $result['_id'] ?? null,
                'car' => $car->toArray()
            ], Response::HTTP_CREATED);
        } catch (\Exception $e) {
            return $this->json([
                'error' => $e->getMessage()
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    #[Route('/cars/{id}', name: 'cars_show', methods: ['GET'])]
    public function show(string $id): JsonResponse
    {
        try {
            $car = $this->openSearchService->getCar($id);

            if (!$car) {
                return $this->json([
                    'error' => 'Car not found'
                ], Response::HTTP_NOT_FOUND);
            }

            return $this->json([
                'id' => $id,
                'car' => $car
            ]);
        } catch (\Exception $e) {
            return $this->json([
                'error' => $e->getMessage()
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    #[Route('/cars/{id}', name: 'cars_delete', methods: ['DELETE'])]
    public function delete(string $id): JsonResponse
    {
        try {
            $result = $this->openSearchService->deleteCar($id);

            return $this->json([
                'message' => 'Car deleted successfully',
                'result' => $result
            ]);
        } catch (\Exception $e) {
            return $this->json([
                'error' => $e->getMessage()
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    #[Route('/opensearch/create-index', name: 'opensearch_create_index', methods: ['POST'])]
    public function createIndex(): JsonResponse
    {
        try {
            $result = $this->openSearchService->createIndex();

            return $this->json([
                'message' => 'Index created successfully',
                'result' => $result
            ]);
        } catch (\Exception $e) {
            return $this->json([
                'error' => $e->getMessage()
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    #[Route('/opensearch/health', name: 'opensearch_health', methods: ['GET'])]
    public function health(): JsonResponse
    {
        try {
            $indexExists = $this->openSearchService->indexExists();

            return $this->json([
                'status' => 'connected',
                'index_exists' => $indexExists,
                'index_name' => 'cars'
            ]);
        } catch (\Exception $e) {
            return $this->json([
                'status' => 'error',
                'error' => $e->getMessage()
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }
}

