<?php
# (C) 2025 Kudryashov Vasili
# Last modified - 2025-05-09 13:43:31
require_once __DIR__ . "/../../app.php";

class WaiterReport extends PClass {
    public function __construct() {
        parent::__construct();
    }

    public function list() {
        $list = [
            ["caption" => $this->tr->tr("Daily revenue"), "file" => "daily-revenue"],
            ["caption" => $this->tr->tr("Departments revenue"), "file" => "departments-revenue"],
        ];   
        $this->result["list"] = $list;
        $this->echoResult();             
    }
}