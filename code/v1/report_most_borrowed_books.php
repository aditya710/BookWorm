<?php
require_once dirname(__FILE__) . "/../include/Common.php";
require_once dirname(__FILE__) . "/../include/Book.php";
try
{
    verifyRequiredParams(array('start_date','end_date'),$inputdata);

    $book = new Book();
    $result = $book->most_borrowed_books($inputdata);
    if($result){
        $response->success = true;
        $response->message = "Book data fetched successfully";
        $response->data = $result;
        $response->responseCode = 200;
    }else{
        $response->success = false;
        $response->message = "Failed to get book data";
        $response->responseCode = 200;
    }
    OutputResponse($response);

}
catch(Exception $ex)
{
//        log4phpException($ex);
}
?>
