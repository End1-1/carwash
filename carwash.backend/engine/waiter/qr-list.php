<?php

require_once (__DIR__ . "/waiter.php");

class QrList extends PClass
{
    public function __construct()
    {
        parent::__construct();
    }

    public function list()
    {
        $dish = $this->stmtall("select f_id, f_name from d_dish where f_id=?", "i", [$this->params->dishid])->fetch_assoc();
        if (empty($dish)) {
            $this->exitError("No result with {$this->params->dishid}");
        }
        $qrlist = $this->stmtall("select f_id, f_date, f_time, f_emarks,cast(f_qty as float) as f_qty, cast(f_remain as float) as f_remain "
            . "from d_qr_list where f_dish=? order by f_date desc, f_time", "i", [$this->params->dishid])->fetch_all(MYSQLI_ASSOC);
        $this->result["dish"] = $dish["f_name"];
        $this->result["qrlist"] = $qrlist;
        $this->echoResult();
    }

    public function add()
    {
        $check = $this->stmtall("select f_id from o_body where f_emarks=? and length(f_emarks)>0", "s", [$this->params->emarks])->fetch_all();
        if (!empty($check)) {
            $this->exitError($this->tr("This emarks already used"));
        }
        $v["f_emarks"] = $this->params->emarks;
        $this->supdate("o_body", $v, $this->params->bodyid);
        $this->result["bodyid"] =  $this->params->bodyid;
        $this->result["emarks"] = $this->params->emarks;
        $this->echoResult();
    }

    public function remove() {
        $this->stmtall("delete from d_qr_list where f_id=?", "i", [$this->params->id]);
        $this->echoResult();
    }
}

if (!empty($params->action)) {
    $qr = new QrList();
    $qr->{$params->action}();
}