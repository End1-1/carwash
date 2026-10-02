<?php
require_once("carwash.php");

$result = queryStr("select sf_get_process_list('{\"f_menu\":$params->f_menu}')");
if ($row = $result->fetch_row()){ 
    printResult(1, $row);
} else {
    printResult(1, $result);
}