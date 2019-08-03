<?php
require_once dirname(__FILE__) . "/../include/Common.php";
require_once dirname(__FILE__) . "/../include/Book.php";
try {
    verifyRequiredParams(array('isbn'), $inputdata);

    $book = new Book();
    $result = $book->get_book_by_isbn($inputdata);

    if($result){

        $response->success = true;
        $response->message = "Book details fetched successfully";
        $response->data = $result;
        $response->responseCode = 200;
    } else {
        $response->success = false;
        $response->message = "Failed to get book details";
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
