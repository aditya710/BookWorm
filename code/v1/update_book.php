<?php
require_once dirname(__FILE__) . "/../include/Common.php";
require_once dirname(__FILE__) . "/../include/Book.php";
try
{
    verifyRequiredParams(array('book_id','loc','apply_all','is_locked'),$inputdata);

    $book = new Book();
    $result = $book->update_book($inputdata);
    if($result === true){
        $response->success = true;
        $response->message = "Book updated successfully";
        $response->responseCode = 200;
    }else{
        $response->success = false;
        $response->message = "Failed to update book";
        $response->responseCode = 200;
    }
    OutputResponse($response);

}
catch(Exception $ex)
{
//        log4phpException($ex);
}
?>
