<?php
# (C) 2025 Kudryashov Vasili
# Created - 2025-05-04 22:47:10
# Last modified - 2025-05-10 11:11:00

require_once __DIR__ . "/waiter.php";
require_once __DIR__ . "/../functions/print.php";

class PrintService extends PClass
{
    use Printer;
    private $fHeaderData = [];
    private $fBodyData = [];
    private $fPreorderData = [];
    private $fPrintAliases = [];
    public function __construct()
    {
        parent::__construct();
        $this->initPrinter();
    }

    public function print($printer, $side, $reprint)
    {
        $this->data = [];
        $originalPrinter = $printer;
        $this->initPrinter();
        $this->font(self::font_name, self::font_size, true);
        if (
            $this->fHeaderData["f_state"] == ORDER_STATE_PREORDER_EMPTY
            || $this->fHeaderData["f_state"] == ORDER_STATE_PREORDER_WITH_ORDER || $this->params->isBooking
        ) {
            $this->font(self::font_name, self::font_size + 10, true);

            $this->ctext($this->tr("PREORDER"));
            $this->br();
            $this->ltext($this->fPreorderData["f_datefor"], 0);
            $this->rtext($this->fPreorderData["f_timefor"]);
            $this->br();
            $this->ltext($this->tr("Guests"), 0);
            $this->rtext($this->fPreorderData["f_guests"]);
            $this->br();
            $this->br();
            $this->line();
            $this->br();
        }
        if ($reprint) {
            $this->fontSize(34);
            $this->fontBold(true);
            $this->ctext($this->tr("REPRINT"));
            $this->br();
            $this->br();
        }
        $this->fontBold(false);
        $this->fontSize(self::font_size + 4);
        $this->ctext($this->tr("New order"));
        $this->br();
        $this->ltext($this->tr("Table"), 0);
        $this->rtext($this->fHeaderData["f_tablename"]);
        $this->br();
        $this->ltext($this->tr("Order no"), 0);
        $this->rtext("{$this->fHeaderData["f_prefix"]}{$this->fHeaderData["f_hallid"]}");
        $this->br();
        $this->ltext($this->tr("Date"), 0);
        $this->rtext((new DateTime())->format(FORMAT_DATE_TO_STR));
        $this->br();
        $this->ltext($this->tr("Time"), 0);
        $this->rtext((new DateTime())->format(FORMAT_TIME_TO_STR));
        $this->br();
        $this->ltext($this->tr("Staff"), 0);
        $this->rtext($this->fHeaderData["f_currentstaffname"]);
        $this->br();
        $this->line();
        $this->br(2);
        $this->fontSize(self::font_size);
        $storages = [];
        $this->fontSize(self::font_size + 10);
        for ($i = 0; $i < count($this->fBodyData); $i++) {
            $o = $this->fBodyData[$i];
            if ($o[$side] != $printer) {
                continue;
            }
            $storages[] = $o["f_storagename"];

            if ($this->params->timeorder > 0) {
                $this->ltext("[{$o["f_timeorder"]}] {$o["f_dishname"]}", 0);
            } else {

                $this->ltext($o["f_dishname"], 0, 500);
            }
            $this->fontBold(true);
            $val = $o["f_qty1"];
            $formatted = strpos($val, '.') !== false
                ? rtrim(rtrim(number_format($val, 2, ".", ","), '0'), '.')
                : number_format($val, 0, ".", ",");
            $this->rtext("x $formatted");
            $this->fontBold(false);
            if ($o["f_dishextra"] > 0) {
                $this->br();
                $this->fontSize(25);
                $this->ltext("{$this->tr("Extra price")} " . number_format($o["f_price"], 2, ".", ","), 0);
            }
            if (strlen($o["f_comment2"]) > 0) {
                $this->br();
                $this->fontSize(25);
                $this->fontBold(true);
                $this->ltext($o["f_comment2"], 0);
                $this->br();
                $this->fontSize(30);
                $this->fontBold(false);
            }
            if (strlen($o["f_comment"]) > 0) {
                $this->br();
                $this->fontSize(self::font_size + 5);
                $this->ltext($o["f_comment"], 0);
                $this->br();
                $this->fontSize(self::font_size + 10);
            }
            $this->br();
            $this->line();
            $this->br(1);
        }
        $this->line();
        $this->br(1);
        $this->fontSize(self::font_size);
        $this->ltext($this->tr("Printer: ") . $printer, 0);
        $this->fontBold(true);
        $this->rtext($side == "f_print1" ? " [1]" : "[2]");
        $this->br();
        $storages = array_unique($storages);
        $this->ltext($this->tr("Storage: ") . " " . implode(",", $storages), 0);
        $this->br();
        $this->ltext(".");
        if (array_key_exists($printer, $this->fPrintAliases)) {
            $printer = $this->fPrintAliases[$printer];
        }
        $this->printCommand($printer);
        return $this->data;
    }
    public function echoResult()
    {
        if (empty($this->params->order)) {
            $this->exitError($this->tr("Order ID is empty"));
        }
        $fPrint1 = [];
        $fPrint2 = [];
        $fPrintAliases = [];
        if ($this->params->alias) {
            foreach ($this->stmtall("select f_alias, f_printer from d_print_aliases")->fetch_all(MYSQLI_ASSOC) as $row) {
                $fPrintAliases[$row["f_alias"]] = $row["f_printer"];
            }
        }
        $sql = <<<EOD
                   select oh.*, t.f_name as f_tablename, concat_ws(' ', cs.f_last, cs.f_first) as f_currentstaffname
                   from o_header oh
                   left join h_tables t on t.f_id=oh.f_table
                   left join s_user cs on cs.f_id=oh.f_currentstaff
                   where oh.f_id=?
                   EOD;
        $this->fHeaderData = $this->stmtall($sql, "s", [$this->params->order])->fetch_assoc();
        if (empty($this->fHeaderData)) {
            $this->exitError($this->$this->tr("Order not found"));
        }


        $this->fPreorderData = $this->stmtall("select * from o_preorder where f_id=?", "s", [$this->params->order])->fetch_assoc();

        $sql = <<<EOD
        select b.*, ct.f_name as f_storagename, dn.f_name as f_dishname, dn.f_extra as f_dishextra
        from o_body b 
        left join c_storages ct on ct.f_id=b.f_store
        left join d_dish dn on b.f_dish=dn.f_id
        where b.f_header=? and (b.f_state=? or b.f_state=?) 
        and (length(f_print1)>0 or length(f_print2)>0) and b.f_qty2<b.f_qty1
        order by b.f_appendtime
        EOD;
        $this->fBodyData = $this->stmtall($sql, "sii", [$this->params->order, DISH_STATE_OK, DISH_STATE_SET])->fetch_all(MYSQLI_ASSOC);
        if (empty($this->fBodyData)) {
            $this->exitError($this->tr("No items to print"));
        }
        foreach ($this->fBodyData as $row) {
            if (strlen($row["f_print1"]) > 0) {
                $fPrint1[] = $row["f_print1"];
            }
            if ($row["f_print1"] != $row["f_print2"]) {
                if (strlen($row["f_print2"]) > 0) {
                    $fPrint2[] = $row["f_print2"];
                }
            }
        }
        $fPrint1 = array_unique($fPrint1);
        $fPrint2 = array_unique($fPrint2);
        foreach ($fPrint1 as $s) {
            $this->result["print"][] = ["data" => $this->print($s, "f_print1", false)];
        }
        foreach ($fPrint2 as $s) {
            $this->result["print"][] = ["data" => $this->print($s, "f_print2", false)];
        }
        if ($this->fHeaderData["f_state"] == ORDER_STATE_OPEN) {
            $this->stmtall("update o_body set f_qty2=f_qty1, f_reprint=abs(f_reprint), f_printtime=current_timestamp() where f_header=? and (f_state=? or f_state=?)  and f_qty2<f_qty1", "sii", [$this->params->order, DISH_STATE_OK, DISH_STATE_SET]);
        }
        if (!empty($this->program->params->reprint)) {
            $fPrint1 = [];
            $fPrint2 = [];
            if ($this->params->use_aliases) {
                foreach ($this->stmtall("select f_alias, f_printer from d_print_aliases")->fetch_all(MYSQLI_ASSOC) as $row) {
                    $fPrintAliases[$row["f_alias"]] = $row["f_printer"];
                }
            }
            $ids = explode(",", $this->params->reprint);
            $placeholders = implode(",", array_fill(0, count($ids), "?"));
            $sql = "SELECT * FROM o_body WHERE f_id IN ($placeholders)";
            $fBodyData = $this->stmtall($sql, str_repeat("i", count($ids)), $ids)->fetch_all(MYSQLI_ASSOC);
            foreach ($fBodyData as $row) {
                if (strlen($row["f_print1"]) > 0) {
                    $fPrint1[] = $row["f_print1"];
                }
                if ($row["f_print1"] != $row["f_print2"]) {
                    if (strlen($row["f_print2"]) > 0) {
                        $fPrint2[] = $row["f_print2"];
                    }
                }
            }
            $fPrint1 = array_unique($fPrint1);
            $fPrint2 = array_unique($fPrint2);
            foreach ($fPrint1 as $s) {
                $this->result["print"][] = ["data" => $this->print($s, "f_print1", true)];
            }
            foreach ($fPrint2 as $s) {
                $this->result["print"][] = ["data" => $this->print($s, "f_print2", true)];
            }
        }
        parent::echoResult();
    }

}

$ps = new PrintService();
$ps->echoResult();