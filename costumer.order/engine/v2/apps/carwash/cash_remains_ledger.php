<?php
# © 2026 , Kudryashov Vasili

require_once __DIR__ . "/index.php";
require_once __DIR__ . "/../worker/dict-payment.php";

/**
 * Касса текущей смены: cash_operations + cash_remains.f_paid_* для оплат заказов прошлых смен.
 */
class CashRemainsLedger extends Auth
{
    /**
     * Заказ принадлежит не текущей смене (другой f_cash_session_id или создан до открытия смены).
     */
    public function isOrderFromPreviousSession(array $orderRow, int $currentSessionId): bool
    {
        $orderSessionId = intval($orderRow["f_cash_session_id"] ?? 0);
        if ($orderSessionId > 0) {
            return $orderSessionId !== $currentSessionId;
        }

        $session = $this->select(
            "SELECT f_date_open FROM cash_session WHERE f_id=?",
            "i",
            [$currentSessionId]
        )->fetch_assoc();
        if (!$session) {
            return false;
        }

        $odata = json_decode($orderRow["f_data"] ?? "{}", true);
        if (!is_array($odata)) {
            $odata = [];
        }
        $openedAt = strtotime(
            trim(($odata["f_date_open"] ?? "1900-01-01") . " " . ($odata["f_time_open"] ?? "00:00:00"))
        );
        $sessionOpen = strtotime($session["f_date_open"] ?? "now");

        return $openedAt > 0 && $openedAt < $sessionOpen;
    }

    private function getPreviousTodayRemain(int $cashboxId, int $sessionId, float $amountOpen): float
    {
        $sql = <<<SQL
        SELECT cr.f_today_remain
        FROM cash_remains cr
        INNER JOIN cash_session cs ON cs.f_id = cr.f_cash_session_id
        WHERE cs.f_cashbox_id = ? AND cs.f_id < ?
        ORDER BY cs.f_id DESC
        LIMIT 1
        SQL;
        $row = $this->select($sql, "ii", [$cashboxId, $sessionId])->fetch_assoc();
        if ($row) {
            return floatval($row["f_today_remain"]);
        }
        return floatval($amountOpen);
    }

    /**
     * Строка cash_remains для открытой смены (создать при отсутствии).
     */
    public function ensureCashRemainsForSession(int $cashboxId, int $sessionId): void
    {
        $exists = $this->select(
            "SELECT f_id FROM cash_remains WHERE f_cash_session_id=?",
            "i",
            [$sessionId]
        )->fetch_assoc();
        if ($exists) {
            return;
        }

        $session = $this->select(
            "SELECT f_amount_open FROM cash_session WHERE f_id=?",
            "i",
            [$sessionId]
        )->fetch_assoc();
        $amountOpen = floatval($session["f_amount_open"] ?? 0);
        $previousRemain = round($this->getPreviousTodayRemain($cashboxId, $sessionId, $amountOpen), 2);

        $this->insert("cash_remains", [
            "f_cash_session_id" => $sessionId,
            "f_previouse_remain" => $previousRemain,
            "f_paid_cash" => 0,
            "f_paid_card" => 0,
            "f_today_cash" => 0,
            "f_today_expenses" => 0,
            "f_today_nopaid" => 0,
            "f_today_remain" => $previousRemain,
        ]);
    }

    public function addPaidFromPreviousSession(
        int $currentSessionId,
        float $cashAmount,
        float $cardAmount
    ): void {
        $cashAmount = round($cashAmount, 2);
        $cardAmount = round($cardAmount, 2);
        if ($cashAmount <= 0 && $cardAmount <= 0) {
            return;
        }

        $row = $this->select(
            "SELECT f_id, f_paid_cash, f_paid_card FROM cash_remains WHERE f_cash_session_id=?",
            "i",
            [$currentSessionId]
        )->fetch_assoc();
        if (!$row) {
            return;
        }

        $this->update("cash_remains", [
            "f_paid_cash" => round(floatval($row["f_paid_cash"]) + $cashAmount, 2),
            "f_paid_card" => round(floatval($row["f_paid_card"]) + $cardAmount, 2),
        ], intval($row["f_id"]));
    }

    /**
     * Приход в кассу текущей смены; для заказа прошлой смены — +f_paid_cash / f_paid_card.
     * cardAmount уже включает Idram.
     */
    public function applyPaymentInCurrentSession(
        array $orderRowBeforeUpdate,
        int $cashboxId,
        int $currentSessionId,
        string $orderId,
        string $orderPrefix,
        float $cashDelta,
        float $cardDelta,
        float $idramDelta,
        int $userId
    ): void {
        $cashDelta = round(max(0, $cashDelta), 2);
        $cardDelta = round(max(0, $cardDelta), 2);
        $idramDelta = round(max(0, $idramDelta), 2);
        $paidCardTotal = $cardDelta + $idramDelta;
        if ($cashDelta <= 0 && $paidCardTotal <= 0) {
            return;
        }

        $this->ensureCashRemainsForSession($cashboxId, $currentSessionId);
        $now = date("Y-m-d H:i:s");
        $baseOp = [
            "f_cashbox_id" => $cashboxId,
            "f_session_id" => $currentSessionId,
            "f_order_id" => $orderId,
            "f_user" => $userId,
            "f_operation_type" => 1,
            "f_datetime" => $now,
            "f_comment" => $orderPrefix,
        ];

        if ($cashDelta > 0) {
            $this->insert("cash_operations", array_merge($baseOp, [
                "f_payment_type_id" => PAYMENT_TYPE_CASH,
                "f_debit" => $cashDelta,
                "f_credit" => 0,
            ]));
        }
        if ($cardDelta > 0) {
            $this->insert("cash_operations", array_merge($baseOp, [
                "f_payment_type_id" => PAYMENT_TYPE_CARD,
                "f_debit" => $cardDelta,
                "f_credit" => 0,
            ]));
        }
        if ($idramDelta > 0) {
            $this->insert("cash_operations", array_merge($baseOp, [
                "f_payment_type_id" => PAYMENT_TYPE_IDRAM,
                "f_debit" => $idramDelta,
                "f_credit" => 0,
            ]));
        }

        $sessionTotal = $cashDelta + $paidCardTotal;
        $this->select(
            "UPDATE cash_session SET f_amount_expected = f_amount_expected + ? WHERE f_id = ?",
            "di",
            [$sessionTotal, $currentSessionId],
            true
        );

        if ($this->isOrderFromPreviousSession($orderRowBeforeUpdate, $currentSessionId)) {
            $this->addPaidFromPreviousSession($currentSessionId, $cashDelta, $paidCardTotal);
        }
    }
}
