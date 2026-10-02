<?php
require_once(__DIR__ . "/waiter.php");

class CheckQr extends PClass
{
    public function __construct()
    {
        parent::__construct();
    }

    public function checkDish()
    {
        if (strlen($this->params->qr) < 29) {
            $barcode = $this->params->qr;
        } else {
            if (substr($this->params->qr, 0, 6) == "000000") {
                $barcode = substr($this->params->qr, 6, 8);
            } else if (substr($this->params->qr, 0, 3) == "010") {
                if (substr($this->params->qr, 0, 8) == "01000000") {
                    $barcode = substr($this->params->qr, 8, 8);
                } else {
                    $barcode = substr($this->params->qr, 3, 13);
                }
            } else {
                $barcode = substr($this->params->qr, 1, 8);
            }
        }
        if (empty($barcode)) {
            return false;
        }
        $this->result["barcode_check"] = $barcode;


        $d = $this->stmtall("select * from d_dish where f_barcode regexp'(^|,)$barcode(,|$)'", "", )->fetch_assoc();
        if (empty($d)) {
            return false;
        }
        $m = $this->stmtall("select f_id, f_menu from d_menu where f_dish=? and f_state=1", "i", [$d["f_id"]])->fetch_all(MYSQLI_ASSOC);
        if (empty($m)) {
            $this->result["msg_m"] = "empty m";
            return false;
        }
        if (strlen($this->params->qr) >= 29) {
            $emarkDuplicate = $this->stmtall("select * from o_body where f_state=1 and f_emarks=?", "s", [$this->params->qr])->fetch_assoc();
            if (!empty($emarkDuplicate)) {
                $this->result["msg"] = $this->tr("Used Emark");
            }
        }
        $this->result["dishes"] = $m;
        $this->result["qr"] = $this->params->qr;
        $this->result["qrstatus"] = 1;
        $this->result["ean13"] = true; //strlen($this->params->qr) == 13 || !empty();
        $this->echoResult();
        return true;
    }

    public function checkQr()
    {
        if ($this->checkDish()) {
            return;
        }
        $this->result["qrstatus"] = 0;
        $this->echoResult();
    }
}

if (!empty($params->action)) {
    $cq = new CheckQr();
    $cq->{$params->action}();
}