-- phpMyAdmin SQL Dump
-- version 4.8.3
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Jun 10, 2019 at 11:39 PM
-- Server version: 8.0.12
-- PHP Version: 7.1.19

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `bookworm_db`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `add_book` (IN `type` INT(11), IN `title` LONGTEXT, IN `subtitle` LONGTEXT, IN `publication` LONGTEXT, IN `description` LONGTEXT, IN `published_date` DATE, IN `page_count` INT(11), IN `lang` VARCHAR(2), IN `thumbnail` VARCHAR(255), IN `isbn_no` VARCHAR(13), IN `cnt` INT(10), IN `e_authors` VARCHAR(100), IN `n_authors` VARCHAR(100))  BEGIN
	DECLARE x INT DEFAULT 0; 
    DECLARE y INT DEFAULT 0; 
    SET y = 1; 

	SELECT COUNT(*) FROM book
    WHERE isbn = isbn_no
    INTO @if_exist;
    
    IF @if_exist = 0 THEN
        INSERT INTO `book` (`id`, `type` ,`title`,`subtitle`,`publication`,`description`,`published_date`,`page_count`,`language`,`thumbnail`,`isbn`) 
            VALUES (UUID_TO_BIN(UUID()), type , title, subtitle,publication, description, published_date,page_count,lang,thumbnail,isbn_no);
	END IF;	

	WHILE cnt > 0 DO
    	INSERT INTO `catalog` (`id`,`isbn`)
        	VALUES ( UUID_TO_BIN(UUID()) , isbn_no);
       	SET cnt = cnt - 1;
	END WHILE;
    
    IF @if_exist = 0 THEN
        select check_is_null_or_empty(e_authors) into @ecount;
        IF @ecount = 0 
        THEN 
               SELECT LENGTH(e_authors) - LENGTH(REPLACE(e_authors, ',', '')) INTO @noOfCommas; 

               IF  @noOfCommas = 0 
                THEN 
                     SELECT split_string(e_authors,' ',1) into @firstname;
                     SELECT split_string(e_authors,' ',2) into @lastname;
                     
                     SELECT get_author_id(@firstname,@lastname) INTO @authorId;

                     INSERT INTO book_author(`id`,`isbn`,`author_id`) VALUES(UUID_TO_BIN(UUID()),isbn_no,@authorId);
                ELSE 
                    SET x = @noOfCommas + 1; 
                    WHILE y  <=  x DO 
                       SELECT split_string(e_authors, ',', y) INTO @author; 
                       SELECT split_string(@author,' ',1) into @firstname;
                       SELECT split_string(@author,' ',2) into @lastname;
					   SELECT get_author_id(@firstname,@lastname) INTO @authorId;
                       INSERT INTO book_author(`id`,`isbn`,`author_id`) VALUES(UUID_TO_BIN(UUID()),isbn_no,@authorId);
                       SET  y = y + 1; 
                    END WHILE; 
            END IF; 
       END IF;
       select check_is_null_or_empty(n_authors) into @ncount;
       IF @ncount = 0
        THEN 
               SELECT LENGTH(n_authors) - LENGTH(REPLACE(n_authors, ',', '')) INTO @noOfCommas; 

               IF  @noOfCommas = 0 
                THEN 
                     SELECT split_string(n_authors,' ',1) into @firstname;
                     SELECT split_string(n_authors,' ',2) into @lastname;
                     
                     INSERT INTO `author` (`first_name`,`last_name`) VALUES(@firstname,@lastname);
                     SELECT row_count() into @affectedRows;
                     IF @affectedRows = 1 THEN 
                     
                     SELECT get_author_id(@firstname,@lastname) INTO @authorId;
					
                     INSERT INTO book_author(`id`,`isbn`,`author_id`) VALUES(UUID_TO_BIN(UUID()),isbn_no,@authorId);
                     END IF;
                ELSE 
                    SET x = @noOfCommas + 1; 
                    WHILE y  <=  x DO 
                       SELECT split_string(n_authors, ',', y) INTO @author; 
                       SELECT split_string(@author,' ',1) into @firstname;
                       SELECT split_string(@author,' ',2) into @lastname;
                        INSERT INTO `author` (`first_name`,`last_name`) VALUES(@firstname,@lastname);
                     SELECT row_count() into @affectedRows;
                     IF @affectedRows = 1 THEN 
                     
                     SELECT get_author_id(@firstname,@lastname) INTO @authorId;
					
                     INSERT INTO book_author(`id`,`isbn`,`author_id`) VALUES(UUID_TO_BIN(UUID()),isbn_no,@authorId);
                     END IF;
                       SET  y = y + 1; 
                    END WHILE; 
            END IF; 
       END IF;
    END IF; 
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `add_user` (IN `type` INT(11), IN `firstname` VARCHAR(20), IN `lastname` VARCHAR(20), IN `phone` VARCHAR(15), IN `email` VARCHAR(100), IN `address_line1` VARCHAR(30), IN `address_line2` VARCHAR(30), IN `city` VARCHAR(20), IN `state` VARCHAR(20), IN `country` VARCHAR(20), IN `pincode` INT(10), IN `dob` DATE)  NO SQL
INSERT INTO user (`user_type`,`firstname`,`lastname`,`phone`,`email`,`address_line1`,
        `address_line2`,`city`,`state`,`country`,`pincode`,`dob`)
 VALUES (type , firstname , lastname , phone , email , address_line1 , address_line2 , city , state , country , pincode ,dob )$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `borrow_book` (IN `bookid` INT(10), IN `userid` INT(11), IN `doi` DATE, IN `dor` DATE, OUT `success` TINYINT, OUT `user_email` VARCHAR(100), OUT `book_title` VARCHAR(100), OUT `message` VARCHAR(100))  NO SQL
BEGIN

	SELECT check_user_borrow(userid) into @is_allowed;
    SET success = 0;
    SET message = "User borrow limit reached";
    IF @is_allowed = 1 THEN
    
        SELECT  is_borrowed , is_locked
        FROM catalog
        WHERE catalog.book_id = bookid
        INTO  @is_borrowed , @is_locked;

        IF @is_borrowed = 0 AND @is_locked = 0 THEN
            INSERT INTO borrow (`id`,`book_id`,`user_id`,`doi`,`dor`)
                VALUES (UUID_TO_BIN(UUID()),bookid,userid,doi,dor);
            SELECT ROW_COUNT() INTO @rowcount;

            IF @rowcount = 1 THEN
                UPDATE catalog SET is_borrowed = 1
                WHERE catalog.book_id = bookid;
                SET success = 1;
                
                SELECT email 
                INTO @useremail 
                FROM user 
                WHERE id = userid;
                
                SET user_email = @useremail;
                
                SELECT t1.title INTO @booktitle from book as t1
                INNER JOIN catalog as t2 
                ON t1.isbn = t2.isbn and t2.book_id = bookid;
                
                SET book_title = @booktitle;
                SET message = "Book borrowed";
            END IF;
        ELSE
        	SET success = 0;
            SET message = "Book is not available to borrow";
        END IF;
	END IF;
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `check_author_exists` (IN `authors` VARCHAR(50), OUT `exist` TINYINT)  NO SQL
BEGIN
DECLARE x INT DEFAULT 0; 
DECLARE y INT DEFAULT 0; 
    SET y = 1;
    
 IF NOT authors IS NULL 
   THEN 
     SELECT split_string(authors,' ',1) into @firstname;
     SELECT split_string(authors,' ',2) into @lastname;

     SELECT count(*) 
      INTO @exists 
      FROM author
      WHERE first_name = @firstname and last_name = @lastname;
      IF @exists = 1 THEN
       
       SET exist = 1;
      ELSE
       SET exist = 0;
      END IF;
              
 END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `check_book_availability_unused` (IN `isbn_id` VARCHAR(13), OUT `availability` TINYINT, OUT `a_date` DATE)  NO SQL
BEGIN
	SET a_date = '2019-05-21';
    SELECT count(*) 
    INTO @availability
    FROM catalog
    WHERE is_borrowed != 1 and 
    book_id in (SELECT book_id FROM catalog where isbn = isbn_id); 
    SET availability = @availability;
    
    IF @availability = 1 THEN
    	SELECT sysdate() into @currentDate;
    	SET a_date = @currentDate;
    ELSE
    	SELECT MIN(dor) 
        INTO @availableDate
        FROM `borrow` 
		WHERE book_id IN 
        (SELECT book_id FROM catalog where isbn = @isbn); 
        
        SET a_date = @availableDate;
    	
     END IF;
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `delete_by_book_id` (IN `bookid` INT(11), OUT `success` TINYINT(1), OUT `message` VARCHAR(100))  NO SQL
BEGIN

SET FOREIGN_KEY_CHECKS = 0;
select count(*) INTO @deleteallowed
from catalog 
WHERE book_id = bookid AND is_borrowed = 0;


IF @deleteallowed =1 THEN

 DELETE from catalog WHERE book_id = bookid;
 
 SELECT row_count() into @affectedrows;
 
 IF @affectedrows = 1 THEN
 
     SET success = 1;
     set message = 'Book deleted successfully';

 ELSE
  
 SET success = 0;
     set message = 'Failed to delete book';

END IF;
ELSE
 SET success = 0;
     set message = 'Failed to delete book. Book already borrowed.';
END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `delete_by_book_isbn` (IN `isbn_no` VARCHAR(13), OUT `success` TINYINT(1), OUT `message` VARCHAR(100))  NO SQL
BEGIN
SET FOREIGN_KEY_CHECKS = 0;
SELECT count(*) 
INTO @currently_borrowed 
FROM borrow 
WHERE actual_dor is null and book_id in (SELECT book_id from  catalog WHERE isbn = isbn_no);

IF @currently_borrowed > 0 THEN 
	SET success = 0;
    SET message = "Book possessed by user";
ELSE 
	DELETE FROM book 
    WHERE isbn = isbn_no;
    SELECT row_count() into @affectedRows;
    IF @affectedRows = 0 THEN
    	SET success = 0;
    	SET message = "Couldnot delete book";
    ELSEIF @affectedRows = 1 THEN 
	    SET success = 1;
    	DELETE FROM catalog
        WHERE isbn = isbn_no;
      	SELECT row_count() into @rowsDeleted;
		IF @rowsDeleted > 0 THEN         
        	
            SET message = "Books deleted from catalog";
        END IF;
    END IF;    
    	
END IF;


END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `delete_user` (IN `userid` INT(10), OUT `success` TINYINT(1), OUT `message` VARCHAR(100))  NO SQL
BEGIN

SET FOREIGN_KEY_CHECKS = 0;


   DELETE from user where id = userid;
   
   SELECT row_count() INTO @rowsDeleted;
   
   IF @rowsDeleted = 1 THEN
   
    SET success = 1;
    SET message = 'user is deleted successfully';
   ELSE
   SET success = 1;
    SET message = @rowsDeleted;
    

END If;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_fine` (IN `bookid` INT(10), IN `userid` INT(11), IN `ador` DATE, OUT `fine` DECIMAL(10,2))  NO SQL
BEGIN
SELECT dor INTO @dor
from borrow
WHERE book_id = bookid and user_id = userid and actual_dor is null;
SELECT get_fine(@dor,ador,userid) into @fine;
SET fine = @fine;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `login` (IN `emailid` VARCHAR(30), IN `pwd` VARCHAR(100), OUT `success` TINYINT, OUT `session_id` VARCHAR(100))  NO SQL
BEGIN
SELECT id 
INTO @user_id
FROM user 
WHERE email = emailid and password = md5(pwd);

SELECT row_count() into @affectedRows;
IF @affectedRows = 0 THEN
	SET success = 0;
ELSE
	INSERT INTO `session`(`id`, `user_id`) 
    VALUES (UUID_TO_BIN(UUID()),@user_id);
    SELECT row_count() into @rowsAdded;
    IF @rowsAdded = 0 THEN
		SET success = 0;
        
    ELSE 
		 SELECT BIN_TO_UUID(id) 
         INTO @session_id
         FROM session
        
         WHERE user_id = @user_id
         ORDER BY  created_on DESC
         LIMIT 1;
       
        SET success = 1;
        SET session_id = @session_id;
    END IF;
END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `pickup_book` (IN `pickupcode` INT(10), OUT `success` TINYINT, OUT `message` VARCHAR(100))  NO SQL
BEGIN 
SELECT check_pickup_code_valid(pickupcode) INTO @valid;
IF @valid = 1 THEN
	UPDATE reservation
    SET pickup = 1
    WHERE pickup_code = pickupcode 
    	AND reservation_date = CURRENT_DATE 
        AND pickup = 0;
    SELECT row_count() INTO @affectedRow;
    IF @affectedRow = 1 THEN 
    	SET success = 1;
        SET message = "Pickup Successfull";
    ELSE
    	SET success = 0;
        SET message = "Book pickup failed";
    END IF;
ELSE 
	SET success = 0;
    SET message = "Invalid Pickup Code";
    	
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `renew_book` (IN `bookid` INT(11), IN `userid` INT(10), OUT `success` TINYINT, OUT `new_dor` DATE, OUT `user_email` VARCHAR(100), OUT `book_title` VARCHAR(100), OUT `message` VARCHAR(100))  NO SQL
BEGIN

SELECT check_user_renew(userid,bookid) INTO @is_renew_allowed;

IF @is_renew_allowed = 1 THEN 
	SELECT dor 
    INTO @returndate
    FROM borrow
    WHERE book_id = bookid and user_id = userid and actual_dor is null;
    
    SELECT get_date_of_return(@returndate,userid) into @newReturnDate;
    
      
    	
    
        UPDATE borrow
        SET times_renewed = times_renewed + 1 , dor = @newReturnDate
        WHERE book_id = bookid 
        and user_id = userid and actual_dor is null;

        SELECT row_count() INTO @affectedRows;

        IF @affectedRows = 1 THEN

            SET success = 1;

            SELECT email 
                    INTO @useremail 
                    FROM user 
                    WHERE id = userid;

                    SET user_email = @useremail;

                    SELECT t1.title INTO @booktitle from book as t1
                    INNER JOIN catalog as t2 
                    ON t1.isbn = t2.isbn and t2.book_id = bookid;

                    SET book_title = @booktitle;

                    SET new_dor = @newReturnDate;


        ELSE 
            SET success = 0;
        END IF;
    
ELSE
	SET success = 0;
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `reserve_book` (IN `bookid` INT(10), IN `userid` INT(11), IN `do_res` DATE, OUT `success` TINYINT, OUT `user_email` VARCHAR(25), OUT `book_title` VARCHAR(50), OUT `pickupcode` INT(10), OUT `message` VARCHAR(100))  NO SQL
BEGIN

SELECT check_book_is_available(bookid,do_res) INTO @isAvailable;

IF @isAvailable = 1 THEN
	SELECT check_user_reserve(userid) INTO @allowed;
    
    IF @allowed = 1 THEN 

	INSERT INTO `reservation`(`id`, `book_id`, `pickup_code`,`user_id`, `reservation_date`) VALUES (UUID_TO_BIN(UUID()),bookid,LPAD(FLOOR(RAND() * 999999.99), 6, '0'),userid,do_res);
    SELECT row_count() into @affectedRows;
    
    IF @affectedRows = 1 THEN 

        SELECT email 
            into @email 
            from user 
            where id = userid;
            SET user_email = @email;
        
        
        SELECT title 
        into @title 
        from book 
        where isbn = (SELECT isbn FROM catalog where book_id = bookid);
        SET book_title = @title;
        
        SELECT pickup_code INTO @code 
        FROM reservation
        WHERE book_id = bookid 
        and user_id = userid 
        and reservation_date = do_res;
        
        
    	SET pickupcode = @code;
    	SET success = 1;
    ELSE 
    	SET success = 0;
        SET message = "Insertion Failed";
    END IF;
    ELSE 
    	SET success = 0;
        SET message = "User blocked from book reservation";
    END IF;
ELSE

	SET success = 0;
    SET message = "Book is unavailable for reservation";
    

END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `return_book` (IN `bookid` INT(10), IN `userid` INT(11), IN `actual_return` DATE, OUT `success` TINYINT, OUT `fine` DECIMAL(10,2), OUT `user_email` VARCHAR(100), OUT `book_title` VARCHAR(100))  NO SQL
BEGIN
SELECT dor INTO @dor
from borrow
WHERE book_id = bookid and user_id = userid and actual_dor is null;

SELECT get_fine(@dor,actual_return,userid) into @fine;

UPDATE  borrow 
SET actual_dor = actual_return , fine = @fine
WHERE book_id = bookid and user_id = userid;

SELECT row_count() into @affectedRows;

IF @affectedRows = 1 THEN

    UPDATE  catalog SET is_borrowed = 0  
    WHERE book_id = bookid;       
    SELECT row_count() into @rows_affected;
    
    IF @rows_affected = 1 THEN 
    	SET success = 1;
        SET fine = @fine;
        SELECT email 
                INTO @useremail 
                FROM user 
                WHERE id = userid;
                
                SET user_email = @useremail;
                
                SELECT t1.title INTO @booktitle from book as t1
                INNER JOIN catalog as t2 
                ON t1.isbn = t2.isbn and t2.book_id = bookid;
                
                SET book_title = @booktitle;
    ELSE 
    	SET success = 0;
    END IF;
ELSE
 SET success = 0;
 END IF;
 
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `set_counter` (INOUT `count` INT(4), IN `inc` INT(4))  BEGIN
 SET count = count + inc;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `show_books` (IN `like_name` VARCHAR(20))  NO SQL
SELECT 
t1.title, t1.subtitle, t1.publication ,t1.isbn ,
t1.description, t1.published_date, t1.page_count ,
t1.language, t1.thumbnail, GROUP_CONCAT(CONCAT(t4.first_name, ' ',t4.last_name)) AS authors ,
t3.description 
FROM book as t1
INNER JOIN book_author as t2
ON t1.isbn = t2.isbn
INNER JOIN author as t4
ON t2.author_id = t4.id
INNER JOIN book_type as t3
ON t1.type = t3.id
WHERE 
    (t1.title LIKE like_name) 
 OR (t4.first_name LIKE like_name) 
 OR (t4.last_name Like like_name)
 OR (t1.isbn Like like_name)
 OR (t1.publication Like like_name)
GROUP BY t1.isbn ASC$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `trial_procedure` (IN `name` VARCHAR(50))  NO SQL
INSERT INTO `book` (`id`, `name`) VALUES (UUID_TO_BIN(UUID()), name)$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `update_book` (IN `bookid` INT(10), IN `loc` VARCHAR(10), IN `apply_all` TINYINT, IN `locked` TINYINT)  NO SQL
BEGIN
UPDATE catalog 
SET is_locked = locked  
WHERE book_id = bookid;

IF apply_all = 0 THEN
	UPDATE catalog 
    SET location = loc  
    WHERE book_id = bookid;
    
ELSEIF apply_all = 1 THEN
	SELECT isbn into @isbn from catalog where book_id = bookid;
	UPDATE catalog
    SET location = loc 
    WHERE isbn = @isbn;
END IF;

END$$

--
-- Functions
--
CREATE DEFINER=`root`@`localhost` FUNCTION `check_book_is_available` (`bookid` INT, `do_res` DATE) RETURNS TINYINT(4) NO SQL
BEGIN

SELECT count(*) 
INTO @available
FROM `borrow` 
WHERE book_id = bookid and actual_dor is null;

IF @available > 0 THEN 
	RETURN 0;
ELSE 
	SELECT count(*) INTO @reserved
    FROM `reservation`
    WHERE book_id = bookid and reservation_date = do_res;
    
    IF @reserved = 1 THEN 
    	RETURN 0;
    ELSE 
    	RETURN 1;
    END IF;
END IF;

RETURN 1;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `check_is_null_or_empty` (`str` VARCHAR(50)) RETURNS TINYINT(4) NO SQL
BEGIN

IF str IS NULL OR str = '' THEN
	RETURN 1;
ELSE 
	RETURN 0;

END IF;
	

END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `check_pickup_code_valid` (`pickupcode` INT(10)) RETURNS TINYINT(4) NO SQL
BEGIN 

SELECT count(id) 
INTO @count
FROM reservation
WHERE pickup_code = pickupcode 
	and pickup = 0 
    and reservation_date = CURRENT_DATE;
    
    IF @count = 1 THEN
    	RETURN 1;
    ELSE
    	RETURN 0;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `check_user_borrow` (`userid` INT(11)) RETURNS TINYINT(4) NO SQL
BEGIN

SELECT max_books_allowed 
INTO @max_limit
FROM user_type
WHERE id = (SELECT user_type FROM user WHERE id = userid);

SELECT COUNT(*)
INTO @total_borrowed
FROM borrow
WHERE user_id = userid AND actual_dor is null;

IF @total_borrowed <= @max_limit THEN
	RETURN 1;
ELSE
	RETURN 0;
END IF;

END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `check_user_renew` (`userid` INT(11), `bookid` INT(10)) RETURNS TINYINT(4) NO SQL
BEGIN
SELECT times_renewable 
INTO @times_renewable
FROM user_type 
WHERE id = (SELECT user_type from user where id = userid);

SELECT times_renewed , dor
INTO @times_renewed , @dateOfReturn
FROM borrow 
WHERE book_id = bookid and user_id = userid and actual_dor is null;

IF @times_renewable > @times_renewed THEN
	SELECT get_date_of_return(@dateOfReturn,userid) INTO @newDor;
    SELECT count(id) 
    INTO @reserved 
    FROM reservation
	WHERE `book_id`=bookid 
    AND `reservation_date` 
        BETWEEN @dateOfReturn AND @newDor;
        
    IF @reserved = 0 THEN
		RETURN 1;
    ELSE 
    	RETURN 0;
    END IF;
ELSE 
	RETURN 0;
END IF;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `check_user_reserve` (`userid` INT(10)) RETURNS TINYINT(4) NO SQL
BEGIN
SELECT count(id) 
INTO @count
FROM `reservation` 
WHERE `user_id`=userid
	AND pickup = 0
    AND reservation_date  BETWEEN  CURRENT_DATE - interval 3 month AND CURRENT_DATE;

SELECT max_failed_reservation 
into @maxFailedReservation
FROM user_type
where id = (SELECT user_type from user WHERE id = userid);

IF @count <= @maxFailedReservation THEN
	RETURN 1;
ELSE
	RETURN 0;
END IF;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `get_author_id` (`fname` VARCHAR(20), `lname` VARCHAR(20)) RETURNS INT(11) NO SQL
BEGIN

SELECT id 
INTO @id 
FROM author 
WHERE first_name = fname and last_name = lname;

RETURN @id;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `get_count_books_borrowed_by_user` (`userid` INT(10)) RETURNS INT(11) NO SQL
BEGIN
SELECT count(id) INTO @books_borrowed
FROM borrow
WHERE user_id = userid and actual_dor is null;

RETURN @books_borrowed;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `get_date_of_return` (`issuedate` DATE, `userid` INT) RETURNS DATE NO SQL
BEGIN
SELECT duration
INTO @duration
FROM user_type
WHERE id = (SELECT user_type from user where id = userid);

SELECT DATE_ADD(issuedate, INTERVAL @duration DAY) INTO @returndate;

RETURN @returndate;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `get_fine` (`dor` DATE, `ador` DATE, `userid` INT(11)) RETURNS DECIMAL(10,2) NO SQL
BEGIN 



SELECT DATEDIFF(ador,dor) into @days;

IF @days > 0 THEN
	SELECT fine 
    INTO @finePerDay
    FROM user_type
    WHERE id = (SELECT user_type from user where id = userid);
    
    SELECT @finePerDay * @days INTO @fine;
    
    
ELSE
	SELECT 0.00 INTO @fine;
END IF;


RETURN @fine;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `split_string` (`stringToSplit` VARCHAR(256), `sign` VARCHAR(12), `position` INT) RETURNS VARCHAR(256) CHARSET utf8mb4 NO SQL
BEGIN
        RETURN REPLACE(SUBSTRING(SUBSTRING_INDEX(stringToSplit, sign, position), 
LENGTH(SUBSTRING_INDEX(stringToSplit, sign, position -1)) + 1), sign, '');
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `author`
--

CREATE TABLE `author` (
  `id` int(10) NOT NULL,
  `first_name` varchar(20) NOT NULL,
  `last_name` varchar(20) NOT NULL,
  `alias` varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT;

--
-- Dumping data for table `author`
--

INSERT INTO `author` (`id`, `first_name`, `last_name`, `alias`) VALUES
(1, 'Andrew', 'H.', NULL),
(2, 'Klaus', 'Pohl', NULL),
(3, 'Steven', 'H.', NULL),
(4, 'Markus', 'Gärtner', NULL),
(5, 'Oskar', 'Karl', NULL),
(6, 'Ludwig', 'Prandtl', NULL),
(7, 'Guy', 'Lebanon', NULL),
(8, 'Mohamed', 'El-Geish', NULL),
(9, 'Bernard', 'Friedland', NULL),
(10, 'William', 'Tyrrell', NULL),
(11, 'Martin', 'Murray', NULL),
(12, 'Mary', 'Wollstonecraft', NULL),
(13, 'Brian', 'Falkner', NULL),
(14, 'Stieg', 'Larsson', NULL),
(15, 'Stephen', 'King', NULL),
(16, 'Nathaniel', 'Hawthorne', NULL),
(17, 'Carianne', 'Bernadowski', NULL),
(18, 'Kelly', 'Morgano', NULL),
(19, 'Joseph', 'Conrad', NULL),
(20, 'Jacques', 'Berthoud', NULL),
(21, 'Mara', 'Kalnins', NULL),
(22, 'Gillian', 'Flynn', NULL),
(23, 'Edward', 'Morgan', NULL),
(24, 'Christof', 'Kehr', NULL),
(25, 'Michaela', 'Meyerhoff', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `book`
--

CREATE TABLE `book` (
  `id` binary(16) DEFAULT NULL,
  `type` int(11) NOT NULL,
  `isbn` varchar(13) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `title` longtext CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `subtitle` longtext CHARACTER SET utf8 COLLATE utf8_general_ci,
  `publication` longtext CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `description` longtext CHARACTER SET utf8 COLLATE utf8_general_ci,
  `published_date` date NOT NULL,
  `page_count` int(10) NOT NULL,
  `language` varchar(10) NOT NULL,
  `thumbnail` varchar(500) NOT NULL,
  `created_on` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `book`
--

INSERT INTO `book` (`id`, `type`, `isbn`, `title`, `subtitle`, `publication`, `description`, `published_date`, `page_count`, `language`, `thumbnail`, `created_on`) VALUES
(0x2e4cbde083eb11e9a7e0e32407b67f56, 1, '9780132350884', 'ATDD in der Praxis', 'Eine praktische Einführung in die Akzeptanztest-getriebene Softwareentwicklung mit Cucumber, Selenium und FitNesse', 'Ruby', 'Diese Buch bietet eine praxisbezogene und anschauliche Einführung in die akzeptanztestgetriebene Entwicklung (Acceptance Test-driven Development, ATTD, auch bekannt als Behavior-driven Development oder Specification-by-Example). Anhand zweier ausführlicher Praxisbeispiele erfährt der Leser, wie sich Testautomatisierung innerhalb eines agilen Entwicklungsprozesses verwenden lässt. Anschließend werden die grundlegenden Prinzipien zusammengefasst und verdeutlicht. Dadurch erlebt der Leser praxisnah, was ATDD ist, und bekommt wertvolle Hinweise, wie er entsprechende Prozesse aufbauen kann.', '2013-04-02', 224, 'de', '', '2019-05-31 21:29:32'),
(0xbd93dec083eb11e9a7e0e32407b67f56, 1, '9780134494166', 'Computing with Data', 'An Introduction to the Data Industry', 'Springer', 'This book introduces basic computing skills designed for industry professionals without a strong computer science background. Written in an easily accessible manner, and accompanied by a user-friendly website, it serves as a self-study guide to survey data science and data engineering for those who aspire to start a computing career, or expand on their current roles, in areas such as applied statistics, big data, machine learning, data mining, and informatics. The authors draw from their combined experience working at software and social network companies, on big data products at several major online retailers, as well as their experience building big data systems for an AI startup. Spanning from the basic inner workings of a computer to advanced data manipulation techniques, this book opens doors for readers to quickly explore and enhance their computing knowledge. Computing with Data comprises a wide range of computational topics essential for data scientists, analysts, and engineers, providing them with the necessary tools to be successful in any role that involves computing with data. The introduction is self-contained, and chapters progress from basic hardware concepts to operating systems, programming languages, graphing and processing data, testing and programming tools, big data frameworks, and cloud computing. The book is fashioned with several audiences in mind. Readers without a strong educational background in CS--or those who need a refresher--will find the chapters on hardware, operating systems, and programming languages particularly useful. Readers with a strong educational background in CS, but without significant industry background, will find the following chapters especially beneficial: learning R, testing, programming, visualizing and processing data in Python and R, system design for big data, data stores, and software craftsmanship.', '2018-11-28', 576, 'en', '', '2019-05-31 21:33:33'),
(0x847149408b7811e996069926f352bec1, 1, '9780156711425', 'A Passage to India', '', 'PQR Books', 'In a scathing indictment of British imperialism, Forster once controversial novel portrays two Englishwomen who experience misunderstanding and cultural conflict after they travel to India', '1990-10-10', 322, 'en', '', '2019-06-10 12:08:54'),
(0x0cbc862e8b7a11e996069926f352bec1, 1, '9780199555918', 'Nostromo', 'A Tale of the Seaboard', 'ABC Books', 'Returning to the steamy backwater of Costaguana in South America Charles Gould is determined to make a success of the inherited silver mine. However, his dreams of wealth and power are thwarted when the country is plunged into revolution.', '2009-08-27', 453, 'en', '', '2019-06-10 12:19:52'),
(0xba016f088a4811e996069926f352bec1, 1, '9780307947307', 'The Stand', 'A Novel', 'QWERTY Publications', 'A monumentally devastating plague leaves only a few survivors who, while experiencing dreams of a battle between good and evil, move toward an actual confrontation as they migrate to Boulder, Colorado.', '1998-12-20', 1153, 'en', '', '2019-06-08 23:54:17'),
(0x68be354a8a4811e996069926f352bec1, 2, '9780307949486', 'The Girl With the Dragon Tattoo', '', 'NPM Publication', 'Forty years after the disappearance of Harriet Vanger from the secluded island owned and inhabited by the powerful Vanger family, her octogenarian uncle hires journalist Mikael Blomqvist and Lisbeth Salander, an unconventional young hacker, to investigate.', '1990-12-20', 644, 'en', '', '2019-06-08 23:52:01'),
(0xd684d5e88a4811e996069926f352bec1, 1, '9780486280486', 'The Scarlet Letter', '', 'ABC Publications', 'Hester Prynne is ostracized from her seventeenth-century Puritan community for refusing to name the father of her child, the product of an adulterous relationship.', '1997-12-20', 180, 'en', '', '2019-06-08 23:55:05'),
(0x100ea63083ec11e9a7e0e32407b67f56, 1, '9780486442785', 'Control System Design', 'An Introduction to State-Space Methods', 'McGraw Hill', 'Introduction to state-space methods covers feedback control; state-space representation of dynamic systems and dynamics of linear systems; frequency-domain analysis; controllability and observability; shaping the dynamic response; and more. 1986 edition.', '2005-03-24', 513, 'en', '', '2019-05-31 21:35:51'),
(0xcf13a47083e911e9a7e0e32407b67f56, 1, '9780486462745', 'Stochastic Processes and Filtering Theory', '', 'ABC Publication', 'This unified treatment presents material previously available only in journals, and in terms accessible to engineering students.', '2007-01-01', 376, 'en', '', '2019-05-31 21:19:43'),
(0x540f1cb283eb11e9a7e0e32407b67f56, 1, '9780486603759', 'Applied Hydro- and Aeromechanics', 'Based on Lectures of L. Prandtl', 'TechMax Publishers', 'Prandtl was one of the great theorists of aerodynamics and this work has long been considered one of the finest introductory works in the field. Topics include flow through pipes, Prandtls own work on boundary layers, drag, airfoil theory, and entry conditions for flow in a pipe.', '1957-01-01', 311, 'en', '', '2019-05-31 21:30:36'),
(0x10507fd283ed11e9a7e0e32407b67f56, 2, '9780486651132', 'Introduction to Space Dynamics', '', 'McGraw Hill', 'Although this classic introduction to space-flight engineering was first published not long after Sputnik was launched, the fundamental principles it elucidates are as varied today as then. The problems to which these principles are applied have changed, and the widespread use of computers has accelerated problem-solving techniques, but this book is still a valuable basic text for advanced undergraduate and graduate students of aerospace engineering. The first two chapters cover vector algebra and kinematics, including angular velocity vector, tangential and normal components, and the general case of space motion. The third chapter deals with the transformation of coordinates, with sections of Euler angles, and the transformation of angular velocities. A variety of interesting problems regarding the motion of satellites and other space vehicles is discussed in Chapter 4, which includes the two-body problem, orbital change due to impulsive thrust, long-range ballistic trajectories, and the effect of the Earth oblateness. The fifth and sixth chapters describe gyrodynamics and the dynamics of gyroscopic instruments, covering such topics as the displacement of a rigid body, precession and nutation of the Earth polar axis, oscillation of the gyrocompass, and inertial navigation. Chapter 7 is an examination of space vehicle motion, with analyses of general equations in body conditions and their transformation to inertial coordinates, attitude drift of space vehicles, and variable mass. The eighth chapter discusses optimization of the performance of single-stage and multistage rockets. Chapter 9 deals with generalized theories of mechanics, including holonomic and non-holonomic systems, Lagrange Equation for impulsive forces, and missile dynamics analysis. Throughout this clear, comprehensive text, practice problems (with answers to many) aid the student in mastering analytic techniques, and numerous charts and diagrams reinforce each lesson. 1961 edition.', '1986-06-01', 317, 'en', '', '2019-05-31 21:43:01'),
(0x3c4bd8aa8a4811e996069926f352bec1, 1, '9780763678029', 'Der Tomorrow Code', 'Thriller', 'ABC Publication', 'Tane und Rebecca erhalten eine rätselhafte Nachricht: eine anscheinend endlose Sequenz von Nullen und Einsen. Sie schaffen es, die Botschaft zu entschlüsseln. Doch die Freude über den Erfolg währt nicht lange – die Nachricht kommt aus der Zukunft (abgeschickt von ihnen selbst) und prophezeit nichts anderes als den Weltuntergang! Nur Tane und Rebecca können die Katastrophe verhindern. Doch die Zeit läuft gegen sie. Langsam, aber unerbittlich setzt ein Massensterben ein...', '2012-10-01', 420, 'de', '', '2019-06-08 23:50:46'),
(0x027e14b683eb11e9a7e0e32407b67f56, 1, '9780813349107', 'Nonlinear Dynamics and Chaos', 'With Applications to Physics, Biology, Chemistry, and Engineering', 'Technical Publications', 'This textbook is aimed at newcomers to nonlinear dynamics and chaos, especially students taking a first course in the subject. The presentation stresses analytical methods, concrete examples, and geometric intuition. The theory is developed systematically, starting with first-order differential equations and their bifurcations, followed by phase plane analysis, limit cycles and their bifurcations, and culminating with the Lorenz equations, chaos, iterated maps, period doubling, renormalization, fractals, and strange attractors. A unique feature of the book is its emphasis on applications. These include mechanical vibrations, lasers, biological rhythms, superconducting circuits, insect outbreaks, chemical oscillators, genetic control systems, chaotic waterwheels, and even a technique for using chaos to send secret messages. In each case, the scientific background is explained at an elementary level and closely integrated with mathematical theory. In the twenty years since the first edition of this book appeared, the ideas and techniques of nonlinear dynamics and chaos have found application to such exciting new fields as systems biology, evolutionary game theory, and sociophysics. This second edition includes new exercises on these cutting-edge developments, on topics as varied as the curiosities of visual perception and the tumultuous love dynamics in Gone With the Wind.', '2014-08-26', 500, 'en', '', '2019-05-31 21:28:19'),
(0x7380ffa48a4c11e996069926f352bec1, 1, '9781400033416', 'Teaching Historical Fiction with Ready-Made Literature Circles for Secondary Readers', '', 'ABC Publication', 'This comprehensive step-by-step guide provides practical guidance to implement literature circles in any social studies or language arts classroom. •Provides an author and title index', '2011-10-24', 229, 'en', '', '2019-06-09 00:20:57'),
(0xb876bb3e83ea11e9a7e0e32407b67f56, 1, '9781491929124', 'Site Reliability Engineering', 'How Google Runs Production Systems', 'O Relly', 'The overwhelming majority of a software systems lifespan is spent in use, not in design or implementation. So, why does conventional wisdom insist that software engineers focus primarily on the design and development of large-scale computing systems? In this collection of essays and articles, key members of Google Site Reliability Team explain how and why their commitment to the entire lifecycle has enabled the company to successfully build, deploy, monitor, and maintain some of the largest software systems in the world. You learn the principles and practices that enable Google engineers to make systems more scalable, reliable, and efficient—lessons directly applicable to your organization. This book is divided into four sections: Introduction—Learn what site reliability engineering is and why it differs from conventional IT industry practices Principles—Examine the patterns, behaviors, and areas of concern that influence the work of a site reliability engineer (SRE) Practices—Understand the theory and practice of an SREs day-to-day work: building and operating large distributed computing systems Management—Explore Googles best practices for training, communication, and meetings that your organization can use', '2016-03-23', 552, 'en', '', '2019-05-31 21:26:15'),
(0x249aec468a4811e996069926f352bec1, 1, '9781503262423', 'Frankenstein', '', 'ABC Publication', 'This book publication is unique which includes exclusive Introduction, Historical Background and handcrafted additional content. ', '2014-11-29', 148, 'en', '', '2019-06-08 23:50:06'),
(0xc4f1648a8a1211e9a7e0e32407b67f56, 1, '9781592293582', 'Materials Management with SAP ERP', 'Functionality and Technical Configuration', 'Gellilo Press', 'Discover the power of Materials Management (MM) with SAP ERP in this completely updated and expanded edition Explore how MM works and integrates with other key SAP software Master core functionalities and configuration techniques to streamline your organization s processes Find out how to make the most of your Materials Management (MM) implementation with this completely updated, comprehensive guide. Based on SAP ERP 6.0, this new edition of the best-selling book is a comprehensive reference to the ins and outs of Materials Management in SAP, with new real-world, practical examples to help you grasp the information quickly and efficiently. You ll learn everything you need to know, from goods receipt and invoice verification to balance sheet valuation and the material ledger. Materials Management Processes and Concepts Discover the various concepts of materials management and how they can be used to help your business run smoothly. Materials Management Configuration Learn specific configuration details to help you optimize your MM implementation.Comprehensive Coverage of Key Concepts Master the various elements of SAP ERP, including material master data, vendor master data, purchase requisitions, request for quotations, inventory management, and much more. Real-World Scenarios and Examples Use the expert advice and examples throughout to help you with your own MM processes. Third Edition, Updated and Expanded This book is updated to include new content on the release strategy for purchasing, special procurement keys, split valuation, pricing conditions in purchasing, taxes in MM, as well as screenshots for the latest GUI and new appendices.', '2018-08-14', 666, 'en', '', '2019-06-08 17:28:02'),
(0x24574ba08bcc11e996069926f352bec1, 1, '9783126753234', 'Grammatiktrainer', 'in 99 Schritten mit Lösungen für Deutsch als Fremd- und Zweitsprache', 'PONS', 'Die Grammatik der gesamten Grundstufe. Überschaubare Lernschritte auf 99 Doppelseiten; links wird erklärt, rechts wird geübt. Einfache Regeln, vieleBilder und Merkhilfen. Beispiele aus dem Alltag und praktische Übungen. Lösungen zur sofortigen Erfolgskontrolle.', '2003-01-01', 248, 'de', '', '2019-06-10 22:07:31'),
(0xfbb5a52a8bcb11e996069926f352bec1, 1, '9783499614118', 'Deutsch Eins für Ausländer', 'Ein Grundkurs zum Reden und Verstehen', 'ABC Books', '', '1990-10-10', 326, 'de', '', '2019-06-10 22:06:22');

-- --------------------------------------------------------

--
-- Table structure for table `book_author`
--

CREATE TABLE `book_author` (
  `id` binary(16) NOT NULL,
  `isbn` varchar(13) NOT NULL,
  `author_id` int(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `book_author`
--

INSERT INTO `book_author` (`id`, `isbn`, `author_id`) VALUES
(0x028001b883eb11e9a7e0e32407b67f56, '9780813349107', 3),
(0x0cbe1d368b7a11e996069926f352bec1, '9780199555918', 19),
(0x0cbe46da8b7a11e996069926f352bec1, '9780199555918', 20),
(0x0cbe661a8b7a11e996069926f352bec1, '9780199555918', 21),
(0x101e638683ec11e9a7e0e32407b67f56, '9780486442785', 9),
(0x1060f95283ed11e9a7e0e32407b67f56, '9780486651132', 10),
(0x24a9ed908a4811e996069926f352bec1, '9781503262423', 12),
(0x2e51011683eb11e9a7e0e32407b67f56, '9780132350884', 4),
(0x3573071083ea11e9a7e0e32407b67f56, '9781937538774', 2),
(0x3c5055108a4811e996069926f352bec1, '9780763678029', 13),
(0x541f08f283eb11e9a7e0e32407b67f56, '9780486603759', 5),
(0x541f676683eb11e9a7e0e32407b67f56, '9780486603759', 6),
(0x68c87a468a4811e996069926f352bec1, '9780307949486', 14),
(0x6b0a92d68b7811e996069926f352bec1, '9780307588371', 22),
(0x7391b1148a4c11e996069926f352bec1, '9781400033416', 17),
(0x7391f3408a4c11e996069926f352bec1, '9781400033416', 18),
(0x8473614e8b7811e996069926f352bec1, '9780156711425', 23),
(0xba0618b48a4811e996069926f352bec1, '9780307947307', 15),
(0xbd96c9be83eb11e9a7e0e32407b67f56, '9780134494166', 7),
(0xbd97278883eb11e9a7e0e32407b67f56, '9780134494166', 8),
(0xc5010b1a8a1211e9a7e0e32407b67f56, '9781592293582', 11),
(0xc7abc9d88a4c11e996069926f352bec1, '9780199555918', 19),
(0xc7ac02548a4c11e996069926f352bec1, '9780199555918', 20),
(0xc7ac412e8a4c11e996069926f352bec1, '9780199555918', 21),
(0xcf14f1a483e911e9a7e0e32407b67f56, '9780486462745', 1),
(0xd688c3248a4811e996069926f352bec1, '9780486280486', 16),
(0xfbba186c8bcb11e996069926f352bec1, '9783499614118', 24),
(0xfbbabe7a8bcb11e996069926f352bec1, '9783499614118', 25);

-- --------------------------------------------------------

--
-- Table structure for table `book_type`
--

CREATE TABLE `book_type` (
  `id` int(11) NOT NULL,
  `description` varchar(10) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `book_type`
--

INSERT INTO `book_type` (`id`, `description`) VALUES
(1, 'purchased'),
(2, 'donated'),
(3, 'loaned');

-- --------------------------------------------------------

--
-- Table structure for table `borrow`
--

CREATE TABLE `borrow` (
  `id` binary(16) NOT NULL,
  `book_id` int(10) NOT NULL,
  `user_id` int(11) NOT NULL,
  `doi` date NOT NULL,
  `dor` date NOT NULL,
  `actual_dor` date DEFAULT NULL,
  `times_renewed` int(11) NOT NULL DEFAULT '0',
  `fine` decimal(10,2) NOT NULL DEFAULT '0.00',
  `fine_paid` tinyint(4) NOT NULL DEFAULT '0',
  `created_on` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `borrow`
--

INSERT INTO `borrow` (`id`, `book_id`, `user_id`, `doi`, `dor`, `actual_dor`, `times_renewed`, `fine`, `fine_paid`, `created_on`) VALUES
(0x32a36a96840011e9a7e0e32407b67f56, 10001, 10000, '2019-05-26', '2019-06-01', '2019-06-01', 0, '0.00', 0, '2019-06-01 01:59:59'),
(0xd8d6b0d0840011e9a7e0e32407b67f56, 10041, 10001, '2019-05-26', '2019-06-01', NULL, 0, '0.00', 0, '2019-06-01 02:04:38'),
(0x071cafd8852511e9a7e0e32407b67f56, 10003, 10000, '2019-06-02', '2019-06-14', '2019-06-03', 0, '0.00', 0, '2019-06-02 12:56:09'),
(0x1f1302d6852511e9a7e0e32407b67f56, 10014, 10000, '2019-06-02', '2019-06-14', '2019-06-03', 0, '0.00', 0, '2019-06-02 12:56:49'),
(0x16c8fa6a852811e9a7e0e32407b67f56, 10006, 10001, '2019-06-02', '2019-08-01', NULL, 0, '0.00', 0, '2019-06-02 13:18:03'),
(0x2e3622cc852811e9a7e0e32407b67f56, 10005, 10001, '2019-06-02', '2019-08-01', NULL, 0, '0.00', 0, '2019-06-02 13:18:43'),
(0x6429e36c85ac11e9a7e0e32407b67f56, 10003, 10002, '2019-06-01', '2019-06-03', '2019-06-10', 0, '0.00', 0, '2019-06-03 05:05:07'),
(0x7eb3da8e85ad11e9a7e0e32407b67f56, 10015, 10004, '2019-06-03', '2019-06-18', '2019-06-03', 0, '0.00', 0, '2019-06-03 05:13:01'),
(0x7c2b1e6a870811e9a7e0e32407b67f56, 10045, 10002, '2019-06-04', '2019-07-04', '2019-06-04', 1, '0.00', 0, '2019-06-04 22:36:52'),
(0xb2197ed0870911e9a7e0e32407b67f56, 10045, 10002, '2019-06-01', '2019-06-04', '2019-06-10', 0, '0.00', 0, '2019-06-04 22:45:32'),
(0x18cad3e887d911e9a7e0e32407b67f56, 10031, 10006, '2019-07-21', '2019-08-15', '2019-06-05', 0, '0.00', 0, '2019-06-05 23:30:10'),
(0x6b6346d087d911e9a7e0e32407b67f56, 10031, 10006, '2019-07-01', '2019-09-13', '2019-06-05', 1, '0.00', 0, '2019-06-05 23:32:29'),
(0xc0b033a287dc11e9a7e0e32407b67f56, 10031, 10005, '2019-07-01', '2019-07-15', NULL, 0, '0.00', 0, '2019-06-05 23:56:20'),
(0xb679c9b6890d11e9a7e0e32407b67f56, 10044, 10005, '2019-06-07', '2019-08-06', NULL, 0, '0.00', 0, '2019-06-07 12:19:20'),
(0x92ac520a890e11e9a7e0e32407b67f56, 10021, 10007, '2019-06-07', '2019-08-06', '2019-06-07', 0, '0.00', 0, '2019-06-07 12:25:29'),
(0x141760ce8a4e11e996069926f352bec1, 10093, 10008, '2019-06-09', '2019-06-24', '2019-06-09', 0, '0.00', 0, '2019-06-09 02:32:36'),
(0xac2feb408a5011e996069926f352bec1, 10099, 10005, '2019-06-09', '2019-06-11', '2019-06-10', 0, '0.00', 0, '2019-06-09 02:51:10'),
(0xd26e0daa8a5011e996069926f352bec1, 10090, 10005, '2019-06-09', '2019-06-11', '2019-06-09', 0, '0.00', 0, '2019-06-09 02:52:14'),
(0xaaaca6048a5111e996069926f352bec1, 10090, 10005, '2019-06-09', '2019-06-11', '2019-06-09', 0, '0.00', 0, '2019-06-09 02:58:17'),
(0xef13815a8a5111e996069926f352bec1, 10090, 10005, '2019-06-09', '2019-06-11', '2019-06-09', 0, '0.00', 0, '2019-06-09 03:00:11'),
(0x88f84ebc8a5311e996069926f352bec1, 10090, 10005, '2019-06-09', '2019-06-11', '2019-06-09', 0, '0.00', 0, '2019-06-09 03:11:39'),
(0xcce2ded08a5311e996069926f352bec1, 10090, 10005, '2019-06-09', '2019-06-11', '2019-06-09', 0, '0.00', 0, '2019-06-09 03:13:33'),
(0x31e46ed48a5411e996069926f352bec1, 10090, 10005, '2019-06-09', '2019-06-11', NULL, 0, '0.00', 0, '2019-06-09 03:16:23'),
(0xb42e4caa8bcd11e996069926f352bec1, 10074, 10003, '2019-06-05', '2019-06-12', NULL, 0, '0.00', 0, '2019-06-11 00:18:41'),
(0xa0e7743a8bcf11e996069926f352bec1, 10073, 10011, '2019-05-15', '2019-06-12', NULL, 0, '0.00', 0, '2019-06-11 00:32:28'),
(0x3036c9108bd011e996069926f352bec1, 10116, 10005, '2019-06-04', '2019-06-12', NULL, 0, '0.00', 0, '2019-06-11 00:36:28'),
(0x09eaa5a88bd311e996069926f352bec1, 10033, 10012, '2019-06-04', '2019-06-12', NULL, 0, '0.00', 0, '2019-06-11 00:56:53'),
(0x1c987c248bd411e996069926f352bec1, 10117, 10009, '2019-06-10', '2019-08-09', NULL, 0, '0.00', 0, '2019-06-11 01:04:34'),
(0x2f159a128bd411e996069926f352bec1, 10081, 10009, '2019-06-10', '2019-08-09', NULL, 0, '0.00', 0, '2019-06-11 01:05:05'),
(0x2123dd5e8bd611e996069926f352bec1, 10063, 10013, '2019-06-10', '2019-06-25', NULL, 0, '0.00', 0, '2019-06-11 01:19:00');

-- --------------------------------------------------------

--
-- Table structure for table `catalog`
--

CREATE TABLE `catalog` (
  `id` binary(16) NOT NULL,
  `book_id` int(10) NOT NULL,
  `isbn` varchar(13) NOT NULL,
  `is_locked` tinyint(1) NOT NULL DEFAULT '0',
  `is_borrowed` tinyint(1) NOT NULL DEFAULT '0',
  `location` varchar(10) DEFAULT NULL,
  `created_on` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `catalog`
--

INSERT INTO `catalog` (`id`, `book_id`, `isbn`, `is_locked`, `is_borrowed`, `location`, `created_on`) VALUES
(0xcf14270683e911e9a7e0e32407b67f56, 10001, '9780486462745', 1, 0, NULL, '2019-05-31 23:19:43'),
(0xcf14385483e911e9a7e0e32407b67f56, 10002, '9780486462745', 1, 0, 'South 5/A', '2019-05-31 23:19:43'),
(0xcf14587083e911e9a7e0e32407b67f56, 10003, '9780486462745', 0, 0, NULL, '2019-05-31 23:19:43'),
(0xcf14759e83e911e9a7e0e32407b67f56, 10004, '9780486462745', 0, 0, NULL, '2019-05-31 23:19:43'),
(0xcf1486f683e911e9a7e0e32407b67f56, 10005, '9780486462745', 0, 0, NULL, '2019-05-31 23:19:43'),
(0xcf149e5283e911e9a7e0e32407b67f56, 10006, '9780486462745', 0, 0, NULL, '2019-05-31 23:19:43'),
(0xb877182c83ea11e9a7e0e32407b67f56, 10014, '9781491929124', 1, 0, 'North 1/C', '2019-05-31 23:26:15'),
(0xb87734ce83ea11e9a7e0e32407b67f56, 10015, '9781491929124', 0, 0, 'North 1/C', '2019-05-31 23:26:15'),
(0xb877481a83ea11e9a7e0e32407b67f56, 10016, '9781491929124', 0, 0, 'North 1/C', '2019-05-31 23:26:15'),
(0xb8775dbe83ea11e9a7e0e32407b67f56, 10017, '9781491929124', 0, 0, 'North 1/C', '2019-05-31 23:26:15'),
(0xb8776f2a83ea11e9a7e0e32407b67f56, 10018, '9781491929124', 0, 0, 'North 1/C', '2019-05-31 23:26:15'),
(0xb877892e83ea11e9a7e0e32407b67f56, 10019, '9781491929124', 0, 0, 'North 1/C', '2019-05-31 23:26:15'),
(0xb877ab6683ea11e9a7e0e32407b67f56, 10020, '9781491929124', 0, 0, 'North 1/C', '2019-05-31 23:26:15'),
(0xb877c81283ea11e9a7e0e32407b67f56, 10021, '9781491929124', 0, 0, 'North 1/C', '2019-05-31 23:26:15'),
(0xc228ad9a83ea11e9a7e0e32407b67f56, 10022, '9781491929124', 0, 0, 'North 1/C', '2019-05-31 23:26:31'),
(0xc232ee5483ea11e9a7e0e32407b67f56, 10023, '9781491929124', 0, 0, 'North 1/C', '2019-05-31 23:26:31'),
(0xc23300b083ea11e9a7e0e32407b67f56, 10024, '9781491929124', 0, 0, 'North 1/C', '2019-05-31 23:26:31'),
(0xc233180c83ea11e9a7e0e32407b67f56, 10025, '9781491929124', 0, 0, 'North 1/C', '2019-05-31 23:26:31'),
(0xc23324dc83ea11e9a7e0e32407b67f56, 10026, '9781491929124', 0, 0, 'North 1/C', '2019-05-31 23:26:31'),
(0xc233346883ea11e9a7e0e32407b67f56, 10027, '9781491929124', 0, 0, 'North 1/C', '2019-05-31 23:26:31'),
(0xc233424683ea11e9a7e0e32407b67f56, 10028, '9781491929124', 0, 0, 'North 1/C', '2019-05-31 23:26:31'),
(0xc2334b9283ea11e9a7e0e32407b67f56, 10029, '9781491929124', 0, 0, 'North 1/C', '2019-05-31 23:26:31'),
(0x027efb4283eb11e9a7e0e32407b67f56, 10030, '9780813349107', 1, 0, 'North 1/A', '2019-05-31 23:28:19'),
(0x027f20ae83eb11e9a7e0e32407b67f56, 10031, '9780813349107', 0, 1, 'North 1/A', '2019-05-31 23:28:19'),
(0x027f38d283eb11e9a7e0e32407b67f56, 10032, '9780813349107', 0, 0, 'North 1/A', '2019-05-31 23:28:19'),
(0x027f62da83eb11e9a7e0e32407b67f56, 10033, '9780813349107', 0, 1, 'North 1/A', '2019-05-31 23:28:19'),
(0x027f7b8083eb11e9a7e0e32407b67f56, 10034, '9780813349107', 0, 0, 'North 1/A', '2019-05-31 23:28:19'),
(0x2e50059083eb11e9a7e0e32407b67f56, 10035, '9780132350884', 1, 0, 'East 4/E', '2019-05-31 23:29:32'),
(0x2e5046a483eb11e9a7e0e32407b67f56, 10036, '9780132350884', 0, 0, 'East 4/E', '2019-05-31 23:29:32'),
(0x2e5072e683eb11e9a7e0e32407b67f56, 10037, '9780132350884', 0, 0, 'East 4/E', '2019-05-31 23:29:32'),
(0x541e2cd483eb11e9a7e0e32407b67f56, 10038, '9780486603759', 1, 0, 'West 2/A', '2019-05-31 23:30:36'),
(0x541e506a83eb11e9a7e0e32407b67f56, 10039, '9780486603759', 0, 0, NULL, '2019-05-31 23:30:36'),
(0x541e7e6483eb11e9a7e0e32407b67f56, 10040, '9780486603759', 0, 0, NULL, '2019-05-31 23:30:36'),
(0x541e9b8883eb11e9a7e0e32407b67f56, 10041, '9780486603759', 0, 0, NULL, '2019-05-31 23:30:36'),
(0x541eb92483eb11e9a7e0e32407b67f56, 10042, '9780486603759', 0, 0, NULL, '2019-05-31 23:30:36'),
(0xbd96660483eb11e9a7e0e32407b67f56, 10043, '9780134494166', 0, 0, NULL, '2019-05-31 23:33:33'),
(0xbd967f4a83eb11e9a7e0e32407b67f56, 10044, '9780134494166', 0, 1, NULL, '2019-05-31 23:33:33'),
(0x101d986683ec11e9a7e0e32407b67f56, 10045, '9780486442785', 0, 0, NULL, '2019-05-31 23:35:51'),
(0x101dc1f683ec11e9a7e0e32407b67f56, 10046, '9780486442785', 0, 0, NULL, '2019-05-31 23:35:51'),
(0x101def6e83ec11e9a7e0e32407b67f56, 10047, '9780486442785', 0, 0, NULL, '2019-05-31 23:35:51'),
(0x101e037883ec11e9a7e0e32407b67f56, 10048, '9780486442785', 0, 0, NULL, '2019-05-31 23:35:51'),
(0x105fc36683ed11e9a7e0e32407b67f56, 10053, '9780486651132', 1, 0, 'West 4/D', '2019-05-31 23:43:01'),
(0x105feb0c83ed11e9a7e0e32407b67f56, 10054, '9780486651132', 0, 0, 'West 4/D', '2019-05-31 23:43:01'),
(0x10600a6a83ed11e9a7e0e32407b67f56, 10055, '9780486651132', 0, 0, 'West 4/D', '2019-05-31 23:43:01'),
(0x10602a7283ed11e9a7e0e32407b67f56, 10056, '9780486651132', 0, 0, 'West 4/D', '2019-05-31 23:43:01'),
(0x10603ce283ed11e9a7e0e32407b67f56, 10057, '9780486651132', 0, 0, 'West 4/D', '2019-05-31 23:43:01'),
(0x1060597a83ed11e9a7e0e32407b67f56, 10058, '9780486651132', 0, 0, 'West 4/D', '2019-05-31 23:43:01'),
(0x10607b6c83ed11e9a7e0e32407b67f56, 10059, '9780486651132', 0, 0, 'West 4/D', '2019-05-31 23:43:01'),
(0x10608ff883ed11e9a7e0e32407b67f56, 10060, '9780486651132', 0, 0, 'West 4/D', '2019-05-31 23:43:01'),
(0x1060a1aa83ed11e9a7e0e32407b67f56, 10061, '9780486651132', 0, 0, 'West 4/D', '2019-05-31 23:43:01'),
(0x1060b36683ed11e9a7e0e32407b67f56, 10062, '9780486651132', 0, 0, 'West 4/D', '2019-05-31 23:43:01'),
(0xc4f8d0128a1211e9a7e0e32407b67f56, 10063, '9781592293582', 0, 1, 'South 8/E', '2019-06-08 19:28:03'),
(0xc4fa84d48a1211e9a7e0e32407b67f56, 10064, '9781592293582', 0, 0, 'South 8/E', '2019-06-08 19:28:03'),
(0xc4fb53dc8a1211e9a7e0e32407b67f56, 10065, '9781592293582', 0, 0, 'South 8/E', '2019-06-08 19:28:03'),
(0xc4fba83c8a1211e9a7e0e32407b67f56, 10066, '9781592293582', 0, 0, 'South 8/E', '2019-06-08 19:28:03'),
(0xc4fbf7d88a1211e9a7e0e32407b67f56, 10067, '9781592293582', 0, 0, 'South 8/E', '2019-06-08 19:28:03'),
(0xc4fc53228a1211e9a7e0e32407b67f56, 10068, '9781592293582', 0, 0, 'South 8/E', '2019-06-08 19:28:03'),
(0xc4fca4588a1211e9a7e0e32407b67f56, 10069, '9781592293582', 0, 0, 'South 8/E', '2019-06-08 19:28:03'),
(0xc4fcea6c8a1211e9a7e0e32407b67f56, 10070, '9781592293582', 1, 0, 'South 8/E', '2019-06-08 19:28:03'),
(0xc4fd47008a1211e9a7e0e32407b67f56, 10071, '9781592293582', 0, 0, 'South 8/E', '2019-06-08 19:28:03'),
(0xc4fd7f228a1211e9a7e0e32407b67f56, 10072, '9781592293582', 0, 0, 'South 8/E', '2019-06-08 19:28:03'),
(0x24a95ad88a4811e996069926f352bec1, 10073, '9781503262423', 0, 1, NULL, '2019-06-09 01:50:06'),
(0x24a976e48a4811e996069926f352bec1, 10074, '9781503262423', 0, 1, NULL, '2019-06-09 01:50:06'),
(0x3c4f95f88a4811e996069926f352bec1, 10075, '9780763678029', 0, 0, 'East 6/E', '2019-06-09 01:50:46'),
(0x3c4fb59c8a4811e996069926f352bec1, 10076, '9780763678029', 0, 0, 'East 6/E', '2019-06-09 01:50:46'),
(0x3c4fc9a68a4811e996069926f352bec1, 10077, '9780763678029', 0, 0, 'East 6/E', '2019-06-09 01:50:46'),
(0x3c4fdf4a8a4811e996069926f352bec1, 10078, '9780763678029', 0, 0, 'East 6/E', '2019-06-09 01:50:46'),
(0x3c4ffbec8a4811e996069926f352bec1, 10079, '9780763678029', 0, 0, 'East 6/E', '2019-06-09 01:50:46'),
(0x68c798608a4811e996069926f352bec1, 10080, '9780307949486', 0, 0, NULL, '2019-06-09 01:52:01'),
(0x68c7c52e8a4811e996069926f352bec1, 10081, '9780307949486', 0, 1, NULL, '2019-06-09 01:52:01'),
(0x68c7dd708a4811e996069926f352bec1, 10082, '9780307949486', 0, 0, NULL, '2019-06-09 01:52:01'),
(0x68c7f3b48a4811e996069926f352bec1, 10083, '9780307949486', 0, 0, NULL, '2019-06-09 01:52:01'),
(0x68c80bce8a4811e996069926f352bec1, 10084, '9780307949486', 0, 0, NULL, '2019-06-09 01:52:01'),
(0x68c824a68a4811e996069926f352bec1, 10085, '9780307949486', 0, 0, NULL, '2019-06-09 01:52:01'),
(0xba05899e8a4811e996069926f352bec1, 10087, '9780307947307', 0, 0, NULL, '2019-06-09 01:54:17'),
(0xba05a32a8a4811e996069926f352bec1, 10088, '9780307947307', 0, 0, NULL, '2019-06-09 01:54:17'),
(0xba05b6448a4811e996069926f352bec1, 10089, '9780307947307', 0, 0, NULL, '2019-06-09 01:54:17'),
(0xba05c7568a4811e996069926f352bec1, 10090, '9780307947307', 0, 1, NULL, '2019-06-09 01:54:17'),
(0xd68823e28a4811e996069926f352bec1, 10091, '9780486280486', 1, 0, 'North 6/F', '2019-06-09 01:55:05'),
(0xd68844b28a4811e996069926f352bec1, 10092, '9780486280486', 0, 0, NULL, '2019-06-09 01:55:05'),
(0xd68865be8a4811e996069926f352bec1, 10093, '9780486280486', 0, 0, NULL, '2019-06-09 01:55:05'),
(0x7390515c8a4c11e996069926f352bec1, 10094, '9781400033416', 0, 0, NULL, '2019-06-09 02:20:57'),
(0x73908df28a4c11e996069926f352bec1, 10095, '9781400033416', 0, 0, NULL, '2019-06-09 02:20:57'),
(0x7390af768a4c11e996069926f352bec1, 10096, '9781400033416', 0, 0, NULL, '2019-06-09 02:20:57'),
(0x7390d0fa8a4c11e996069926f352bec1, 10097, '9781400033416', 0, 0, NULL, '2019-06-09 02:20:57'),
(0x7390e4b48a4c11e996069926f352bec1, 10098, '9781400033416', 0, 0, NULL, '2019-06-09 02:20:57'),
(0x7390fc108a4c11e996069926f352bec1, 10099, '9781400033416', 0, 0, NULL, '2019-06-09 02:20:57'),
(0x7391102e8a4c11e996069926f352bec1, 10100, '9781400033416', 0, 0, NULL, '2019-06-09 02:20:57'),
(0x739120fa8a4c11e996069926f352bec1, 10101, '9781400033416', 0, 0, NULL, '2019-06-09 02:20:57'),
(0x739132528a4c11e996069926f352bec1, 10102, '9781400033416', 0, 0, NULL, '2019-06-09 02:20:57'),
(0x7391436e8a4c11e996069926f352bec1, 10103, '9781400033416', 0, 0, NULL, '2019-06-09 02:20:57'),
(0x84729cbe8b7811e996069926f352bec1, 10110, '9780156711425', 0, 0, NULL, '2019-06-10 14:08:54'),
(0x8472b9248b7811e996069926f352bec1, 10111, '9780156711425', 0, 0, NULL, '2019-06-10 14:08:54'),
(0x8472cb628b7811e996069926f352bec1, 10112, '9780156711425', 0, 0, NULL, '2019-06-10 14:08:54'),
(0x8472dbca8b7811e996069926f352bec1, 10113, '9780156711425', 0, 0, NULL, '2019-06-10 14:08:54'),
(0x0cbda7668b7a11e996069926f352bec1, 10114, '9780199555918', 0, 0, NULL, '2019-06-10 14:19:52'),
(0x0cbdc4768b7a11e996069926f352bec1, 10115, '9780199555918', 0, 0, NULL, '2019-06-10 14:19:52'),
(0xfbb8fe5a8bcb11e996069926f352bec1, 10116, '9783499614118', 0, 1, NULL, '2019-06-11 00:06:22'),
(0xfbb966a68bcb11e996069926f352bec1, 10117, '9783499614118', 0, 1, NULL, '2019-06-11 00:06:22'),
(0xfbb983ca8bcb11e996069926f352bec1, 10118, '9783499614118', 0, 0, NULL, '2019-06-11 00:06:22'),
(0x24652e148bcc11e996069926f352bec1, 10119, '9783126753234', 0, 0, NULL, '2019-06-11 00:07:31'),
(0x24658e9a8bcc11e996069926f352bec1, 10120, '9783126753234', 0, 0, NULL, '2019-06-11 00:07:31');

-- --------------------------------------------------------

--
-- Table structure for table `reservation`
--

CREATE TABLE `reservation` (
  `id` binary(16) NOT NULL,
  `book_id` int(10) NOT NULL,
  `pickup_code` int(10) NOT NULL,
  `user_id` int(11) NOT NULL,
  `reservation_date` date NOT NULL,
  `pickup` tinyint(4) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `reservation`
--

INSERT INTO `reservation` (`id`, `book_id`, `pickup_code`, `user_id`, `reservation_date`, `pickup`) VALUES
(0x194e5d7e8b8211e996069926f352bec1, 10111, 171880, 10010, '2019-07-25', 0),
(0x2a6058ba8bd711e996069926f352bec1, 10091, 704075, 10006, '2019-06-13', 0),
(0x4f3e2fb88b8211e996069926f352bec1, 10111, 706952, 10010, '2019-06-10', 1),
(0x501b351e87e711e9a7e0e32407b67f56, 10023, 482716, 10005, '2019-06-06', 1),
(0x60a01758852911e9a7e0e32407b67f56, 10031, 100000, 10000, '2019-07-19', 0),
(0x66fe8d5c87e311e9a7e0e32407b67f56, 10024, 310754, 10005, '2019-09-28', 0),
(0x73336c4a8bd611e996069926f352bec1, 10070, 200281, 10006, '2019-06-28', 0),
(0x77d1478287e811e9a7e0e32407b67f56, 10020, 905005, 10005, '2019-06-06', 0),
(0x8cbcdcd887e311e9a7e0e32407b67f56, 10024, 485436, 10005, '2019-05-31', 0),
(0xb8ce0c88885211e9a7e0e32407b67f56, 10023, 733214, 10005, '2019-05-22', 0),
(0xbaae338687e711e9a7e0e32407b67f56, 10022, 686221, 10005, '2019-06-05', 0),
(0xc95ace2e885211e9a7e0e32407b67f56, 10023, 459, 10005, '2019-05-27', 0),
(0xdf5cb0ac8bd611e996069926f352bec1, 10070, 27649, 10006, '2019-06-12', 0),
(0xe58c2c1c885411e9a7e0e32407b67f56, 10042, 391516, 10005, '2019-05-16', 0);

-- --------------------------------------------------------

--
-- Table structure for table `session`
--

CREATE TABLE `session` (
  `id` binary(16) NOT NULL,
  `user_id` int(10) NOT NULL,
  `created_on` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `user`
--

CREATE TABLE `user` (
  `id` int(11) NOT NULL,
  `user_type` int(11) NOT NULL,
  `firstname` varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `lastname` varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `phone` varchar(15) NOT NULL,
  `email` varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `password` varchar(100) DEFAULT NULL,
  `address_line1` varchar(200) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `address_line2` varchar(200) CHARACTER SET utf8 COLLATE utf8_general_ci DEFAULT NULL,
  `city` varchar(20) DEFAULT NULL,
  `state` varchar(20) DEFAULT NULL,
  `country` varchar(20) DEFAULT NULL,
  `pincode` int(10) DEFAULT NULL,
  `dob` date DEFAULT NULL,
  `created_on` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `user`
--

INSERT INTO `user` (`id`, `user_type`, `firstname`, `lastname`, `phone`, `email`, `password`, `address_line1`, `address_line2`, `city`, `state`, `country`, `pincode`, `dob`, `created_on`) VALUES
(10003, 2, 'Daenerys ', 'Targaryen', '7042565572', 'Priya.Kumari@stud.hochschule-heidelberg.de', NULL, 'House of Targaryen, 20115', '', 'Perth', '', 'Scotland', 169115, '1993-03-02', '2019-06-03 00:55:56'),
(10005, 2, 'Peter ', 'Parker', '17673560883', 'neerajanturkar@gmail.com', NULL, '20 Ingram Street', 'Queens', 'New York', '', 'US', 111375, '1995-12-20', '2019-06-03 00:58:58'),
(10006, 2, 'Harry', 'Potter', '15126982578', 'neerajanturkar@gmail.com', NULL, '424, Bonhoeffer Strasse 9', 'Weiblingen', 'Heidelberg', 'BW', 'Germany', 69123, '1990-12-20', '2019-06-03 01:00:33'),
(10009, 2, 'Clark', 'Kent', '9403131593', 'neerajanturkar@gmail.com', NULL, '424, Bonstrasse 9', 'Weiblingen', 'Heidelberg', 'BW', 'Germany', 69123, '1995-12-20', '2019-06-10 12:41:27'),
(10010, 1, 'Vikas', 'DT', '9403131593', 'vikas.dodera@gmail.com', NULL, '410, Abc Strasse', 'Weiblingen', 'Heidelberg', 'BW', 'Germany', 69123, '1990-06-12', '2019-06-10 13:10:06'),
(10011, 2, 'Prof. Marek', 'Sukiennik', '4915136912568', 'msukiennik@outlook.com', NULL, '101, LG Strasse', 'Weiblingen', 'Heidelberg', 'BW', 'Germany', 69123, '1970-10-20', '2019-06-10 22:29:52'),
(10012, 1, 'Ethan', 'Hunt', '15146982578', 'maumau.chrisnach@gmail.com', NULL, '424 Bonhoefferstrasse 9', '', 'Heidelberg', 'BW', 'Germany', 69123, '1994-12-20', '2019-06-10 22:55:25'),
(10013, 1, 'Sherlock', 'Holmes', '15126982571', 'neerajanturkar@gmail.com', NULL, '424, Bonhoeffer Strasse 9', '', 'Heidelberg', 'BW', 'Germany', 69123, '1990-12-20', '2019-06-10 23:18:22');

--
-- Triggers `user`
--
DELIMITER $$
CREATE TRIGGER `update_catalog_on_user_delete` BEFORE DELETE ON `user` FOR EACH ROW BEGIN
UPDATE catalog
SET is_borrowed = 0
WHERE book_id IN (SELECT book_id from borrow where user_id = old.id);

UPDATE borrow
SET actual_dor = NOW()
WHERE user_id = old.id and actual_dor is null;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `user_type`
--

CREATE TABLE `user_type` (
  `id` int(11) NOT NULL,
  `type` varchar(15) NOT NULL,
  `duration` int(10) NOT NULL,
  `times_renewable` int(10) NOT NULL,
  `max_books_allowed` int(10) NOT NULL DEFAULT '0',
  `fine` decimal(5,2) NOT NULL,
  `max_failed_reservation` int(11) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `user_type`
--

INSERT INTO `user_type` (`id`, `type`, `duration`, `times_renewable`, `max_books_allowed`, `fine`, `max_failed_reservation`) VALUES
(1, 'Student', 15, 2, 3, '0.30', 3),
(2, 'Professor', 60, 5, 10, '0.20', 5),
(3, 'Admin', 60, 5, 10, '0.10', 5);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `author`
--
ALTER TABLE `author`
  ADD PRIMARY KEY (`id`),
  ADD KEY `first_name` (`first_name`);

--
-- Indexes for table `book`
--
ALTER TABLE `book`
  ADD PRIMARY KEY (`isbn`),
  ADD KEY `type` (`type`);

--
-- Indexes for table `book_author`
--
ALTER TABLE `book_author`
  ADD PRIMARY KEY (`id`),
  ADD KEY `author_id` (`author_id`),
  ADD KEY `isbn` (`isbn`);

--
-- Indexes for table `book_type`
--
ALTER TABLE `book_type`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `book_type_id_uindex` (`id`);

--
-- Indexes for table `borrow`
--
ALTER TABLE `borrow`
  ADD KEY `book_id` (`book_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `catalog`
--
ALTER TABLE `catalog`
  ADD PRIMARY KEY (`book_id`),
  ADD KEY `isbn` (`isbn`);

--
-- Indexes for table `reservation`
--
ALTER TABLE `reservation`
  ADD PRIMARY KEY (`id`),
  ADD KEY `book_id` (`book_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `session`
--
ALTER TABLE `session`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `user`
--
ALTER TABLE `user`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `user_type`
--
ALTER TABLE `user_type`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `author`
--
ALTER TABLE `author`
  MODIFY `id` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=28;

--
-- AUTO_INCREMENT for table `book_type`
--
ALTER TABLE `book_type`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `catalog`
--
ALTER TABLE `catalog`
  MODIFY `book_id` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10121;

--
-- AUTO_INCREMENT for table `user`
--
ALTER TABLE `user`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10014;

--
-- AUTO_INCREMENT for table `user_type`
--
ALTER TABLE `user_type`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `book`
--
ALTER TABLE `book`
  ADD CONSTRAINT `book_ibfk_1` FOREIGN KEY (`type`) REFERENCES `book_type` (`id`);

--
-- Constraints for table `book_author`
--
ALTER TABLE `book_author`
  ADD CONSTRAINT `book_author_ibfk_1` FOREIGN KEY (`isbn`) REFERENCES `book` (`isbn`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `borrow`
--
ALTER TABLE `borrow`
  ADD CONSTRAINT `borrow_ibfk_1` FOREIGN KEY (`book_id`) REFERENCES `catalog` (`book_id`),
  ADD CONSTRAINT `borrow_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`);

--
-- Constraints for table `catalog`
--
ALTER TABLE `catalog`
  ADD CONSTRAINT `catalog_ibfk_1` FOREIGN KEY (`isbn`) REFERENCES `book` (`isbn`);

--
-- Constraints for table `reservation`
--
ALTER TABLE `reservation`
  ADD CONSTRAINT `reservation_ibfk_1` FOREIGN KEY (`book_id`) REFERENCES `catalog` (`book_id`),
  ADD CONSTRAINT `reservation_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`);

--
-- Constraints for table `session`
--
ALTER TABLE `session`
  ADD CONSTRAINT `session_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
