<?php

    require_once dirname(__FILE__) . "/../include/Common.php";
    require_once dirname(__FILE__) . "/../include/User.php";
    try
    {
        verifyRequiredParams(array('type','firstname','lastname','phone','email','address_line1'),$inputdata);
        $user = new User();
        $result = $user->add_user($inputdata);
        if($result === true){
            $response->success = true;
            $response->message = "User added successfully";
            $response->responseCode = 200;
        }else{
            $response->success = false;
            $response->message = "Failed to add user";
            $response->responseCode = 200;
        }
        OutputResponse($response);
    }
    catch(Exception $ex)
    {

    }
?>
