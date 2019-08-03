<?php
    require_once dirname(__FILE__) . "/../include/Common.php";
    require_once dirname(__FILE__) . "/../include/Book.php";
    $book = new Book();

    $all_books = $book->get_all_books();

    if($all_books){
        $response->success = true;
        $response->message = "Books fetched successfully";
        $response->responseCode = 200;
        $response->data  = $all_books;
    }else{
        $response->success = false;
        $response->message = "Could not fetch books";
        $response->responseCode = 200;

    }
    OutputResponse($response);
?>