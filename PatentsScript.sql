drop table Patents;
drop table Clients;
drop table Lawyers;
drop TRIGGER UpdateTotFee;
drop FUNCTION max_fee_for_feild;
alter session set nls_date_format='DD/MM/YY';

--Q.1
create table Lawyers
(
            lid varchar2(9) PRIMARY KEY,
            LName varchar2(20),
            field varchar2(20),
            TotalFee INTEGER DEFAULT 0
);

create table Clients
(
            cid varchar2(9)  PRIMARY KEY,
            CName varchar2(20),
            City varchar2(50)
);
CREATE TABLE Patents
(
  lid VARCHAR2(9),
  cid VARCHAR2(9),
  PatName VARCHAR2(50),
  PatDate DATE,
  PatField VARCHAR2(20),
  PatApproved DATE,
  PatFee INTEGER,
  PRIMARY KEY(PatName  ,  PatDate),
  CONSTRAINT fk_lawyers FOREIGN KEY (lid)  REFERENCES Lawyers(lid),
  CONSTRAINT fk_clients FOREIGN KEY (cid)  REFERENCES Clients(cid)
);
--Checking tables created
SELECT * FROM LAWYERS;
SELECT * FROM CLIENTS;
SELECT * FROM PATENTS;

--Q.2
set define off;
CREATE OR REPLACE TRIGGER UpdateTotFee
BEFORE INSERT OR  UPDATE ON Patents
FOR EACH ROW

BEGIN

  IF INSERTING THEN
      UPDATE Lawyers
      SET TotalFee = TotalFee + :new.PatFee
      WHERE :new.lid = lid;
  END IF;
  
  IF UPDATING THEN
      UPDATE Lawyers
      SET TOTALFEE = ( TOTALFEE - :old.PatFee )+ :new.PatFee
      WHERE :new.lid = lid;
  END IF;
  
END;


--Q.3 and Q.4
INSERT INTO LAWYERS(lid,LNAME,field) VALUES('a','meni','Games');
INSERT INTO LAWYERS(lid,LNAME,field) VALUES('b','dan','IT');
INSERT INTO LAWYERS(lid,LNAME,field) VALUES('c','gadi','Cars');
INSERT INTO LAWYERS(lid,LNAME,field) VALUES('d','ofir','IT');
INSERT INTO LAWYERS(lid,LNAME,field) VALUES('e','yoni','Games');
INSERT INTO LAWYERS(lid,LNAME,field) VALUES('f','hen','Cars');

INSERT INTO Clients VALUES('aa','beni','beer-sheva');
INSERT INTO Clients VALUES('bb','ayelet','tel-aviv');
INSERT INTO Clients VALUES('cc','ran','hifa');
INSERT INTO Clients VALUES('dd','ziv','eilat');
INSERT INTO Clients VALUES('ee','eli','jerusalem');
INSERT INTO Clients VALUES('ff','yosi','dimona');


INSERT INTO PATENTS VALUES ('a','bb','abb','01/10/05','e','01/10/05',5);
INSERT INTO PATENTS VALUES ('a','cc','acc','01/10/06','e','01/10/06',3);
INSERT INTO PATENTS VALUES ('b','dd','bdd','01/10/07','yy','01/10/07',10);
INSERT INTO PATENTS VALUES ('b','ee','bee','01/10/08','oo','01/10/08',11);
INSERT INTO PATENTS VALUES ('c','ff','cff','01/10/09','e','01/10/09',1);
INSERT INTO PATENTS VALUES ('c','aa','caa','01/10/15','ww','01/10/15',1);

UPDATE PATENTS
SET PatFee = 100
WHERE LID = 'a' AND CID = 'cc';

SELECT * FROM LAWYERS;

UPDATE PATENTS
SET PATFIELD = 'Check'
WHERE LID = 'b' AND CID = 'ee';

SELECT * FROM LAWYERS;
SELECT * FROM PATENTS;

--Q.5.1
SET SERVEROUTPUT ON
set define on;
DECLARE 
  c_lid Patents.lid%TYPE;
  c_cid Patents.cid%TYPE;
  c_PatDate Patents.PatDate%TYPE;
  c_PatApproved Patents.PatApproved%TYPE;
  c_PatFee Patents.PatFee%TYPE;
  c_PatField PATENTS.PATFIELD%TYPE;
  user_field VARCHAR2(20);
  
  CURSOR PAT_CUR IS
        SELECT p1.lid ,p1.cid , p1.PatDate , p1.PatApproved , p1.PatFee , p1.PatField 
        FROM Patents p1 , ( SELECT AVG(PatFee) as avg_fee , p.PatField
                            FROM Patents p  
                            WHERE p.PATFIELD = '&user_field' 
                            group by  p.patfield )p2
        WHERE p1.PatFee < p2.avg_fee
        AND p1.PatField = p2.PatField
        ORDER BY p1.patApproved ASC;

BEGIN
      OPEN PAT_CUR;
   
        LOOP 
        
            FETCH PAT_CUR INTO c_lid , c_cid , c_PatDate , c_PatApproved , c_PatFee ,c_PatField  ;
            EXIT WHEN PAT_CUR%NOTFOUND;
            DBMS_OUTPUT.PUT_LINE (c_lid || ' | ' ||c_cid ||' | '|| c_PatDate ||' | '|| c_PatApproved || ' | '|| c_PatFee ); 
        
        END LOOP ;
        
      CLOSE PAT_CUR;
      
END;


--Q.5.2
SET SERVEROUTPUT ON
set define on;
DECLARE 
  c_lid Patents.lid%TYPE;
  c_cid Patents.cid%TYPE;
  c_PatDate Patents.PatDate%TYPE;
  c_PatApproved Patents.PatApproved%TYPE;
  c_PatFee Patents.PatFee%TYPE;
  c_PatField PATENTS.PATFIELD%TYPE;
  user_field VARCHAR2(20);
  
  CURSOR PAT_CUR IS
        SELECT p1.lid ,p1.cid , p1.PatDate , p1.PatApproved , p1.PatFee , p1.PatField 
        FROM Patents p1 , ( SELECT AVG(PatFee) as avg_fee , p.PatField
                            FROM Patents p  
                            WHERE p.PATFIELD = '&user_field' 
                            group by  p.patfield )p2
        WHERE p1.PatFee < p2.avg_fee
        AND p1.PatField = p2.PatField
        ORDER BY p1.patApproved ASC;

BEGIN
      FOR i IN PAT_CUR
        LOOP 
            DBMS_OUTPUT.PUT_LINE ( i.lid || ' | ' || i.cid ||' | '|| i.PatDate ||' | '|| i.PatApproved || ' | '|| i.PatFee ); 
        
        END LOOP ;
      
END;

--Q.6

CREATE or replace FUNCTION max_fee_for_feild(u_field varchar2)
RETURN INTEGER IS
MaxFee INTEGER;
BEGIN
      SELECT MAX(PatFee) INTO MaxFee FROM PATENTS WHERE PatField = u_field;
      IF MaxFee IS NULL THEN
          RETURN -1;
      END IF;
      RETURN MaxFee;
END max_fee_for_feild;


DECLARE 
        MaxFee INT;
        u_field VARCHAR2(20);
  
BEGIN
              u_field := '&user_field';
              MaxFee := max_fee_for_feild(u_field);
              IF MaxFee = -1 THEN RAISE NO_DATA_FOUND; 
              ELSE
                      dbms_output.put_line('The max fee for patent field ' || u_field || ' is ' || MaxFee);
              END IF;
              
              EXCEPTION
                      WHEN NO_DATA_FOUND THEN
                      dbms_output.put_line('There are no patents with patent field :' || u_field);
END; 

--Q.7

DECLARE 
    l_name VARCHAR2(20);
    tot_fee INTEGER;
BEGIN 
    l_name := '&name';
    FOR i IN (SELECT l.lname , c.cname , p.patname , p.patfee
              FROM Lawyers l , Clients c , Patents p
              WHERE l.lid = p.lid
              AND l.lname = l_name AND p.cid = c.cid)
    LOOP
        DBMS_OUTPUT.PUT_LINE ( i.lname || ' | ' || i.cname ||' | '|| i.patname ||' | '|| i.patfee  ); 
    END LOOP;
    SELECT SUM(PATFEE) INTO tot_fee FROM PATENTS P ,LAWYERS L
    WHERE L.lid = P.lid AND L.lname = l_name;
    DBMS_OUTPUT.PUT_LINE('Total fee : ' || tot_fee) ;
    
END;


          


