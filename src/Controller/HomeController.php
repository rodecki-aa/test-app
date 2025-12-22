<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Annotation\Route;

class HomeController extends AbstractController
{
    public function index(): Response
    {
        // Get encryption key from environment with a fallback
        $encryptionKey = $_ENV['ENCRYPTION_KEY'] ?? 'not-configured';

        return $this->render('home/index.html.twig', [
            'encryption_key' => $encryptionKey,
        ]);
    }
}
