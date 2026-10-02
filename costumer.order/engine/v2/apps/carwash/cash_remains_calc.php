<?php
# © 2026 , Kudryashov Vasili
# Расчёт cash_remains (как при закрытии смены) без записи в БД.

require_once __DIR__ . "/../../worker/db.php";

class CashRemainsCalc
{
    private Db $db;

    public function __construct(Db $db)
    {
        $this->db = $db;
    }

    /**
     * Снимок остатков на момент расчёта (те же формулы, что InsertCashRemainsOnClose).
     *
     * @return array<string, float|int>
     */
    public function snapshot(array $cashbox): array
    {
        $session_id = intval($cashbox["f_id"] ?? 0);
        $cashbox_id = intval($cashbox["f_cashbox_id"] ?? 0);
        if ($session_id <= 0 || $cashbox_id <= 0) {
            return [];
        }

        require_once __DIR__ . "/../worker/dict-payment.php";

        $exists = $this->db->select(
            "SELECT f_id, f_previouse_remain, f_paid_cash, f_paid_card FROM cash_remains WHERE f_cash_session_id=?",
            "i",
            [$session_id]
        )->fetch_assoc();

        $session_open = $cashbox["f_date_open"] ?? date("Y-m-d H:i:s");

        if ($exists) {
            $previous_remain = floatval($exists["f_previouse_remain"]);
        } else {
            $previous_remain = $this->getPreviousCashRemain(
                $cashbox_id,
                $session_id,
                floatval($cashbox["f_amount_open"] ?? 0)
            );
        }

        $paid_cash = $this->sumPaidFromPreviousSessions(
            $session_id,
            PAYMENT_TYPE_CASH,
            $session_open
        );
        $paid_card = $this->sumPaidFromPreviousSessions(
            $session_id,
            PAYMENT_TYPE_CARD,
            $session_open
        ) + $this->sumPaidFromPreviousSessions(
            $session_id,
            PAYMENT_TYPE_IDRAM,
            $session_open
        );

        if ($exists) {
            $paid_cash = max($paid_cash, floatval($exists["f_paid_cash"] ?? 0));
            $paid_card = max($paid_card, floatval($exists["f_paid_card"] ?? 0));
        }

        $today_cash = $this->sumTodayCashFromOrders($session_id)
            + $this->sumManualCashInflow($session_id);
        $today_expenses = $this->sumTodayCashExpenses($session_id);
        $unpaid_orders = $this->sumUnpaidOrdersForSession($session_id);
        $today_remain = ($previous_remain - $paid_card)
            + ($today_cash - $today_expenses)
            + $unpaid_orders;

        return [
            "f_cash_session_id" => $session_id,
            "f_previouse_remain" => round($previous_remain, 2),
            "f_paid_cash" => round($paid_cash, 2),
            "f_paid_card" => round($paid_card, 2),
            "f_today_cash" => round($today_cash, 2),
            "f_today_expenses" => round($today_expenses, 2),
            "f_today_nopaid" => round($unpaid_orders, 2),
            "f_today_remain" => round($today_remain, 2),
        ];
    }

    /**
     * Пересчитать и записать cash_remains для открытой смены (перед показом / preview).
     */
    public function syncOpenSession(array $cashbox): array
    {
        $snap = $this->snapshot($cashbox);
        if (empty($snap)) {
            return [];
        }

        $session_id = intval($snap["f_cash_session_id"]);
        $exists = $this->db->select(
            "SELECT f_id FROM cash_remains WHERE f_cash_session_id=?",
            "i",
            [$session_id]
        )->fetch_assoc();

        if ($exists) {
            $row = $snap;
            unset($row["f_cash_session_id"]);
            $this->db->update("cash_remains", $row, intval($exists["f_id"]));
            $snap["f_id"] = intval($exists["f_id"]);
        } else {
            $snap["f_id"] = $this->db->insert("cash_remains", $snap);
        }

        return $snap;
    }

    private function getPreviousCashRemain($cashbox_id, $session_id, $amount_open)
    {
        $sql = <<<SQL
        SELECT cr.f_today_remain
        FROM cash_remains cr
        INNER JOIN cash_session cs ON cs.f_id = cr.f_cash_session_id
        WHERE cs.f_cashbox_id = ? AND cs.f_id < ?
        ORDER BY cs.f_id DESC
        LIMIT 1
        SQL;
        $row = $this->db->select($sql, "ii", [$cashbox_id, $session_id])->fetch_assoc();
        if ($row) {
            return floatval($row["f_today_remain"]);
        }
        return floatval($amount_open);
    }

    /**
     * Оплаты в текущей смене за заказы прошлых смен (o_header + cash_operations).
     */
    private function sumPaidFromPreviousSessions($session_id, $payment_type_id, $session_open)
    {
        $sql = <<<SQL
        SELECT COALESCE(SUM(co.f_debit), 0) AS f_amount
        FROM cash_operations co
        INNER JOIN o_header oh ON oh.f_id = co.f_order_id
        WHERE co.f_session_id = ?
          AND co.f_payment_type_id = ?
          AND co.f_debit > 0
          AND co.f_order_id IS NOT NULL
          AND co.f_order_id != ''
          AND co.f_order_id != '0'
          AND (
            (COALESCE(oh.f_cash_session_id, 0) > 0 AND oh.f_cash_session_id < ?)
            OR (
              COALESCE(oh.f_cash_session_id, 0) = 0
              AND STR_TO_DATE(
                CONCAT(
                  COALESCE(JSON_VALUE(oh.f_data, '$.f_date_open'), '1900-01-01'),
                  ' ',
                  COALESCE(JSON_VALUE(oh.f_data, '$.f_time_open'), '00:00:00')
                ),
                '%Y-%m-%d %H:%i:%s'
              ) < STR_TO_DATE(?, '%Y-%m-%d %H:%i:%s')
            )
          )
        SQL;
        $row = $this->db->select(
            $sql,
            "iiis",
            [$session_id, $payment_type_id, $session_id, $session_open]
        )->fetch_assoc();
        return floatval($row["f_amount"] ?? 0);
    }

    /**
     * Наличные по заказам текущей смены — из o_header.f_data (как в отчётах).
     */
    private function sumTodayCashFromOrders($session_id)
    {
        $sql = <<<SQL
        SELECT COALESCE(SUM(
            GREATEST(
                COALESCE(CAST(JSON_VALUE(oh.f_data, '$.f_amount_cash') AS DECIMAL(14,2)), 0),
                COALESCE(CAST(JSON_VALUE(oh.f_data, '$.f_amountcash') AS DECIMAL(14,2)), 0)
            )
        ), 0) AS f_amount
        FROM o_header oh
        WHERE oh.f_cash_session_id = ?
          AND oh.f_state IN (1, 2)
        SQL;
        $row = $this->db->select($sql, "i", [$session_id])->fetch_assoc();
        return floatval($row["f_amount"] ?? 0);
    }

    /** Внесение наличных без заказа (MoveMoney). */
    private function sumManualCashInflow($session_id)
    {
        $noOrder = $this->sqlCashOpWithoutOrder();
        $sql = <<<SQL
        SELECT COALESCE(SUM(co.f_debit), 0) AS f_amount
        FROM cash_operations co
        WHERE co.f_session_id = ?
          AND co.f_payment_type_id = 1
          AND co.f_debit > 0
          AND {$noOrder}
        SQL;
        $row = $this->db->select($sql, "i", [$session_id])->fetch_assoc();
        return floatval($row["f_amount"] ?? 0);
    }

    private function sqlCashOpWithoutOrder(): string
    {
        return "(co.f_order_id IS NULL OR co.f_order_id = '' OR co.f_order_id = '0')";
    }

    private function sumTodayCashExpenses($session_id)
    {
        $noOrder = $this->sqlCashOpWithoutOrder();
        $sql = <<<SQL
        SELECT COALESCE(SUM(co.f_credit), 0) AS f_amount
        FROM cash_operations co
        WHERE co.f_session_id = ?
          AND co.f_payment_type_id = 1
          AND co.f_credit > 0
          AND {$noOrder}
        SQL;
        $row = $this->db->select($sql, "i", [$session_id])->fetch_assoc();
        return floatval($row["f_amount"] ?? 0);
    }

    /**
     * Неоплаченный остаток (Cashbox::OrderUnpaidAmount / история).
     */
    private function orderUnpaidAmount(array $row): float
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

    /** Неоплаченные заказы текущей смены — только o_header с f_cash_session_id. */
    private function sumUnpaidOrdersForSession($session_id)
    {
        $sql = <<<SQL
        SELECT oh.f_amounttotal, oh.f_data
        FROM o_header oh
        WHERE oh.f_cash_session_id = ?
          AND oh.f_state IN (1, 2)
        SQL;
        $rs = $this->db->select($sql, "i", [$session_id]);
        $sum = 0.0;
        while ($row = $rs->fetch_assoc()) {
            $sum += $this->orderUnpaidAmount($row);
        }
        return $sum;
    }
}
