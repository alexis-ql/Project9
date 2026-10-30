/* ==========================================================================
   club_db_starter.sql
   CIS 4720 Database Management and SQL
   Project 9

   WHAT THIS FILE IS
   Your starter for Project 9. It builds a schema called club_db with one
   table in it, member, already filled in. Everything else is yours to write
   under the headings further down.

   WHY MEMBER IS GIVEN TO YOU
   Read its CREATE TABLE statement before you start. It is a worked example
   of the two things this project is about: a surrogate key, and a starting
   value for that key. You build payment and payment_log the same way.

   BEFORE YOU RUN IT
   Connect SQLTools to information_schema first, the same as Lab 5d and
   Lab 5e. The first two statements in this file create club_db and switch
   you into it. Step 1 walks through it.

   HOW TO RUN IT
   One statement at a time. Put the cursor on it and press Ctrl + E twice.
   The function and the triggers you write later are each a single statement
   from CREATE down to END, so select the whole block and run the selection.

   LABELING AND COMMENTING IS REQUIRED
   Above every statement you write, put a short comment in your own words
   saying what it does. The comments are graded.
   ========================================================================== */


-- =================================================================
-- SETUP. Run these three first, one at a time, while you are still
-- connected to information_schema.
-- =================================================================

-- every schema on this server. club_db will not be in the list yet.
show databases;

-- make yours. IF NOT EXISTS means it is safe to run twice.
create database if not exists club_db;

-- switch into it, so everything below lands in the right place.
use club_db;


-- ======================================================================
-- GIVEN TO YOU. The member table.
--
-- member_id is a surrogate key: a number the database invents so that
-- every row can be told apart. Nobody is born with one.
--
-- AUTO_INCREMENT = 100 after the closing bracket is what makes the first
-- member 100 instead of 1. Club membership numbers start at 100 because
-- that is how the club has always done it, which is the usual reason.
-- ======================================================================

CREATE TABLE member (
    member_id  INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(30) NOT NULL,
    last_name  VARCHAR(30) NOT NULL,
    joined_on  DATE,
    total_paid DECIMAL(7,2) DEFAULT 0.00
) AUTO_INCREMENT = 100;

INSERT INTO member (first_name, last_name, joined_on) VALUES ('Noor',   'Haddad',   '2026-01-15');
INSERT INTO member (first_name, last_name, joined_on) VALUES ('Caleb',  'Ortiz',    '2026-02-03');
INSERT INTO member (first_name, last_name, joined_on) VALUES ('Sofia',  'Marchetti','2026-02-28');
INSERT INTO member (first_name, last_name, joined_on) VALUES ('Desmond','Blake',    '2026-03-11');


-- ======================================================================
-- CHECK. Four members, numbered 100 to 103, every total_paid at 0.00.
-- ======================================================================

SELECT * FROM member;


-- ######################################################################
-- YOUR PROJECT 9 WORK STARTS BELOW THIS LINE
--
-- LABELING AND COMMENTING IS REQUIRED. It is worth a full point.
--
-- You write the SQL for Steps 2, 3, 4 and 9 yourself.
--
-- Steps 5, 6, 7 and 8 are in the handout with the skeleton complete and
-- ONE statement removed from each. Copy the skeleton in, then write the
-- missing statement yourself. The handout walks you through each one a
-- line at a time.
-- ######################################################################


-- =================================================================
-- STEP 2. Create the payment table, key starting at 5000
-- =================================================================

-- the PAYMENT table is created with 5 columns,
-- payment_id is the primary key and auto incremented,
-- member_id is a foreign key referencing member_id in the MEMBER table
-- The counter is set to start at 5000

CREATE TABLE IF NOT EXISTS payment (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT NOT NULL,
    amount DECIMAL(7,2) NOT NULL,
    paid_on DATE,
    method VARCHAR(10),
    FOREIGN KEY (member_id) REFERENCES MEMBER(member_id)

) AUTO_INCREMENT = 5000;

DESCRIBE payment;


-- =================================================================
-- STEP 3. Create the payment_log table
-- =================================================================

-- the PAYMENT payment_log is created with 5 columns,
-- log_id is the primary key and auto incremented,
-- The counter starts at 1

CREATE TABLE IF NOT EXISTS payment_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT,
    amount DECIMAL(7,2),
    action VARCHAR(20),
    logged_on DATETIME

) AUTO_INCREMENT = 1;


DESCRIBE payment_log;

-- =================================================================
-- STEP 4. Check your two counters before anything is inserted
-- =================================================================

-- The counters of the MEMBER, PAYMENT, and PAYMENT_LOG tables are checked
-- MEMBER displays a counter of 104 due to the counter starting at 100 + 4 new records
-- PAYMENT displays a counter of 5000, its declared starting value
-- PAYMENT_LOG displays a counter of 1, its declared starting value

SELECT table_name, auto_increment
FROM information_schema.tables
WHERE table_schema = 'club_db';


-- =================================================================
-- STEP 5. Create the member_total function
--
-- Copy the skeleton from the handout, then write the SELECT that goes in
-- the gap. One statement from CREATE FUNCTION down to END, so select the
-- whole block and run the selection.
-- =================================================================

-- A function is declared
-- The function sums all the amounts beloning to p_member_id (a member)
-- If a member's payments sum up to NULL, the function returns instead 0.00

-- adds up one member's payments and hands back the total
CREATE FUNCTION member_total(p_member_id INT)
-- money, so two decimal places
RETURNS DECIMAL(7,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    -- somewhere to hold the answer while we work it out
    DECLARE v_total DECIMAL(7,2);
    -- add up just this member's rows
        SELECT SUM(amount)
        INTO v_total
        FROM payment
        WHERE member_id = p_member_id;
    -- a member with no payments sums to NULL, so turn that into 0.00
RETURN IFNULL(v_total, 0.00);
END


-- =================================================================
-- STEP 6. A BEFORE INSERT trigger that fills in what was left out
-- =================================================================

-- The trigger "trg_payment_before_insert" is created
-- The trigger runs before a new row is inserted in the PAYMENT table
-- It runs once for every row inserted.
-- The trigger contains two actions:
    -- (1) If paid_on is NULL, the current date is inserted
    -- (2) The payment method is set to uppercase letters


-- runs while the row is still on its way in, so it can change it
CREATE TRIGGER trg_payment_before_insert
BEFORE INSERT ON payment
FOR EACH ROW
BEGIN
    -- no date given, so record it as paid today
    IF NEW.paid_on IS NULL then
        SET NEW.paid_on = CURDATE();
    END IF;

    -- store the method in capitals whatever case it arrived in
SET NEW.method = UPPER(NEW.method);
END


-- =================================================================
-- STEP 7. An AFTER INSERT trigger that updates and logs
-- =================================================================

-- The trigger "trg_payment_after_insert" is created
-- The trigger runs after a new row is inserted in the PAYMENT table
-- It runs once for every row inserted.
-- The trigger contains 2 actions:
    -- (1) The total_paid value is updated to the value returned by the member_total() function
        -- NEW.member_id refers to the member_id of the newly inserted record
        -- THE WHERE clause makes sure that only that member's record is updated

    -- (2) A record is inserted into the PAYMENT_LOG table, recording a new payment.


-- fires once a payment row has landed
CREATE TRIGGER trg_payment_after_insert
AFTER INSERT ON payment
FOR EACH ROW
BEGIN
    -- job one: bring that member's total up to date
    UPDATE member -- refers to the MEMBER table
    SET total_paid = member_total(NEW.member_id)
    WHERE member_id = NEW.member_id;
    -- job two: write a line in the log saying what happened
    INSERT INTO payment_log (member_id, amount, action, logged_on)
    VALUES (new.member_id, NEW.amount, 'ADDED', NOW());
END

-- =================================================================
-- STEP 8. An AFTER DELETE trigger that does the same in reverse
-- =================================================================

-- The trigger "trg_payment_after_delete" is created
-- The trigger runs after a new row is deleted from the PAYMENT table
-- It runs once for every row deleted.
-- The trigger contains 2 actions:
    -- (1) The total_paid value is updated to the value returned by the member_total() function
        -- OLD.member_id refers to the member_id of the deleted record
        --THE WHERE clause makes sure that only that member's record is updated

    -- (2) A record is inserted into the PAYMENT_LOG table, recording a deleted payment.

-- fires once a payment row has gone
CREATE TRIGGER trg_payment_after_delete
AFTER DELETE ON payment
FOR EACH ROW
BEGIN
    -- OLD, not NEW, because the row that matters is the one
    -- that was just removed. a deleted row has no NEW
    UPDATE member -- refers to the MEMBER table
    SET total_paid = member_total(OLD.member_id)
    WHERE member_id = OLD.member_id;
    -- and the log says RMEOVED this time
    INSERT INTO payment_log (member_id, amount, action, logged_on)
    VALUES (OLD.member_id, OLD.amount, 'REMOVED', NOW());
END



-- =================================================================
-- STEP 9. Add four payments, then remove one, and watch it all happen
-- =================================================================

-- 4 records are inserted in the PAYMENT table

INSERT INTO payment (member_id, amount, method) VALUES (100,45.00,'cash');
INSERT INTO payment (member_id, amount, paid_on, method) VALUES (100,30.00,'2026-04-02','cash');
INSERT INTO payment (member_id, amount, method) VALUES (101,45.00,'check');
INSERT INTO payment (member_id, amount, paid_on, method) VALUES (102,60.00,'2026-03-15','card');

SELECT * FROM PAYMENT;

SELECT * FROM MEMBER;

-- The record with a payment_id of 5001 is deleted from the PAYMENT table

DELETE FROM payment WHERE payment_id = 5001;

SELECT * FROM MEMBER;

SELECT * FROM PAYMENT_LOG;

-- =================================================================
-- STEP 10 and 11. Push to GitHub and submit the URL
-- Nothing to write here. Follow the handout.
-- =================================================================
