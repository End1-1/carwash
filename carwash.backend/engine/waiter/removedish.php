<?php
# © 2025, Kudryashov Vasili
# Created - 2025-05-04 22:47:10
# Last modified - 2025-05-10 11:11:00

require_once __DIR__ . "/waiter.php";
require_once __DIR__ . "/stoplist.php";

class RemoveDish extends PClass
{
    public function echoResult() {
        $sl = new StopList();
        $sl->removeDish();
        $bv["f_state"]= $this->params->f_state;
        $bv["f_removetime"] = date("Y-m-d H:i:s");
        $bv["f_removeuser"] = $this->userid;
        $bv["f_emarks"] = null;
        $this->supdate("o_body", $bv, $this->params->f_id);
        parent::echoResult();
    }
}

$rd = new RemoveDish();
$rd->echoResult();