<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Annotation\Route;
use Symfony\Component\DependencyInjection\ParameterBag\ParameterBagInterface;

class HomeController extends AbstractController
{
    public function __construct(
        private ParameterBagInterface $params
    ) {
    }

    public function index(): Response
    {
        return $this->render('home/index.html.twig', [
            'OPENSEARCH_HOST' => $this->params->get('opensearch.host'),
            'OPENSEARCH_USERNAME' => $this->params->get('opensearch.username'),
            'OPENSEARCH_PASSWORD' => $this->params->get('opensearch.password'),
        ]);
    }
}
