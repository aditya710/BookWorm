<?php
require_once dirname(__FILE__) . "/../include/Common.php";
require_once dirname(__FILE__) . "/../include/Book.php";
    try {
        verifyRequiredParams(array('book_id', 'user_id'), $inputdata);

        $book = new Book();
        $result = $book->borrow_book($inputdata);
        if($result['success'] == 1){
            $response->success = true;
            $response->message = $result['message'];
            $response->responseCode = 200;
        }else{
            $response->success = false;
            $response->message = $result['message'];
            $response->responseCode = 200;
        }


    } catch (Exception $exception){

        print_r($exception);
        $response->success = false;
        $response->message = "Failed to borrow book";
        $response->responseCode = 200;
    }
    OutputResponse($response);
?>
