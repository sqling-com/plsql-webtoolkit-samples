-- AppDoc: the written half of the Northwind documentation.
--
-- The harvest (owart.harvest --forms) records what the seven Northwind modules say about
-- themselves -- screens, items, types, rules, tables.  This adds what a person writes:
-- the application's description, each form's description and help, and each field's
-- description.  It runs after the harvest and finds rows by application, screen code and
-- item name, so it does not care which ids the harvest was given.
SET DEFINE OFF

UPDATE app SET app_description =
  'Northwind Traders, the classic order-entry sample, as seven Oracle Forms modules: customers and their orders, '
  || 'orders and their lines, products, suppliers, employees and the lookup tables. NW_MAIN is the starting form.',
  app_schema = 'MAIN'
WHERE app_id = 'NW';

-- FORMS ------------------------------------------------------------------------------------

UPDATE screen SET
  screen_description = 'The starting form: a menu that opens each of the other Northwind forms. It reads and writes no tables.',
  screen_help = '<p>Choose the form you want to work in. Each button opens that form; closing it brings you back here.</p>'
    || '<ul><li><b>Customers</b> &ndash; companies that place orders, with their order history.</li>'
    || '<li><b>Orders</b> &ndash; orders and their lines.</li>'
    || '<li><b>Products</b> &ndash; what is sold, with price and stock.</li>'
    || '<li><b>Suppliers</b> &ndash; who supplies the products.</li>'
    || '<li><b>Employees</b> &ndash; the staff who take orders.</li>'
    || '<li><b>Lookups</b> &ndash; categories, shippers, regions and territories.</li></ul>'
    || '<p><b>Exit</b> leaves the application.</p>'
WHERE app_id = 'NW' AND screen_code = 'NW_MAIN';

UPDATE screen SET
  screen_description = 'Maintains CUSTOMERS. A second, read-only block lists the customer''s orders, newest first, '
    || 'from ORDERS (joined on CUSTOMERID).',
  screen_help = '<p>Look up, add, change or remove a customer.</p>'
    || '<ul><li><b>Find a customer</b>: press <b>Enter Query</b>, type part of any field (for example the company name), '
    || 'then <b>Execute Query</b>. Use the arrow keys or scroll to move between the customers found.</li>'
    || '<li><b>Add a customer</b>: press <b>New</b>, type a five-letter <b>Customer ID</b> and the company details, then <b>Save</b>.</li>'
    || '<li><b>Change</b> any field and press <b>Save</b>. <b>Delete</b> removes the current customer.</li></ul>'
    || '<p>The <b>Orders for this customer</b> list underneath is for reference: it shows the customer''s orders, newest first, '
    || 'and cannot be changed here. Use the Orders form to work on an order.</p>'
WHERE app_id = 'NW' AND screen_code = 'NW_CUSTOMERS';

UPDATE screen SET
  screen_description = 'Maintains ORDERS and their lines in "Order Details" (master-detail on ORDERID). Customers, employees '
    || 'and products are chosen from lists of values; shippers from a list. The order total and each line total are calculated.',
  screen_help = '<p>Enter and maintain customer orders and the products on them.</p>'
    || '<ul><li><b>Find an order</b>: press <b>Enter Query</b>, type an order ID, a customer ID or a date, then <b>Execute Query</b>.</li>'
    || '<li><b>New order</b>: press <b>New</b>. The order ID is assigned when you save. Choose the <b>Customer</b> and <b>Employee</b> '
    || 'with the <b>...</b> buttons, pick a shipper in <b>Ship Via</b>, and fill in the dates and shipping address.</li>'
    || '<li><b>Lines</b>: press <b>New line</b>, then <b>Pick product...</b> to choose a product; its unit price is filled in for you. '
    || 'Enter the quantity and any discount (0.15 is 15%). <b>Delete line</b> removes the current line.</li>'
    || '<li>Press <b>Save</b> to save the order and all its lines together.</li></ul>'
    || '<p><b>Order Total</b> adds up the lines (price &times; quantity, less discount); <b>Line Total</b> shows one line.</p>'
WHERE app_id = 'NW' AND screen_code = 'NW_ORDERS';

UPDATE screen SET
  screen_description = 'Maintains PRODUCTS. The supplier is chosen from a list of values over SUPPLIERS and the category '
    || 'from a list of the CATEGORIES.',
  screen_help = '<p>Maintain the products Northwind sells.</p>'
    || '<ul><li><b>Find a product</b>: <b>Enter Query</b>, type part of the name (or a category or supplier), <b>Execute Query</b>.</li>'
    || '<li><b>New product</b>: press <b>New</b>, give it a name, choose its <b>Supplier</b> with the <b>...</b> button and its '
    || '<b>Category</b> from the list, then the price and stock figures, and <b>Save</b>. The product ID is assigned on save.</li>'
    || '<li>Tick <b>Discontinued</b> for a product that is no longer sold; it stays on old orders.</li></ul>'
    || '<p><b>Reorder Level</b> is the stock level at which more should be ordered.</p>'
WHERE app_id = 'NW' AND screen_code = 'NW_PRODUCTS';

UPDATE screen SET
  screen_description = 'Maintains SUPPLIERS. A second, read-only block lists the supplier''s products from PRODUCTS '
    || '(joined on SUPPLIERID).',
  screen_help = '<p>Maintain the companies that supply Northwind''s products.</p>'
    || '<ul><li><b>Find a supplier</b>: <b>Enter Query</b>, type part of the company name, country or any other field, '
    || '<b>Execute Query</b>.</li>'
    || '<li><b>New supplier</b>: press <b>New</b>, fill in the company name and contact details, <b>Save</b>. '
    || 'The supplier ID is assigned on save.</li></ul>'
    || '<p>The <b>Products from this supplier</b> list is for reference. Use the Products form to change a product.</p>'
WHERE app_id = 'NW' AND screen_code = 'NW_SUPPLIERS';

UPDATE screen SET
  screen_description = 'Maintains EMPLOYEES on three tab pages (Personal, Address, Notes). Reports To is chosen from a '
    || 'list of values over EMPLOYEES and shown by name.',
  screen_help = '<p>Maintain Northwind''s staff.</p>'
    || '<ul><li><b>Find an employee</b>: <b>Enter Query</b>, type part of the last name or any other field, <b>Execute Query</b>.</li>'
    || '<li><b>New employee</b>: press <b>New</b>, enter at least the first and last name, and <b>Save</b>. '
    || 'The employee ID is assigned on save.</li>'
    || '<li>The fields are on three tabs: <b>Personal</b> (name, title, dates, manager), <b>Address</b> (address and phone) '
    || 'and <b>Notes</b>.</li>'
    || '<li><b>Reports To</b>: press <b>...</b> to choose the employee&rsquo;s manager from the list.</li></ul>'
WHERE app_id = 'NW' AND screen_code = 'NW_EMPLOYEES';

UPDATE screen SET
  screen_description = 'Maintains the small lookup tables on four tab pages, each a grid: CATEGORIES, SHIPPERS, REGIONS '
    || 'and TERRITORIES.',
  screen_help = '<p>Maintain the lists the other forms choose from. Each tab is one list, shown as a grid.</p>'
    || '<ul><li><b>Categories</b> &ndash; the product categories offered on the Products form.</li>'
    || '<li><b>Shippers</b> &ndash; the shipping companies offered in Ship Via on the Orders form.</li>'
    || '<li><b>Regions</b> and <b>Territories</b> &ndash; sales regions, and the territories within each.</li></ul>'
    || '<p>Press <b>New</b> to add a row to the current tab, change any cell in place, and press <b>Save</b>. '
    || 'Ids are assigned on save, except a territory&rsquo;s, which you type.</p>'
WHERE app_id = 'NW' AND screen_code = 'NW_LOOKUPS';

-- FIELDS: shared wording first, by item name or column, then each form's own -----------------

UPDATE screen_item SET item_description = 'Save all changes made in the form.'
WHERE item_name = 'TOOLBAR.PB_SAVE' AND screen_id IN (SELECT screen_id FROM screen WHERE app_id = 'NW');
UPDATE screen_item SET item_description = 'Start a new, empty record in the current block.'
WHERE item_name = 'TOOLBAR.PB_NEW' AND screen_id IN (SELECT screen_id FROM screen WHERE app_id = 'NW');
UPDATE screen_item SET item_description = 'Remove the current record (it is deleted from the database when you save).'
WHERE item_name = 'TOOLBAR.PB_DELETE' AND screen_id IN (SELECT screen_id FROM screen WHERE app_id = 'NW');
UPDATE screen_item SET item_description = 'Clear the form for typing search criteria.'
WHERE item_name = 'TOOLBAR.PB_ENTER_QUERY' AND screen_id IN (SELECT screen_id FROM screen WHERE app_id = 'NW');
UPDATE screen_item SET item_description = 'Find the records that match what is typed (or all of them).'
WHERE item_name = 'TOOLBAR.PB_EXECUTE_QUERY' AND screen_id IN (SELECT screen_id FROM screen WHERE app_id = 'NW');
UPDATE screen_item SET item_description = 'Close this form and return to the menu.'
WHERE item_name = 'TOOLBAR.PB_CLOSE' AND screen_id IN (SELECT screen_id FROM screen WHERE app_id = 'NW');

UPDATE screen_item SET item_description = 'Street address.'
WHERE item_column_name IN ('ADDRESS', 'SHIPADDRESS') AND screen_id IN (SELECT screen_id FROM screen WHERE app_id = 'NW');
UPDATE screen_item SET item_description = 'City.'
WHERE item_column_name IN ('CITY', 'SHIPCITY') AND screen_id IN (SELECT screen_id FROM screen WHERE app_id = 'NW');
UPDATE screen_item SET item_description = 'State, province or region, where the country uses one.'
WHERE item_column_name IN ('REGION', 'SHIPREGION') AND screen_id IN (SELECT screen_id FROM screen WHERE app_id = 'NW');
UPDATE screen_item SET item_description = 'Postal or ZIP code.'
WHERE item_column_name IN ('POSTALCODE', 'SHIPPOSTALCODE') AND screen_id IN (SELECT screen_id FROM screen WHERE app_id = 'NW');
UPDATE screen_item SET item_description = 'Country.'
WHERE item_column_name IN ('COUNTRY', 'SHIPCOUNTRY') AND screen_id IN (SELECT screen_id FROM screen WHERE app_id = 'NW');
UPDATE screen_item SET item_description = 'Telephone number, written as is usual in its country.'
WHERE item_column_name = 'PHONE' AND screen_id IN (SELECT screen_id FROM screen WHERE app_id = 'NW');
UPDATE screen_item SET item_description = 'Fax number.'
WHERE item_column_name = 'FAX' AND screen_id IN (SELECT screen_id FROM screen WHERE app_id = 'NW');
UPDATE screen_item SET item_description = 'The person to deal with at the company.'
WHERE item_column_name = 'CONTACTNAME' AND screen_id IN (SELECT screen_id FROM screen WHERE app_id = 'NW');
UPDATE screen_item SET item_description = 'The contact''s job title.'
WHERE item_column_name = 'CONTACTTITLE' AND screen_id IN (SELECT screen_id FROM screen WHERE app_id = 'NW');

-- One form's fields: UPDATE ... SET item_description = <text> WHERE the form and item match.
-- Written as a list the procedure below applies, so each line reads as "item: description".
CREATE OR REPLACE PROCEDURE nw_doc(p_screen VARCHAR2, p_item VARCHAR2, p_text VARCHAR2) IS
BEGIN
  UPDATE screen_item SET item_description = p_text
   WHERE item_name = p_item
     AND screen_id = (SELECT screen_id FROM screen WHERE app_id = 'NW' AND screen_code = p_screen);
END;
/

BEGIN
  -- NW_MAIN
  nw_doc('NW_MAIN', 'MENU.PB_CUSTOMERS', 'Open the Customers form.');
  nw_doc('NW_MAIN', 'MENU.PB_ORDERS', 'Open the Orders form.');
  nw_doc('NW_MAIN', 'MENU.PB_PRODUCTS', 'Open the Products form.');
  nw_doc('NW_MAIN', 'MENU.PB_SUPPLIERS', 'Open the Suppliers form.');
  nw_doc('NW_MAIN', 'MENU.PB_EMPLOYEES', 'Open the Employees form.');
  nw_doc('NW_MAIN', 'MENU.PB_LOOKUPS', 'Open the Lookups form: categories, shippers, regions and territories.');
  nw_doc('NW_MAIN', 'MENU.PB_EXIT', 'Leave the application.');

  -- NW_CUSTOMERS
  nw_doc('NW_CUSTOMERS', 'CUSTOMERS.CUSTOMERID', 'The customer''s five-letter code, typed when the customer is added and kept in capitals; it identifies the customer on orders.');
  nw_doc('NW_CUSTOMERS', 'CUSTOMERS.COMPANYNAME', 'The customer''s company name; the list is in this order.');
  nw_doc('NW_CUSTOMERS', 'ORDERS.CUSTOMERID', 'Links each listed order to the customer above; not shown.');
  nw_doc('NW_CUSTOMERS', 'ORDERS.ORDERID', 'The order''s number.');
  nw_doc('NW_CUSTOMERS', 'ORDERS.ORDERDATE', 'When the order was placed; the list is newest first.');
  nw_doc('NW_CUSTOMERS', 'ORDERS.SHIPPEDDATE', 'When the order was shipped; empty if it has not been.');
  nw_doc('NW_CUSTOMERS', 'ORDERS.FREIGHT', 'Shipping charge for the order.');
  nw_doc('NW_CUSTOMERS', 'ORDERS.SHIPNAME', 'Who the order was shipped to.');
  nw_doc('NW_CUSTOMERS', 'ORDERS.SHIPCITY', 'City the order was shipped to.');
  nw_doc('NW_CUSTOMERS', 'ORDERS.SHIPCOUNTRY', 'Country the order was shipped to.');

  -- NW_ORDERS
  nw_doc('NW_ORDERS', 'ORDERS.ORDERID', 'The order''s number, assigned when a new order is saved (one more than the highest so far).');
  nw_doc('NW_ORDERS', 'ORDERS.CUSTOMERID', 'The customer placing the order, chosen from the customer list (the ... button); typed IDs are kept in capitals.');
  nw_doc('NW_ORDERS', 'ORDERS.CUSTOMER_NAME', 'The chosen customer''s company name, shown for reference.');
  nw_doc('NW_ORDERS', 'ORDERS.EMPLOYEEID', 'The employee who took the order, chosen from the employee list.');
  nw_doc('NW_ORDERS', 'ORDERS.EMPLOYEE_NAME', 'The chosen employee''s name, shown for reference.');
  nw_doc('NW_ORDERS', 'ORDERS.ORDERDATE', 'When the order was placed.');
  nw_doc('NW_ORDERS', 'ORDERS.REQUIREDDATE', 'When the customer needs the order.');
  nw_doc('NW_ORDERS', 'ORDERS.SHIPPEDDATE', 'When the order was shipped; leave empty until it is.');
  nw_doc('NW_ORDERS', 'ORDERS.SHIPVIA', 'The shipping company: Speedy Express, United Package or Federal Shipping.');
  nw_doc('NW_ORDERS', 'ORDERS.FREIGHT', 'Shipping charge for the order.');
  nw_doc('NW_ORDERS', 'ORDERS.SHIPNAME', 'Name to ship the order to.');
  nw_doc('NW_ORDERS', 'ORDERS.ORDER_TOTAL', 'The value of the order: each line''s unit price times quantity, less its discount, added up. Calculated when the order is fetched.');
  nw_doc('NW_ORDERS', 'ORDER_DETAILS.ORDERID', 'Links each line to the order above; filled in automatically and not shown.');
  nw_doc('NW_ORDERS', 'ORDER_DETAILS.PRODUCTID', 'The product on this line, chosen with Pick product...; choosing one also fills in its unit price.');
  nw_doc('NW_ORDERS', 'ORDER_DETAILS.PRODUCT_NAME', 'The chosen product''s name, shown for reference.');
  nw_doc('NW_ORDERS', 'ORDER_DETAILS.UNITPRICE', 'Price of one unit on this order; taken from the product, and can be changed.');
  nw_doc('NW_ORDERS', 'ORDER_DETAILS.QUANTITY', 'How many units are ordered (1 for a new line).');
  nw_doc('NW_ORDERS', 'ORDER_DETAILS.DISCOUNT', 'Discount on the line as a fraction: 0.15 is 15% off (0 for a new line).');
  nw_doc('NW_ORDERS', 'ORDER_DETAILS.LINE_TOTAL', 'Unit price times quantity, less the discount.');
  nw_doc('NW_ORDERS', 'TOOLBAR.PB_CUSTOMER_LOV', 'Choose the customer from a list.');
  nw_doc('NW_ORDERS', 'TOOLBAR.PB_EMPLOYEE_LOV', 'Choose the employee from a list.');
  nw_doc('NW_ORDERS', 'TOOLBAR.PB_PRODUCT_LOV', 'Choose the current line''s product from a list.');
  nw_doc('NW_ORDERS', 'TOOLBAR.PB_NEW_LINE', 'Add a line to the order.');
  nw_doc('NW_ORDERS', 'TOOLBAR.PB_DELETE_LINE', 'Remove the current line from the order (when you save).');

  -- NW_PRODUCTS
  nw_doc('NW_PRODUCTS', 'PRODUCTS.PRODUCTID', 'The product''s number, assigned when a new product is saved.');
  nw_doc('NW_PRODUCTS', 'PRODUCTS.PRODUCTNAME', 'The product''s name; the list is in this order.');
  nw_doc('NW_PRODUCTS', 'PRODUCTS.SUPPLIERID', 'The supplier of the product, chosen from the supplier list (the ... button).');
  nw_doc('NW_PRODUCTS', 'PRODUCTS.SUPPLIER_NAME', 'The chosen supplier''s company name, shown for reference.');
  nw_doc('NW_PRODUCTS', 'PRODUCTS.CATEGORYID', 'The product''s category, chosen from the list (Beverages, Condiments, Confections ...).');
  nw_doc('NW_PRODUCTS', 'PRODUCTS.QUANTITYPERUNIT', 'What one unit is, for example "24 - 12 oz bottles".');
  nw_doc('NW_PRODUCTS', 'PRODUCTS.UNITPRICE', 'Current price of one unit; new order lines start from this price.');
  nw_doc('NW_PRODUCTS', 'PRODUCTS.UNITSINSTOCK', 'Units on hand.');
  nw_doc('NW_PRODUCTS', 'PRODUCTS.UNITSONORDER', 'Units ordered from the supplier and not yet received.');
  nw_doc('NW_PRODUCTS', 'PRODUCTS.REORDERLEVEL', 'Stock level at which more should be ordered.');
  nw_doc('NW_PRODUCTS', 'PRODUCTS.DISCONTINUED', 'Ticked when the product is no longer sold.');
  nw_doc('NW_PRODUCTS', 'TOOLBAR.PB_SUPPLIER_LOV', 'Choose the supplier from a list.');

  -- NW_SUPPLIERS
  nw_doc('NW_SUPPLIERS', 'SUPPLIERS.SUPPLIERID', 'The supplier''s number, assigned when a new supplier is saved.');
  nw_doc('NW_SUPPLIERS', 'SUPPLIERS.COMPANYNAME', 'The supplier''s company name; the list is in this order.');
  nw_doc('NW_SUPPLIERS', 'SUPPLIERS.HOMEPAGE', 'The supplier''s web site.');
  nw_doc('NW_SUPPLIERS', 'PRODUCTS.SUPPLIERID', 'Links each listed product to the supplier above; not shown.');
  nw_doc('NW_SUPPLIERS', 'PRODUCTS.PRODUCTID', 'The product''s number.');
  nw_doc('NW_SUPPLIERS', 'PRODUCTS.PRODUCTNAME', 'The product''s name.');
  nw_doc('NW_SUPPLIERS', 'PRODUCTS.QUANTITYPERUNIT', 'What one unit of the product is.');
  nw_doc('NW_SUPPLIERS', 'PRODUCTS.UNITPRICE', 'Current price of one unit.');
  nw_doc('NW_SUPPLIERS', 'PRODUCTS.UNITSINSTOCK', 'Units on hand.');

  -- NW_EMPLOYEES
  nw_doc('NW_EMPLOYEES', 'EMPLOYEES.EMPLOYEEID', 'The employee''s number, assigned when a new employee is saved.');
  nw_doc('NW_EMPLOYEES', 'EMPLOYEES.LASTNAME', 'Family name; the list is in last-name, first-name order.');
  nw_doc('NW_EMPLOYEES', 'EMPLOYEES.FIRSTNAME', 'Given name.');
  nw_doc('NW_EMPLOYEES', 'EMPLOYEES.TITLE', 'Job title.');
  nw_doc('NW_EMPLOYEES', 'EMPLOYEES.TITLEOFCOURTESY', 'How to address the employee: Mr., Ms., Dr. ...');
  nw_doc('NW_EMPLOYEES', 'EMPLOYEES.BIRTHDATE', 'Date of birth.');
  nw_doc('NW_EMPLOYEES', 'EMPLOYEES.HIREDATE', 'Date the employee started.');
  nw_doc('NW_EMPLOYEES', 'EMPLOYEES.REPORTSTO', 'The employee''s manager, chosen from the employee list (the ... button); empty for the head of the company.');
  nw_doc('NW_EMPLOYEES', 'EMPLOYEES.MANAGER_NAME', 'The manager''s name, shown for reference.');
  nw_doc('NW_EMPLOYEES', 'EMPLOYEES.HOMEPHONE', 'Home telephone number.');
  nw_doc('NW_EMPLOYEES', 'EMPLOYEES.EXTENSION', 'Office telephone extension.');
  nw_doc('NW_EMPLOYEES', 'EMPLOYEES.NOTES', 'Free-form notes about the employee (on the Notes tab).');
  nw_doc('NW_EMPLOYEES', 'EMPLOYEES.PHOTOPATH', 'Where the employee''s photograph is kept.');
  nw_doc('NW_EMPLOYEES', 'TOOLBAR.PB_MANAGER_LOV', 'Choose the manager (Reports To) from a list.');

  -- NW_LOOKUPS
  nw_doc('NW_LOOKUPS', 'CATEGORIES.CATEGORYID', 'The category''s number, assigned on save.');
  nw_doc('NW_LOOKUPS', 'CATEGORIES.CATEGORYNAME', 'The category''s name, as the Products form lists it.');
  nw_doc('NW_LOOKUPS', 'CATEGORIES.DESCRIPTION', 'What the category covers.');
  nw_doc('NW_LOOKUPS', 'SHIPPERS.SHIPPERID', 'The shipper''s number, assigned on save; orders refer to it in Ship Via.');
  nw_doc('NW_LOOKUPS', 'SHIPPERS.COMPANYNAME', 'The shipping company''s name.');
  nw_doc('NW_LOOKUPS', 'REGIONS.REGIONID', 'The region''s number, assigned on save.');
  nw_doc('NW_LOOKUPS', 'REGIONS.REGIONDESCRIPTION', 'The sales region''s name (Eastern, Western, Northern, Southern).');
  nw_doc('NW_LOOKUPS', 'TERRITORIES.TERRITORYID', 'The territory''s code (its ZIP code), typed when the territory is added.');
  nw_doc('NW_LOOKUPS', 'TERRITORIES.TERRITORYDESCRIPTION', 'The territory''s name: the town or city it is centred on.');
  nw_doc('NW_LOOKUPS', 'TERRITORIES.REGIONID', 'The number of the region the territory belongs to (see the Regions tab).');
END;
/

DROP PROCEDURE nw_doc;
COMMIT;
