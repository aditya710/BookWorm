-- phpMyAdmin SQL Dump
-- version 4.8.3
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: May 28, 2019 at 10:19 AM
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
CREATE DEFINER=`root`@`localhost` PROCEDURE `add_book` (IN `type` INT(11), IN `title` VARCHAR(50), IN `subtitle` VARCHAR(50), IN `publication` VARCHAR(20), IN `description` VARCHAR(200), IN `published_date` VARCHAR(10), IN `page_count` INT(11), IN `lang` VARCHAR(2), IN `thumbnail` VARCHAR(255), IN `isbn_no` VARCHAR(13), IN `cnt` INT(10), IN `e_authors` VARCHAR(100), IN `n_authors` VARCHAR(100))  BEGIN
	DECLARE x INT DEFAULT 0; 
    DECLARE y INT DEFAULT 0; 
    SET y = 1; 

	SELECT COUNT(*) FROM book
    WHERE isbn = isbn_no
    INTO @if_exist;
    
    IF @if_exist = 0 THEN
        INSERT INTO `book` (`id`, `type` ,`title`,`subtitle`,`publication`,`description`,`published_date`,`page_count`,`language`,`thumbnail`,`isbn`) 
            VALUES (UUID_TO_BIN(UUID()), type , title, subtitle,publication, description, published_date,page_count,lang,thumbnail,isbn);
	END IF;	

	WHILE cnt > 0 DO
    	INSERT INTO `catalog` (`id`,`isbn`)
        	VALUES ( UUID_TO_BIN(UUID()) , isbn);
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

                     INSERT INTO book_author(`id`,`isbn`,`author_id`) VALUES(UUID_TO_BIN(UUID()),isbn,@authorId);
                ELSE 
                    SET x = @noOfCommas + 1; 
                    WHILE y  <=  x DO 
                       SELECT split_string(e_authors, ',', y) INTO @author; 
                       SELECT split_string(@author,' ',1) into @firstname;
                       SELECT split_string(@author,' ',2) into @lastname;
					   SELECT get_author_id(@firstname,@lastname) INTO @authorId;
                       INSERT INTO book_author(`id`,`isbn`,`author_id`) VALUES(UUID_TO_BIN(UUID()),isbn,@authorId);
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
					
                     INSERT INTO book_author(`id`,`isbn`,`author_id`) VALUES(UUID_TO_BIN(UUID()),isbn,@authorId);
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
					
                     INSERT INTO book_author(`id`,`isbn`,`author_id`) VALUES(UUID_TO_BIN(UUID()),isbn,@authorId);
                     END IF;
                       SET  y = y + 1; 
                    END WHILE; 
            END IF; 
       END IF;
    END IF; 
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `add_user` (IN `type` INT(11), IN `firstname` VARCHAR(20), IN `lastname` VARCHAR(20), IN `phone` VARCHAR(15), IN `email` VARCHAR(25), IN `address_line1` VARCHAR(30), IN `address_line2` VARCHAR(30), IN `city` VARCHAR(20), IN `state` VARCHAR(20), IN `country` VARCHAR(20), IN `pincode` INT(10), IN `dob` DATE)  NO SQL
INSERT INTO user (`user_type`,`firstname`,`lastname`,`phone`,`email`,`address_line1`,
        `address_line2`,`city`,`state`,`country`,`pincode`,`dob`)
 VALUES (type , firstname , lastname , phone , email , address_line1 , address_line2 , city , state , country , pincode ,dob )$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `borrow_book` (IN `bookid` INT(10), IN `userid` INT(11), IN `doi` DATE, IN `dor` DATE, OUT `success` TINYINT)  NO SQL
BEGIN

	SELECT check_user_borrow(userid) into @is_allowed;
    SET success = 0;
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
            END IF;
        ELSE
        	SET success = 0;
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `renew_book` (IN `bookid` INT(11), IN `userid` INT(10), OUT `success` TINYINT)  NO SQL
BEGIN

SELECT check_user_renew(userid,bookid) INTO @is_renew_allowed;

IF @is_renew_allowed = 1 THEN 
	SELECT dor 
    INTO @returndate
    FROM borrow
    WHERE book_id = bookid and user_id = userid;
    
    SELECT get_date_of_return(@returndate,userid) into @newReturnDate;
    
	UPDATE borrow
    SET times_renewed = times_renewed + 1 , dor = @newReturnDate
    WHERE book_id = bookid and user_id = userid;
    
    SELECT row_count() INTO @affectedRows;
    
    IF @affectedRows = 1 THEN
    	
    	SET success = 1;
    ELSE 
    	SET success = 0;
    END IF;
ELSE
	SET success = 0;
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `reserve_book` (IN `bookid` INT(10), IN `userid` INT(11), IN `do_res` DATE, OUT `success` TINYINT, OUT `user_email` VARCHAR(25), OUT `book_title` VARCHAR(50))  NO SQL
BEGIN

SELECT check_book_is_available(bookid,do_res) INTO @isAvailable;

IF @isAvailable = 1 THEN

	INSERT INTO `reservation`(`id`, `book_id`, `user_id`, `reservation_date`) VALUES (UUID_TO_BIN(UUID()),bookid,userid,do_res);
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
    
    	SET success = 1;
    ELSE 
    	SET success = 0;
    END IF;
ELSE

	SET success = 0;

END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `return_book` (IN `bookid` INT(10), IN `userid` INT(11), IN `actual_return` DATE, OUT `success` TINYINT, OUT `fine` DECIMAL(10,2))  NO SQL
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

CREATE DEFINER=`root`@`localhost` FUNCTION `check_user_borrow` (`user_id` INT(11)) RETURNS TINYINT(4) NO SQL
BEGIN

SELECT max_books_allowed 
INTO @max_limit
FROM user_type
WHERE id = (SELECT user_type FROM user WHERE id = user_id);

SELECT COUNT(*)
INTO @total_borrowed
FROM borrow
WHERE user_id = user_id AND actual_dor is null;

IF @total_borrowed < @max_limit THEN
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

SELECT times_renewed
INTO @times_renewed
FROM borrow 
WHERE book_id = bookid and user_id = userid;

IF @times_renewable > @times_renewed THEN
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
(1, 'Neeraj', 'Anturkar', NULL),
(2, 'Aditi', 'Goyal', NULL),
(4, 'Pari', 'Katke', NULL),
(9, 'Parth', 'Soni', NULL),
(10, 'Vinayak', 'Bhalerao', NULL),
(11, 'Pranav', 'Wankawala', NULL),
(12, 'Reinhold', 'Plota', NULL),
(13, 'Waldemar', 'Fix', NULL),
(14, 'E.', 'Keppler', NULL),
(15, 'Williams', '', NULL),
(16, 'Kathryn', 'K.', NULL),
(17, 'Heinz', 'Forsthuber', NULL),
(18, 'Jörg', 'Siebert', NULL),
(19, 'Renata', 'Munzel', NULL),
(20, 'Martin', 'Munzel', NULL),
(21, 'Jörg', 'Thomas', NULL),
(22, 'Gerhard', 'Keller', NULL),
(23, 'Sunil', 'Chopra', NULL),
(24, 'Peter', 'Meindl', NULL),
(25, 'Bernd', 'Britzelmaier', NULL),
(26, 'Thomas', 'Hutzschenreuter', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `book`
--

CREATE TABLE `book` (
  `id` binary(16) NOT NULL,
  `type` int(11) NOT NULL,
  `title` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `isbn` varchar(13) NOT NULL,
  `subtitle` varchar(50) DEFAULT NULL,
  `publication` varchar(20) DEFAULT NULL,
  `description` varchar(200) CHARACTER SET utf8 COLLATE utf8_general_ci DEFAULT NULL,
  `published_date` varchar(10) CHARACTER SET utf8 COLLATE utf8_general_ci DEFAULT NULL,
  `page_count` int(11) DEFAULT NULL,
  `language` varchar(2) DEFAULT NULL,
  `thumbnail` varchar(255) DEFAULT NULL,
  `created_on` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `book`
--

INSERT INTO `book` (`id`, `type`, `title`, `isbn`, `subtitle`, `publication`, `description`, `published_date`, `page_count`, `language`, `thumbnail`, `created_on`) VALUES
(0xf32bf4d07e0711e98df9744a1796ab97, 1, 'Implementing Sap Erp Sales ', '9780070264847', '', 'Mc Graw Hill', 'This long-anticipated revision to the author s Implementing SAP R/3 Sales ', '', 513, 'en', '', '2019-05-24 09:40:22'),
(0x3e5da7447d0b11e9ab5703a01aa2df79, 1, 'Plant Maintenance with SAP', '9781493214846', 'Business User Guide', 'SAP Press', '', '', 455, 'EN', 'https://sappress.com/s4hana', '2019-05-23 03:31:25'),
(0xde64490a7d0b11e9ab5703a01aa2df79, 1, 'SAP C/4 HANA', '9781493214847', 'Business User Guide', 'SAP Press', '', '', 455, 'EN', 'https://sappress.com/s4hana', '2019-05-23 03:35:54'),
(0xc53424de7e0811e98df9744a1796ab97, 1, 'Meditation Für Anfänger', '9781980879718', 'Eine Schritt-Für-Schritt-Anleitung,', 'ABC Publication', 'Achtung! Nur bis zum 18. Mai 2018 gibt es jetzt das Taschenbuch zum Einführungspreis für nur 4,39 e statt 14,90 e. Verdammt - schon wieder unzählige E-Mails, dutzende Sachen auf der', '', 147, 'de', '', '2019-05-24 09:46:14'),
(0xf0c4a64e7d9c11e98df9744a1796ab97, 2, 'Liebe, Freiheit, Alleinsein', '9783442215997', '', 'Abc Pub', '', '', 348, 'en', '', '2019-05-23 20:54:21'),
(0x354776ba7e0c11e98df9744a1796ab97, 2, 'Allgemeine Betriebswirtschaftslehre', '9783658172268', 'Grundlagen mit zahlreichen Praxisbeispielen', 'SAP Press', '', '', 497, 'de', '', '2019-05-24 10:10:51'),
(0xa4ee2fba7e0a11e98df9744a1796ab97, 2, 'Produktionsplanung und -steuerung mit SAP ERP', '9783836227087', 'NEW NEW', 'NEW NEW', '', '', 539, 'en', '', '2019-05-24 09:59:39'),
(0x4226c5867e0a11e98df9744a1796ab97, 1, 'SAP-Finanzwesen - Customizing', '9783836239707', '', 'SAP Press', '', '', 608, 'en', '', '2019-05-24 09:56:53'),
(0xa1e4e60c7e0911e98df9744a1796ab97, 1, 'Praxishandbuch SAP-Finanzwesen', '9783836239905', '', 'SAP PRESS', '', '', 653, 'de', '', '2019-05-24 09:52:24'),
(0x7441edac7d9c11e98df9744a1796ab97, 1, 'SAP-Materialwirtschaft', '9783836244190', 'Disposition mit SAP MM', 'SAP Press', '', '', 777, 'en', '', '2019-05-23 20:50:53'),
(0xd284080c7e0311e98df9744a1796ab97, 1, 'SAP - Der technische Einstieg', '9783836266673', 'SAP GUI, ABAP, SAP HANA und vieles mehr', 'asda', '', '', 499, 'de', '', '2019-05-24 09:10:49'),
(0xfea9fd367e0a11e98df9744a1796ab97, 1, 'Supply Chain Management', '9783868941883', 'Strategie, Planung und Umsetzung', 'SAP Press', '', '', 629, 'en', '', '2019-05-24 10:02:09'),
(0xdd9f3b1e7e0b11e98df9744a1796ab97, 1, 'Controlling', '9783868942965', 'Grundlagen - Praxis - Umsetzung', 'SAP Press', 'Wer als Fach- oder Führungskraft in Unternehmen tätig ist, kommt heute ohne solide Grundkenntnisse des Controllings nicht aus. ', '', 432, 'de', '', '2019-05-24 10:08:23'),
(0x9ab7de3c7e0611e98df9744a1796ab97, 2, 'Über die Eigenschaften von Zählrohren ', '9783943544619', 'Zur Interpretation von Röntgenstrahlungsmessungen', 'sdasdas', '', '', 90, 'de', '', '2019-05-24 09:30:44');

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
(0x3548e8067e0c11e98df9744a1796ab97, '9783658172268', 26),
(0x3e63656c7d0b11e9ab5703a01aa2df79, '9781493214846', 1),
(0x42373c227e0a11e98df9744a1796ab97, '9783836239707', 19),
(0x423781507e0a11e98df9744a1796ab97, '9783836239707', 20),
(0x9abb16247e0611e98df9744a1796ab97, '9783943544619', 14),
(0xa1e7bcc47e0911e98df9744a1796ab97, '9783836239905', 15),
(0xa1e8f5e47e0911e98df9744a1796ab97, '9783836239905', 17),
(0xa1ead18e7e0911e98df9744a1796ab97, '9783836239905', 18),
(0xa4f764727e0a11e98df9744a1796ab97, '9783836227087', 21),
(0xa4f815347e0a11e98df9744a1796ab97, '9783836227087', 22),
(0xc537945c7e0811e98df9744a1796ab97, '9781980879718', 16),
(0xd293a0fa7e0311e98df9744a1796ab97, '9783836266673', 12),
(0xd29401307e0311e98df9744a1796ab97, '9783836266673', 13),
(0xdda702727e0b11e98df9744a1796ab97, '9783868942965', 25),
(0xde725a687d0b11e9ab5703a01aa2df79, '9781493214847', 9),
(0xde7292e47d0b11e9ab5703a01aa2df79, '9781493214847', 10),
(0xf33a91de7e0711e98df9744a1796ab97, '9780070264847', 15),
(0xfeab1a227e0a11e98df9744a1796ab97, '9783868941883', 23),
(0xfeab5f787e0a11e98df9744a1796ab97, '9783868941883', 24);

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
(0x434012cc7e6111e98df9744a1796ab97, 1, 10000, '2019-05-19', '2019-05-22', '2019-05-24', 0, '0.60', 0, '2019-05-27 10:53:23'),
(0x688a62047e6511e98df9744a1796ab97, 2, 10000, '2019-05-28', '2019-05-31', NULL, 0, '0.00', 0, '2019-05-27 10:53:23'),
(0xb62672647e6511e98df9744a1796ab97, 30, 10000, '2019-05-27', '2019-05-30', NULL, 0, '0.00', 0, '2019-05-27 10:53:23'),
(0x4ada5ed47f5611e98df9744a1796ab97, 12, 10000, '2019-05-26', '2019-06-25', '2019-05-26', 1, '0.00', 0, '2019-05-27 10:53:23'),
(0x6cd2db827f5711e98df9744a1796ab97, 24, 10000, '2019-05-26', '2019-06-10', NULL, 0, '0.00', 0, '2019-05-27 10:53:23'),
(0x81ccd5fa7f5811e98df9744a1796ab97, 19, 10002, '2019-05-19', '2019-05-23', '2019-05-26', 0, '0.60', 0, '2019-05-27 10:53:23'),
(0xdd46f9967f5911e98df9744a1796ab97, 15, 10002, '2019-05-01', '2019-05-15', NULL, 0, '0.00', 0, '2019-05-27 10:53:23'),
(0xf0854b82813111e988711c6298d35a47, 9, 10004, '2019-05-26', '2019-05-31', NULL, 0, '0.00', 0, '2019-05-28 12:18:30');

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
(0x3e6278be7d0b11e9ab5703a01aa2df79, 1, '9781493214846', 0, 0, NULL, '2019-05-26 07:06:20'),
(0x3e6298e47d0b11e9ab5703a01aa2df79, 2, '9781493214846', 0, 1, NULL, '2019-05-26 07:06:20'),
(0x3e62d2967d0b11e9ab5703a01aa2df79, 3, '9781493214846', 0, 0, NULL, '2019-05-26 07:06:20'),
(0x3e62e2ae7d0b11e9ab5703a01aa2df79, 4, '9781493214846', 0, 0, NULL, '2019-05-26 07:06:20'),
(0x53f7e0f67d0b11e9ab5703a01aa2df79, 5, '9781493214846', 0, 0, NULL, '2019-05-26 07:06:20'),
(0x53fead507d0b11e9ab5703a01aa2df79, 6, '9781493214846', 0, 0, NULL, '2019-05-26 07:06:20'),
(0x53fed2da7d0b11e9ab5703a01aa2df79, 7, '9781493214846', 0, 0, NULL, '2019-05-26 07:06:20'),
(0x53feecfc7d0b11e9ab5703a01aa2df79, 8, '9781493214846', 0, 0, NULL, '2019-05-26 07:06:20'),
(0xde71ba9a7d0b11e9ab5703a01aa2df79, 9, '9781493214847', 0, 1, NULL, '2019-05-26 07:06:20'),
(0xde71efce7d0b11e9ab5703a01aa2df79, 10, '9781493214847', 0, 0, NULL, '2019-05-26 07:06:20'),
(0x7448f0b67d9c11e98df9744a1796ab97, 11, '9783836244190', 0, 0, NULL, '2019-05-26 07:06:20'),
(0xf0c9705c7d9c11e98df9744a1796ab97, 12, '9783442215997', 0, 0, NULL, '2019-05-26 07:06:20'),
(0xd2928e4a7e0311e98df9744a1796ab97, 13, '9783836266673', 0, 0, NULL, '2019-05-26 07:06:20'),
(0xd292b0b47e0311e98df9744a1796ab97, 14, '9783836266673', 0, 0, NULL, '2019-05-26 07:06:20'),
(0xd292bfe67e0311e98df9744a1796ab97, 15, '9783836266673', 0, 1, NULL, '2019-05-26 07:06:20'),
(0xd292e85e7e0311e98df9744a1796ab97, 16, '9783836266673', 0, 0, NULL, '2019-05-26 07:06:20'),
(0xd292f4de7e0311e98df9744a1796ab97, 17, '9783836266673', 0, 0, NULL, '2019-05-26 07:06:20'),
(0x9aba9fbe7e0611e98df9744a1796ab97, 18, '9783943544619', 0, 0, NULL, '2019-05-26 07:06:20'),
(0x9abac4c67e0611e98df9744a1796ab97, 19, '9783943544619', 0, 0, NULL, '2019-05-26 07:06:20'),
(0x9abacfca7e0611e98df9744a1796ab97, 20, '9783943544619', 0, 0, NULL, '2019-05-26 07:06:20'),
(0xf33a37347e0711e98df9744a1796ab97, 21, '9780070264847', 0, 0, NULL, '2019-05-26 07:06:20'),
(0xc5370abe7e0811e98df9744a1796ab97, 22, '9781980879718', 0, 0, NULL, '2019-05-26 07:06:20'),
(0xe01dca667e0811e98df9744a1796ab97, 23, '9781980879718', 0, 0, NULL, '2019-05-26 07:06:20'),
(0xa1e743487e0911e98df9744a1796ab97, 24, '9783836239905', 0, 1, NULL, '2019-05-26 07:06:20'),
(0xa9521ff47e0911e98df9744a1796ab97, 25, '9783836239905', 0, 0, NULL, '2019-05-26 07:06:20'),
(0xb3751f7c7e0911e98df9744a1796ab97, 26, '9783836239905', 0, 0, NULL, '2019-05-26 07:06:20'),
(0x423695c47e0a11e98df9744a1796ab97, 27, '9783836239707', 0, 0, NULL, '2019-05-26 07:06:20'),
(0xa4f571d07e0a11e98df9744a1796ab97, 28, '9783836227087', 0, 0, NULL, '2019-05-26 07:06:20'),
(0xfeaab0dc7e0a11e98df9744a1796ab97, 29, '9783868941883', 0, 0, NULL, '2019-05-26 07:06:20'),
(0xdda6ab887e0b11e98df9744a1796ab97, 30, '9783868942965', 0, 1, NULL, '2019-05-26 07:06:20'),
(0x35487b0a7e0c11e98df9744a1796ab97, 31, '9783658172268', 0, 0, NULL, '2019-05-26 07:06:20');

-- --------------------------------------------------------

--
-- Table structure for table `reservation`
--

CREATE TABLE `reservation` (
  `id` binary(16) NOT NULL,
  `book_id` int(10) NOT NULL,
  `user_id` int(11) NOT NULL,
  `reservation_date` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `reservation`
--

INSERT INTO `reservation` (`id`, `book_id`, `user_id`, `reservation_date`) VALUES
(0x00ffc60e7f4d11e98df9744a1796ab97, 23, 10000, '2019-05-28'),
(0x0e5b17fe7f4311e98df9744a1796ab97, 20, 10000, '2019-05-27'),
(0x148b78c67f4811e98df9744a1796ab97, 25, 10000, '2019-05-27'),
(0x18d6091e7f5211e98df9744a1796ab97, 28, 10000, '2019-05-28'),
(0x1df713c07f4811e98df9744a1796ab97, 26, 10000, '2019-05-27'),
(0x25f395bc7f4811e98df9744a1796ab97, 27, 10000, '2019-05-27'),
(0x28d63cfc7f4911e98df9744a1796ab97, 11, 10000, '2019-05-28'),
(0x2d5df9d07f4a11e98df9744a1796ab97, 15, 10000, '2019-05-28'),
(0x2e8b963e7f4811e98df9744a1796ab97, 28, 10000, '2019-05-27'),
(0x307cf5247f4711e98df9744a1796ab97, 22, 10000, '2019-05-27'),
(0x3eb9db0e7f3b11e98df9744a1796ab97, 1, 10000, '2019-05-27'),
(0x4a8786667f4a11e98df9744a1796ab97, 16, 10000, '2019-05-28'),
(0x4e48de0e7f4911e98df9744a1796ab97, 12, 10000, '2019-05-28'),
(0x4fc66c847f4d11e98df9744a1796ab97, 24, 10000, '2019-05-28'),
(0x5dbcc6047f4711e98df9744a1796ab97, 23, 10000, '2019-05-27'),
(0x62c010ae7f4a11e98df9744a1796ab97, 17, 10000, '2019-05-28'),
(0x71b6c18c7f4211e98df9744a1796ab97, 14, 10000, '2019-05-27'),
(0x77fc39a07f4711e98df9744a1796ab97, 24, 10000, '2019-05-27'),
(0x7a676c2c7f4d11e98df9744a1796ab97, 25, 10000, '2019-05-28'),
(0x865626167f4011e98df9744a1796ab97, 3, 10001, '2019-05-27'),
(0x8d39b4e87f4a11e98df9744a1796ab97, 18, 10000, '2019-05-28'),
(0x8f170ec07f4d11e98df9744a1796ab97, 26, 10000, '2019-05-28'),
(0x8f25d6407f4211e98df9744a1796ab97, 15, 10000, '2019-05-27'),
(0x90c4056a7f4911e98df9744a1796ab97, 13, 10000, '2019-05-28'),
(0x9f9b13787f4211e98df9744a1796ab97, 16, 10000, '2019-05-27'),
(0xb91bd0307f4c11e98df9744a1796ab97, 21, 10000, '2019-05-28'),
(0xbc93715e7f4811e98df9744a1796ab97, 29, 10000, '2019-05-27'),
(0xc42b7bb07f4c11e98df9744a1796ab97, 22, 10000, '2019-05-28'),
(0xd2a638f67f4211e98df9744a1796ab97, 17, 10000, '2019-05-27'),
(0xde1bedb27f4611e98df9744a1796ab97, 21, 10000, '2019-05-27'),
(0xde9ecec27f4a11e98df9744a1796ab97, 19, 10000, '2019-05-28'),
(0xe23932227f4811e98df9744a1796ab97, 10, 10000, '2019-05-28'),
(0xe8e755967f4211e98df9744a1796ab97, 18, 10000, '2019-05-27'),
(0xf3bf992a7f5011e98df9744a1796ab97, 27, 10000, '2019-05-28'),
(0xf5fb08227f4211e98df9744a1796ab97, 19, 10000, '2019-05-27'),
(0xf7ef95827f4a11e98df9744a1796ab97, 20, 10000, '2019-05-28'),
(0xfebe51ec7f4911e98df9744a1796ab97, 14, 10000, '2019-05-28');

-- --------------------------------------------------------

--
-- Table structure for table `session`
--

CREATE TABLE `session` (
  `id` binary(16) NOT NULL,
  `user_id` int(10) NOT NULL,
  `created_on` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `session`
--

INSERT INTO `session` (`id`, `user_id`, `created_on`) VALUES
(0x1b3ec800806811e988711c6298d35a47, 10004, '2019-05-27 12:13:43'),
(0x36e552e6806711e988711c6298d35a47, 10004, '2019-05-27 12:07:20'),
(0x3cd3ee0e806411e988711c6298d35a47, 10004, '2019-05-27 11:46:01'),
(0x56df8508806711e988711c6298d35a47, 10004, '2019-05-27 12:08:13'),
(0x5780131e806811e988711c6298d35a47, 10004, '2019-05-27 12:15:24'),
(0x85387170806811e988711c6298d35a47, 10004, '2019-05-27 12:16:41'),
(0x87bb5ea4806711e988711c6298d35a47, 10004, '2019-05-27 12:09:35'),
(0x883db396806611e988711c6298d35a47, 10004, '2019-05-27 12:02:27'),
(0x97085438806811e988711c6298d35a47, 10004, '2019-05-27 12:17:11'),
(0xa9746f10806511e988711c6298d35a47, 10004, '2019-05-27 11:56:13'),
(0xb3a7c694806511e988711c6298d35a47, 10004, '2019-05-27 11:56:30'),
(0xb8f0eb3a806511e988711c6298d35a47, 10004, '2019-05-27 11:56:39'),
(0xc32a8cc6806711e988711c6298d35a47, 10004, '2019-05-27 12:11:15'),
(0xf87c2fca806611e988711c6298d35a47, 10004, '2019-05-27 12:05:35'),
(0xfb8760a4806111e988711c6298d35a47, 10004, '2019-05-27 11:29:53');

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
  `email` varchar(25) NOT NULL,
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
(10000, 1, 'Neeraj', 'Anturkar', '9403131593', 'neerajanturkar@gmail.com', NULL, '424, Bonhoeffer Strasse 9', 'Weiblingen', 'Heidelberg', 'BW', 'Germany', NULL, '1995-12-20', '2019-05-18 03:19:25'),
(10001, 1, 'Abc', 'Pqr', '8793404781', 'neeraj@kisan.net', NULL, '22, Admiral Soman Path,', ' Girija Society', 'PUNE', 'Maharashtra', 'India', NULL, '1995-12-20', '2019-05-18 03:30:17'),
(10002, 2, 'MyFirstName', 'MyLastName', 'MyPhone', 'MyEmail', NULL, 'MyAddressLine1', 'MyAddressLine2', 'MyCity', 'MyState', 'MyCountry', NULL, '1968-12-15', '2019-05-18 03:50:44'),
(10003, 1, 'afas', 'asda', '9403131593', 'nsa@mailinator', NULL, 'Girija Society', 'Rambaug Colony', 'PUNE', 'BW', 'India', 411038, '1990-12-12', '2019-05-26 21:32:09'),
(10004, 3, 'Aditya', 'Shelar', '4917147822632', 'adityashelar77@gmail.com', 'a9b3096aab7e53e15df76b0432d451a6', '121, Bonhoeffer Strasse 13', '', 'Heidelberg', 'BW', 'Germany', 69123, '1994-01-10', '2019-05-27 09:10:42');

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
  `fine` decimal(5,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `user_type`
--

INSERT INTO `user_type` (`id`, `type`, `duration`, `times_renewable`, `max_books_allowed`, `fine`) VALUES
(1, 'student', 15, 2, 3, '0.30'),
(2, 'teacher', 60, 5, 10, '0.20'),
(3, 'admin', 60, 5, 10, '0.10');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `author`
--
ALTER TABLE `author`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `book`
--
ALTER TABLE `book`
  ADD PRIMARY KEY (`isbn`),
  ADD UNIQUE KEY `id` (`id`),
  ADD KEY `name_index` (`title`),
  ADD KEY `book_ibfk_1` (`type`);

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
  MODIFY `id` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=27;

--
-- AUTO_INCREMENT for table `book_type`
--
ALTER TABLE `book_type`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `catalog`
--
ALTER TABLE `catalog`
  MODIFY `book_id` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=32;

--
-- AUTO_INCREMENT for table `user`
--
ALTER TABLE `user`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10005;

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
  ADD CONSTRAINT `book_ibfk_1` FOREIGN KEY (`type`) REFERENCES `book_type` (`id`) ON DELETE CASCADE;

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
