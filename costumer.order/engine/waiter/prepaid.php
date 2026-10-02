<?php

require_once (__DIR__ . "/waiter.php");

class Prepaid extends DB
{
    public function __construct()
    {
        parent::__construct();

    }

    private function getPrepaid() {

    }

    private function savePrepaid() {
        
    }

    public function handle()
    {
        switch ($this->params->action) {
            case "get":
                $this->getPrepaid();
                break;
            case "save":
                $this->savePrepaid();
                break;
            default:
                $this->exitError("Go away, unpaid hacker!");
                break;
        }
    }
}

$prepaid = new Prepaid();
$prepaid->handle();