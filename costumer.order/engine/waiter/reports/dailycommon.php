<?php
# (C) 2025 Kudryashov Vasili
# Created - 2025-05-09 13:43:31
# Last modified - 2025-05-09 13:43:31

class DailyCommon extends PClass {
    public function __construct() {
        parent::__construct();
    }

    public function echoResult()() {
        /*
                    QJsonArray jHall;
            QString hallFilter = fIn["hall"].toString();
            srh.getJsonFromQuery(QString("select f_id, f_name, f_settings from h_halls %1")
                                 .arg(hallFilter.isEmpty() ? "" : " where f_id in (" + hallFilter + ")"), jHall);
            QJsonArray jTables;
            srh.getJsonFromQuery(QString("select t.f_id, t.f_hall, t.f_name, t.f_lock, t.f_lockSrc, \
h.f_id as f_header, concat(u.f_last, ' ', left(u.f_first, 1), '.') as f_staffName, \
h.f_amounttotal as f_amount, h.f_print, bc.f_govnumber, \
date_format(h.f_dateopen, '%d.%m.%Y') as f_dateopen, h.f_timeOpen, \
t.f_special_config \
from h_tables t \
left join o_header h on h.f_table=t.f_id and h.f_state=1 \
left join o_header_options o on o.f_id=h.f_id \
left join b_car bc on bc.f_id=o.f_car \
left join s_user u on u.f_id=h.f_staff  %1 \
order by f_id")
                                 .arg(hallFilter.isEmpty() ? "" : " where t.f_hall in (" + hallFilter + ") "), jTables);
            //srh.getJsonFromQuery("select f_id, f_hall, f_name, f_lock, f_lockSrc from h_tables order by f_id", jTables);
            QJsonArray jShift;
            srh.getJsonFromQuery("select f_id, f_name from s_salary_shift", jShift);
            o["reply"] = 1;
            o["halls"] = jHall;
            o["tables"] = jTables;
            o["shifts"] = jShift;
            break;




             QJsonArray ja;
            QDate d1 = QDate::fromString(fIn["date1"].toString(), FORMAT_DATE_TO_STR_MYSQL);
            QDate d2 = QDate::fromString(fIn["date2"].toString(), FORMAT_DATE_TO_STR_MYSQL);
            bv[":f_datecash1"] = d1;
            bv[":f_datecash2"] = d2;
            bv[":f_state"] = ORDER_STATE_CLOSE;
            QString sqlQuery;
            sqlQuery =
                "select oh.f_id, concat(oh.f_prefix, oh.f_hallid) as f_order, date_format(oh.f_datecash, '%d.%m.%Y') as f_datecash, oh.f_timeclose, "
                "h.f_name as f_hall, t.f_name as f_table, concat(u.f_last, ' ', u.f_first) as f_staff,"
                "oh.f_amounttotal, ot.f_receiptnumber "
                "from o_header oh "
                "left join h_halls h on h.f_id=oh.f_hall "
                "left join h_tables t on t.f_id=oh.f_table "
                "left join s_user u on u.f_id=oh.f_staff "
                "left join o_tax ot on ot.f_id=oh.f_id "
                "where (oh.f_state=:f_state and oh.f_datecash between :f_datecash1 and :f_datecash2) ";
            if (fIn["opened"].toString().toInt() > 0) {
                sqlQuery += " or (oh.f_state=1) ";
            }
            if (fIn["hall"].toString().toInt() > 0) {
                sqlQuery += QString(" and oh.f_hall=%1 ").arg(fIn["hall"].toString());
            }
            if (fIn["shift"].toString().toInt() > 0) {
                sqlQuery += QString(" and oh.f_shift=%1 ").arg(fIn["shift"].toString());
            }
            sqlQuery += "order by oh.f_timeclose";
            srh.getJsonFromQuery(sqlQuery, ja, bv);
            o["reply"] = 0;
            o["report"] = ja;
        */
        $list = [
            ["caption" => $this->tr->tr("Daily revenue"), "file" => "daily-revenue"],
            ["caption" => $this->tr->tr("Departments revenue"), "file" => "departments-revenue"],
        ];   
        $this->result["list"] = $list;
        $parent::>echoResult();             
    }
}

$dc = new DailyCommon();
$dc->echoResult();