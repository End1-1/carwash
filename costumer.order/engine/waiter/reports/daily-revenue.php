<?php
# (C) 2025 Kudryashov Vasili
# Last modified - 2025-05-09 14:00:10
require_once __DIR__ . "/reports.php";

class Common extends DBPrinter
{
    public function printReport()
    {

        $this->font(self::font_name, self::font_size + 10, true);
        $this->ctext($this->tr("Daily revenue"));
        $this->font(self::font_name, self::font_size + 10, false);
        $this->ctext("{$this->params->date1} - {$this->params->date2}");
        $this->line();
        $this->br();

        #General info 
        $d = $this->db->stmtall("select count(oh.f_id) as f_count, cast(coalesce(sum(oh.f_amounttotal), 0) as float) as f_amounttotal, "
            . "cast(sum(oh.f_amountcash)as float) as f_amountcash, cast(sum(oh.f_amountcard) as float) as f_amountcard, "
            . "cast(sum(oh.f_amountbank)as float) as f_amountbank, cast(sum(oh.f_amountother)as float) as f_amountother, "
            . "cast(sum(oh.f_amountidram)as float) as f_amountidram,  "
            . "cast(sum(oh.f_amountpayx)as float) as f_amountpayx,  "
            . "cast(sum(oh.f_hotel)as float) as f_hotel "
            . "from o_header oh "
            . "where oh.f_state=2 "
            . "and oh.f_datecash between ? and ? ", "ss", [$this->params->date1, $this->params->date2])->fetch_assoc();
        $this->lrtext($this->tr("Number of orders"), number_format($d["f_count"]));
        if ($d["f_amountcash"] > 0) {
            $this->lrtext($this->tr("Cash"), number_format($d["f_amountcash"]));
        }
        if ($d["f_amountcard"] > 0) {
            $this->lrtext($this->tr("Card"), number_format($d["f_amountcard"]));
        }
        if ($d["f_amountbank"] > 0) {
            $this->lrtext($this->tr("Bank"), number_format($d["f_amountbank"]));
        }
        if ($d["f_amountidram"] > 0) {
            $this->lrtext($this->tr("Idram"), number_format($d["f_amountidram"]));
        }
        if ($d["f_amountother"] > 0) {
            $this->lrtext($this->tr("Other"), number_format($d["f_amountother"]));
        }
        if ($d["f_hotel"] > 0) {
            $this->lrtext($this->tr("Hotel"), number_format($d["f_hotel"]));
        }
        $this->lrtext($this->tr("Total"), number_format($d["f_amounttotal"]));
        $this->line();
        $this->br();

        #By staff
        $d = $this->db->stmtall("select concat(u.f_last, ' ', u.f_first) as f_staff, count(oh.f_id) as f_count, "
            . "cast(sum(oh.f_amounttotal) as float) as f_amounttotal, "
            . "cast(sum(oh.f_amountcash)  as float)as f_amountcash, "
            . "cast(sum(oh.f_amountcard) as float) as f_amountcard, "
            . "cast(sum(oh.f_amountbank) as float) as f_amountbank, "
            . "cast(sum(oh.f_amountother) as float) as f_amountother, "
            . "cast(sum(oh.f_amountidram)  as float)as f_amountidram,  "
            . "cast(sum(oh.f_amountpayx)  as float)as f_amountpayx, "
            . "cast(sum(oh.f_hotel) as float) as f_hotel, "
            . "cast(sum(oh.f_amountservice) as float) as f_service "
            . "from o_header oh "
            . "left join s_user u on u.f_id=oh.f_staff "
            . "where oh.f_state=2 "
            . "and oh.f_datecash between ? and ? "
            . "group by 1 ", "ss", [$this->params->date1, $this->params->date2])->fetch_all(MYSQLI_ASSOC);

        foreach ($d as $w) {
            $this->ltext($w["f_staff"])->br();
            $this->lrtext($this->tr("Number of orders"), number_format($w["f_count"]));

            if ($w["f_amountcash"] > 0) {
                $this->lrtext($this->tr("Cash"), number_format($w["f_amountcash"]));
            }
            if ($w["f_amountcard"] > 0) {
                $this->lrtext($this->tr("Card"), number_format($w["f_amountcard"]));
            }
            if ($w["f_amountbank"] > 0) {
                $this->lrtext($this->tr("Bank"), number_format($w["f_amountbank"]));
            }
            if ($w["f_amountidram"] > 0) {
                $this->lrtext($this->tr("Idram"), number_format($w["f_amountidram"]));
            }
            if ($w["f_amountother"] > 0) {
                $this->lrtext($this->tr("Other"), number_format($w["f_amountother"]));
            }
            if ($w["f_service"] > 0) {
                $this->lrtext($this->tr("Tips"), number_format($w["f_service"]));
            }
            $this->lrtext($this->tr("Total"), number_format($w["f_amounttotal"]));
            $this->line();
            $this->br();
        }

        $this->lrtext($this->tr("Printed"), date("d/m/y H:i:s"));

        echo json_encode(["status" => 1, "report" => $this->data]);
    }
}

$common = new Common();
$common->printReport();