<?php
require_once dirname(__FILE__) . "/../include/Common.php";
require_once dirname(__FILE__) . "/../include/Book.php";
try
{

    verifyRequiredParams(array('book_id','user_id','reservation_date'),$inputdata);
    $book = new Book();
    $data = $book->reserve_book($inputdata);
    if($data){
        $response->success = true;
        $response->message = "Book reserved successfully";
        $response->responseCode = 200;

    }else{
        $response->success = false;
        $response->message = "Failed to reserve book";
        $response->responseCode = 200;
    }
    OutputResponse($response);


}catch (Exception $exception){
    print_r($exception);
}
?>

