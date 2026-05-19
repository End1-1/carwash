<?php
require_once (__DIR__ . "/reports.php");

class Common extends DBPrinter
{
    public function printReport()
    {

        $this->font(font_name, 20, true);
        $this->ctext($this->tr("Departments revenue"));
        $this->font(font_name, 12, false);
        $this->ctext("{$this->params->date1} - {$this->params->date2}");
        $this->line();
        $this->br();

        #General info 
        $d = $this->db->stmtall("select p1.f_name, cast(sum(f_grandtotal) as float) as f_total "
            . "from o_body ob "
            . "left join o_header oh on oh.f_id=ob.f_header "
            . "left join d_dish d on d.f_id=ob.f_dish "
            . "left join d_part2 p2 on p2.f_id=d.f_part "
            . "left join d_part1 p1 on p1.f_id=p2.f_part "
            . "where oh.f_state=2 and ob.f_state=1 "
            . "and oh.f_datecash between ? and ? "
            . "group by 1", "ss", [$this->params->date1, $this->params->date2])->fetch_all(MYSQLI_ASSOC);

        $total = 0;
        foreach ($d as $w) {
            $this->lrtext($w["f_name"], number_format($w["f_total"]));
            $total += $w["f_total"];
        }
        $this->font(font_name, 14, true);
        $this->lrtext($this->tr("Total"), number_format($total));
        $this->br();
        $this->font(font_name, 14, false);
        $this->lrtext($this->tr("Printed"), date("d/m/y H:i:s"));

        echo json_encode(["status" => 1, "report" => $this->data]);
    }
}

$common = new Common();
$common->printReport();