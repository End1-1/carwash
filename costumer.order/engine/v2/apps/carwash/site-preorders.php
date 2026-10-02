<?php
# © 2026 , Kudryashov Vasili
# Список веб-предзаказов (o_site_preorder) для кассового приложения.

require_once __DIR__ . "/index.php";

class SitePreorders extends Auth
{
    private const STATUS_ACTIVE = 1;
    private const STATUS_DONE = 2;
    private const STATUS_CANCELLED = 3;

    /** Route: /engine/v2/carwash/site-preorders/list */
    public function List($params)
    {
        $this->result['data'] = [
            'active' => $this->fetchByStatus(self::STATUS_ACTIVE, 200),
            'history' => $this->fetchHistory(30),
        ];
        $this->echoResult();
    }

    /** Route: /engine/v2/carwash/site-preorders/start */
    public function Start($params)
    {
        $id = (int)($params->id ?? $params->f_id ?? 0);
        if ($id <= 0) {
            dieWithCode('Invalid id', 400);
        }

        $row = $this->select(
            'SELECT f_id, f_status, f_data FROM o_site_preorder WHERE f_id = ?',
            'i',
            [$id]
        )->fetch_assoc();

        if (!$row) {
            dieWithCode('Not found', 404);
        }
        if ((int)$row['f_status'] !== self::STATUS_ACTIVE) {
            dieWithCode('Preorder is not active', 400);
        }

        $data = json_decode($row['f_data'] ?? '{}', true);
        if (!is_array($data)) {
            $data = [];
        }

        $orderId = trim((string)($params->order_id ?? ''));
        if ($orderId !== '') {
            $data['pos_order_id'] = $orderId;
        }

        $this->update('o_site_preorder', [
            'f_status' => self::STATUS_DONE,
            'f_data' => json_encode($data, JSON_UNESCAPED_UNICODE),
        ], $id);

        $this->result['data'] = [
            'f_id' => $id,
            'f_status' => self::STATUS_DONE,
        ];
        $this->echoResult();
    }

    private function fetchByStatus(int $status, int $limit): array
    {
        $rows = $this->select(
            <<<SQL
            SELECT o.f_id, o.f_date, o.f_status, o.f_data,
                   p.f_phone, p.f_name, p.f_taxname, p.f_contact
            FROM o_site_preorder o
            LEFT JOIN c_partners p ON p.f_id = o.f_user
            WHERE o.f_status = ?
            ORDER BY o.f_date DESC
            LIMIT ?
            SQL,
            'ii',
            [$status, $limit]
        )->fetch_all(MYSQLI_ASSOC);

        return $this->mapRows($rows);
    }

    private function fetchHistory(int $limit): array
    {
        $rows = $this->select(
            <<<SQL
            SELECT o.f_id, o.f_date, o.f_status, o.f_data,
                   p.f_phone, p.f_name, p.f_taxname, p.f_contact
            FROM o_site_preorder o
            LEFT JOIN c_partners p ON p.f_id = o.f_user
            WHERE o.f_status IN (?, ?)
            ORDER BY o.f_date DESC
            LIMIT ?
            SQL,
            'iii',
            [self::STATUS_DONE, self::STATUS_CANCELLED, $limit]
        )->fetch_all(MYSQLI_ASSOC);

        return $this->mapRows($rows);
    }

    private function mapRows(array $rows): array
    {
        $out = [];
        foreach ($rows as $row) {
            $data = json_decode($row['f_data'] ?? '{}', true);
            if (!is_array($data)) {
                $data = [];
            }

            $customer = is_array($data['customer'] ?? null) ? $data['customer'] : [];
            $name = trim((string)($customer['f_name'] ?? ''));
            if ($name === '') {
                $name = trim((string)($row['f_name'] ?? ''));
            }
            if ($name === '') {
                $name = trim((string)($row['f_taxname'] ?? ''));
            }
            if ($name === '') {
                $name = trim((string)($row['f_contact'] ?? ''));
            }

            $phone = trim((string)($customer['f_phone'] ?? ''));
            if ($phone === '') {
                $phone = trim((string)($row['f_phone'] ?? ''));
            }

            $out[] = [
                'f_id' => (int)$row['f_id'],
                'f_date' => $row['f_date'],
                'f_status' => (int)$row['f_status'],
                'total' => (float)($data['total'] ?? 0),
                'customer_name' => $name,
                'customer_phone' => $phone,
                'car' => $data['car'] ?? null,
                'car_type' => $data['car_type'] ?? null,
                'cart' => $data['cart'] ?? [],
                'visit' => $data['visit'] ?? null,
                'visit_datetime' => is_array($data['visit'] ?? null)
                    ? ($data['visit']['f_datetime'] ?? null)
                    : null,
            ];
        }
        return $out;
    }
}
