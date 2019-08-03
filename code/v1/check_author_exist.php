<?php
require_once dirname(__FILE__) . "/../include/Common.php";
require_once dirname(__FILE__) . "/../include/Book.php";
try
{
    verifyRequiredParams('authors',$inputdata);

    $book = new Book();
    $result = $book->check_authors_exist($inputdata);
    if($result){
        $response->success = true;
        $response->data = $result;
        $response->message = "Authors fetched successfully";
        $response->responseCode = 200;
    }else{
        $response->success = false;
        $response->message = "Failed to fetch author";
        $response->responseCode = 200;
    }
    OutputResponse($response);

}
catch(Exception $ex)
{
//        log4phpException($ex);
}
?>
