<?php
# (C) 2024 - 2025 Kudryashov Vasili
# Created - 2025-05-04 22:47:10
# Last modified - 2025-05-04 22:47:07
require_once __DIR__ . "/../app.php";

const ORDER_STATE_OPEN = 1;
const ORDER_STATE_PREORDER_EMPTY = 5;
const ORDER_STATE_PREORDER_WITH_ORDER = 6;
const DISH_STATE_OK = 1;
const DISH_STATE_SET = 4;
const FORMAT_DATE_TO_STR = "d/m/Y";  
const FORMAT_TIME_TO_STR = "H:i"; 