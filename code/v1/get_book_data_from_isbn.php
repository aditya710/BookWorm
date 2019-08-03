<?php
    require_once dirname(__FILE__) . "/../include/Common.php";
    verifyRequiredParams('isbn',$inputdata);
    try{
        $isbn = $inputdata['isbn'];

        $ch = curl_init();

        curl_setopt($ch, CURLOPT_URL, 'https://www.googleapis.com/books/v1/volumes?q=isbn%3D'.$isbn);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
        $data = curl_exec($ch);
        curl_close($ch);


        $json_book = json_decode($data);

        if($json_book->totalItems > 0) {
            $response->success = true;
            $response->message = "Book Details Fetched successfully";
            $response->responseCode = 200;
            $response->title = $json_book->items[0]->volumeInfo->title;
            $response->subtitle = $json_book->items[0]->volumeInfo->subtitle;
            $response->publication = $json_book->items[0]->volumeInfo->publication;
            $response->authors = $json_book->items[0]->volumeInfo->authors;
            $response->description = $json_book->items[0]->volumeInfo->description;
            $response->publishedDate = $json_book->items[0]->volumeInfo->publishedDate;
            $response->pageCount = $json_book->items[0]->volumeInfo->pageCount;
            $response->language = $json_book->items[0]->volumeInfo->language;
            $response->thumbnail = $json_book->items[0]->volumeInfo->imageLinks->thumbnail;
            OutputResponse($response);
        }else{
            $response->success = false;
        }

    //Print the data out onto the page.
    }catch (Exception $exception){

    }
?>