<?php
# © 2026 , Kudryashov Vasili
# Публичный API онлайн-заказа клиентов (сайт costumer.order).

require_once __DIR__ . "/../../worker/db.php";
require_once __DIR__ . "/../../worker/uuid.php";

class Customer extends Db
{
    private const STATUS_ACTIVE = 1;
    private const STATUS_DONE = 2;
    private const STATUS_CANCELLED = 3;

    /** s_activation.f_state */
    private const ACTIVATION_PENDING = 1;
    private const ACTIVATION_USED = 2;
    private const ACTIVATION_INVALID = 3;
    private const ACTIVATION_SITE_SESSION = 4;

    private ?array $partner = null;

    private function failJson(string $message, int $httpCode = 400): void
    {
        http_response_code($httpCode);
        $this->result['status'] = 0;
        $this->result['data'] = $message;
        $this->echoResult();
        exit;
    }

    public function GetCarCatalog($params)
    {
        $fCar = (int)($params->f_car ?? 0);

        if ($fCar > 0) {
            $models = $this->select(
                "SELECT f_id, f_car, f_name, f_type FROM s_car_model WHERE f_car = ? ORDER BY f_name",
                "i",
                [$fCar]
            )->fetch_all(MYSQLI_ASSOC);

            $this->result['data'] = [
                'models' => $models,
            ];
            $this->echoResult();
            return;
        }

        $cars = $this->select(
            "SELECT f_id, f_name FROM s_car ORDER BY f_name"
        )->fetch_all(MYSQLI_ASSOC);

        $this->result['data'] = [
            'cars' => $cars,
        ];
        $this->echoResult();
    }

    /** Route: /engine/v2/carwash/customer/get-menu */
    public function GetMenu($params)
    {
        $fMenu = (int)($params->f_menu ?? 0);
        if ($fMenu <= 0) {
            $fMenu = 1;
        }

        $part1 = $this->select(
            "SELECT f_id, f_name FROM d_part1"
        )->fetch_all(MYSQLI_ASSOC);

        $part2 = $this->select(
            <<<SQL
            SELECT p.f_id, p.f_class AS f_part, p.f_name, COALESCE(s.f_data, '') AS f_image
            FROM c_groups p
            LEFT JOIN s_images s ON s.f_id = p.f_image
            SQL
        )->fetch_all(MYSQLI_ASSOC);

        $dish = $this->select(
            <<<SQL
            SELECT
                d.f_group AS f_part,
                m.f_dish,
                d.f_name AS f_dish_name,
                m.f_price,
                m.f_print1,
                m.f_print2,
                '' AS f_image,
                COALESCE(d.f_description, '') AS f_comment,
                CAST(COALESCE(JSON_VALUE(d.f_data, '$.f_cooking_time'), 60) AS UNSIGNED) AS f_cooking_time,
                COALESCE(d.f_adg, p2.f_adgcode) AS f_adgt
            FROM c_menu m
            LEFT JOIN c_goods d ON d.f_id = m.f_dish
            LEFT JOIN c_groups p2 ON p2.f_id = d.f_group
            WHERE m.f_state = 1 AND m.f_menu = ?
            SQL,
            "i",
            [$fMenu]
        )->fetch_all(MYSQLI_ASSOC);

        if (empty($dish)) {
            $this->result['status'] = 0;
            $this->result['data'] = "No dishes for menu {$fMenu}";
            $this->echoResult();
            return;
        }

        $this->result['data'] = [
            'f_menu' => $fMenu,
            'part1' => $part1,
            'part2' => $part2,
            'dish' => $dish,
        ];
        $this->echoResult();
    }

    /** Route: /engine/v2/carwash/customer/send-otp */
    public function SendOtp($params)
    {
        $phone = $this->normalizePhone($params->phone ?? '');
        $name = trim((string)($params->name ?? ''));
        if ($phone === '') {
            $this->failJson('Invalid phone', 400);
        }
        if (mb_strlen($name) < 2) {
            $this->failJson('Name required', 400);
        }

        $userId = $this->findOrCreatePartner($phone, $name);
        $token = uuid_v4();
        $confirmationCode = (string) random_int(1000, 9999);

        $this->select(
            "UPDATE s_activation SET f_state = ? WHERE f_state = ? AND f_phone = ?",
            "iis",
            [self::ACTIVATION_INVALID, self::ACTIVATION_PENDING, $phone],
            true
        );

        $this->insert('s_activation', [
            'f_ip' => $this->getClientIp(),
            'f_state' => self::ACTIVATION_PENDING,
            'f_session' => $token,
            'f_created' => date('Y-m-d H:i:s'),
            'f_code' => $confirmationCode,
            'f_phone' => $phone,
            'f_user' => $userId,
        ]);

        $this->sendSms($phone, (int) $confirmationCode);

        $this->result['data'] = [
            'token' => $token,
            'phone' => $phone,
            'name' => $name,
        ];
        $this->echoResult();
    }

    /** Route: /engine/v2/carwash/customer/verify-otp */
    public function VerifyOtp($params)
    {
        $token = trim((string)($params->token ?? ''));
        $code = preg_replace('/\D+/', '', (string)($params->code ?? ''));
        if ($token === '' || $code === '') {
            $this->failJson('Token and code required', 400);
        }

        $activation = $this->select(
            <<<SQL
            SELECT f_user, f_phone
            FROM s_activation
            WHERE f_session = ? AND f_state = ? AND TRIM(LEADING '0' FROM f_code) = TRIM(LEADING '0' FROM ?)
            SQL,
            'sis',
            [$token, self::ACTIVATION_PENDING, $code]
        )->fetch_assoc();
        if (empty($activation)) {
            $this->failJson(Translator::t('Invalid confirmation code'), 401);
        }

        $this->select(
            "UPDATE s_activation SET f_state = ? WHERE f_session = ? AND f_state = ?",
            "isi",
            [self::ACTIVATION_USED, $token, self::ACTIVATION_PENDING],
            true
        );

        $partner = $this->select(
            <<<SQL
            SELECT f_id, f_phone, f_name, f_taxname, f_contact
            FROM c_partners
            WHERE f_id = ?
            SQL,
            "i",
            [(int)$activation['f_user']]
        )->fetch_assoc();
        if (empty($partner)) {
            $this->failJson('User not found', 404);
        }
        $partner = $this->mapPartnerRow($partner);

        $this->select(
            "UPDATE s_activation SET f_state = ? WHERE f_state = ? AND f_phone = ?",
            "iis",
            [self::ACTIVATION_INVALID, self::ACTIVATION_SITE_SESSION, $partner['f_phone']],
            true
        );

        $sessionToken = uuid_v4();
        $this->insert('s_activation', [
            'f_ip' => $this->getClientIp(),
            'f_state' => self::ACTIVATION_SITE_SESSION,
            'f_session' => $sessionToken,
            'f_created' => date('Y-m-d H:i:s'),
            'f_code' => '',
            'f_phone' => $partner['f_phone'],
            'f_user' => (int)$partner['f_id'],
        ]);

        $this->result['data'] = [
            'token' => $sessionToken,
            'user' => [
                'f_id' => (int)$partner['f_id'],
                'f_phone' => $partner['f_phone'],
                'f_name' => $partner['f_name'],
            ],
        ];
        $this->echoResult();
    }

    /** Route: /engine/v2/carwash/customer/get-visit-slots */
    public function GetVisitSlots($params)
    {
        $date = trim((string)($params->f_date ?? ''));
        if ($date === '') {
            $date = date('Y-m-d');
        }
        if (!$this->isVisitDateAllowed($date)) {
            dieWithCode('Invalid visit date', 400);
        }

        // Заглушка: 24/7, позже — занятость из БД/расписания.
        $this->result['data'] = [
            'f_date' => $date,
            'slots' => $this->buildVisitSlotsStub($date),
        ];
        $this->echoResult();
    }

    /** Route: /engine/v2/carwash/customer/submit-order */
    public function SubmitOrder($params)
    {
        $this->requireSiteAuth();

        $cart = $params->cart ?? null;
        if (!is_array($cart) && !($cart instanceof \Traversable)) {
            $cart = [];
        }
        $cart = array_values((array)$cart);
        if (empty($cart)) {
            dieWithCode('Cart is empty', 400);
        }

        $visit = $this->normalizeVisit($params->visit ?? null);
        if ($visit === null) {
            dieWithCode('Visit date/time required', 400);
        }

        $total = (float)($params->total ?? 0);
        if ($total <= 0) {
            $total = $this->calcCartTotal($cart);
        }

        $payload = [
            'car' => $params->car ?? null,
            'car_type' => $params->car_type ?? null,
            'cart' => $cart,
            'total' => $total,
            'visit' => $visit,
            'payment' => $params->payment ?? null,
            'locale' => $params->locale ?? LANG,
            'customer' => [
                'f_id' => (int)$this->partner['f_id'],
                'f_phone' => $this->partner['f_phone'],
                'f_name' => $this->partner['f_name'],
            ],
        ];

        $orderId = $this->insert('o_site_preorder', [
            'f_user' => (int)$this->partner['f_id'],
            'f_date' => date('Y-m-d H:i:s'),
            'f_status' => self::STATUS_ACTIVE,
            'f_data' => json_encode($payload, JSON_UNESCAPED_UNICODE),
        ]);

        $this->result['data'] = [
            'f_id' => $orderId,
            'f_status' => self::STATUS_ACTIVE,
            'total' => $total,
        ];
        $this->echoResult();
    }

    /** Route: /engine/v2/carwash/customer/list-orders */
    public function ListOrders($params)
    {
        $this->requireSiteAuth();
        $userId = (int)$this->partner['f_id'];

        $active = $this->select(
            <<<SQL
            SELECT f_id, f_date, f_status, f_data
            FROM o_site_preorder
            WHERE f_user = ? AND f_status = ?
            ORDER BY f_date DESC
            SQL,
            'ii',
            [$userId, self::STATUS_ACTIVE]
        )->fetch_all(MYSQLI_ASSOC);

        $history = $this->select(
            <<<SQL
            SELECT f_id, f_date, f_status, f_data
            FROM o_site_preorder
            WHERE f_user = ? AND f_status IN (?, ?)
            ORDER BY f_date DESC
            LIMIT 10
            SQL,
            'iii',
            [$userId, self::STATUS_DONE, self::STATUS_CANCELLED]
        )->fetch_all(MYSQLI_ASSOC);

        $this->result['data'] = [
            'active' => $this->mapOrders($active),
            'history' => $this->mapOrders($history),
        ];
        $this->echoResult();
    }

    private function requireSiteAuth(): void
    {
        global $bearerToken;
        if (empty($bearerToken)) {
            $this->failJson('Unauthorized', 401);
        }
        $row = $this->select(
            <<<SQL
            SELECT p.f_id, p.f_phone, p.f_name, p.f_taxname, p.f_contact
            FROM s_activation a
            INNER JOIN c_partners p ON p.f_id = a.f_user
            WHERE a.f_session = ? AND a.f_state = ?
            SQL,
            'si',
            [$bearerToken, self::ACTIVATION_SITE_SESSION]
        )->fetch_assoc();
        if (empty($row)) {
            $this->failJson('Unauthorized', 401);
        }
        $this->partner = $this->mapPartnerRow($row);
    }

    private function findOrCreatePartner(string $phone, string $name): int
    {
        $existing = $this->findPartnerByPhone($phone);
        if ($existing !== null) {
            if ($name !== '' && $name !== $existing['f_name']) {
                $this->update('c_partners', [
                    'f_name' => $name,
                    'f_taxname' => $name,
                    'f_contact' => $name,
                ], (int)$existing['f_id']);
            }
            return (int)$existing['f_id'];
        }

        return (int)$this->insert('c_partners', [
            'f_phone' => $phone,
            'f_name' => $name,
            'f_taxname' => $name,
            'f_contact' => $name,
        ]);
    }

    private function findPartnerByPhone(string $phone): ?array
    {
        $row = $this->select(
            "SELECT f_id, f_phone, f_name, f_taxname, f_contact FROM c_partners WHERE f_phone = ? LIMIT 1",
            "s",
            [$phone]
        )->fetch_assoc();
        if (!empty($row)) {
            return $this->mapPartnerRow($row);
        }

        $digits = preg_replace('/\D+/', '', $phone);
        if (str_starts_with($digits, '374')) {
            $digits = substr($digits, 3);
        }
        if (strlen($digits) !== 8) {
            return null;
        }

        $candidates = $this->select(
            "SELECT f_id, f_phone, f_name, f_taxname, f_contact FROM c_partners WHERE f_phone LIKE ?",
            "s",
            ['%' . $digits]
        )->fetch_all(MYSQLI_ASSOC);

        foreach ($candidates as $candidate) {
            $stored = preg_replace('/\D+/', '', (string)($candidate['f_phone'] ?? ''));
            if (str_starts_with($stored, '374')) {
                $stored = substr($stored, 3);
            }
            if ($stored === $digits) {
                return $this->mapPartnerRow($candidate);
            }
        }

        return null;
    }

    private function mapPartnerRow(array $row): array
    {
        $name = trim((string)($row['f_name'] ?? ''));
        if ($name === '') {
            $name = trim((string)($row['f_taxname'] ?? ''));
        }
        if ($name === '') {
            $name = trim((string)($row['f_contact'] ?? ''));
        }

        return [
            'f_id' => (int)$row['f_id'],
            'f_phone' => (string)($row['f_phone'] ?? ''),
            'f_name' => $name,
        ];
    }

    private function normalizePhone(string $raw): string
    {
        $digits = preg_replace('/\D+/', '', $raw);
        if ($digits === '') {
            return '';
        }
        if (str_starts_with($digits, '374')) {
            $digits = substr($digits, 3);
        }
        if (strlen($digits) !== 8) {
            return '';
        }
        return '+374' . $digits;
    }

    private function sendSms(string $phone, int $code): void
    {
        global $otp_login, $otp_pass, $otp_url, $otp_ordinator;

        if (empty($otp_url) || empty($otp_login)) {
            return;
        }

        $data = [
            'messages' => [[
                'recipient' => $phone,
                'priority' => '2',
                'sms' => [
                    'originator' => $otp_ordinator ?? 'Carwash',
                    'content' => [
                        'text' => "<#> Your OTP code: \n {$code} \n99Yxa876Gxa",
                    ],
                ],
                'message-id' => date('YmdHis'),
            ]],
        ];

        $ch = curl_init($otp_url);
        curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json; charset=utf-8']);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_USERPWD, "{$otp_login}:{$otp_pass}");
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        $this->result['sms'] = [
            'http_code' => $httpCode,
            'response' => $response,
        ];
    }

    private function calcCartTotal(array $cart): float
    {
        $sum = 0.0;
        foreach ($cart as $item) {
            $item = (array)$item;
            $sum += ((float)($item['f_price'] ?? 0)) * ((int)($item['f_qty'] ?? 1));
        }
        return $sum;
    }

    private const VISIT_DAYS_AHEAD = 3;
    private const VISIT_SLOT_MINUTES = 30;

    private function isVisitDateAllowed(string $ymd): bool
    {
        $dt = \DateTime::createFromFormat('Y-m-d', $ymd);
        if (!$dt || $dt->format('Y-m-d') !== $ymd) {
            return false;
        }
        $today = new \DateTime('today');
        $max = (clone $today)->modify('+' . (self::VISIT_DAYS_AHEAD - 1) . ' days');
        return $dt >= $today && $dt <= $max;
    }

    /** Заглушка слотов 24/7; позже — фильтр по занятости. */
    private function buildVisitSlotsStub(string $ymd): array
    {
        $slots = [];
        for ($h = 0; $h < 24; $h++) {
            foreach ([0, 30] as $m) {
                $slots[] = sprintf('%02d:%02d', $h, $m);
            }
        }
        if ($ymd === date('Y-m-d')) {
            $now = new \DateTime();
            $mins = (int)$now->format('G') * 60 + (int)$now->format('i');
            $rem = $mins % self::VISIT_SLOT_MINUTES;
            if ($rem > 0) {
                $mins += self::VISIT_SLOT_MINUTES - $rem;
            } elseif ((int)$now->format('s') > 0) {
                $mins += self::VISIT_SLOT_MINUTES;
            }
            $slots = array_values(array_filter($slots, static function (string $slot) use ($mins): bool {
                [$hh, $mm] = array_map('intval', explode(':', $slot));
                return $hh * 60 + $mm >= $mins;
            }));
        }
        return $slots;
    }

    private function normalizeVisit($raw): ?array
    {
        if ($raw === null) {
            return null;
        }
        $v = is_array($raw) ? $raw : (array)$raw;
        $date = trim((string)($v['f_date'] ?? ''));
        $time = trim((string)($v['f_time'] ?? ''));
        if ($date === '' || $time === '') {
            return null;
        }
        if (!$this->isVisitDateAllowed($date)) {
            return null;
        }
        if (!preg_match('/^\d{2}:\d{2}$/', $time)) {
            return null;
        }
        $allowed = $this->buildVisitSlotsStub($date);
        if (!in_array($time, $allowed, true)) {
            return null;
        }
        return [
            'f_date' => $date,
            'f_time' => $time,
            'f_datetime' => $date . ' ' . $time . ':00',
        ];
    }

    private function mapOrders(array $rows): array
    {
        $out = [];
        foreach ($rows as $row) {
            $data = json_decode($row['f_data'] ?? '{}', true);
            if (!is_array($data)) {
                $data = [];
            }
            $out[] = [
                'f_id' => (int)$row['f_id'],
                'f_date' => $row['f_date'],
                'f_status' => (int)$row['f_status'],
                'total' => (float)($data['total'] ?? 0),
                'car_type' => $data['car_type'] ?? null,
                'cart' => $data['cart'] ?? [],
                'visit' => $data['visit'] ?? null,
            ];
        }
        return $out;
    }

    private function getClientIp(): string
    {
        if (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
            return (string)$_SERVER['HTTP_X_FORWARDED_FOR'];
        }
        if (!empty($_SERVER['REMOTE_ADDR'])) {
            return (string)$_SERVER['REMOTE_ADDR'];
        }
        if (!empty($_SERVER['HTTP_CLIENT_IP'])) {
            return (string)$_SERVER['HTTP_CLIENT_IP'];
        }
        return '';
    }
}
