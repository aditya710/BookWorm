<?php
    require_once dirname(__FILE__) . "/../include/Common.php";
    require_once dirname(__FILE__) . "/../include/Book.php";

    $book = new Book();
    try{
        $data = $book->send_due_reminders();
        if($data){
            $response->success = true;
            $response->message = "Due reminder sent successfully";
            $response->responseCode = 200;
            $response->data = $data;
        }else{
            $response->success = false;
            $response->message = "Failed to send due reminder";
            $response->responseCode = 200;
        }
        OutputResponse($response);

    }
    catch(Exception $ex)
    {
        //        log4phpException($ex);
    }
?>
