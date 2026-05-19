<?php
# © 2026 , Kudryashov Vasili
# Created: 2026-01-17 16:06:01
# Last Modified: 2026-03-15 19:50:23
require_once __DIR__ . "/index.php";

class Cashbox extends Auth
{
    public function GetOpenedCashboxSessionId($cashbox_id)
    {
        $cashbox_session = $this->select("select f_id, f_cashbox_id from cash_session where f_state=1 and f_cashbox_id=?", "i", [$cashbox_id])->fetch_assoc();
        return $cashbox_session;
    }

    public function GetRawCashboxSession($cashbox_session_id)
    {
        return $this->select("select * from cash_session where f_id=?", "i", [$cashbox_session_id])->fetch_assoc();
    }

    public function GetCashboxSession($cashbox_session_id)
    {
        $sql = <<<EOD
        SELECT c.f_id, datetime_fmt(c.f_date_open, 0) as f_date_open, datetime_fmt(c.f_date_close, 0) as f_date_close, 
        money_fmt(c.f_amount_expected) as f_amount_expected,
        concat(u1.f_last, ' ', LEFT(u1.f_first, 1), '.') AS f_user_open_name, 
        concat(u2.f_last, ' ', LEFT(u2.f_first, 1), '.') AS f_user_close_name, 
        count(distinct case when o.f_operation_type = 1 then o.f_order_id end) as f_orders_count
        FROM cash_session c
        LEFT JOIN s_user u1 ON u1.f_id=c.f_user_open
        LEFT JOIN s_user u2 ON u2.f_id=c.f_user_open
        left join cash_operations o on o.f_session_id=c.f_id
        where c.f_id=?
        limit 1
        EOD;

        return $this->select($sql, "i", [$cashbox_session_id])->fetch_assoc();
    }

    public function GetOpenCashboxSession($cashbox_id)
    {
        $cash_session = $this->GetOpenedCashboxSessionId($cashbox_id);
        if (!$cash_session) {
            return null;
        }

        return $this->GetCashboxSession($cash_session["f_id"]);
    }

    public function CheckStatus($params)
    {
        if (empty($params->cashbox_id)) {
            dieWithCode("cashbox_id not specified");
        }
        $cashbox = $this->GetOpenCashboxSession($params->cashbox_id);
        $this->result["cashbox_session_id"] = $cashbox ? $cashbox["f_id"]  : 0;
        $this->result["cashbox_session"] = $cashbox ?? [];
        $this->echoResult();
    }

    public function MoveMoney($params)
    {
        $cash_session = $this->GetOpenCashboxSession($params->cashbox_id);
        if (!$cash_session) {
            die(Translator::t("No active session"));
        }
        $v["f_cashbox_id"] = $params->cashbox_id;
        $v["f_session_id"] = $cash_session["f_id"];
        $v["f_order_id"] = $params->f_order_id;
        $v["f_user"] = $this->userid;
        $v["f_datetime"] = date("Y-m-d H:i:s");
        $v["f_payment_type_id"] = $params->f_payment_type_id;
        $v["f_debit"] = $params->f_debit;
        $v["f_credit"] = $params->f_credit;
        $v["f_currency_id"] = $params->f_currency_id;
        $v["f_comment"]  = $params->f_comment;
        $this->insert("cash_operations", $v);
        $this->echoResult();
    }

    public function Open($params)
    {
        $cashbox_id = intval($params->cashbox_id ?? 0);
        if ($cashbox_id <= 0) {
            dieWithCode("cashbox_id not specified");
        }
        $cashbox = $this->GetOpenCashboxSession($cashbox_id);
        $cash_remains = null;
        if (!$cashbox) {
            $this->beginTransaction();
            try {
                $this->insert("cash_session", [
                    "f_state" => 1,
                    "f_cashbox_id" => $cashbox_id,
                    "f_user_open" => $this->userid,
                    "f_date_open" => date("Y-m-d H:i:s"),
                    "f_amount_open" => $params->amount_open ?? 0,
                    "f_amount_fact" => 0,
                    "f_amount_expected" => 0,
                    "f_amount_difference" => 0
                ]);
                $opened = $this->GetOpenedCashboxSessionId($cashbox_id);
                if (!$opened) {
                    dieWithCode("Failed to open cash session");
                }
                $session_id = intval($opened["f_id"]);
                $cash_remains = $this->InsertCashRemainsOnOpen(
                    $cashbox_id,
                    $session_id,
                    floatval($params->amount_open ?? 0)
                );
                $this->commit();
            } catch (\Throwable $e) {
                $this->rollback();
                dieWithCode($e->getMessage());
            }
            $cashbox = $this->GetCashboxSession($session_id);
        }
        $this->result["cashbox_session"] = $cashbox;
        if ($cash_remains) {
            $this->result["cash_remains"] = $cash_remains;
        }
        $this->echoResult();
    }

    /**
     * При открытии смены: запись cash_remains, f_previouse_remain = f_today_remain прошлой смены.
     */
    private function InsertCashRemainsOnOpen($cashbox_id, $session_id, $amount_open)
    {
        $exists = $this->select(
            "SELECT f_id FROM cash_remains WHERE f_cash_session_id=?",
            "i",
            [$session_id]
        )->fetch_assoc();
        if ($exists) {
            return $this->select("SELECT * FROM cash_remains WHERE f_cash_session_id=?", "i", [$session_id])->fetch_assoc();
        }

        $previous_remain = round(
            $this->GetPreviousCashRemain($cashbox_id, $session_id, $amount_open),
            2
        );

        $row = [
            "f_cash_session_id" => $session_id,
            "f_previouse_remain" => $previous_remain,
            "f_paid_cash" => 0,
            "f_paid_card" => 0,
            "f_today_cash" => 0,
            "f_today_expenses" => 0,
            "f_today_nopaid" => 0,
            "f_today_remain" => $previous_remain,
        ];
        $row["f_id"] = $this->insert("cash_remains", $row);
        return $row;
    }

    /**
     * Остаток кассы на конец предыдущей закрытой смены этой кассы (или f_amount_open).
     */
    private function GetPreviousCashRemain($cashbox_id, $session_id, $amount_open)
    {
        $sql = <<<SQL
        SELECT cr.f_today_remain
        FROM cash_remains cr
        INNER JOIN cash_session cs ON cs.f_id = cr.f_cash_session_id
        WHERE cs.f_cashbox_id = ? AND cs.f_id < ?
        ORDER BY cs.f_id DESC
        LIMIT 1
        SQL;
        $row = $this->select($sql, "ii", [$cashbox_id, $session_id])->fetch_assoc();
        if ($row) {
            return floatval($row["f_today_remain"]);
        }
        return floatval($amount_open);
    }

    /**
     * Оплаты за заказы прошлых смен в текущей смене (cash_operations).
     */
    private function SumPaidFromPreviousSessions($cashbox_id, $session_id, $payment_type_id, $session_open)
    {
        $sql = <<<SQL
        SELECT COALESCE(SUM(co.f_debit), 0) AS f_amount
        FROM cash_operations co
        WHERE co.f_cashbox_id = ?
          AND co.f_payment_type_id = ?
          AND co.f_debit > 0
          AND co.f_datetime >= ?
          AND co.f_session_id = ?
          AND co.f_order_id IS NOT NULL
          AND EXISTS (
            SELECT 1 FROM cash_operations prev
            WHERE prev.f_order_id = co.f_order_id
              AND prev.f_session_id < ?
              AND prev.f_id < co.f_id
          )
        SQL;
        $row = $this->select(
            $sql,
            "iisii",
            [$cashbox_id, $payment_type_id, $session_open, $session_id, $session_id]
        )->fetch_assoc();
        return floatval($row["f_amount"] ?? 0);
    }

    /** Чистые поступления наличных за текущую смену (только f_debit, тип оплаты «наличные»). */
    private function SumTodayCashInflow($session_id)
    {
        $sql = <<<SQL
        SELECT COALESCE(SUM(co.f_debit), 0) AS f_amount
        FROM cash_operations co
        WHERE co.f_session_id = ?
          AND co.f_payment_type_id = 1
          AND co.f_debit > 0
        SQL;
        $row = $this->select($sql, "i", [$session_id])->fetch_assoc();
        return floatval($row["f_amount"] ?? 0);
    }

    private function SumTodayCashExpenses($session_id)
    {
        $sql = <<<SQL
        SELECT COALESCE(SUM(co.f_credit), 0) AS f_amount
        FROM cash_operations co
        WHERE co.f_session_id = ?
          AND co.f_payment_type_id = 1
          AND co.f_credit > 0
          AND co.f_order_id IS NULL
        SQL;
        $row = $this->select($sql, "i", [$session_id])->fetch_assoc();
        return floatval($row["f_amount"] ?? 0);
    }

    /**
     * Неоплаченный остаток по заказу (как в истории: f_amount_other или полная сумма без нал/карта/idram).
     */
    private function OrderUnpaidAmount(array $row)
    {
        $odata = json_decode($row["f_data"] ?? "{}", true);
        if (!is_array($odata)) {
            $odata = [];
        }
        $other = floatval($odata["f_amount_other"] ?? $odata["f_amountother"] ?? 0);
        if ($other > 0.01) {
            return $other;
        }
        $cash = floatval($odata["f_amount_cash"] ?? $odata["f_amountcash"] ?? 0);
        $card = floatval($odata["f_amount_card"] ?? $odata["f_amountcard"] ?? 0);
        $idram = floatval($odata["f_amount_idram"] ?? $odata["f_amountidram"] ?? 0);
        $paid = $cash + $card + $idram;
        $subTotal = floatval($odata["f_sub_total"] ?? $odata["f_subtotal"] ?? 0);
        $total = floatval($row["f_amounttotal"] ?? 0);
        $orderTotal = $subTotal > 0.01 ? $subTotal : $total;
        if ($orderTotal > 0.01 && $paid <= 0.01) {
            return $orderTotal;
        }
        return 0;
    }

    /**
     * Неоплаченные заказы текущей смены: закрытые в этой смене + ещё открытые с начала смены.
     */
    private function SumUnpaidOrdersForSession($session_id, $session_open)
    {
        $sql = <<<SQL
        SELECT oh.f_amounttotal, oh.f_data
        FROM o_header oh
        WHERE oh.f_cash_session_id = ?
           OR (
                oh.f_state = 1
                AND STR_TO_DATE(
                    CONCAT(
                        COALESCE(JSON_VALUE(oh.f_data, '$.f_date_open'), '1900-01-01'),
                        ' ',
                        COALESCE(JSON_VALUE(oh.f_data, '$.f_time_open'), '00:00:00')
                    ),
                    '%Y-%m-%d %H:%i:%s'
                ) >= ?
            )
        SQL;
        $rs = $this->select($sql, "is", [$session_id, $session_open]);
        $sum = 0.0;
        while ($row = $rs->fetch_assoc()) {
            $sum += $this->OrderUnpaidAmount($row);
        }
        return $sum;
    }

    /**
     * Снимок остатков при закрытии смены → cash_remains.
     * f_today_remain = (f_previouse_remain - f_paid_card) + (f_today_cash - f_today_expenses) + неоплаченные заказы смены
     */
    private function InsertCashRemainsOnClose($cashbox)
    {
        $session_id = intval($cashbox["f_id"]);
        $cashbox_id = intval($cashbox["f_cashbox_id"]);
        $exists = $this->select(
            "SELECT f_id, f_previouse_remain FROM cash_remains WHERE f_cash_session_id=?",
            "i",
            [$session_id]
        )->fetch_assoc();

        require_once __DIR__ . "/../worker/dict-payment.php";
        $session_open = $cashbox["f_date_open"] ?? date("Y-m-d H:i:s");

        if ($exists) {
            $previous_remain = floatval($exists["f_previouse_remain"]);
        } else {
            $previous_remain = $this->GetPreviousCashRemain(
                $cashbox_id,
                $session_id,
                $cashbox["f_amount_open"] ?? 0
            );
        }
        $paid_cash = $this->SumPaidFromPreviousSessions(
            $cashbox_id,
            $session_id,
            PAYMENT_TYPE_CASH,
            $session_open
        );
        $paid_card = $this->SumPaidFromPreviousSessions(
            $cashbox_id,
            $session_id,
            PAYMENT_TYPE_CARD,
            $session_open
        ) + $this->SumPaidFromPreviousSessions(
            $cashbox_id,
            $session_id,
            PAYMENT_TYPE_IDRAM,
            $session_open
        );
        $today_cash = $this->SumTodayCashInflow($session_id);
        $today_expenses = $this->SumTodayCashExpenses($session_id);
        $unpaid_orders = $this->SumUnpaidOrdersForSession($session_id, $session_open);
        $today_remain = ($previous_remain - $paid_card)
            + ($today_cash - $today_expenses)
            + $unpaid_orders;

        $row = [
            "f_cash_session_id" => $session_id,
            "f_previouse_remain" => round($previous_remain, 2),
            "f_paid_cash" => round($paid_cash, 2),
            "f_paid_card" => round($paid_card, 2),
            "f_today_cash" => round($today_cash, 2),
            "f_today_expenses" => round($today_expenses, 2),
            "f_today_nopaid" => round($unpaid_orders, 2),
            "f_today_remain" => round($today_remain, 2),
        ];
        if ($exists) {
            $this->update("cash_remains", $row, intval($exists["f_id"]));
            $row["f_id"] = intval($exists["f_id"]);
        } else {
            $row["f_id"] = $this->insert("cash_remains", $row);
        }
        return $row;
    }

    /**
     * Закрывает кассовую смену: cash_remains + cash_session (f_state=2).
     * Строки cash_operations (приходы по заказам, внесения/изъятия) не меняются.
     */
    public function Close($params)
    {
        $cash_session = $this->GetOpenedCashboxSessionId($params->cashbox_id);
        if (!$cash_session) {
            die(Translator::t("No active session"));
        }
        $cashbox = $this->GetRawCashboxSession($cash_session["f_id"]);
        if (!$cashbox) {
            dieWithCode("Do you want to hack close function of cashbox?");
        }

        $this->beginTransaction();
        try {
            $cash_remains = $this->InsertCashRemainsOnClose($cashbox);

            $cashbox["f_state"] = 2;
            $cashbox["f_date_close"] = date("Y-m-d H:i:s");
            $cashbox["f_user_close"] = $this->userid;
            $cashbox["f_amount_fact"] = $params->amount_fact ?? 0;
            $cashbox["f_amount_expected"] = $cashbox["f_amount_expected"];
            $cashbox["f_amount_difference"] = ($params->amount_fact ?? 0) - $cashbox["f_amount_expected"];
            $this->update("cash_session", $cashbox, $cashbox["f_id"]);
            $this->commit();
        } catch (\Throwable $e) {
            $this->rollback();
            dieWithCode($e->getMessage());
        }

        $this->result["cash_remains"] = $cash_remains;
        $this->result["cashbox"] = $this->GetCashboxSession($cash_session["f_id"]);
        $this->echoResult();
    }
}
