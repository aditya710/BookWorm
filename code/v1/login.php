<?php
require_once dirname(__FILE__) . "/../include/Common.php";
require_once dirname(__FILE__) . "/../include/User.php";
try
{
    verifyRequiredParams(array('email','password'),$inputdata);
    $user = new User();
    $result = $user->login($inputdata);
    if($result['success'] == 1){
        $response->success = true;
        $response->session_id = $result['session_id'];
        $response->message = "User loged in successfully";
        $response->responseCode = 200;
    }else{
        $response->success = false;
        $response->message = "Failed to login user";
        $response->responseCode = 200;
    }
    OutputResponse($response);
}
catch(Exception $ex)
{

}
?>
