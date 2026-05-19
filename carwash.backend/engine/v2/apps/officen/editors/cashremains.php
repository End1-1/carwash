<?php
# © 2026 , Kudryashov Vasili

class CashRemains
{
    private $db;

    public function __construct($db)
    {
        $this->db = $db;
    }

    public function get($params)
    {
        $filterRaw = $params->filter ?? [];
        $filter = [];
        foreach ($filterRaw as $item) {
            foreach ((array)$item as $k => $v) {
                $filter[$k] = $v;
            }
        }

        $cashbox_id = (int)($filter["cashbox_id"] ?? 0);
        if ($cashbox_id <= 0) {
            return [
                "rows" => [],
                "headers" => $this->headers(),
                "toolbar" => ["reload" => true],
                "filter" => $this->filterConfig(),
            ];
        }

        $sql = <<<EOD
        SELECT
            cr.f_cash_session_id,
            datetime_fmt(cs.f_date_open, 0) AS f_date_open,
            datetime_fmt(cs.f_date_close, 0) AS f_date_close,
            money_fmt(cr.f_previouse_remain) AS f_previouse_remain,
            money_fmt(cr.f_paid_cash) AS f_paid_cash,
            money_fmt(cr.f_paid_card) AS f_paid_card,
            money_fmt(cr.f_today_cash) AS f_today_cash,
            money_fmt(cr.f_today_expenses) AS f_today_expenses,
            money_fmt(cr.f_today_nopaid) AS f_today_nopaid,
            money_fmt(cr.f_today_remain) AS f_today_remain
        FROM cash_remains cr
        INNER JOIN cash_session cs ON cs.f_id = cr.f_cash_session_id
        WHERE cs.f_cashbox_id = ?
        ORDER BY cs.f_date_close DESC, cr.f_cash_session_id DESC
        LIMIT 30
        EOD;

        return [
            "rows" => $this->db->select($sql, "i", [$cashbox_id])->fetch_all(MYSQLI_NUM),
            "headers" => $this->headers(),
            "toolbar" => ["reload" => true],
            "sum" => [3, 4, 5, 6, 7, 8, 9],
            "filter" => $this->filterConfig(),
        ];
    }

    private function headers()
    {
        return [
            Translator::t("Cash session"),
            Translator::t("Date open"),
            Translator::t("Date close"),
            Translator::t("Previous day remain"),
            Translator::t("Paid previous sessions cash"),
            Translator::t("Paid previous sessions card"),
            Translator::t("Today cash inflow"),
            Translator::t("Today expenses"),
            Translator::t("Today unpaid orders"),
            Translator::t("Today remain"),
        ];
    }

    private function filterConfig()
    {
        return [
            ["type" => "number", "name" => "cashbox_id", "label" => Translator::t("Cashbox")],
        ];
    }

    public function GetItem($params)
    {
        dieWithCode("Not supported");
    }
}
