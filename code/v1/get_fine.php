<?php
require_once dirname(__FILE__) . "/../include/Common.php";
require_once dirname(__FILE__) . "/../include/Book.php";
try
{

    verifyRequiredParams(array('book_id', 'user_id'), $inputdata);
    $book = new Book();
    $data = $book->get_fine($inputdata);
    if($data){
        $response->success = true;
        $response->fine = $data;
        $response->message = "Fine fetched successfully";
        $response->responseCode = 200;

    }else{
        $response->success = false;
        $response->message = "Failed to fetch fine";
        $response->responseCode = 200;
    }
    OutputResponse($response);

}
catch(Exception $ex)
{
    //        log4phpException($ex);
}
?>
