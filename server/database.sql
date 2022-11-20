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
    INVENTORY_ID INTEGER ,
    R_NAME VARCHAR(200),
    R_USERNAME VARCHAR(200),
    R_PASSWORD VARCHAR(200),
    R_ADDRESS VARCHAR(500),
    R_EMAIL VARCHAR(500),
    R_APPROVAL_STATUS VARCHAR(20) DEFAULT 'FALSE'
);

CREATE TABLE CUSTOMER (
    C_ID SERIAL PRIMARY KEY,
    C_MOBILE_NUM VARCHAR(200),
    C_USERNAME VARCHAR(200),
    C_PASSWORD VARCHAR(200),
    C_ADDRESS VARCHAR(500),
    C_EMAIL VARCHAR(200)
);

 --1 -> approval
 --2 -> common
CREATE TABLE NOTIFICATIONS(
    N_ID uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    REFERRER_ID uuid  NOT NULL,
    string VARCHAR(500) NOT NULL,
    type INTEGER NOT NULL
);
-- INVENTORY_ID NUM FOREIGN KEY REFERENCES INVENTORY (INVENTORY_ID),
------------------------
-- USE PL/SQL FOR IDS
------------------------
-- LOGIC TO HANDLE COUNT 
CREATE TABLE INVENTORY(
    INVENTORY_ID uuid PRIMARY KEY uuid_generate_v4(),
    INVENTORY_COUNT INTEGER,
    INTVENTORY_TYPE VARCHAR(20),
    INVENTORY_DESCRIPTION VARCHAR(200)
);

-- CREATE TABLE STOCK (
--     INVENTORY_ID
--     STOCK_ID SERIAL PRIMARY KEY,
--     STOCK_ITEMS VARCHAR(500),
--     STOCK_NUMBER NUM, 
--     STOCK_TYPE VARCHAR(200),
--     STOCK_DESC VARCAHR(500)
-- );



-- CREATE TABLE PURCHASING(
--     PURCHASING_ID SERIAL PRIMARY KEY,
--     CUSTOMER_ID NUM FOREIGN KEY REFRENCES CUSTOMER(C_ID),
--     PURCHASE_DESCRIPTION VARCHAR(300),
--     PURCHASE_AMOUNT DOUBLE, 
--     PURCHASE_DESC VARCAR(500)
-- );



