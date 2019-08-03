<?php
require_once dirname(__FILE__) . "/../include/Common.php";
require_once dirname(__FILE__) . "/../include/Book.php";
try {
    verifyRequiredParams('pickup_code', $inputdata);

    $book = new Book();
    $result = $book->check_pickup_code_is_valid($inputdata);
    if($result == 0 or $result == 1){
        $response->success = true;
        $response->valid = $result;
        $response->message = "Pick up code validity check successfully";
        $response->responseCode = 200;
    }else{
        $response->success = false;
        $response->message = "Failed to check pickup code validity";
        $response->responseCode = 200;
    }
    OutputResponse($response);

}catch (Exception $exception){
    print_r($exception);
}
?>