<?php
    require_once dirname(__FILE__) . "/../include/Common.php";
    require_once dirname(__FILE__) . "/../include/Book.php";
    try
    {

        $book = new Book();
        $data = $book->get_all_books($inputdata);
        if($data){
            $response->success = true;
            $response->message = "Books fetched successfully";
            $response->responseCode = 200;
            $response->data = $data;
        }else{
            $response->success = false;
            $response->message = "Failed to fetch books";
            $response->responseCode = 200;
        }
        OutputResponse($response);

    }
    catch(Exception $ex)
    {
    //        log4phpException($ex);
    }
?>