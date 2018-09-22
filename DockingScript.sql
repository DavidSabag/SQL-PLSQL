-- Name: David Sabag
--ID: 300675337

drop table Docking;
drop table Piers;
drop table Ships;
drop TRIGGER updateTotalShips;
drop FUNCTION Ships_num;
alter session set nls_date_format='DD/MM/YY';

--Q.1
create table Piers
(
            pid varchar2(9)  PRIMARY KEY,
            name varchar2(20),
            capacity INTEGER NOT NULL,
            type varchar2(20) UNIQUE,
            totalShips  INTEGER DEFAULT 0
);

create table Ships
(
  sid varchar2(9)  PRIMARY KEY,
  name varchar2(20) ,
  country varchar2(20),  
  cargo_weight INTEGER NOT NULL
  
);

create table Docking  
(
    sid varchar2(9) ,
    pid varchar2(9) ,
    arrivel_date DATE ,
    departure_date DATE,
   CONSTRAINT fk_ships FOREIGN KEY (sid)  REFERENCES Ships(sid),
   CONSTRAINT fk_piers FOREIGN KEY (pid)  REFERENCES Piers(pid)
);
--insert values to piers
INSERT INTO Piers(pid,name,CAPACITY,TYPE) VALUES('1','A',30000,'agricultural exports'); 
INSERT INTO Piers(pid,name,CAPACITY,TYPE) VALUES('2','B',30000,'timber');
INSERT INTO Piers(pid,name,CAPACITY,TYPE) VALUES('3','C',30000,'metals');
INSERT INTO Piers(pid,name,CAPACITY,TYPE) VALUES('4','D',30000,'sling');
INSERT INTO Piers(pid,name,CAPACITY,TYPE) VALUES('5','E',60000,'Panamax');
INSERT INTO Piers(pid,name,CAPACITY,TYPE) VALUES('6','F',30000,'bulk');

--SELECT * FROM PIERS;
--insert values to ships
INSERT INTO Ships VALUES('11','S1','China',30000);
INSERT INTO Ships VALUES('22','S2','Zimbabwe',25000);
INSERT INTO Ships VALUES('33','S3','Guatemala',15000);
INSERT INTO Ships VALUES('44','S4','China',25000);
INSERT INTO Ships VALUES('55','S5','Marshall Islands',20000);
INSERT INTO Ships VALUES('66','S6','Russia',20000);
INSERT INTO Ships VALUES('77','S7','Malta',45000);
INSERT INTO Ships VALUES('88','S8','Panama',50000);
INSERT INTO Ships VALUES('99','S9','Malta',15000);
INSERT INTO Ships VALUES('1010','S10','Marshall Islands',20000);
INSERT INTO Ships VALUES('1111','S11','Liberia',25000);
INSERT INTO Ships VALUES('1212','S12','Liberia',15000);
INSERT INTO Ships VALUES('1313','S13','Zimbabwe',20000);
INSERT INTO Ships VALUES('1414','S14','Panama',55000);


--Q.2 + Q.3
set define off;
CREATE OR REPLACE TRIGGER updateTotalShips
BEFORE INSERT ON Docking
FOR EACH ROW
DECLARE
  weight INTEGER;
  cap INTEGER;

BEGIN
      select cargo_weight into weight from Ships where sid = :new.sid;
      select capacity into cap from Piers where pid = :new.pid; 
      IF :new.arrivel_date <= :new.departure_date and  weight <= cap THEN
            UPDATE Piers
            SET totalShips = totalShips + 1
            WHERE :new.pid = pid;
             
      ELSE
            raise_application_error(-20000, 'INVALID INPUTS');
      END IF;
      
END;

--insert values to Docking
INSERT INTO Docking VALUES('88','5','15/8/17','15/8/17');
INSERT INTO Docking VALUES('22','1','17/8/17','18/8/17');
INSERT INTO Docking VALUES('1414','5','16/8/17','20/8/17');
INSERT INTO Docking VALUES('1010','3','15/8/17','19/8/17');
INSERT INTO Docking VALUES('99','2','16/8/17','16/8/17');
INSERT INTO Docking VALUES('33','2','15/8/17','15/8/17');
INSERT INTO Docking VALUES('66','3','17/8/17','19/8/17');
INSERT INTO Docking VALUES('1111','5','16/8/17','16/8/17');
INSERT INTO Docking VALUES('1212','2','15/8/17','15/8/17');
INSERT INTO Docking VALUES('55','4','17/8/17','20/8/17');
INSERT INTO Docking VALUES('77','5','16/8/17','16/8/17');
INSERT INTO Docking VALUES('44','1','16/8/17','17/8/17');

--Checking exception works
--INSERT INTO Docking VALUES('44','1','18/8/17','15/8/17');
--INSERT INTO Docking VALUES('88','1','16/8/17','17/8/17');

-- Making sure trigger wored
SELECT * FROM PIERS;

--Q.4.A
SET SERVEROUTPUT ON
set define on;
DECLARE 
  c_sid VARCHAR2(20);
  c_pid VARCHAR2(20);
  c_AD DATE;
  c_DD DATE;
  c_delay INTEGER;
  user_field VARCHAR2(20);
  
CURSOR PIER_CUR IS
        
        SELECT DISTINCT d1.sid , d1.pid , d1.arrivel_date , d1.departure_date , (d1.departure_date - d1.ARRIVEL_DATE) as delay_time 
        FROM Docking d1 , (select pid ,(departure_date - ARRIVEL_DATE) as delay_time from DOCKING )d2
        WHERE d1.pid = '&user_field' 
        and d1.pid = d2.pid 
        and (d1.departure_date - d1.ARRIVEL_DATE) > d2.delay_time;
BEGIN 
    OPEN PIER_CUR;
    FETCH PIER_CUR INTO c_sid , c_pid , c_AD , c_DD , c_delay;
    DBMS_OUTPUT.PUT_LINE ('This report for pier '|| c_pid || ':');
    CLOSE PIER_CUR;
    
    OPEN PIER_CUR;
          LOOP
              FETCH PIER_CUR INTO c_sid , c_pid , c_AD , c_DD , c_delay;
              EXIT WHEN PIER_CUR%NOTFOUND;
              DBMS_OUTPUT.PUT_LINE (c_sid || ' | ' ||c_AD ||' | '|| c_DD ||' | '|| c_delay || ' Days '); 
          END LOOP;
    CLOSE PIER_CUR;
      
END;

--Q.4.B
SET SERVEROUTPUT ON
set define on;
DECLARE 
  c_sid VARCHAR2(20);
  c_pid VARCHAR2(20);
  c_AD DATE;
  c_DD DATE;
  c_delay INTEGER;
  user_field VARCHAR2(20);
  
CURSOR PIER_CUR IS
        
        SELECT DISTINCT d1.sid , d1.pid , d1.arrivel_date , d1.departure_date , (d1.departure_date - d1.ARRIVEL_DATE) as delay_time 
        FROM Docking d1 , (select pid ,(departure_date - ARRIVEL_DATE) as delay_time from DOCKING )d2
        WHERE d1.pid = '&user_field' 
        and d1.pid = d2.pid 
        and (d1.departure_date - d1.ARRIVEL_DATE) > d2.delay_time;
BEGIN 
      FOR i IN PIER_CUR
        LOOP 
            DBMS_OUTPUT.PUT_LINE ('This report for pier '|| i.pid || ':');
            DBMS_OUTPUT.PUT_LINE (i.sid || ' | ' ||i.arrivel_date ||' | '|| i.departure_date ||' | ' || i.delay_time || ' Days '); 
        
        END LOOP ;


      
END;


--Q.5
CREATE or replace FUNCTION Ships_num(fromD DATE , toD DATE)
RETURN INTEGER IS
shipsNum INTEGER;
BEGIN
      shipsNum :=0;
      FOR i in (select arrivel_date ,departure_date from Docking )
      LOOP
          IF( i.arrivel_date >= fromD AND i.arrivel_date <=toD ) OR (i.departure_date >= fromD AND i.departure_date <=toD) THEN
              shipsNum := shipsNum + 1;
          END IF;
      END LOOP;
      
      IF shipsNum > 0 THEN
        RETURN shipsNum;
      ELSE 
        RAISE NO_DATA_FOUND;
        
      END IF;
      
      EXCEPTION 
          WHEN NO_DATA_FOUND THEN
              RETURN -2;
              
END Ships_num;


DECLARE 
    fromD VARCHAR2(20);
    toD VARCHAR2(20);
    ships_num1 INTEGER;
    shipName VARCHAR2(20);
    pierName VARCHAR2(20);
BEGIN
    fromD :='&from_date';
    toD := '&to_date';
    
    ships_num1 := Ships_num(fromD , toD);
    DBMS_OUTPUT.PUT_LINE ('From: ' || fromD);
    DBMS_OUTPUT.PUT_LINE ('To: ' || toD);
    
    IF ships_num1 > 0 THEN
    
        FOR i IN (SELECT sid , pid , arrivel_date , departure_date FROM Docking)
    
          LOOP
                  IF ( i.arrivel_date >= fromD AND i.arrivel_date <=toD ) OR (i.departure_date >= fromD AND i.departure_date <=toD) THEN
                      SELECT name INTO shipName FROM Ships WHERE i.sid = sid;
                      SELECT name INTO pierName FROM Piers WHERE i.pid = pid;
                      DBMS_OUTPUT.PUT_LINE (pierName ||' | '|| shipName ||' | '||  i.arrivel_date ||' | '||  i.departure_date);
                  END IF;
          END LOOP;
          DBMS_OUTPUT.PUT_LINE ('From '|| fromD || ' to ' || toD || ' there where ' || ships_num1 || ' ships. ');
          
    ELSE
      DBMS_OUTPUT.PUT_LINE ('There are no ships in period :' || fromD ||' - ' || toD);
    END IF;
    
        
END; 

--Q.6

DECLARE 

  countryName VARCHAR2(20);
  pier_num VARCHAR2(20);
  AD VARCHAR2(20);
  DD VARCHAR2(20);
  count_ships INTEGER;
  avg_weight INTEGER;

BEGIN
  countryName := '&country_name';
  count_ships := 0;
  FOR i IN (SELECT sid , name , country , cargo_weight FROM Ships WHERE country = countryName)
  LOOP
      
      SELECT pid INTO pier_num FROM Docking WHERE i.sid = sid ;
      SELECT arrivel_date INTO AD FROM Docking WHERE i.sid = sid;
      SELECT departure_date INTO DD FROM Docking WHERE i.sid = sid ;
      DBMS_OUTPUT.PUT_LINE(i.sid || ' | '|| pier_num || ' | ' || AD || ' | ' || DD);
      count_ships := count_ships + 1;

  END LOOP;
  
  IF count_ships = 0 THEN
      RAISE NO_DATA_FOUND;
  END IF;
  
  SELECT AVG(cargo_weight) INTO avg_weight FROM Ships WHERE country = countryName;
  
  DBMS_OUTPUT.PUT_LINE('Total ships : ' || count_ships);
  DBMS_OUTPUT.PUT_LINE('Average weight : ' || avg_weight);
  
  EXCEPTION 
      WHEN NO_DATA_FOUND THEN
          DBMS_OUTPUT.PUT_LINE('No ship anchored from this country');
        
END; 


--Liberia


