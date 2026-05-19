<?php
# © 2024 - 2025, Kudryashov Vasili
# Last modified - 2025-05-11 18:53:00
require_once __DIR__ . "/waiter.php";

class StopList extends DB
{
    private $translator;
    public function __construct()
    {
        parent::__construct();
        $this->translator = new DBTranslator();
    }

    public function removeStopList()
    {
        $v = $this->params->hostinfo;
        $v["date"] = date("Y-m-d");
        $v["time"] = date("H:i:s");
        $v["type"] = 1;
        $v["user"] = $this->user["f_last"] . " " . $this->user["f_first"];
        $v["rec"] = "";
        $v["invoice"] = "";
        $v["reservation"] = "";
        $v["action"] = "Stop list was removed";
        $v["value1"] = "";
        $v["value2"] = "";
        $this->echoResult();
    }

    public function getStopList()
    {
        $stoplist = $this->stmtall("select f_dish, f_qty from d_stoplist")->fetch_all(MYSQLI_ASSOC);
        $this->result["list"] = $stoplist;
        $this->echoResult();
    }

    public function set()
    {
        $this->stmtall("delete from d_stoplist where f_dish=?", "i", [$this->params->f_dish]);
        $v["f_dish"] = $this->params->f_dish;
        $v["f_qty"] = $this->params->f_qty;
        $this->sinsert("d_stoplist", $v);
        $this->result["f_dish"] = $this->params->f_dish;
        $this->result["f_qty"] = $this->params->f_qty;
        $this->echoResult();
    }

    public function removeDish()
    {
        $this->stmtall("delete from d_stoplist where f_dish=?", "i", [$this->params->f_dish]);
        $this->result["f_dish"] = $this->params->f_dish;
        $this->echoResult();
    }

    public function restoreQty($echo = true)
    {
        $row = $this->stmtall("select * from d_stoplist where f_dish=?", "i", [$this->params->f_dish])->fetch_assoc();
        $this->result["f_dish"] = $this->params->f_dish;
        $this->result["f_qty"] = $this->params->f_qty;
        if (empty($row)) {
            $this->echoResult();
            return;
        }
        $this->stmtall("update d_stoplist set f_qty=? where f_dish=?", "di", [$row["f_qty"] + $this->params->f_qty, $this->params->f_dish]);
        $this->result["ok"] = true;
        $this->result["f_qty"] = $this->params->f_qty + $row["f_qty"];
        $this->result["f_dish"] = $this->params->f_dish;
        if ($echo) {
            $this->echoResult();
        }
    }

    public function add()
    {
        $this->set();
    }

    public function check()
    {
        #check emark first. strange, but thats is
        if (strlen($this->params->emark) > 0) {
            $e = $this->stmtall("select f_id from o_body where f_emarks=?", "s", [$this->params->emark])->fetch_assoc();
            if (!empty($e)) {
                $this->exitError($this->translator->tr("Emark duplicate"));
            }
        }
        $this->result["f_dish"] = $this->params->f_dish;
        $this->result["f_menu"] = $this->params->f_menu;
        $this->result["emark"] = $this->params->emark;
        $row = $this->stmtall("select * from d_stoplist where f_dish=?", "i", [$this->params->f_dish])->fetch_assoc();
        if (empty($row)) {
            $this->result["ok"] = true;
            $this->echoResult();
            return;
        }
        if ($row["f_qty"] - $this->params->f_qty < 0) {
            $this->exitError($this->translator->tr("Stop quantity reached"));
        }
        $row["f_qty"] = $row["f_qty"] - $this->params->f_qty;
        $this->stmtall("update d_stoplist set f_qty=? where f_dish=?", "di", [$row["f_qty"], $this->params->f_dish]);
        $this->result["f_newqty"] = $row["f_qty"];
        $this->echoResult();
    }

    public function execute()
    {
        switch ($this->params->action) {
            case "remove":
                $this->removeStopList();
                break;
            case "get":
                $this->getStopList();
                break;
            case "set":
                $this->set();
                break;
            case "removedish":
                $this->removeDish();
                break;
            case "restoreqty":
                $this->restoreQty();
                break;
            case "add":
                $this->add();
                break;
            case "check":
                $this->check();
                break;
        }
    }
}

$stopList = new StopList();
$stopList->execute();