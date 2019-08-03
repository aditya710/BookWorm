<?php
    require_once dirname(__FILE__) . "/../include/Common.php";
    require_once dirname(__FILE__) . "/../include/Book.php";
    try
    {
        verifyRequiredParams(array('type','title','publication','cnt','isbn'),$inputdata);

        $book = new Book();
        $result = $book->add_book($inputdata);
        if($result === true){
            $response->success = true;
            $response->message = "Book added successfully";
            $response->responseCode = 200;
        }else{
            $response->success = false;
            $response->message = "Failed to add book";
            $response->responseCode = 200;
        }
        OutputResponse($response);

    }
    catch(Exception $ex)
    {
//        log4phpException($ex);
    }
?>
