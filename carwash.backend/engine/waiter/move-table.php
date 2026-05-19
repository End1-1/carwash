<?php
require_once(__DIR__ . "/waiter.php");

class MoveTable extends PClass
{
    public function __construct()
    {
        parent::__construct();
    }

    public function moveTable()
    {
        $this->db->begin_transaction();
        $ct = $this->stmtall("select * from h_tables where f_id=? for update", "i", [$this->params->oldtable])->fetch_assoc();
        $nt = $this->stmtall("select * from h_tables where f_id=? for update", "i", [$this->params->newtable])->fetch_assoc();
        #check if table locked by other host
        if (!empty($nt["f_locksrc"])) {
            if ($nt["f_locksrc"] != $this->params->hostinfo) {
                $this->exitError($this->tr("Table locked") . "<br>" . $nt["f_locksrc"]);
            }
        }
        #check dst table is empty. if not empty return, becouse for this we have other tool
        $dstord = $this->stmtall("select f_id from o_header where f_table=? and f_state=1", "i", [$this->params->newtable])->fetch_assoc();
        if (!empty($dstord)) {
            $this->exitError($this->tr("Destination table is not empty. Use 'move items tool'"));
        }
        $this->stmtall("update h_tables set f_locktime=current_timestamp(), f_locksrc=? where f_id=?", "si", 
        [$this->params->hostinfo, $this->params->newtable]);
        $this->stmtall("update h_tables set f_locksrc=null where f_id=?", "i", [$this->params->oldtable]);
        $this->stmtall(
            "update o_header set f_table=?, f_hall=? where f_id=?",
            "iis",
            [$this->params->newtable, $nt["f_hall"], $this->params->order]
        );
        $p["f_comp"] = $this->params->hostinfo;
        $p["f_date"] = date("Y-m-d");
        $p["f_time"] = date("H:i:s");
        $p["f_user"] = $this->user["f_first"] . " " . $this->user["f_last"];
        $p["f_type"] = 1;
        $p["f_rec"] = $this->params->order;
        $p["f_invoice"] = $this->params->order;
        $p["f_action"] = "Move table";
        $p["f_value1"] = $ct["f_name"];
        $p["f_value2"] = $nt["f_name"];
        $this->sinsert("log", $p);
        $this->db->commit();
        $this->result["newTableId"] = $this->params->newtable;
        $this->echoResult();
    }
}

if (!empty($params->action)) {
    $mt = new MoveTable();
    $mt->{$params->action}();
}