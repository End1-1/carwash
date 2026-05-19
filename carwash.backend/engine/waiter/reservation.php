<?php
require_once (__DIR__ . "/../app.php");

class Reservation extends PClass
{
    private $id;
    function __construct()
    {
        parent::__construct();
        if (empty($this->params->id)) {
            $this->params->id = 0;
        }
        $this->id = $this->params->id;
    }

    function open($id)
    {
        $this->result["header"] = $this->stmtall("select oh.*, t.f_name as f_tablename, h.f_name as f_hallname "
            . "from o_header oh "
            . "left join h_tables t on t.f_id=oh.f_table "
            . "left join h_halls h on h.f_id=oh.f_hall "
            . "where oh.f_id=?", "s", [$this->id])->fetch_assoc();
        $this->result["preorder"] = $this->stmtall("select * from o_preorder where f_id=?", "s", [$this->id])->fetch_assoc();
        $this->result["hoteldata"] = $this->stmtall("select oh.*, mp.f_name as f_mealplanname, vm.f_name as f_vatmodename "
            . "from o_header_hotel oh "
            . "left join o_meal_plan mp on mp.f_id=oh.f_mealplan "
            . "left join o_vat_mode vm on vm.f_id=oh.f_vatmode "
            . "where oh.f_id=?", "s", [$this->id])->fetch_assoc();
        $this->result["config"] = json_decode($this->stmtall("select f_config from sys_json_config limit 1")->fetch_row()[0]);
        $this->echoResult();
    }

    function save()
    {
        $isnew = empty($this->id);
        if ($isnew) {
            $this->id = $this->uuidv4();
            $prefix = "";
            $hallid = 0;
            $this->oheaderCounter($prefx, $hallid, $this->params->header->f_hall);
            $this->params->header->f_prefix = $prefix;
            $this->params->header->f_hallid = $hallid;
        }

        $datestart = new DateTimeImmutable($this->params->hoteldata->f_checkin);
        $datenext = $datestart;
        $dateend = new DateTimeImmutable($this->params->hoteldata->f_checkout);

        $check = $this->stmtall(
            "select oh.f_id "
            . "from o_header oh "
            . "left join o_header_hotel ohh on ohh.f_id=oh.f_id "
            . "where oh.f_id<>? and ? between ohh.f_checkin and DATE_ADD(ohh.f_checkout, INTERVAL -1 DAY) "
            . "and oh.f_table=? and oh.f_state in (1,5,6)",
            "ssi",
            [
                $this->id,
                $this->params->hoteldata->f_checkin,
                $this->params->header->f_table
            ]
        )->fetch_all();
        if (!empty($check)) {
            $this->exitError($this->tr->tr("Reservation exists on selected entry date"));
        }

        $this->db->begin_transaction();
        $v["f_id"] = $this->id;
        $v["f_state"] = $this->params->header->f_state;
        $v["f_prefix"] = $this->params->header->f_prefix;
        $v["f_hallid"] = $this->params->header->f_hallid;
        $v["f_table"] = $this->params->header->f_table;
        $v["f_hall"] = $this->params->header->f_hall;
        $v["f_dateopen"] = date("Y-m-d");
        $v["f_timeopen"] = date("H:i:s");
        $v["f_cashier"] = $this->userid;
        $v["f_staff"] = $this->userid;
        $v["f_precheck"] = 0;
        $v["f_print"] = 0;
        $v["f_guests"] = $this->params->header->f_guests;
        $v["f_comment"] = "";
        $this->sinsertupdate("o_header", $v, $this->id, $isnew);

        $v["f_id"] = $this->id;
        $this->sinsertupdate("o_header_options", $v, $this->id, $isnew);
        $v["f_id"] = $this->id;
        $this->sinsertupdate("o_tax", $v, $this->id, $isnew);
        $v["f_id"] = $this->id;
        $this->sinsertupdate("o_pay_cl", $v, $this->id, $isnew);
        $v["f_id"] = $this->id;
        $this->sinsertupdate("o_pay_room", $v, $this->id, $isnew);
        $v["f_id"] = $this->id;
        $this->sinsertupdate("o_header_flags", $v, $this->id, $isnew);
        $v["f_id"] = $this->id;
        $this->sinsertupdate("o_payment", $v, $this->id, $isnew);
        $v = get_object_vars($this->params->preorder);
        $v["f_id"] = $this->id;
        $this->sinsertupdate("o_preorder", $v, $this->id, $isnew);
        $v = get_object_vars($this->params->hoteldata);
        $v["f_id"] = $this->id;
        $this->sinsertupdate("o_header_hotel", $v, $this->id, $isnew);

        $this->stmtall("delete from o_header_hotel_date where f_header=?", "s", [$this->id]);
        if ($datestart > $dateend) {
            $this->exitError(tr("Invalid entry date"));
        }
        do {
            $v["f_header"] = $this->id;
            $v["f_date"] = $datenext->format("Y-m-d");
            $v["f_1"] = $datestart < $datenext ? 1 : 0;
            $v["f_2"] = $dateend > $datenext ? 1 : 0;
            $this->sinsert("o_header_hotel_date", $v);
            $datenext = $datenext->modify('+1 day');

        } while ($datenext < $dateend->modify("+1 day"));

        $this->db->commit();
        if ($this->params->checkin) {
            $this->checkin();
        } else {
            $this->open($this->id);
        }

    }

    function checkin()
    {
        if (empty($this->params->table)) {
            $this->params->table = $this->params->header->f_table;
        }
        $current = $this->stmtall("select f_id from o_header where f_state=? and f_table=?", "ii", [1, $this->params->table])->fetch_assoc();
        if (!empty($current)) {
            exitError(tr("Cannot checkin, an opened order exists"));
        }
        $this->stmtall("update o_header set f_state=1 where f_id=?", "s", [$this->id]);
        $this->result["withcheckin"] = true;
        $this->echoResult();
    }

    function cancel()
    {
        $this->db->begin_transaction();
        $this->stmtall("update o_header set f_state=3 where f_id=?", "s", [$this->id]);
        $this->stmtall("update o_body set f_state=2 where f_header=? and f_state=1", "s", [$this->id]);
        $this->db->commit();
        $this->echoResult();
    }

    public function list()
    {
        $out = $this->stmtall("select oh.f_id, oh.f_state, t.f_name as f_tableforname, os.f_name as f_statename, ohd.f_checkin, ohd.f_checkout, ohd.f_roomrate, "
            . "ohd.f_guestcount, ohd.f_remarks, p.f_guestname, p.f_phone, p.f_email, p.f_passport, "
            . "oh.f_table, p.f_fortable "
            . "from o_header oh "
            . "left join o_state os on os.f_id=oh.f_state "
            . "left join o_preorder p on p.f_id=oh.f_id "
            . "left join o_header_hotel ohd on ohd.f_id=oh.f_id "
            . "left join h_tables t on t.f_id=p.f_fortable "
            . "left join h_halls h on h.f_id=t.f_hall "
            . "where oh.f_state in (1,5,6)  "
            . "order by p.f_datefor, p.f_fortable, p.f_timefor ")->fetch_all(MYSQLI_ASSOC);
        $this->result["out"] = $out;
        $this->echoResult();
    }

    public function history()
    {
        $out = [];
        $groupdate = "date_format(b.f_working_day, '%d/%m/%Y')";
        switch ($this->params->groupping) {
            case 0:
                $groupdate = "date_format(b.f_working_day, '%d/%m/%Y')";
                break;
            case 1:
                $groupdate = "DATE_FORMAT(b.f_working_day, '%m/%Y')";
                break;
            case 2:
                $groupdate = "DATE_FORMAT(b.f_working_day, '%Y')";
                break;
        }
        $revenue = $this->stmtall(
            "select $groupdate as d, sum(f_total) as f_total "
            . "from o_body b "
            . "left join o_header oh on oh.f_id=b.f_header "
            . "left join o_preorder p on p.f_id=oh.f_id "
            . "left join o_header_hotel ohh on ohh.f_id=oh.f_id "
            . "where oh.f_state in (1,2) and b.f_state=1 "
            . "and b.f_working_day between ? and ? "
            . "group by 1 ",
            "ss",
            [$this->params->d1, $this->params->d2]
        )->fetch_all(MYSQLI_ASSOC);
        $guests = $this->stmtall(
            "select $groupdate as d,  cast(sum(ohh.f_guestcount) as int) as f_total "
            . "from o_body b "
            . "left join o_header oh on oh.f_id=b.f_header "
            . "left join o_preorder p on p.f_id=oh.f_id "
            . "left join o_header_hotel ohh on ohh.f_id=oh.f_id "
            . "where oh.f_state in (1,2) and b.f_state=1 "
            . "and b.f_working_day  between ? and ? "
            . "group by 1 ",
            "ss",
            [$this->params->d1, $this->params->d2]
        )->fetch_all(MYSQLI_ASSOC);
        foreach ($revenue as $r) {
            $out[$r["d"]]["revenue"] = $r["f_total"];
        }
        foreach ($guests as $g) {
            $out[$g["d"]]["guests"] = $g["f_total"];
        }
        $this->result["out"] = $out;
        $this->echoResult();
    }

    public function forecast()
    {
        $out = [];
        $groupdate = "date_format(f_date, '%d/%m/%Y')";
        switch ($this->params->groupping) {
            case 0:
                $groupdate = "date_format(f_date, '%d/%m/%Y')";
                break;
            case 1:
                $groupdate = "DATE_FORMAT(f_date, '%m/%Y')";
                break;
            case 2:
                $groupdate = "DATE_FORMAT(f_date, '%Y')";
                break;
        }
        $this->db->begin_transaction();
        $this->stmtall("CREATE TEMPORARY TABLE forecast (f_date DATE, f_guests INT, f_rate float);");
        $this->stmtall("INSERT INTO FORECAST(f_date, f_guests, f_rate)  "
            . "WITH RECURSIVE d AS "
            . "(SELECT ? AS dt "
            . "UNION ALL "
            . " SELECT dt + INTERVAL 1 DAY "
            . " FROM d WHERE dt <?) "
            . " SELECT dt, coalesce(ohh.f_guestcount, 0), coalesce(ohh.f_roomrate , 0) "
            . "FROM d "
            . "LEFT JOIN o_header_hotel ohh ON d.dt BETWEEN ohh.f_checkin AND ohh.f_checkout "
            . "LEFT JOIN o_header oh ON oh.f_id=ohh.f_id "
            . "WHERE oh.f_state IN (5,6);", "ss", [$this->params->d1, $this->params->d2]);
        $out = $this->stmtall("select $groupdate as dt,  cast(coalesce(sum(f_guests), 0) as int) as guests, "
            . "coalesce(sum(f_rate), 0) as total "
            . "from forecast "
            . "group by 1 "
            . "order by f_date ")->fetch_all(MYSQLI_ASSOC);
        $this->db->commit();
        $this->result["out"] = $out;
        $this->echoResult();
    }
}