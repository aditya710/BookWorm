<?php
    require_once dirname(__FILE__) . "/../include/Common.php";
    require_once dirname(__FILE__) . "/../include/Book.php";
    try {
        verifyRequiredParams(array('book_id'), $inputdata);

        $book = new Book();
        $result = $book->delete_by_bookid($inputdata);

        if($result['success']==1){
            $response->success = true;
            $response->message = $result['message'];
            $response->responseCode = 200;
        } else {
            $response->success = false;
            $response->message = $result['message'];
            $response->responseCode = 200;
        }
        OutputResponse($response);
    }
    catch(Exception $e)
    {
        $response->success = false;
        $response->message = $e;
        $response->responseCode = 500;
        OutputResponse($response);
    }

?>
