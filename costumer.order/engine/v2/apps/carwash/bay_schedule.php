<?php
/**
 * Bay schedule for goods-in-progress.
 * Mirrors carwash.backend/status/bay_schedule.js (tested walkthrough):
 * 3 bays, 60 minutes wash+dry from bay entry, free parking until entry+120,
 * then paid parking off the schedule. Queue is arrival order and only enters
 * a bay that is not in its wash hour. The clock starts when the bay is assigned.
 *
 * Test time scale (staff settings, default off) divides only those two
 * durations. Entry timestamps stay Y-m-d H:i:s of the assignment instant.
 * The 20-second status poll is not scaled.
 */

const CARWASH_BAY_COUNT = 3;
const CARWASH_WASH_SEC = 3600;
const CARWASH_PARK_END_SEC = 7200;

function carwash_bay_time_scale_paths(): array
{
    return [
        __DIR__ . DIRECTORY_SEPARATOR . "bay_time_scale.json",
        rtrim(sys_get_temp_dir(), "/\\") . DIRECTORY_SEPARATOR . "carwash_bay_time_scale.json",
    ];
}

function carwash_bay_time_scale_load(): array
{
    $off = ["enabled" => 0, "coeff" => 60];
    $path = null;
    $bestMtime = -1;
    foreach (carwash_bay_time_scale_paths() as $candidate) {
        if (!is_file($candidate)) {
            continue;
        }
        $mtime = @filemtime($candidate);
        if ($mtime === false) {
            $mtime = 0;
        }
        if ($mtime >= $bestMtime) {
            $bestMtime = $mtime;
            $path = $candidate;
        }
    }
    if ($path === null) {
        return $off;
    }
    $raw = @file_get_contents($path);
    if ($raw === false || $raw === "") {
        return $off;
    }
    $json = json_decode($raw, true);
    if (!is_array($json)) {
        return $off;
    }
    $enabled = ($json["enabled"] ?? 0) === 1
        || ($json["enabled"] ?? 0) === "1"
        || ($json["enabled"] ?? 0) === true;
    $coeff = isset($json["coeff"]) ? (int)$json["coeff"] : 60;
    if ($coeff < 1) {
        $coeff = 60;
    }
    if ($coeff > 1000000) {
        $coeff = 1000000;
    }
    return ["enabled" => $enabled ? 1 : 0, "coeff" => $coeff];
}

function carwash_bay_time_scale_save(int $enabled, int $coeff): bool
{
    if ($coeff < 1) {
        $coeff = 60;
    }
    if ($coeff > 1000000) {
        $coeff = 1000000;
    }
    $payload = json_encode(
        ["enabled" => $enabled ? 1 : 0, "coeff" => $coeff],
        JSON_UNESCAPED_UNICODE
    );
    if ($payload === false) {
        return false;
    }
    $ok = false;
    foreach (carwash_bay_time_scale_paths() as $path) {
        $tmp = $path . ".tmp";
        if (file_put_contents($tmp, $payload, LOCK_EX) === false) {
            continue;
        }
        if (is_file($path)) {
            @unlink($path);
        }
        if (@rename($tmp, $path)) {
            $ok = true;
        } else {
            @unlink($tmp);
        }
    }
    return $ok;
}

function carwash_bay_time_scale_durations(): array
{
    $scale = carwash_bay_time_scale_load();
    $wash = (float)CARWASH_WASH_SEC;
    $park = (float)CARWASH_PARK_END_SEC;
    if ((int)$scale["enabled"] === 1) {
        $coeff = (int)$scale["coeff"];
        if ($coeff < 1) {
            $coeff = 60;
        }
        $wash = CARWASH_WASH_SEC / $coeff;
        $park = CARWASH_PARK_END_SEC / $coeff;
    }
    return [
        "enabled" => (int)$scale["enabled"],
        "coeff" => (int)$scale["coeff"],
        "wash" => $wash,
        "park" => $park,
    ];
}

function carwash_bay_time_scale_public(): array
{
    $d = carwash_bay_time_scale_durations();
    return [
        "enabled" => $d["enabled"],
        "coeff" => $d["coeff"],
        "wash_sec" => $d["wash"],
        "park_end_sec" => $d["park"],
    ];
}

function carwash_sql_after($entry, $seconds): string
{
    return date("Y-m-d H:i:s", (int)round((int)$entry + (float)$seconds));
}

function carwash_bay_schedule_apply($db): void
{
    $lock = $db->select("SELECT GET_LOCK('carwash_bay_schedule', 3) AS lck")->fetch_assoc();
    if (!$lock || (int)($lock["lck"] ?? 0) !== 1) {
        return;
    }
    try {
        carwash_bay_schedule_apply_locked($db);
    } finally {
        $db->select("SELECT RELEASE_LOCK('carwash_bay_schedule')", "", [], true);
    }
}

function carwash_bay_schedule_apply_locked($db): void
{
    $rows = $db->select(
        "SELECT ogp.f_id, ogp.f_header, ogp.f_status, ogp.f_data, oh.f_table
         FROM o_goods_process ogp
         INNER JOIN o_header oh ON oh.f_id = ogp.f_header
         WHERE ogp.f_status IN (1, 2, 3)"
    )->fetch_all(MYSQLI_ASSOC);
    if (!$rows) {
        return;
    }

    $tables = $db->select(
        "SELECT f_id, f_name FROM h_tables WHERE f_hall = 1"
    )->fetch_all(MYSQLI_ASSOC);
    $tableIds = carwash_bay_table_ids($tables ?: []);

    $groups = [];
    foreach ($rows as $row) {
        $hid = (string)$row["f_header"];
        if (!isset($groups[$hid])) {
            $groups[$hid] = [];
        }
        $groups[$hid][] = $row;
    }

    $dur = carwash_bay_time_scale_durations();
    $washSec = $dur["wash"];
    $parkSec = $dur["park"];

    $cars = [];
    $linesByHeader = [];
    foreach ($groups as $hid => $lines) {
        $cars[] = carwash_car_from_lines($hid, $lines, $washSec);
        $linesByHeader[$hid] = $lines;
    }

    $now = time();
    $next = carwash_advance_bay_schedule($cars, $now, $washSec, $parkSec);

    foreach ($next as $car) {
        $hid = $car["headerId"];
        $lines = $linesByHeader[$hid] ?? [];
        foreach ($lines as $line) {
            $ogp = carwash_ogp_array($line["f_data"]);
            $before = carwash_schedule_signature((int)$line["f_status"], $ogp);
            $updated = carwash_apply_car_state($ogp, $car, $now, $washSec, $parkSec);
            $status = (int)$car["status"];
            $after = carwash_schedule_signature($status, $updated);
            if ($before === $after) {
                continue;
            }
            $json = json_encode($updated, JSON_UNESCAPED_UNICODE);
            $db->select(
                "UPDATE o_goods_process SET f_status = ?, f_data = ? WHERE f_id = ?",
                "iss",
                [$status, $json, $line["f_id"]],
                true
            );
        }

        if ((int)$car["status"] === 2 && (int)$car["bay"] >= 1) {
            $idx = (int)$car["bay"] - 1;
            if (isset($tableIds[$idx]) && (int)$tableIds[$idx] > 0) {
                $tid = (int)$tableIds[$idx];
                $current = (int)($lines[0]["f_table"] ?? 0);
                if ($current !== $tid) {
                    $db->select(
                        "UPDATE o_header SET f_table = ? WHERE f_id = ?",
                        "is",
                        [$tid, $hid],
                        true
                    );
                }
            }
        }
    }
}

function carwash_bay_table_ids(array $tables): array
{
    usort($tables, function ($a, $b) {
        $an = carwash_bay_sort_key($a);
        $bn = carwash_bay_sort_key($b);
        if ($an === $bn) {
            return ((int)$a["f_id"]) <=> ((int)$b["f_id"]);
        }
        return $an <=> $bn;
    });
    $ids = [];
    foreach ($tables as $t) {
        if (count($ids) >= CARWASH_BAY_COUNT) {
            break;
        }
        $ids[] = (int)$t["f_id"];
    }
    return $ids;
}

function carwash_bay_sort_key(array $t): int
{
    $name = trim((string)($t["f_name"] ?? ""));
    if (preg_match('/(\d+)/', $name, $m)) {
        return (int)$m[1];
    }
    return (int)($t["f_id"] ?? 0);
}

function carwash_ogp_array($raw): array
{
    if (is_array($raw)) {
        return $raw;
    }
    if (!is_string($raw) || $raw === "") {
        return [];
    }
    $decoded = json_decode($raw, true);
    return is_array($decoded) ? $decoded : [];
}

function carwash_sql_time($value): ?int
{
    if ($value === null || $value === "") {
        return null;
    }
    $t = strtotime((string)$value);
    if ($t === false) {
        return null;
    }
    return $t;
}

function carwash_car_from_lines(string $headerId, array $lines, float $washSec = CARWASH_WASH_SEC): array
{
    $lineIds = [];
    $arrival = null;
    $wash = null;
    $free = null;
    $paid = false;

    foreach ($lines as $line) {
        $lineIds[] = (string)$line["f_id"];
        $ogp = carwash_ogp_array($line["f_data"]);
        $st = (int)$line["f_status"];
        $ss = isset($ogp["f_substatus"]) && $ogp["f_substatus"] !== ""
            ? (int)$ogp["f_substatus"]
            : ($st === 1 ? 1 : 0);
        $arr = carwash_sql_time($ogp["f_status_1_1_time"] ?? null);
        if ($arr !== null && ($arrival === null || $arr < $arrival)) {
            $arrival = $arr;
        }
        $entry = carwash_sql_time($ogp["f_bay_entry"] ?? null);
        if ($entry === null) {
            $entry = carwash_sql_time($ogp["f_status_2_2_time"] ?? null);
        }
        if ($entry === null) {
            $entry = carwash_sql_time($ogp["f_status_2_3_time"] ?? null);
        }
        $bay = (int)($ogp["f_bay"] ?? 0);
        if (!empty($ogp["f_paid_parking"]) || $st === 4 || ($st === 3 && $ss === 5)) {
            $paid = true;
        }
        if ($st === 2 && ($ss === 2 || $ss === 3)) {
            if ($wash === null || ($entry !== null && ($wash["entry"] === null || $entry < $wash["entry"]))) {
                $wash = ["entry" => $entry, "bay" => $bay];
            }
        } elseif ($st === 3 && $ss === 4) {
            if ($entry === null) {
                $doneAt = carwash_sql_time($ogp["f_status_3_4_time"] ?? null);
                $entry = $doneAt !== null ? $doneAt - $washSec : time() - $washSec;
            }
            if ($free === null) {
                $free = ["entry" => $entry];
            }
        }
    }

    if ($paid) {
        return carwash_car_state($headerId, $lineIds, $arrival, 4, 5, 0, null, true);
    }
    if ($wash !== null) {
        return carwash_car_state($headerId, $lineIds, $arrival, 2, 2, $wash["bay"], $wash["entry"], false);
    }
    if ($free !== null) {
        return carwash_car_state($headerId, $lineIds, $arrival, 3, 4, 0, $free["entry"], false);
    }
    return carwash_car_state($headerId, $lineIds, $arrival, 1, 1, 0, null, false);
}

function carwash_car_state($headerId, $lineIds, $arrival, $status, $substatus, $bay, $entry, $paid): array
{
    return [
        "headerId" => (string)$headerId,
        "lineIds" => $lineIds,
        "arrival" => $arrival,
        "status" => (int)$status,
        "substatus" => (int)$substatus,
        "bay" => (int)$bay,
        "entry" => $entry,
        "paid" => (bool)$paid,
    ];
}

function carwash_advance_bay_schedule(array $input, int $now, float $washSec = CARWASH_WASH_SEC, float $parkSec = CARWASH_PARK_END_SEC): array
{
    $cars = [];
    foreach ($input as $c) {
        $cars[] = $c;
    }
    $active = [];

    foreach ($cars as $i => $c) {
        if (!empty($c["paid"]) || (int)$c["status"] === 4 || ((int)$c["status"] === 3 && (int)$c["substatus"] === 5)) {
            $cars[$i] = carwash_mark_paid($c);
            continue;
        }
        if ((int)$c["status"] === 2 && ((int)$c["substatus"] === 2 || (int)$c["substatus"] === 3)) {
            if ($c["entry"] === null) {
                $c["entry"] = $now;
            }
            if ($now >= $c["entry"] + $parkSec) {
                $cars[$i] = carwash_mark_paid($c);
                continue;
            }
            if ($now >= $c["entry"] + $washSec) {
                $c = carwash_mark_free($c);
            } else {
                $c["status"] = 2;
                $c["substatus"] = 2;
                $c["paid"] = false;
            }
        } elseif ((int)$c["status"] === 3 && (int)$c["substatus"] === 4) {
            if ($c["entry"] === null || $now >= $c["entry"] + $parkSec) {
                $cars[$i] = carwash_mark_paid($c);
                continue;
            }
            $c = carwash_mark_free($c);
        } else {
            $c = carwash_mark_queue($c);
        }
        $cars[$i] = $c;
        $active[] = $i;
    }

    $washing = [];
    foreach ($active as $idx) {
        if ((int)$cars[$idx]["status"] === 2) {
            $washing[] = $idx;
        }
    }
    usort($washing, function ($ia, $ib) use ($cars) {
        $d = ($cars[$ia]["entry"] ?? 0) <=> ($cars[$ib]["entry"] ?? 0);
        if ($d !== 0) {
            return $d;
        }
        return strcmp($cars[$ia]["headerId"], $cars[$ib]["headerId"]);
    });

    $used = [];
    $needBay = [];
    foreach ($washing as $idx) {
        $bay = (int)$cars[$idx]["bay"];
        if ($bay >= 1 && $bay <= CARWASH_BAY_COUNT && empty($used[$bay])) {
            $used[$bay] = $cars[$idx]["headerId"];
        } else {
            $cars[$idx]["bay"] = 0;
            $needBay[] = $idx;
        }
    }
    foreach ($needBay as $idx) {
        $bay = carwash_lowest_free_bay($used);
        if (!$bay) {
            $cars[$idx] = carwash_mark_queue($cars[$idx]);
        } else {
            $entry = $cars[$idx]["entry"] === null ? $now : $cars[$idx]["entry"];
            $cars[$idx] = carwash_mark_wash($cars[$idx], $bay, $entry);
            $used[$bay] = $cars[$idx]["headerId"];
        }
    }

    $queue = [];
    foreach ($active as $idx) {
        if ((int)$cars[$idx]["status"] === 1) {
            $queue[] = $idx;
        }
    }
    usort($queue, function ($ia, $ib) use ($cars, $now) {
        $aa = $cars[$ia]["arrival"] === null ? $now : $cars[$ia]["arrival"];
        $bb = $cars[$ib]["arrival"] === null ? $now : $cars[$ib]["arrival"];
        if ($aa !== $bb) {
            return $aa <=> $bb;
        }
        return strcmp($cars[$ia]["headerId"], $cars[$ib]["headerId"]);
    });
    foreach ($queue as $idx) {
        $free = carwash_lowest_free_bay($used);
        if (!$free) {
            break;
        }
        $cars[$idx] = carwash_mark_wash($cars[$idx], $free, $now);
        $used[$free] = $cars[$idx]["headerId"];
    }

    return $cars;
}

function carwash_lowest_free_bay(array $used): int
{
    for ($b = 1; $b <= CARWASH_BAY_COUNT; $b++) {
        if (empty($used[$b])) {
            return $b;
        }
    }
    return 0;
}

function carwash_mark_paid(array $c): array
{
    $c["status"] = 4;
    $c["substatus"] = 5;
    $c["bay"] = 0;
    $c["paid"] = true;
    return $c;
}

function carwash_mark_free(array $c): array
{
    $c["status"] = 3;
    $c["substatus"] = 4;
    $c["bay"] = 0;
    $c["paid"] = false;
    return $c;
}

function carwash_mark_wash(array $c, int $bay, int $entry): array
{
    $c["status"] = 2;
    $c["substatus"] = 2;
    $c["bay"] = $bay;
    $c["entry"] = $entry;
    $c["paid"] = false;
    return $c;
}

function carwash_mark_queue(array $c): array
{
    $c["status"] = 1;
    $c["substatus"] = 1;
    $c["bay"] = 0;
    $c["entry"] = null;
    $c["paid"] = false;
    return $c;
}

function carwash_apply_car_state(array $ogp, array $car, int $now, float $washSec = CARWASH_WASH_SEC, float $parkSec = CARWASH_PARK_END_SEC): array
{
    $ogp["f_substatus"] = (int)$car["substatus"];
    $ogp["f_bay"] = (int)$car["bay"];
    if (!empty($car["paid"]) || (int)$car["status"] === 4) {
        $ogp["f_substatus"] = 5;
        $ogp["f_bay"] = 0;
        $ogp["f_paid_parking"] = 1;
        if (empty($ogp["f_paid_parking_time"])) {
            $ogp["f_paid_parking_time"] = date("Y-m-d H:i:s", $now);
        }
        return $ogp;
    }
    unset($ogp["f_paid_parking"]);
    if ((int)$car["status"] === 2 && $car["entry"] !== null) {
        $entryStr = date("Y-m-d H:i:s", (int)$car["entry"]);
        $ogp["f_bay"] = (int)$car["bay"];
        $ogp["f_substatus"] = 2;
        $ogp["f_bay_entry"] = $entryStr;
        $ogp["f_status_2_2_time"] = $entryStr;
        $ogp["f_wash_end"] = carwash_sql_after($car["entry"], $washSec);
        $ogp["f_free_parking_end"] = carwash_sql_after($car["entry"], $parkSec);
        return $ogp;
    }
    if ((int)$car["status"] === 3 && (int)$car["substatus"] === 4 && $car["entry"] !== null) {
        $entryStr = date("Y-m-d H:i:s", (int)$car["entry"]);
        $ogp["f_bay"] = 0;
        $ogp["f_substatus"] = 4;
        $ogp["f_bay_entry"] = $entryStr;
        $ogp["f_status_3_4_time"] = carwash_sql_after($car["entry"], $washSec);
        $ogp["f_free_parking_end"] = carwash_sql_after($car["entry"], $parkSec);
        return $ogp;
    }
    $ogp["f_substatus"] = 1;
    $ogp["f_bay"] = 0;
    unset($ogp["f_bay_entry"]);
    return $ogp;
}

function carwash_schedule_signature(int $status, array $ogp): string
{
    return json_encode([
        $status,
        (int)($ogp["f_substatus"] ?? 0),
        (int)($ogp["f_bay"] ?? 0),
        (string)($ogp["f_bay_entry"] ?? ""),
        empty($ogp["f_paid_parking"]) ? 0 : 1,
    ]);
}
