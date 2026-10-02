<?php
require_once (__DIR__ . "/waiter.php");
define("noout", 1);
require_once(__DIR__ . "/hall-state.php");

$t = stmtall("select f_version from s_app where f_app='WAITER'")->fetch_assoc();
if (empty($t)) {
    stmtall("insert into s_app (f_app, f_version) values ('WAITER', '0')");
    $waiterversion = 0;
} else {
    $waiterversion = $t["f_version"];
}

$t = stmtall("select f_version from s_app where f_app='menu'")->fetch_assoc();
if (empty($t)) {
    stmtall("insert into s_app (f_app, f_version) values ('menu', '0')");
    $version = 0;
} else {
    $version = intval($t["f_version"]);
}

$hallState = new HallState();
$orders = $hallState->getData();
$horders = [];
foreach ($orders as $o) {
    $horders[$o["f_table"]] = $o;
}
if ($version == $params->version) {
    printResult(1, ["nochanges" => true, "waiterversion" => $waiterversion, "orders"=>$horders]);
    return;
}

$ttables = stmtall("select * from h_tables")->fetch_all(MYSQLI_ASSOC);
$htables = [];
foreach ($ttables as $t) {
    $htables[$t["f_id"]] = $t;
}

$thalls = stmtall("select * from h_halls")->fetch_all(MYSQLI_ASSOC);
$hhalls = [];
foreach ($thalls as $t) {
    $hhalls[$t["f_id"]] = $t;
}

$tuser = stmtall("select * from s_user where f_state=1")->fetch_all(MYSQLI_ASSOC);
$suser = [];
foreach ($tuser as $t) {
    $suser[$t["f_id"]] = $t;
}

$tstore = stmtall("select * from c_storages")->fetch_all(MYSQLI_ASSOC);
$cstorages = [];
foreach ($tstore as $t) {
    $cstorages[$t["f_id"]] = $t;
}

$tdishspecial = stmtall("select * from d_special")->fetch_all(MYSQLI_ASSOC);
$dishspecial = [];
foreach ($tdishspecial as $t) {
    if (!key_exists($t["f_dish"], $dishspecial)) {
        $dishspecial[$t["f_dish"]] = [];
    }
    array_push($dishspecial[$t["f_dish"]], $t["f_comment"]);
}


$tmenus = stmtall("select * from d_menu_names where f_enabled=1")->fetch_all(MYSQLI_ASSOC);
$menunames = [];
$menu = [];
foreach ($tmenus as $m) {
    $menunames[$m["f_id"]] = $m;
    $menu[strval($m["f_id"])] = $m;
}


$tdpart1 = stmtall("select f_id, f_name from d_part1 where f_id in ("
    . "select f_part from d_part2 where f_id in ("
    . "select f_part from d_dish where f_id in ("
    . "select f_dish from d_menu where f_state=1)))")->fetch_all(MYSQLI_ASSOC);
$dpart1 = [];
foreach ($tdpart1 as $d) {
    $dpart1[$d["f_id"]] = $d;
}
foreach ($menu as $id=>$m) {
    $children = [];
    foreach ($tdpart1 as $d) {
        $d["children"] = [];
        $children[strval($d["f_id"])] = $d;
    }
    $menu[$id]["children"] = $children;
}

$tpart2 = stmtall("with recursive R as ( "
    ."SELECT p1.*, 0 as l "
    ."FROM d_part2 p1 "
    ."WHERE p1.f_parent=0 "
    ."union all "
    ."SELECT p2.*, R.l + 1 "
    ."from d_part2 p2 "
    ."join R ON p2.f_parent=R.f_id "
  .") "
  ."SELECT R.*, c.f_children FROM R "
  ."left JOIN (SELECT  f_parent, GROUP_CONCAT(f_id) AS f_children from d_part2 group BY 1) c ON c.f_parent=r.f_id "
  ."ORDER BY r.l, r.f_queue, r.f_name ")->fetch_all(MYSQLI_ASSOC);
$dpart2 = [];
foreach ($tpart2 as $t) {
    $dpart2[$t["f_id"]] = $t;
    foreach ($menu as $id=>$m) {
        //var_dump($menu[$id]["children"][strval($t["f_part"])]);
        //array_push($menu[$id]["children"][$t["f_part"]], $t);
        $menu[$id]["children"][strval($t["f_part"])]["children"][$t["f_id"]] = $t;
    }
}

$sql = <<<EOD
select m.f_id, m.f_dish, m.f_menu, mn.f_name as f_menuname, 
p1.f_id as f_part1, p1.f_name as f_part1name, p2.f_name as f_part2name, 
    d.f_color, d.f_part, d.f_name, cast(m.f_price as float) as f_price, 
    m.f_store, m.f_print1, m.f_print2, m.f_recent, 
    d.f_extra, if (length(d.f_adgt)>0, d.f_adgt, p2.f_adgcode) as f_adgcode, 
    d.f_service, d.f_discount, 1.0 as f_qty1, 0.0 as f_qty2, 1 as f_state, 
    d.f_addbyqr, d.f_barcode
    from d_menu m 
    left join d_dish d on d.f_id=m.f_dish 
    left join d_part2 p2 on p2.f_id=d.f_part 
    left join d_part1 p1 on p1.f_id=p2.f_part 
    left join d_menu_names mn on mn.f_id=m.f_menu 
    where m.f_state=1 
    order by d.f_queue
EOD;
$tmenu = stmtall($sql)->fetch_all(MYSQLI_ASSOC);
$dmenu = [];
foreach ($tmenu as $d) {
    $dmenu[$d["f_id"]] = $d;
}

$tdish = stmtall("select * from d_dish ")->fetch_all(MYSQLI_ASSOC);
$ddish = [];
foreach ($tdish as $t) {
    $ddish[$t["f_id"]] = $t;
}

$tcashnames = stmtall("select f_id, f_name from e_cash_names order by 2")->fetch_all(MYSQLI_ASSOC);
$dcashnames = [];
foreach ($tcashnames as $c) {
    $dcashnames[$c["f_id"]] = $c;
}

printResult(1, [
    "nochanges" => false,
    "waiterversion" => $waiterversion,
    "version" => $version,
    "h_halls" => $hhalls,
    "h_tables" => $htables,
    "s_user" => $suser,
    "c_storages" => $cstorages,
    "d_special" => $dishspecial,
    "d_menu_names" => $menunames,
    "d_menu" => $dmenu,
    "d_dish" => $ddish,
    "d_part1" => $dpart1,
    "d_part2" => $dpart2,
    "e_cash_names" => $dcashnames,
    "orders"=>$horders,
    "fullmenu"=>$menu
]);