<?php
require_once dirname(__FILE__) . "/../include/Common.php";
require_once dirname(__FILE__) . "/../include/User.php";
try
{

    $user = new User();
    $result = $user->get_all_users($inputdata);
    if($result){
        $response->success = true;
        $response->message = "Users  fetched successfully";
        $response->data = $result;
        $response->responseCode = 200;
    }else{
        $response->success = false;
        $response->message = $result['message'];
        $response->responseCode = 200;
    }
    OutputResponse($response);
}
catch(Exception $ex)
{
    $response->success = false;
    $response->message = $ex;
    $response->responseCode = 500;
    OutputResponse($response);
}
?>