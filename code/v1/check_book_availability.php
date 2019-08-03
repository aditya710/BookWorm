<?php
require_once dirname(__FILE__) . "/../include/Common.php";
require_once dirname(__FILE__) . "/../include/Book.php";
try {
    verifyRequiredParams(array('book_id', 'reservation_date'), $inputdata);

    $book = new Book();
    $result = $book->check_book_is_available($inputdata);
    if($result == 0 or $result == 1){
        $response->success = true;
        $response->available = $result;
        $response->message = "Book availability check successfully";
        $response->responseCode = 200;
    }else{
        $response->success = false;
        $response->message = "Failed to check book availability";
        $response->responseCode = 200;
    }
    OutputResponse($response);

}catch (Exception $exception){
    print_r($exception);
}
?>