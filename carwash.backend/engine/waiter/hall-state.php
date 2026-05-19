<?php
require_once (__DIR__ . "/waiter.php");

class HallState extends DB
{
    public function __construct()
    {
        parent::__construct();
        global $params;
        $this->params = $params;
    }

    public function getData()
    {
        #plain tables
        $where = "";
        if (!empty($this->params->staff) && ($this->params->staff > 0)) {
            $where .= " and oh.f_staff={$this->params->staff} ";
        }
        if (empty ($this->params->date)) {
            $this->params->date = date("Y-m-d");
        }
        $h = $this->stmtall("select oh.f_id, date_format(oh.f_dateopen, '%d/%m/%Y') as f_dateopen, oh.f_timeopen, "
            . "oh.f_comment, oh.f_precheck, oh.f_print, cast(oh.f_amounttotal as float) as f_amounttotal, "
            . "oh.f_staff, concat(u.f_last, left(u.f_first, 1), '.') as f_staffname,  "
            . "date_format(od.f_checkin, '%d/%m/%Y') as f_checkin, date_format(od.f_checkout, '%d/%m/%Y')as f_checkout, "
            . "op.f_guestname, cast(op.f_prepaidcash+op.f_prepaidcard as float) as f_prepaid, "
            . "oh.f_state, oh.f_table, ft.f_name as f_fortablename, t.f_name as f_tablename "
            . "from o_header oh "
            . "left join s_user u on u.f_id=oh.f_staff "
            . "left join o_preorder op on op.f_id=oh.f_id "
            . "left join o_header_hotel od on od.f_id=oh.f_id "
            . "left join h_tables t on t.f_id=oh.f_table "
            . "left join h_tables ft on ft.f_id=op.f_fortable "
            . "where (oh.f_state=1) or (oh.f_state in (5,6) and od.f_checkin<=?) $where ", "s", [$this->params->date])->fetch_all(MYSQLI_ASSOC);
        $ht = [];
        foreach ($h as $d) {
            $ht[$d["f_table"]] = $d;
        }
        return $ht;
    }

    public function get()
    {

        $this->result["data"] = $this->getData();
        $this->echoResult();
    }
}

if (!defined("noout")) {
    $hallstate = new HallState();
    $hallstate->get();
}