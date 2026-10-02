<?php
# © 2026 , Kudryashov Vasili

require_once __DIR__ . "/../../carwash/cash_remains_calc.php";
require_once __DIR__ . "/../../../worker/helper.php";

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

        $preview_session_id = 0;
        $preview = null;

        $openSession = $this->db->select(
            "SELECT * FROM cash_session WHERE f_cashbox_id=? AND f_state=1 LIMIT 1",
            "i",
            [$cashbox_id]
        )->fetch_assoc();

        if ($openSession) {
            $preview_session_id = intval($openSession["f_id"]);
            $calc = new CashRemainsCalc($this->db);
            $snap = $calc->syncOpenSession($openSession);
            if (!empty($snap)) {
                $preview = $this->formatSnapshotForTable($snap);
            }
        }

        $sql = <<<EOD
        SELECT
            cr.f_cash_session_id,
            datetime_fmt(cs.f_date_open, 0) AS f_date_open,
            IF(cs.f_state = 1, '', datetime_fmt(cs.f_date_close, 0)) AS f_date_close,
            money_fmt(cr.f_previouse_remain) AS f_previouse_remain,
            money_fmt(cr.f_paid_cash) AS f_paid_cash,
            money_fmt(cr.f_paid_card) AS f_paid_card,
            money_fmt(cr.f_today_cash) AS f_today_cash,
            money_fmt(cr.f_today_expenses) AS f_today_expenses,
            money_fmt(cr.f_today_nopaid) AS f_today_nopaid,
            money_fmt(cr.f_today_remain) AS f_today_remain,
            cs.f_state
        FROM cash_remains cr
        INNER JOIN cash_session cs ON cs.f_id = cr.f_cash_session_id
        WHERE cs.f_cashbox_id = ?
        ORDER BY (cs.f_state = 1) DESC, COALESCE(cs.f_date_close, cs.f_date_open) DESC, cr.f_cash_session_id DESC
        LIMIT 30
        EOD;

        $rawRows = $this->db->select($sql, "i", [$cashbox_id])->fetch_all(MYSQLI_NUM);
        $rows = [];
        foreach ($rawRows as $raw) {
            $row = array_slice($raw, 0, 10);
            if ($preview_session_id > 0 && intval($row[0]) === $preview_session_id) {
                $row[2] = "";
            }
            $rows[] = $row;
        }

        return [
            "rows" => $rows,
            "headers" => $this->headers(),
            "toolbar" => ["reload" => true],
            "sum" => [3, 4, 5, 6, 7, 8, 9],
            "filter" => $this->filterConfig(),
            "preview_session_id" => $preview_session_id,
            "preview" => $preview,
        ];
    }

    /** Колонки 3–9 таблицы из числового снимка. */
    private function formatSnapshotForTable(array $snap)
    {
        return [
            3 => money_fmt_php($snap["f_previouse_remain"] ?? 0),
            4 => money_fmt_php($snap["f_paid_cash"] ?? 0),
            5 => money_fmt_php($snap["f_paid_card"] ?? 0),
            6 => money_fmt_php($snap["f_today_cash"] ?? 0),
            7 => money_fmt_php($snap["f_today_expenses"] ?? 0),
            8 => money_fmt_php($snap["f_today_nopaid"] ?? 0),
            9 => money_fmt_php($snap["f_today_remain"] ?? 0),
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
