<?php
	// date_default_timezone_set('Asia/Kolkata');
	//Set error reporting to display only fatal errors
	   error_reporting(~E_ALL & ~E_NOTICE & ~E_WARNING);
	//Initialize start time, needed to calculate timeInMillis while sending back response
	$start = microtime(true);
	try
	{
		//Getting the Constants.php file
		require_once dirname(__FILE__) . "/Constants.php";
		//Getting the ResponseModel.php file
		require_once dirname(__FILE__) . "/ResponseModel.php";
		//Getting the DbOperation.php file
		//require_once dirname(__FILE__) . "/DbOperation.php";
		//Getting the Logger.php file
		// require_once dirname(__FILE__) . '/../libs/log4php/src/main/php/Logger.php';
		//Configuring logger
		// Logger::configure(dirname(__FILE__) . '/../libs/log4php/configuration.xml');
		
		
		//Getting input request data
		$inputdata = GetInputParams();
		//Creating ResponseModel object to set response
		$response = new ResponseModel();
		//Validate app_key
		// ValidateAppKey($inputdata);
		// //Log request
		// log4phpRequest($inputdata,null);
	}
	catch(Exception $ex)
	{
		log4phpException($ex);
	}
	
	//Function to send response back to client
	function OutputResponse($response)
	{
		$time_elapsed=microtime(true) - $GLOBALS['start'];
		$response->timeInMillis=round($time_elapsed * 1000);
		$outputdata=json_encode($response);//		print_r($response);
		// log4phpResponse($response);
		echo $outputdata;
		exit();
	}
	
	//Function to get input parameters in the request
	function GetInputParams()
	{
		//print_r($_FILES);
		//print_r($_SERVER['REQUEST_METHOD']);
		//print_r($_GET);
		//print_r($_POST);
	//	print_r($_REQUEST);
		if (strtoupper($_SERVER['REQUEST_METHOD']) == 'GET' || !empty($_FILES["file"]["name"]))
		{
			if(count($_POST)>0)
			{
				$inputdata=$_POST;
			}
			else
			{
				$inputdata=$_GET;
			}
		}
		else if (strtoupper($_SERVER['REQUEST_METHOD']) == 'POST')
		{
			if($_SERVER["CONTENT_TYPE"]=="application/json")
			{
				$inputJSON = file_get_contents('php://input');
				$inputdata= json_decode( $inputJSON, TRUE ); //convert JSON into array
			}
			else
				$inputdata=$_POST;
		}
		else
		{
			$inputdata=$_REQUEST;
		}
		//print_r($inputdata);
		return $inputdata;
	}	
	
	//Function to validate app_key
	// function ValidateAppKey($inputdata)
	// {
	// 	if (!empty($inputdata["app_key"]))
	// 	{
	// 		require_once dirname(__FILE__) . '/DbConnect.php';
	// 		$db = new DbConnect();
	// 		$con = $db->connect();
	// 		$sql="SELECT * FROM `app_key`  WHERE `key`= '".$inputdata["app_key"]."'";
	// 		$stmt = $con->prepare($sql);		
	// 		$stmt->execute();
	// 		$keyinfo = $stmt->get_result()->fetch_assoc();		
	// 		$stmt->close();
	// 		if(!isset($keyinfo) || $keyinfo==null)
	// 		{
	// 			$response->success=false;
	// 			$response->message="Invalid app key";
	// 			$response->responseCode=102;
	// 			OutputResponse($response);
	// 		}
	// 		else
	// 		{
	// 			//var_dump($keyinfo);die;
	// 			if($keyinfo['event_id'] && $inputdata["eventCode"])
	// 			{
	// 				require_once dirname(__FILE__) . '/Event.php';
	// 				$event = new Event();
	// 				$eventinfo=$event->getEventdetailbyEventcode($inputdata["eventCode"]);
	// 				if($eventinfo->details['id'] && $eventinfo->details['id']==$keyinfo['event_id'])
	// 				{
	// 					return true;
	// 				}
	// 				else
	// 				{
	// 					$response->success=false;
	// 					$response->message="Invalid app key & event pair";
	// 					$response->responseCode=102;
	// 					OutputResponse($response);
	// 				}
	// 			}
	// 			return $true;
	// 		}			
	// 	}
	// 	else
	// 	{
	// 		$response->success=false;
	// 		$response->message="Empty app key";
	// 		$response->responseCode=101;
	// 		OutputResponse($response);
	// 	}
	// }
	
	//Function to get client's ip address
	function get_client_ip_address() {
		$ipaddress = '';
		if ($_SERVER['HTTP_CLIENT_IP'])
			$ipaddress = $_SERVER['HTTP_CLIENT_IP'];
		else if($_SERVER['HTTP_X_FORWARDED_FOR'])
			$ipaddress = $_SERVER['HTTP_X_FORWARDED_FOR'];
		else if($_SERVER['HTTP_X_FORWARDED'])
			$ipaddress = $_SERVER['HTTP_X_FORWARDED'];
		else if($_SERVER['HTTP_FORWARDED_FOR'])
			$ipaddress = $_SERVER['HTTP_FORWARDED_FOR'];
		else if($_SERVER['HTTP_FORWARDED'])
			$ipaddress = $_SERVER['HTTP_FORWARDED'];
		else if($_SERVER['REMOTE_ADDR'])
			$ipaddress = $_SERVER['REMOTE_ADDR'];
		else
			$ipaddress = 'UNKNOWN';
		return $ipaddress;
	}
	
	//Function to get url for logging
	function curPageURL() 
	{
		 $pageURL = 'http';
		 if ($_SERVER["HTTPS"] == "on") {$pageURL .= "s";}
		 $pageURL .= "://";
		 if ($_SERVER["SERVER_PORT"] != "80") {
		  $pageURL .= $_SERVER["SERVER_NAME"].":".$_SERVER["SERVER_PORT"].$_SERVER["REQUEST_URI"];
		 } else {
		  $pageURL .= $_SERVER["SERVER_NAME"].$_SERVER["REQUEST_URI"];
		 }
		 return preg_replace('/\?.*$/', '',$pageURL);
	}
	
	//Function to log request
	// function log4phpRequest($inputdata,$userinfo)
	// {		
	// 	$logger = Logger::getRootLogger();	
		
	// 	if($userinfo)
	// 	{
	// 		$inputdata["uid"]= $userinfo["d"]["uid"];
	// 		unset($inputdata["token"]);
	// 	}	
		
	// 	if (!empty($inputdata["app_key"]) )
	// 	{
	// 		unset($inputdata["app_key"]);
	// 	}
		
	// 	$logger->debug("Url:".curPageURL()." Request:".json_encode($inputdata)." From:".get_client_ip_address()." Browser :".$_SERVER['HTTP_USER_AGENT']." Content-type:".$_SERVER["CONTENT_TYPE"]); 
	// }
	
	//Function to log response
	// function log4phpResponse($outputdata)
	// {		
	// 	$logger = Logger::getRootLogger();
		
	// 	if(isset($outputdata->token))
	// 	{
	// 		unset($outputdata->token);
	// 	}
	// 	$logger->debug("Url:".curPageURL()." Response:".json_encode($outputdata)); 
	// }
	
	//Function to log response
	// function log4phpException($exception)
	// {		
	// 	$logger = Logger::getRootLogger();
	// 	$logger->error("Url:".curPageURL()." Exception:".json_encode($exception)); 
	// 	$response->success=false;
	// 	$response->message="Internal server error";
	// 	$response->responseCode=500;
	// 	OutputResponse($response);
	// }
	
	function verifyRequiredParams($required_fields, $inputdata)
	{
		//Assuming there is no error
		$error = false;
	 
		//Error fields are blank
		$error_fields = "";
	 
		//Getting the request parameters
		$request_params = $inputdata;
	 
		//Looping through all the parameters
		foreach ($required_fields as $field) {
	 
			//if any required parameter is missing
			//var_dump($field);
			//var_dump(isset($request_params[$field]));
			//var_dump(strlen(trim($request_params[$field])));
			
			if (!isset($request_params[$field]) || strlen(trim($request_params[$field])) <= 0) {
				//error is true
				$error = true;
	 
				//Concatnating the missing parameters in error fields
				$error_fields .= $field . ', ';
			}
		}
	 
		//if there is a parameter missing then error is true
		if ($error) {
			//Adding values to response array
			$response->success=false;
			$response->message='Required field(s) ' . substr($error_fields, 0, -2) . ' is missing or empty';
			$response->responseCode=103;
			OutputResponse($response);
		}
	}
	
	
	
	
	
	//This method sends email and returns true if successfully sent
	function SendMail($toEmail, $subject, $html, $text, $fromEmail=null, $fromName=null ,$attachment=null)
	{

		require dirname(__FILE__) . '/../libs/phpmailer/vendor/autoload.php';
		$mail = new PHPMailer;
		//$mail->SMTPDebug = 3;                               // Enable verbose debug output
		$mail->isSMTP();                                      // Set mailer to use SMTP
		$mail->Host = 'smtp.gmail.com';   // Specify main and backup SMTP servers
		$mail->SMTPAuth = true;                               // Enable SMTP authentication
		$mail->Username = 'campuslibrary2019@gmail.com';                 // SMTP username
		$mail->Password = 'Anturkar@05';                           // SMTP password
		$mail->SMTPSecure = 'tls';                            // Enable TLS encryption, `ssl` also accepted
		$mail->Port = 587;                                    // TCP port to connect to
		$mail->CharSet = 'UTF-8';
		$mail->Encoding = 'base64';
		if($fromEmail == null)
			$fromEmail = 'campuslibrary2019@gmail.com';
		if($fromName == null)
			$fromName = 'Campus Library';
		$mail->setFrom($fromEmail, $fromName);
		$mail->addAddress($toEmail);     // Add a recipient
		//$mail->addAddress('ellen@example.com');               // Name is optional
		//$mail->addReplyTo('info@example.com', 'Information');
		//$mail->addCC('cc@example.com');
		//$mail->addBCC('bcc@example.com');
		if($attachment){
			$mail->addAttachment($attachment);
		}         // Add attachments
		//$mail->addAttachment('/tmp/image.jpg', 'new.jpg');    // Optional name
		$mail->isHTML(true);                                  // Set email format to HTML

		$mail->Subject = $subject;
		$mail->Body    = $html;
		$mail->AltBody = $text;

		if(!$mail->send()) {
			// log4phpException($mail->ErrorInfo);
            print_r($mail->ErrorInfo);
			return false;
		} else {
			return true;
		}
	}

	//Function to handle fatal errors
	function shutdown() {
		$error = error_get_last();
		if ($error['type'] === E_ERROR) {
			// fatal error has occured
			// log4phpException($error);
		}
	}
	register_shutdown_function('shutdown');
?>