<?php
    require_once dirname(__FILE__) . "/../include/Common.php";
    require_once dirname(__FILE__) . "/../include/Book.php";
    verifyRequiredParams('book_id',$inputdata);

    $book = new Book();
    try{
        $data = $book->get_book($inputdata);
        if($data){
            $response->success = true;
            $response->message = "Book details fetched successfully";
            $response->responseCode = 200;
            $response->data = $data;
        }else{
            $response->success = false;
            $response->message = "Failed to fetch book details";
            $response->responseCode = 200;
        }
        OutputResponse($response);

    }
    catch(Exception $ex)
    {
    //        log4phpException($ex);
    }
?>
