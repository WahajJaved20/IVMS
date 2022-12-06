CREATE DATABASE IVMS_DB;

-- create extension if not exists "uuid-ossp"
CREATE TABLE ADMIN (
    ADMIN_ID uuid PRIMARY KEY DEFAULT
    uuid_generate_v4(),
    ADMIN_USERNAME VARCHAR(255) not null,
    ADMIN_NAME VARCHAR(255) not null,
    ADMIN_EMAIL VARCHAR(255) not null,
    ADMIN_PASSWORD VARCHAR (255) not null
);


CREATE TABLE RETAILER(
    R_ID uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    R_MOBILE_NUM VARCHAR(200),
    R_NAME VARCHAR(200),
    R_USERNAME VARCHAR(200),
    R_PASSWORD VARCHAR(200),
    R_ADDRESS VARCHAR(500),
    R_EMAIL VARCHAR(500),
    R_APPROVAL_STATUS VARCHAR(20) DEFAULT 'FALSE'
);



CREATE VIEW RETAILER_ACCESSES AS
SELECT RETAILER.R_ID,R_NAME,R_APPROVAL_STATUS,INVENTORY.INVENTORY_ID
FROM RETAILER JOIN INVENTORY ON RETAILER.R_ID=INVENTORY.R_ID;

CREATE TABLE NOTIFICATIONS(
    N_ID uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    REFERRER_ID uuid  NOT NULL,
    string VARCHAR(500) NOT NULL,
    type INTEGER NOT NULL
);
------------------------
-- USE PL/SQL FOR IDS
------------------------
-- LOGIC TO HANDLE COUNT 
CREATE TABLE INVENTORY(
    INVENTORY_ID uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    R_ID uuid,
    INVENTORY_COUNT INTEGER DEFAULT 0,
    INVENTORY_TYPE VARCHAR(20),
    INVENTORY_DESCRIPTION VARCHAR(200),
    INVENTORY_MAX_COUNT INTEGER
);


ALTER TABLE RETAILER ADD CONSTRAINT retailerFK FOREIGN KEY(INVENTORY_ID) REFERENCES INVENTORY(INVENTORY_ID);

CREATE TABLE PRODUCT(
    INVENTORY_ID uuid,
    PRODUCT_ID VARCHAR(200) PRIMARY KEY DEFAULT 'P-',
    PRODUCT_ID SERIAL PRIMARY KEY,
    PRODUCT_NAME VARCHAR(50),
    PRODUCT_COUNT INTEGER,
    PRODUCT_DESCRIPTION VARCHAR(200),
    PRODUCT_TYPE VARCHAR(200)
);


ALTER TABLE PRODUCT ADD CONSTRAINT PRODUCTFK FOREIGN KEY(INVENTORY_ID) REFERENCES INVENTORY(INVENTORY_ID);





ALTER TABLE PRODUCT ADD CONSTRAINT productFK FOREIGN KEY(INVENTORY_ID) REFERENCES INVENTORY(INVENTORY_ID);
CREATE FUNCTION product_function()
    returns trigger language PLPGSQL
    AS $$
    BEGIN 
        IF INVENTORY_COUNT<INVENTORY_MAX_COUNT THEN
            INSERT INTO PRODUCT (INVENTORY_ID, PRODUCT_NAME, PRODUCT_COUNT)
            VALUES (OLD.INVENTORY_ID, OLD.PRODUCT_NAME, OLD.PRODUCT_COUNT);
        ELSE
            RAISE NOTICE 'INVENTORY FULL';
        end if;
    END;
    $$
CREATE TRIGGER CHECKPRODUCT
    BEFORE UPDATE 
    ON PRODUCT
    FOR EACH ROW
    EXECUTE PROCEDURE product_function();

CREATE TABLE SENDER (
    S_ID SERIAL PRIMARY KEY,
    S_NAME VARCHAR(50),
    S_MOBILE_NUM VARCHAR(200),
    S_ADDRESS VARCHAR(500),
    S_EMAIL VARCHAR(200)
);
CREATE TABLE INBOUND(
	INBOUND_ID VARCHAR(200) PRIMARY KEY DEFAULT 'I-',
	SENDER_ID INTEGER,
	Approval_Status VARCHAR(10) DEFAULT 'False',
	Inventory_ID uuid,
	PRODUCT_COUNT INTEGER,
	PRODUCT_ID INTEGER
);
ALTER TABLE INBOUND ADD CONSTRAINT inboundInvenFK FOREIGN KEY(Inventory_ID) REFERENCES INVENTORY(INVENTORY_ID);
ALTER TABLE INBOUND ADD CONSTRAINT inboundSendFK FOREIGN KEY(SENDER_ID) REFERENCES SENDER(S_ID);
CREATE TABLE OUTBOUND(
	OUTBOUND_ID VARCHAR(200) PRIMARY KEY DEFAULT 'O-',
	Inventory_ID References FORIEGN KEY INVENTORY(INVENTORY_ID),
	PRODUCT_ID REFERENCES FORIEGN KEY PRODUCT(PRODUCT_ID),
	PRODUCT_COUNT NUMBER,
	RECIEVER_ID REFERENCES FORIEGN KEY RECIEVER(RECIEVER_ID)
);
CREATE TABLE RECIEVER (
    R_ID VARCHAR(200) PRIMARY KEY DEFAULT 'R-',
    R_NAME VARCHAR(200) UNIQUE,
    R_MOBILE_NUM VARCHAR(200),
    R_ADDRESS VARCHAR(500),
    R_EMAIL VARCHAR(200)
);

CREATE TABLE HISTORY (
    HISTORY_ID SERIAL PRIMARY KEY,
    ID VARCHAR(200) UNIQUE NOT NULL,
    ENTRY_TIME TIMESTAMP
);

--triggers
--============================
--password check in retailer (DONE)
--============================

CREATE OR REPLACE FUNCTION CHECK_PASSWORD()
    RETURNS TRIGGER
    AS $$
    BEGIN 
        IF length(NEW.R_PASSWORD)<8 THEN
            RAISE NOTICE 'Password Length not sufficient!';
            RETURN NULL;
        ELSE 
            RETURN NEW;
        END IF;
        
    END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE TRIGGER check_pass 
    BEFORE INSERT OR UPDATE ON RETAILER
    FOR EACH ROW
    EXECUTE FUNCTION CHECK_PASSWORD();

--============================
--CHECK PHONE NUMBER LENGTH = 11 (DONE)
--============================

CREATE OR REPLACE FUNCTION CHECK_PHONE()
    RETURNS TRIGGER
    AS $$
    BEGIN 
        IF length(NEW.R_MOBILE_NUM)<11 OR length(NEW.R_MOBILE_NUM)>11 THEN
            RAISE NOTICE 'Mobile no. not possible';
            RETURN NULL;
        ELSE 
            RETURN NEW;
        END IF;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER check_num 
    BEFORE INSERT OR UPDATE ON RETAILER
    FOR EACH ROW
    EXECUTE FUNCTION CHECK_PHONE();

--=====================================
--TRIGGER TO CHECK IF INVENTORY FULL 
--=====================================
CREATE OR REPLACE FUNCTION product_function()
    returns trigger
    AS $$
    BEGIN 
        IF NEW.INVENTORY_COUNT<NEW.INVENTORY_MAX_COUNT THEN
            RETURN NEW;
        ELSE
            RAISE NOTICE 'INVENTORY FULL';
            RETURN NULL;
        end if;
    END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE TRIGGER CHECKPRODUCT
    BEFORE INSERT OR UPDATE 
    ON PRODUCT
    FOR EACH ROW
    EXECUTE PROCEDURE product_function();
--=====================================
--TRIGGER TO CHECK IF INVENTORY BECOMES NEGATIVE (DONE)
--=====================================
CREATE OR REPLACE TRIGGER CHECKPRODUCT1
    BEFORE INSERT OR UPDATE 
    ON INVENTORY
    FOR EACH ROW
    EXECUTE PROCEDURE product_function();
CREATE OR REPLACE FUNCTION product_func()
    returns trigger
    AS $$
    BEGIN 
        IF NEW.INVENTORY_COUNT > 0 THEN
            RETURN NEW;
        ELSE
            RAISE NOTICE "INVENTORY COUNT CAN'T BE NEGATIVE";
            RETURN NULL;
        end if;
    END;
$$ LANGUAGE plpgsql;
--============================
--TRIGGER FOR RECIEVER_ID (DONE)
--============================

CREATE OR REPLACE FUNCTION R_ID()
    RETURNS TRIGGER 
    AS $$
    BEGIN 
        -- RAISE NOTICE '%', CONCAT(NEW.R_ID, NEXTVAL('SMTH'));
        NEW.R_ID := CONCAT(NEW.R_ID, NEXTVAL('RECIEVER_SEQUENCE'));
        return NEW;
    END;
    $$ LANGUAGE plpgsql;    
CREATE OR REPLACE TRIGGER RECIEVER_NEW
    BEFORE INSERT ON RECIEVER
    FOR EACH ROW
    EXECUTE PROCEDURE R_ID();


CREATE SEQUENCE RECIEVER_SEQUENCE
START 10
INCREMENT 1
OWNED BY RECIEVER.r_id;
--============================
--TRIGGER FOR PRODUCT_ID (DONE)
--============================

CREATE OR REPLACE FUNCTION PRODUCT_NEW_ID()
    RETURNS TRIGGER 
    AS $$
    BEGIN 
        -- RAISE NOTICE '%', CONCAT(NEW.R_ID, NEXTVAL('SMTH'));
        NEW.PRODUCT_id := CONCAT(NEW.PRODUCT_id, NEXTVAL('PRODUCT_SEQUENCE'));
        return NEW;
    END;
    $$ LANGUAGE plpgsql;    
CREATE OR REPLACE TRIGGER PRODUCT_NEW
    BEFORE INSERT ON PRODUCT
    FOR EACH ROW
    EXECUTE PROCEDURE PRODUCT_NEW_ID();

CREATE SEQUENCE PRODUCT_SEQUENCE
START 10
INCREMENT 1
OWNED BY PRODUCT.PRODUCT_id;

--============================
--TRIGGER FOR INBOUND_ID (DONE)
--============================

CREATE OR REPLACE FUNCTION INBOUND_NEW_ID()
    RETURNS TRIGGER 
    AS $$
    BEGIN 
        -- RAISE NOTICE '%', CONCAT(NEW.R_ID, NEXTVAL('SMTH'));
        NEW.INBOUND_id := CONCAT(NEW.INBOUND_id, NEXTVAL('INBOUND_SEQUENCE'));
        return NEW;
    END;
    $$ LANGUAGE plpgsql;    
CREATE OR REPLACE TRIGGER INBOUND_NEW
    BEFORE INSERT ON INBOUND
    FOR EACH ROW
    EXECUTE PROCEDURE INBOUND_NEW_ID();

CREATE SEQUENCE INBOUND_SEQUENCE
START 1
INCREMENT 1
OWNED BY INBOUND.INBOUND_id;

--============================
--TRIGGER FOR OUTBOUND_ID (DONE)
--============================

CREATE OR REPLACE FUNCTION OUTBOUND_NEW_ID()
    RETURNS TRIGGER 
    AS $$
    BEGIN 
        -- RAISE NOTICE '%', CONCAT(NEW.R_ID, NEXTVAL('SMTH'));
        NEW.OUTBOUND_id := CONCAT(NEW.OUTBOUND_id, NEXTVAL('OUTBOUND_SEQUENCE'));
        return NEW;
    END;
    $$ LANGUAGE plpgsql;    
CREATE OR REPLACE TRIGGER OUTBOUND_NEW
    BEFORE INSERT ON OUTBOUND
    FOR EACH ROW
    EXECUTE PROCEDURE OUTBOUND_NEW_ID();

CREATE SEQUENCE OUTBOUND_SEQUENCE
START 1
INCREMENT 1
OWNED BY OUTBOUND.OUTBOUND_id;


--============================
--Trigger for updating inventory count(NOT DONE)
--============================

CREATE OR REPLACE FUNCTION UPDATE_INVENTORY_COUNT()
    RETURNS TRIGGER
    AS $$
    BEGIN 
        -- UPDATE INVENTORY SET INVENTORY_COUNT = Inventory_count+NEW.PRODUCT_COUNT WHERE INVENTORY_ID = NEW.INVENTORY_ID;  
        select inventory_count from inventory where Inventory_ID
    END;
    $$ LANGUAGE plpgsql;
CREATE OR REPLACE TRIGGER UPDATE_INVENTORY
    AFTER INSERT 
    ON PRODUCT 
    FOR EACH ROW 
    EXECUTE PROCEDURE UPDATE_INVENTORY_COUNT();



--insert values 
INSERT INTO RECIEVER (R_NAME,R_MOBILE_NUM, R_ADDRESS, R_EMAIL) VALUES ('haTa','030012345678', 'HAA', 'HATIF');
INSERT INTO INVENTORY (r_id, INVENTORY_DESCRIPTION, INVENTORY_MAX_COUNT, INVENTORY_TYPE)VALUES ('0043d2b2-8eab-46cd-bc9c-5b467f04f461', 'HAA', 20, 'HAA');
INSERT INTO PRODUCT (INVENTORY_ID,PRODUCT_NAME, PRODUCT_COUNT, PRODUCT_DESCRIPTION, PRODUCT_TYPE) VALUES('8b5963e5-5471-4694-a2c2-87eb153c4065', 'HAA', 2,'haahshd', 'shoes');
INSERT INTO RETAILER (R_MOBILE_NUM, R_NAME, R_USERNAME, R_ADDRESS,R_PASSWORD, R_EMAIL) VALUES ('03218745530', 'ha', 'ha', 'ha','hatif1234', 'ha');