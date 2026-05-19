<?php
require_once __DIR__ . "/../app.php";

class OOrder extends DB
{

    private $translator;
    private $orderid;
    private $current_staff;
    private $config;
    public function __construct()
    {
        global $params;
        parent::__construct();
        $this->params = $params;
        $this->translator = new DBTranslator();
        $this->orderid = empty($params->orderid) ? "" : $params->orderid;
        $this->current_staff = $this->user["f_id"];
    }

    public function getConfig()
    {
        if (empty($this->config)) {
            $t = $this->stmtall("select f_hall from h_tables where f_id=?", "i", [$this->params->table])->fetch_assoc();
            $this->config["hall"] = $t["f_hall"];
            $t = $this->stmtall("select f_key, f_value from s_settings_values where f_settings=(select f_settings from h_halls where f_id=?)", "i", [$this->config["hall"]])->fetch_all(MYSQLI_ASSOC);
            foreach ($t as $kv) {
                $this->config[$kv["f_key"]] = $kv["f_value"];
            }
        }
        return $this->config;
    }

    public function open()
    {
        $this->beginTransaction();
        #try lock
        $table = $this->stmtall("select t.* "
            . "from h_tables t "
            . "where t.f_id=? for update", "i", [$this->params->table])->fetch_assoc();
        #TODO  check lock time
        if (!empty($table["f_locksrc"]) && $table["f_locksrc"] != $this->params->locksrc) {
            $this->commit();
            $this->exitError($this->translator->tr("Table locked by another pc"));
        }
        $this->commit();
        $this->stmtall("update h_tables set f_locksrc=?, f_locktime=current_timestamp() where f_id=?", "si", [$this->params->locksrc, $this->params->table]);
        $order = $this->stmtall("select o.f_id from o_header o where o.f_table=? and o.f_state=1", "i", [$this->params->table])->fetch_assoc();
        if (empty($order)) {
            if ($this->params->createifempty) {
                $this->create();
            } else {
                if (empty($this->params->comfirmcreate)) {
                    $this->result["table"] = $this->params->table;
                    $this->result["confirmcreate"] = true;
                    $this->echoResult();
                    return;
                } else {
                    $this->create();
                }
            }
        } else {
            $this->orderid = $order["f_id"];
            $this->stmtall("update o_header set f_currentstaff=? where f_id=?", "is", [$this->user["f_id"], $this->orderid]);
        }
        $header = $this->stmtall("select * from o_header where f_id=?", "s", [$this->orderid])->fetch_assoc();
        $headerOptions = $this->stmtall("select * from o_header_options where f_id=?", "s", [$this->orderid])->fetch_assoc();
        if (empty($headerOptions)) {
            $this->stmtall("insert into o_header_options (f_id) values (?)", "s", [$this->orderid]);
            $headerOptions = $this->stmtall("select * from o_header_options where f_id=?", "s", [$this->orderid])->fetch_assoc();
        }
        $otax = $this->stmtall("select * from o_tax where f_id=?", "s", [$this->orderid])->fetch_assoc();
        if (empty($otax)) {
            $this->stmtall("insert into o_tax (f_id) values (?)", "s", [$this->orderid]);
            $otax = $this->stmtall("select * from o_tax where f_id=?", "s", [$this->orderid])->fetch_assoc();
        }
        $oroom = $this->stmtall("select * from o_pay_room where f_id=?", "s", [$this->orderid])->fetch_assoc();
        if (empty($oroom)) {
            $this->stmtall("insert into o_pay_room (f_id) values (?)", "s", [$this->orderid]);
            $oroom = $this->stmtall("select * from o_pay_room where f_id=?", "s", [$this->orderid])->fetch_assoc();
        }
        $opaycl = $this->stmtall("select * from o_pay_cl where f_id=?", "s", [$this->orderid])->fetch_assoc();
        if (empty($opaycl)) {
            $this->stmtall("insert into o_pay_cl (f_id) values (?)", "s", [$this->orderid]);
            $opaycl = $this->stmtall("select * from o_pay_cl where f_id=?", "s", [$this->orderid])->fetch_assoc();
        }
        $opreorder = $this->stmtall("select * from o_preorder where f_id=?", "s", [$this->orderid])->fetch_assoc();
        if (empty($opreorder)) {
            $this->stmtall("insert into o_preorder (f_id) values (?)", "s", [$this->orderid]);
            $opreorder = $this->stmtall("select * from o_preorder where f_id=?", "s", [$this->orderid])->fetch_assoc();
        }
        $dishes = $this->stmtall("select ob.*, d.f_name "
            . "from o_body ob "
            . "left join d_dish d on d.f_id=ob.f_dish "
            . "where ob.f_state>0 and ob.f_header=? order by ob.f_row, ob.f_appendtime ", "s", [$this->orderid])->fetch_all(MYSQLI_ASSOC);
        $oheaderhotel = $this->stmtall("select * from o_header_hotel where f_id=?", "s", [$this->orderid])->fetch_assoc();


        $stopList = $this->stmtall("select f_dish, f_qty from d_stoplist")->fetch_all(MYSQLI_ASSOC);

        $v["f_comp"] = $this->params->hostinfo;
        $v["f_date"] = date("Y-m-d");
        $v["f_time"] = date("H:i:s");
        $v["f_type"] = 1;
        $v["f_user"] = $this->user["f_last"] . " " . $this->user["f_first"];
        $v["f_rec"] = $this->orderid;
        $v["f_invoice"] = $this->orderid;
        $v["f_reservation"] = "";
        $v["f_action"] = "Open order";
        $v["f_value1"] = "";
        $v["f_value2"] = "";
        $this->sinsert("log", $v);

        echo json_encode(
            [
                "status" => 1,
                "table" => $table,
                "header" => $header,
                "headerOptions" => $headerOptions,
                "otax" => $otax,
                "oroom" => $oroom,
                "opaycl" => $opaycl,
                "opreorder" => $opreorder,
                "dishes" => $dishes,
                "oheaderHotel" => $oheaderhotel,
                "stopList" => $stopList,
            ],
            JSON_UNESCAPED_UNICODE
        );
    }

    public function close() {
        
    }

    public function create()
    {
        $c = $this->getConfig();
        $this->beginTransaction();
        $this->orderid = $this->uuidv4();
        $v["f_id"] = $this->orderid;
        $this->sinsert("o_header_options", $v);
        $v["f_id"] = $this->orderid;
        $this->sinsert("o_tax", $v);
        $v["f_id"] = $this->orderid;
        $this->sinsert("o_pay_cl", $v);
        $v["f_id"] = $this->orderid;
        $this->sinsert("o_pay_room", $v);
        $v["f_id"] = $this->orderid;
        $this->sinsert("o_header_flags", $v);
        $v["f_id"] = $this->orderid;
        $this->sinsert("o_payment", $v);
        $v["f_id"] = $this->orderid;
        $this->sinsert("o_preorder", $v);
        $v["f_id"] = $this->orderid;
        $v["f_checkin"] = date("Y-m-d");
        $v["f_checkout"] = date("Y-m-d");
        $this->sinsert("o_header_hotel", $v);
        $v["f_header"] = $this->orderid;
        $v["f_date"] = date("Y-m-d");
        $v["f_1"] = 0;
        $v["f_2"] = 1;
        $this->sinsert("o_header_hotel_date", $v);

        $hall = $this->stmtall("select f_hall, f_name from h_tables where f_id=?", "i", [$this->params->table])->fetch_assoc();
        $counter = $this->stmtall("select h.f_counterhall, h.f_id, h.f_prefix, h2.f_counter + 1 as f_counter "
            . "from h_halls h "
            . " left join h_halls h2 on h2.f_id=h.f_counterhall "
            . "where h.f_id=? for update", "i", [$hall["f_hall"]])->fetch_assoc();
        if (empty($counter)) {
            $this->rollback();
            $this->exitError("NO COUNTER FOR THIS HALL {$hall["f_hall"]}");
        }
        $hallid = $counter["f_counter"];
        $prefix = $counter["f_prefix"];
        $this->stmtall("update h_halls set f_counter=? where f_id=?", "ii", [$hallid, $counter["f_counterhall"]]);

        $v["f_id"] = $this->orderid;
        $v["f_cashier"] = $this->params->current_staff;
        $v["f_staff"] = $this->params->current_staff;
        $v["f_table"] = $this->params->table;
        $v["f_prefix"] = $prefix;
        $v["f_hallid"] = $hallid;
        $v["f_datecash"] = date("Y-m-d");
        $v["f_dateopen"] = date("Y-m-d");
        $v["f_timeopen"] = date("H:i:s");
        $v["f_currentstaff"] = $this->params->current_staff;
        $v["f_state"] = 1;
        $v["f_precheck"] = 0;
        $v["f_print"] = 0;
        $v["f_guests"] = 0;
        $v["f_comment"] = "";
        $v["f_hall"] = $hall["f_hall"];
        $v["f_amounttotal"] = 0;
        $v["f_amountcash"] = 0;
        $v["f_amountcard"] = 0;
        $v["f_amountbank"] = 0;
        $v["f_amountother"] = 0;
        $v["f_amountservice"] = 0;
        $v["f_amountdiscount"] = 0;
        $v["f_servicefactor"] = floatval($c["2"]);
        $v["f_discountfactor"] = 0;
        $this->sinsert("o_header", $v);
        $this->commit();

        $v["f_comp"] = $this->params->hostinfo;
        $v["f_date"] = date("Y-m-d");
        $v["f_time"] = date("H:i:s");
        $v["f_type"] = 1;
        $v["f_user"] = $this->user["f_last"] . " " . $this->user["f_first"];
        $v["f_rec"] = $this->orderid;
        $v["f_invoice"] = $this->orderid;
        $v["f_reservation"] = "";
        $v["f_action"] = "New order";
        $v["f_value1"] = $prefix . $hallid;
        $v["f_value2"] = $hall["f_name"];
        $this->sinsert("log", $v);

    }

    public function addDish()
    {
        $id = $this->uuidv4();
        $v["f_id"] = $id;
        $v["f_header"] = $this->params->header;
        $v["f_state"] = 1;
        $v["f_dish"] = $this->params->dish;
        $v["f_qty1"] = 1;
        $v["f_qty2"] = 0;
        $v["f_price"] = $this->params->price;
        $v["f_service"] = $this->params->canservice == 0 ? 0 : $this->params->service_factor;
        $v["f_discount"] = $this->params->discount;
        $v["f_total"] = $this->params->price;
        $v["f_grandtotal"] = $this->params->price;
        $v["f_store"] = $this->params->store;
        $v["f_print1"] = $this->params->print1;
        $v["f_print2"] = $this->params->print2;
        $v["f_comment"] = "";
        $v["f_adgcode"] = $this->params->adgcode;
        $v["f_appendtime"] = date("Y-m-d H:i:s");
        $v["f_canservice"] = $this->params->canservice;
        $v["f_candiscount"] = $this->params->candiscount;
        $v["f_appenduser"] = $this->user["f_id"];
        $v["f_emarks"] = $this->params->emarks;
        $v["f_working_day"] = $this->params->f_working_day;
        $this->result["obody"] = $v;
        $this->sinsert("o_body", $v);
        $this->echoResult();
    }

    public function modifyDish()
    {
        $v["f_qty1"] = $this->params->qty1;
        $v["f_comment"] = $this->params->comment;
        $this->supdate("o_body", $v, $this->params->id);
        $this->echoResult();
    }

    public function removeDish()
    {
        $this->stmtall("update o_body set f_state=0 where f_id=?", "s", [$this->params->id]);
        $this->echoResult();
    }

    public function order()
    {
        $v["f_state"] = 1;
        $v["f_order"] = (string) json_encode($this->params->order);
        $this->sinsert("sys_mobile", $v);
        $this->echoResult();
    }

    public function unlockTable()
    {
        $this->stmtall("update h_tables set f_locksrc='' where f_locksrc=? and f_id=?", "si", [$this->params->locksrc, $this->params->table]);
        $this->echoResult();
    }
}

$order = new OOrder();
switch ($params->action) {
    case "open":
        $order->open();
        break;
    case "close":
        $order->close();
        break;
    case "adddish":
        $order->addDish();
        break;
    case "unlocktable":
        $order->unlockTable();
        break;
    case "removedish":
        $order->removeDish();
        break;
    case "modifydish":
        $order->modifyDish();
        break;
    case "order":
        $order->order();
        break;
    default:
        echo "KARRRR, KAAARRRRR!";
        break;
}