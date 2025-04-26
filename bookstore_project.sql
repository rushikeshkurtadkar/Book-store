
CREATE TABLE books (
    book_id INT PRIMARY KEY,
    title VARCHAR(255),
    author VARCHAR(255),
    price DECIMAL(5,2),
    stock INT
);

CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    name VARCHAR(255),
    email VARCHAR(255)
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    book_id INT,
    quantity INT,
    order_date DATE,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (book_id) REFERENCES books(book_id)
);

INSERT INTO books (book_id, title, author, price, stock) VALUES
(1, 'The Alchemist', 'Paulo Coelho', 9.99, 12),
(2, '1984', 'George Orwell', 8.99, 8),
(3, 'To Kill a Mockingbird', 'Harper Lee', 7.50, 5),
(4, 'One Piece Vol.1', 'Eiichiro Oda', 6.00, 20);

INSERT INTO customers (customer_id, name, email) VALUES
(1, 'Monkey D. Luffy', 'luffy@example.com'),
(2, 'Roronoa Zoro', 'zoro@example.com');

INSERT INTO orders (order_id, customer_id, book_id, quantity, order_date) VALUES
(1, 1, 4, 2, '2025-04-25'),
(2, 2, 1, 1, '2025-04-26');

DELIMITER //
CREATE TRIGGER reduce_stock
AFTER INSERT ON orders
FOR EACH ROW
BEGIN
    UPDATE books
    SET stock = stock - NEW.quantity
    WHERE book_id = NEW.book_id;
END;
//
DELIMITER ;

CREATE VIEW low_stock_books AS
SELECT title, stock
FROM books
WHERE stock <= 5;

DELIMITER //
CREATE PROCEDURE place_order(
    IN p_customer_id INT,
    IN p_book_id INT,
    IN p_quantity INT
)
BEGIN
    DECLARE current_stock INT;
    SELECT stock INTO current_stock FROM books WHERE book_id = p_book_id;
    IF current_stock >= p_quantity THEN
        INSERT INTO orders (order_id, customer_id, book_id, quantity, order_date)
        VALUES (
            (SELECT IFNULL(MAX(order_id), 0) + 1 FROM orders),
            p_customer_id, p_book_id, p_quantity, CURDATE()
        );
    ELSE
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Not enough stock!';
    END IF;
END;
//
DELIMITER ;

SELECT 
    o.order_id,
    c.name,
    b.title,
    o.quantity,
    o.order_date
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN books b ON o.book_id = b.book_id;
