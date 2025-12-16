<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\DependencyInjection\Attribute\Autowire;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Annotation\Route;

class HomeController extends AbstractController
{
    public function index(
        #[Autowire(env: 'ENCRYPTION_KEY')]
        string $encryptionKey
    ): Response
    {
        return $this->render('home/index.html.twig', [
            'encryption_key' => $encryptionKey,
        ]);
    }
}
