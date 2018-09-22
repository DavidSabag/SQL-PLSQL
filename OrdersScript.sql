SET SERVEROUTPUT ON
declare
      cat number;
      catAVG number(10,2);
      p_name VARCHAR2(50);
begin
      cat:= &k;
      SELECT AVG( LIST_PRICE) INTO catAVG FROM Products;
      FOR i IN(SELECT LIST_PRICE FROM Products ORDER BY LIST_PRICE DESC) 
      LOOP
                IF i.LIST_PRICE>=catAVG THEN
                        SELECT PRODUCT_NAME INTO p_name FROM PRODUCTS WHERE LIST_PRICE=i.LIST_PRICE AND CATEGORY_ID=cat;
                        dbms_output.put(' " ' ||p_name||' " ' ||' , '||' " ' || i.LIST_PRICE||' " ' ||'|');
                END IF;
        END LOOP;
        dbms_output.new_line;
END;



 /*q.2*/
CREATE or replace FUNCTION categoryAvg(cat_id integer)
RETURN INT IS
cat_id_avg INT;
BEGIN
                      SELECT AVG(LIST_PRICE) INTO cat_id_avg FROM PRODUCTS WHERE CATEGORY_ID=cat_id;
                      IF cat_id_avg is NULL THEN
                      RETURN -1;
                      END IF;
                      RETURN cat_id_avg;  
END categoryAvg;

DECLARE 
        cat INT;
        avrg INT;
BEGIN
              cat:=&ENTER_CATEGORY;
              avrg:=categoryAvg(cat);
              IF avrg = -1 THEN RAISE NO_DATA_FOUND; 
              ELSE
                      dbms_output.put_line('Category ID: '||cat||' Average:'||avrg);
              END IF;
              
              EXCEPTION
                      WHEN NO_DATA_FOUND THEN
                      dbms_output.put_line('The category you enterd is NOT exist!!');
END; 




/*q.3*/
ALTER TABLE order_items ADD TOTAL NUMBER;

set define off;
CREATE OR REPLACE TRIGGER trg_to_TOTAL
BEFORE INSERT OR  UPDATE ON order_items
FOR EACH ROW 
DECLARE
      tot NUMBER(10,2);
BEGIN
            tot :=  (  :new.ITEM_PRICE   -   :new.DISCOUNT_AMOUNT  )  * :new.QUANTITY;
            :new.TOTAL:=tot;
            DBMS_OUTPUT.PUT_LINE ( 'Update Date: ' ||  to_char ( SYSDATE ,'DD/MM/YYYY' ) || '  Item ID: ' || :new.item_id || '  Order ID: ' || :new.order_id || '  Price: ' || :new.total) ;
END;     
        
UPDATE order_items  
SET total=1.0
WHERE DISCOUNT_AMOUNT=186.2;

INSERT INTO  order_items (ITEM_ID, ORDER_ID, PRODUCT_ID, ITEM_PRICE, DISCOUNT_AMOUNT, QUANTITY)  VALUES (14,9,7,199,19,3);
 SELECT * FROM order_items;     
 


 /*q.4*/
 SELECT customer_id , first_name , last_name
 FROM CUSTOMERS
 WHERE customer_id in ( SELECT customer_id
                                  FROM orders
                                  WHERE order_id in (SELECT order_id
                                                      FROM order_items
                                                      WHERE product_id in  (SELECT product_id 
                                                                            FROM products
                                                                            MINUS
                                                                            SELECT product_id 
                                                                            FROM products pr1, (SELECT CATEGORY_ID,LIST_PRICE FROM products) pr2
                                                                                                 WHERE pr1.LIST_PRICE <pr2.LIST_PRICE
                                                                                                  AND pr1.CATEGORY_ID = pr2.CATEGORY_ID)));
                                                                                                                                                                                                        



-- q.5

UPDATE order_items
SET discount_amount  = a.discount_amount
FROM order_items
INNER JOIN (select oi.order_id, oi.product_id, b.discount_amount
            from orders o, order_items oi,
                 (select customer_id, product_id, tot
                  from (    select DISTINCT customer_id, product_id, count(product_id) * sum (quantity) as tot
                          from (select  orders.order_id, customer_id, product_id, quantity, item_id
                                  from orders, order_items
                                  where orders.order_id = order_items.order_id)
                          GROUP BY customer_id, product_id )
                          MINUS
                          select a.customer_id, a.product_id, a.tot
                          from (  select DISTINCT customer_id, product_id, count(product_id) * sum (quantity) as tot
                                          from (select  orders.order_id, customer_id, product_id, quantity, item_id
                                                  from orders, order_items
                                                  where orders.order_id = order_items.order_id)
                                          GROUP BY customer_id, product_id )   a,
                                          (  select DISTINCT customer_id, product_id, count(product_id) * sum (quantity) as tot
                                          from (select  orders.order_id, customer_id, product_id, quantity, item_id
                                                  from orders, order_items
                                                  where orders.order_id = order_items.order_id)
                                          GROUP BY customer_id, product_id )   b
                          where a.tot < b.tot)  a,
                          (select order_id, product_id, discount_amount
                                          from order_items
                                          minus
                                          select a.order_id, a.product_id, a.discount_amount
                                          from order_items a, order_items b
                                          where a.product_id = b.product_id
                                          and a.discount_amount< b.discount_amount) b
                          where o.customer_id = a.customer_id and
                                        oi.product_id = a.product_id and
                                        a.product_id = b .product_id and
                                        o.order_id = oi.order_id and
                                        oi.order_id = b.order_id) a
ON (order_id = a.order_id , product_id = a.product_id)
WHERE discount_amount > -1 ;