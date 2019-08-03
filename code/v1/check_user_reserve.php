<?php
require_once dirname(__FILE__) . "/../include/Common.php";
require_once dirname(__FILE__) . "/../include/Book.php";
try {
    verifyRequiredParams('user_id', $inputdata);

    $book = new Book();
    $result = $book->check_user_reserve($inputdata);
    if($result == 0 or $result == 1){
        $response->success = true;
        $response->allowed = $result;
        $response->message = "User book reserve check successfully";
        $response->responseCode = 200;
    }else{
        $response->success = false;
        $response->message = "Failed to check user book reserve";
        $response->responseCode = 200;
    }
    OutputResponse($response);

}catch (Exception $exception){
    print_r($exception);
}
?>