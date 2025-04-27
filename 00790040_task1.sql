-- Create Database called Airport
CREATE DATABASE Airport;
USE Airport;

-- Create tables in Airport database 
CREATE TABLE Passengers (PassengerID int IDENTITY(1,1) PRIMARY KEY, PassengerFirstName nvarchar(50) NOT NULL, 
PassengerLastName nvarchar(50) NOT NULL, PassengerEmail nvarchar(100) NOT NULL CHECK (PassengerEmail LIKE '%_@_%._%'),
PassengerDOB date NOT NULL, EmergencyContact nvarchar(50) NULL, Meal nvarchar(50) NOT NULL); 

CREATE TABLE Flights (FlightID int IDENTITY(1,1) PRIMARY KEY, FlightNumber int NOT NULL, Depart datetime NOT NULL, 
Arrive datetime NOT NULL, Origin nvarchar(50) NOT NULL, Destination nvarchar(50) NOT NULL);

CREATE TABLE Reservations (ReservationID int IDENTITY(1,1) PRIMARY KEY, Status nvarchar(50) NOT NULL, 
Date date NOT NULL, FlightID int NOT NULL FOREIGN KEY REFERENCES Flights (FlightID));

CREATE TABLE PassengerReservations (PassengerID int NOT NULL FOREIGN KEY REFERENCES Passengers (PassengerID),
ReservationID int NOT NULL FOREIGN KEY REFERENCES Reservations (ReservationID),
PRIMARY KEY (PassengerID, ReservationID), PrefSeat nvarchar(10) NULL CHECK (PrefSeat LIKE '___'));

CREATE TABLE Tickets (TicketID int IDENTITY(1,1) PRIMARY KEY, IssueDate date NOT NULL, IssueTime time NOT NULL, 
Fare money NOT NULL, Seat nvarchar(10) NOT NULL, Class nvarchar(20) NOT NULL, 
PassengerID int NOT NULL FOREIGN KEY REFERENCES Passengers (PassengerID), 
ReservationID int NOT NULL FOREIGN KEY REFERENCES Reservations (ReservationID),
CONSTRAINT UQ_Tickets_Passenger_Reservation UNIQUE (PassengerID, ReservationID));

CREATE TABLE Baggage (BaggageID INT IDENTITY(1,1) PRIMARY KEY,
Weight DECIMAL(6, 3) NULL, Status NVARCHAR(10) NULL,
PassengerID INT NOT NULL, ReservationID INT NOT NULL,
CONSTRAINT FK_Baggage_PassengerReservations FOREIGN KEY (PassengerID, ReservationID)
REFERENCES PassengerReservations(PassengerID, ReservationID));

CREATE TABLE Employees (EmployeeID int IDENTITY(1,1) PRIMARY KEY NOT NULL, 
Username nvarchar(40) UNIQUE NOT NULL,
PasswordHash binary(64) NOT NULL, Salt UNIQUEIDENTIFIER,
FirstName nvarchar(40) NOT NULL, LastName nvarchar(40) NOT NULL, 
EmployeeEmail nvarchar(100) NOT NULL CHECK (EmployeeEmail LIKE '%_@_%._%'));

CREATE TABLE EBoarding (EBoardingNumber INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
PassengerID INT NOT NULL FOREIGN KEY REFERENCES Passengers(PassengerID),
TicketID INT UNIQUE NOT NULL FOREIGN KEY REFERENCES Tickets(TicketID),
EmployeeID INT NOT NULL FOREIGN KEY REFERENCES Employees(EmployeeID),
Taxes MONEY NOT NULL DEFAULT 0.0, BaggageFee MONEY NOT NULL DEFAULT 0.0,
MealUpgrade INT NOT NULL DEFAULT 0 CHECK (MealUpgrade = 1 OR MealUpgrade = 0),
MealUpgradeFee MONEY CONSTRAINT EBMealUpgradeFee DEFAULT 20.00,
PrefSeat INT NOT NULL DEFAULT 0 CHECK (PrefSeat = 1 OR PrefSeat = 0),
PrefSeatFee MONEY CONSTRAINT EBPrefSeatFee DEFAULT 30.00,
TotalAddFare AS (Taxes + BaggageFee + (MealUpgrade * MealUpgradeFee) + (PrefSeat * PrefSeatFee)));

--Create Ticket Reservation Module (trm) schema

CREATE SCHEMA trm;

ALTER SCHEMA trm TRANSFER dbo.Passengers;
ALTER SCHEMA trm TRANSFER dbo.PassengerReservations;
ALTER SCHEMA trm TRANSFER dbo.Reservations;
ALTER SCHEMA trm TRANSFER dbo.Tickets;
ALTER SCHEMA trm TRANSFER dbo.Baggage;
ALTER SCHEMA trm TRANSFER dbo.EBoarding;

-- Create stored procedure to add new employees to the Employees table 
CREATE PROCEDURE uspAddEmployee 
@username NVARCHAR(50), @password NVARCHAR(50), @firstname NVARCHAR(40), @lastname NVARCHAR(40), @employeeemail nvarchar(100)
AS
DECLARE @salt UNIQUEIDENTIFIER=NEWID()
INSERT INTO Employees(Username, PasswordHash, Salt, FirstName, LastName, EmployeeEmail)
VALUES(@username, HASHBYTES('SHA2_512',
@password+CAST(@salt AS NVARCHAR(36))), @salt, @firstname, @lastname, @employeeemail);

-- Use stored procedure to poplate Employees table 
EXECUTE uspAddEmployee @username = 'MM101', @password = 'MM101!', 
@firstname='Molly', @lastname= 'Monday', @employeeemail = 'Molly@airport.com'

EXECUTE uspAddEmployee @username = 'TT102', @password = 'TT102!', 
@firstname='Tracy', @lastname= 'Tuesday', @employeeemail = 'Tracy@airport.com'

EXECUTE uspAddEmployee @username = 'WW103', @password = 'WW103!', 
@firstname='Wendy', @lastname= 'Wednesday', @employeeemail = 'Wendy@airport.com'

EXECUTE uspAddEmployee @username = 'TT104', @password = 'TT104!', 
@firstname='Thandi', @lastname= 'Thursday', @employeeemail = 'Thandi@airport.com'

EXECUTE uspAddEmployee @username = 'FF105', @password = 'FF105!', 
@firstname='Freddy', @lastname= 'Friday', @employeeemail = 'Freddy@airport.com'

EXECUTE uspAddEmployee @username = 'SS106', @password = 'SS106!', 
@firstname='Sally', @lastname= 'Saturday', @employeeemail = 'Sally@airport.com'

EXECUTE uspAddEmployee @username = 'SS107', @password = 'SS107!', 
@firstname='Suzy', @lastname= 'Sunday', @employeeemail = 'Suzy@airport.com'

SELECT * FROM Employees

--Create logins and users for all employees 
CREATE LOGIN MM101 WITH PASSWORD = 'MM101!';

CREATE LOGIN TT102 WITH PASSWORD = 'TT102!';

CREATE LOGIN WW103 WITH PASSWORD = 'WW103!';

CREATE LOGIN TT104 WITH PASSWORD = 'TT104!';

CREATE LOGIN FF105 WITH PASSWORD = 'FF105!';

CREATE LOGIN SS106 WITH PASSWORD = 'SS106!';

CREATE LOGIN SS107 WITH PASSWORD = 'SS107!';

CREATE USER MM101 FOR LOGIN MM101;

CREATE USER TT102 FOR LOGIN TT102;

CREATE USER WW103 FOR LOGIN WW103;

CREATE USER TT104 FOR LOGIN TT104;

CREATE USER FF105 FOR LOGIN FF105;

CREATE USER SS106 FOR LOGIN SS106;

CREATE USER SS107 FOR LOGIN SS107;

--Create roles (supervisors and staff) and grant permissions 

CREATE ROLE Staff;
GRANT SELECT, UPDATE, INSERT, DELETE ON SCHEMA :: trm
TO Staff
GRANT SELECT ON dbo.Flights
TO Staff

CREATE ROLE Supervisor;
GRANT SELECT, UPDATE, INSERT, DELETE ON SCHEMA :: trm
TO Supervisor WITH GRANT OPTION
GRANT SELECT, UPDATE, INSERT, DELETE ON dbo.Employees
TO Supervisor WITH GRANT OPTION
GRANT SELECT ON dbo.Flights
TO Supervisor WITH GRANT OPTION;

ALTER ROLE Supervisor ADD MEMBER MM101;
ALTER ROLE Supervisor ADD MEMBER TT102;

ALTER ROLE Staff ADD MEMBER WW103;
ALTER ROLE Staff ADD MEMBER TT104;
ALTER ROLE Staff ADD MEMBER FF105;
ALTER ROLE Staff ADD MEMBER SS106;
ALTER ROLE Staff ADD MEMBER SS107;

-- Populate trm.Passengers table
INSERT INTO trm.Passengers VALUES ('Donny', 'Doc', 'Donny@passenger.com', '1980-01-01', 'Snow White', 'Vegetarian');

INSERT INTO trm.Passengers VALUES ('Garry', 'Grumpy', 'Garry@passenger.com', '1999-01-01', 'Snow White', 'Non-Vegetarian');

INSERT INTO trm.Passengers VALUES ('Harry', 'Happy', 'Harry@passenger.com', '1998-01-01', 'Snow White', 'Vegetarian');

INSERT INTO trm.Passengers VALUES ('Sammy', 'Sleepy', 'Sammy@passenger.com', '1997-01-01', 'Snow White', 'Non-Vegetarian');

INSERT INTO trm.Passengers VALUES ('Barry', 'Bashful', 'Barry@passenger.com', '1996-01-01', 'Snow White', 'Vegetarian');

INSERT INTO trm.Passengers VALUES ('Scotty', 'Sneezy', 'Scotty@passenger.com', '1995-01-01', 'Snow White', 'Non-Vegetarian');

INSERT INTO trm.Passengers (PassengerFirstName, PassengerLastName, PassengerEmail, PassengerDOB, Meal)
VALUES ('Danny', 'Dopey', 'Danny@passenger.com', '1994-01-01', 'Vegetarian');

SELECT * FROM trm.Passengers;

-- Populate Flights table
INSERT INTO Flights VALUES ('100', '2026-04-22 10:34:00', '2026-04-22 11:34:00', 'London', 'Paris');

INSERT INTO Flights VALUES ('200', '2026-03-22 07:34:00', '2026-03-22 15:34:00', 'London', 'New York');

INSERT INTO Flights VALUES ('300', '2026-03-22 16:34:00', '2026-03-22 19:20:00', 'New York', 'Los Angeles');

INSERT INTO Flights VALUES ('400', '2026-03-30 12:34:00', '2026-03-30 13:20:00', 'Paris', 'London');

INSERT INTO Flights VALUES ('500', '2026-04-07 12:34:00', '2026-04-07 13:15:00', 'London', 'Edinburgh');

INSERT INTO Flights VALUES ('600', '2026-04-08 19:34:00', '2026-04-08 21:20:00', 'London', 'Berlin');

INSERT INTO Flights VALUES ('700', '2026-04-09 11:34:00', '2026-04-09 13:20:00', 'London', 'Madrid');

SELECT * FROM Flights

-- Populate Reservations table 
INSERT INTO trm.Reservations VALUES ('confirmed', '2026-04-22',  '1');

INSERT INTO trm.Reservations VALUES ('confirmed', '2026-03-22',  '2');

INSERT INTO trm.Reservations VALUES ('confirmed', '2026-03-22',  '3');

INSERT INTO trm.Reservations VALUES ('pending', '2026-03-30',  '4');

INSERT INTO trm.Reservations VALUES ('cancelled', '2026-04-08',  '5');

INSERT INTO trm.Reservations VALUES ('pending', '2026-04-09',  '7');

INSERT INTO trm.Reservations VALUES ('pending', '2026-04-09',  '7');

SELECT * FROM trm.Reservations;


-- Populate PassengerReservations table 

INSERT INTO trm.PassengerReservations VALUES ('1', '1', '10B');

INSERT INTO trm.PassengerReservations VALUES ('2', '2', '10C');

INSERT INTO trm.PassengerReservations VALUES ('2', '3', '09A');

INSERT INTO trm.PassengerReservations VALUES ('3', '4', '10B');

INSERT INTO trm.PassengerReservations VALUES ('4', '4', '10B');

INSERT INTO trm.PassengerReservations (PassengerID, ReservationID) VALUES ('6', '6');

INSERT INTO trm.PassengerReservations (PassengerID, ReservationID) VALUES ('7', '7');

SELECT * FROM trm.PassengerReservations;

-- Populate Tickets table 
INSERT INTO trm.Tickets VALUES ('2026-04-22', '07:00:00', '100.00', '10B', 'business,', '1', '1');

INSERT INTO trm.Tickets VALUES ('2026-04-22', '07:00:00', '100.00', '10C', 'business', '2', '2');

INSERT INTO trm.Tickets VALUES ('2026-03-22', '06:00:00', '600.00', '9A', 'business', '2', '3');

INSERT INTO trm.Tickets VALUES ('2026-04-08', '16:00:00', '150.00', '45A', 'economy', '6', '6');

SELECT * FROM trm.Tickets;

-- Populate Baggage table 
INSERT INTO trm.Baggage VALUES ('30.55', 'checked-in', '1', '1');

INSERT INTO trm.Baggage VALUES ('10.55', 'loaded', '1', '1');

INSERT INTO trm.Baggage VALUES ('15.00', 'loaded', '2', '2');

INSERT INTO trm.Baggage VALUES ('15.00', 'loaded', '2', '3');

INSERT INTO trm.Baggage VALUES ('41.00', 'loaded', '6', '6');

SELECT * FROM trm.Baggage;

-- Populate EBoarding table 

INSERT INTO trm.EBoarding (PassengerID, TicketID, EmployeeID, Taxes, MealUpgrade, PrefSeat) 
VALUES ('1', '1', '1', '10', '1', '1');

INSERT INTO trm.EBoarding (PassengerID, TicketID, EmployeeID, Taxes, MealUpgrade, PrefSeat)
VALUES ('2', '2', '2', '0', '0', '1');

INSERT INTO trm.EBoarding (PassengerID, TicketID, EmployeeID, Taxes, MealUpgrade, PrefSeat)
VALUES ('2', '3', '2', '100', '1', '0');

INSERT INTO trm.EBoarding (PassengerID, TicketID, EmployeeID, Taxes, BaggageFee, MealUpgrade, PrefSeat)
VALUES ('6', '4', '6', '50', '100', '1', '0');

SELECT * FROM trm.EBoarding;

-- Create view for Passenger Name Records (PNRs) 

CREATE VIEW trm.PNR AS
SELECT 
    p.PassengerFirstName, 
    p.PassengerLastName, 
    r.Status, 
    f.FlightNumber, 
    f.Origin, 
    f.Destination, 
    f.Arrive, 
    f.Depart, 
    pr.PrefSeat, 
    eb.EBoardingNumber
FROM trm.Passengers p
JOIN trm.PassengerReservations pr 
    ON p.PassengerID = pr.PassengerID
JOIN trm.Reservations r 
    ON pr.ReservationID = r.ReservationID
JOIN Flights f 
    ON r.FlightID = f.FlightID
LEFT JOIN trm.Tickets t 
    ON t.PassengerID = pr.PassengerID 
    AND t.ReservationID = pr.ReservationID  -- composite key join
LEFT JOIN trm.EBoarding eb 
    ON eb.TicketID = t.TicketID;


SELECT * FROM trm.PNR;


-- Create stored procedure for adding a row to the Tickets and EBoarding tables on ticket issuance 

CREATE PROCEDURE trm.IssueTicketAndEBoarding
    @ReservationID INT,
    @PassengerID INT,
    @FlightID INT,
    @Seat NVARCHAR(10),
    @Class NVARCHAR(20),
    @Fare MONEY,
    @EmployeeID INT,
    @Taxes MONEY = 0,
    @MealUpgrade INT = 0, -- 0 = No, 1 = Yes
    @PrefSeat INT = 0     -- 0 = No, 1 = Yes
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @Today DATE = CAST(GETDATE() AS DATE);
        DECLARE @Now TIME = CAST(GETDATE() AS TIME);
        DECLARE @NewTicketID INT;

        -- Step 1: Insert the ticket into Tickets table
        INSERT INTO trm.Tickets (
            IssueDate, IssueTime, Fare, Seat, Class, PassengerID, ReservationID
        ) VALUES (
            @Today, @Now, @Fare, @Seat, @Class, @PassengerID, @ReservationID
        );

        SET @NewTicketID = SCOPE_IDENTITY();

        -- Step 2: Insert into EBoarding
        INSERT INTO trm.EBoarding (
            PassengerID, TicketID, EmployeeID, Taxes, MealUpgrade, PrefSeat
        ) VALUES (
            @PassengerID, @NewTicketID, @EmployeeID, @Taxes, @MealUpgrade, @PrefSeat
        );
		
		-- Retrieve the generated EBoardingNumber
        DECLARE @NewEBoardingNumber INT = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        -- Return the new EBoardingNumber
        SELECT @NewTicketID AS TicketID, @NewEBoardingNumber AS EBoardingNumber;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END;

--Create trigger to calculate BaggageFee in EBoarding table when new rows inserted into Tickets and EBoarding tables
--(that is, on ticket issuance)

CREATE TRIGGER trm.CalcBaggageFee
ON trm.EBoarding
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE eb
    SET eb.BaggageFee = 
        CASE 
            WHEN ISNULL(b.TotalWeight, 0) <= 40.000 THEN 0
            ELSE (b.TotalWeight - 40.000) * 100
        END
    FROM trm.EBoarding eb
    INNER JOIN inserted i ON eb.EBoardingNumber = i.EBoardingNumber
    INNER JOIN trm.Tickets t ON i.TicketID = t.TicketID
    INNER JOIN (
        SELECT PassengerID, ReservationID, SUM(Weight) AS TotalWeight
        FROM trm.Baggage
        GROUP BY PassengerID, ReservationID
    ) b ON t.PassengerID = b.PassengerID AND t.ReservationID = b.ReservationID;
END;


-- Example of how above stored procedure could be used by airport staff for ticket issuance: 

    --First: employee pulls up passenger's PNR to confirm reservation details 

	SELECT * FROM trm.PNR WHERE PassengerFirstName='Danny' AND PassengerLastName = 'Dopey';

	-- Second: employee adds row to baggage table (once employee has weighed passenger's baggage)

		INSERT INTO trm.Baggage VALUES ('41.00', 'loaded', '7', '7');

    -- Third: employee uses above stored procedure to add rows to the Tickets and EBoarding tables 

EXEC trm.IssueTicketAndEBoarding
    @ReservationID = 7,
    @PassengerID = 7,
    @FlightID = 7,
    @Seat = '1A',
    @Class = 'firstclass',
    @Fare = 350.00,
    @EmployeeID = 7,
    @Taxes = 18.00,
    @MealUpgrade = 1,   -- 1 = Yes, 0 = No
    @PrefSeat = 0;      -- 1 = Yes, 0 = No

Select * from trm.Tickets;

Select * from trm.EBoarding;

-- Question 2: Add the constraint to check that the reservation date is not in the past.
ALTER TABLE trm.Reservations 
ADD CHECK (Date>= (CONVERT (date, GETDATE())));

INSERT INTO trm.Reservations VALUES ('pending', '2024-04-22', '1');

-- Question 3: Identify Passengers with Pending Reservations and Passengers with age more than 40 years.

SELECT DISTINCT p.PassengerID, p.PassengerFirstName, p.PassengerLastName
FROM trm.Passengers p
JOIN trm.PassengerReservations pr ON pr.PassengerID = p.PassengerID
JOIN trm.Reservations r ON r.ReservationID = pr.ReservationID
WHERE r.Status = 'pending'

UNION

SELECT PassengerID, PassengerFirstName, PassengerLastName 
FROM trm.Passengers 
WHERE DATEDIFF(YY, PassengerDOB, GETDATE()) >= 40;

-- Question 4: Search the database of the ticketing system for matching character strings by last name of passenger. 
					--Results should be sorted with most recent issued ticket first

CREATE PROCEDURE trm.PassLastNameTicket @PassengerLastName nvarchar(50)
AS SELECT p.PassengerLastName, p.PassengerFirstName, t.IssueDate, t.IssueTime 
FROM trm.Passengers p JOIN trm.Tickets t
ON p.PassengerID=t.PassengerID
WHERE p.PassengerLastName = @PassengerLastName
ORDER BY t.IssueDate DESC, t.IssueTime DESC;

Exec trm.PassLastNameTicket @PassengerLastName='Grumpy'

-- Question 4: Return a full list of passengers and his/her specific meal requirement in business class who has a reservation today 

    -- First, I will create records for passengers who have reservations today  
	--This is so I can test the user-defined function once it's ready 

	INSERT INTO trm.Passengers VALUES ('Snow', 'White', 'Snow@passenger.com', '1999-01-01', 'Prince', 'Vegetarian');
	INSERT INTO trm.Passengers VALUES ('Evil', 'Queen', 'Evil@passenger.com', '1961-01-01', 'King', 'Non-Vegetarian');

	INSERT INTO trm.Reservations VALUES ('confirmed', '2025-04-24',  '6');

    INSERT INTO trm.PassengerReservations VALUES ('8', '9', '01A');
	INSERT INTO trm.PassengerReservations VALUES ('9', '9', '01B');

	--Next I use the IssueTicketAndEBoarding procedure to insert rows into Tickets and EBoarding table
	--The Tickets table is where the 'Class' field is, in this example I need to set it to 'business' 
EXEC trm.IssueTicketAndEBoarding
    @ReservationID = 9,
    @PassengerID = 8,
    @FlightID = 6,
    @Seat = '01A',
    @Class = 'business',
    @Fare = 500.00,
    @EmployeeID = 7,
    @Taxes = 0.0,
    @MealUpgrade = 0,   
    @PrefSeat = 0;      

	EXEC trm.IssueTicketAndEBoarding
    @ReservationID = 9,
    @PassengerID = 9,
    @FlightID = 6,
    @Seat = '01B',
    @Class = 'business', 
    @Fare = 500.00,
    @EmployeeID = 7,
    @Taxes = 0.0,
    @MealUpgrade = 0,   
    @PrefSeat = 0;     

	--Next, I write a user-defined function to answer the question: 
CREATE FUNCTION trm.BusinessClassMealToday()
RETURNS TABLE AS
RETURN 
( SELECT p.PassengerFirstName, p.PassengerLastName, p.Meal 
FROM trm.Passengers p JOIN trm.PassengerReservations pr ON p.PassengerID = pr.PassengerID
JOIN trm.Reservations r ON pr.ReservationID = r.ReservationID
JOIN trm.Tickets t 
    ON t.PassengerID = pr.PassengerID 
    AND t.ReservationID = pr.ReservationID  --  composite key join
WHERE t.Class='business' AND r.Date = CONVERT(DATE,GETDATE()));

	-- Lastly, I run the user-defined function to check if its worked: 
SELECT * FROM trm.BusinessClassMealToday();

-- Question 4: Update the details for a passenger that has booked a flight before

CREATE PROCEDURE trm.UpdatePassengerDetails
    @PassengerID INT,
    @FirstName NVARCHAR(50) = NULL,
    @LastName NVARCHAR(50) = NULL,
    @Email NVARCHAR(100) = NULL,
    @DOB DATE = NULL,
    @EmergencyContact NVARCHAR(50) = NULL,
    @Meal NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT * FROM trm.PassengerReservations WHERE PassengerID = @PassengerID
    )
    BEGIN
        UPDATE trm.Passengers
        SET 
            PassengerFirstName = ISNULL(@FirstName, PassengerFirstName),
            PassengerLastName = ISNULL(@LastName, PassengerLastName),
            PassengerEmail = ISNULL(@Email, PassengerEmail),
            PassengerDOB = ISNULL(@DOB, PassengerDOB),
            EmergencyContact = ISNULL(@EmergencyContact, EmergencyContact),
            Meal = ISNULL(@Meal, Meal)
        WHERE PassengerID = @PassengerID;

        PRINT 'Passenger details updated (partial or full).';
    END
    ELSE
    BEGIN
        PRINT 'Passenger does not have any reservations. No update performed.';
    END
END;

	--Checking the above stored procedure works by changing a passenger's meal preference: 

SELECT * FROM trm.Passengers;

EXEC trm.UpdatePassengerDetails
    @PassengerID = 1,
    @Meal = 'Non-Vegetarian';

	SELECT * FROM trm.Passengers;

	--Checking the above stored procedure works by trying to update the record of a passenger who has no reservation: 

EXEC trm.UpdatePassengerDetails
    @PassengerID = 5,
    @Meal = 'Non-Vegetarian';

-- Question 5: Create a view containing all all e-boarding numbers issued by a specific 
--employee showing the overall revenue generated by that employee on a particular flight.

CREATE VIEW trm.EmployeeFlightRevenue AS
SELECT 
    e.EmployeeID,
    eb.EBoardingNumber,
    r.FlightID,  
    t.Fare,
    eb.BaggageFee,

    -- Show MealUpgradeFee only if MealUpgrade = 1
    CASE 
        WHEN eb.MealUpgrade = 1 THEN eb.MealUpgradeFee 
        ELSE 0 
    END AS MealUpgradeRevenue,

    -- Show PrefSeatFee only if PrefSeat = 1
    CASE 
        WHEN eb.PrefSeat = 1 THEN eb.PrefSeatFee 
        ELSE 0 
    END AS PrefSeatRevenue,

    eb.Taxes,

    -- Total revenue = Fare + BaggageFee + Meal + PrefSeat + Taxes
    (t.Fare + eb.BaggageFee + 
        CASE WHEN eb.MealUpgrade = 1 THEN eb.MealUpgradeFee ELSE 0 END + 
        CASE WHEN eb.PrefSeat = 1 THEN eb.PrefSeatFee ELSE 0 END + 
        eb.Taxes
    ) AS TotalRevenue

FROM 
    trm.EBoarding eb
JOIN trm.Tickets t ON eb.TicketID = t.TicketID
JOIN trm.Reservations r ON t.ReservationID = r.ReservationID  
JOIN Employees e ON eb.EmployeeID = e.EmployeeID;

SELECT * FROM trm.EmployeeFlightRevenue WHERE EmployeeID = '7' AND FlightID = '7';

--Question 6: Create a trigger so that the current seat allotment of a passenger automatically updates to reserved when the ticket is issued.

CREATE TRIGGER trm.UpdatePrefSeat
ON trm.Tickets
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Step 1: Set others' PrefSeat to NULL (seat now taken on the same flight)
    UPDATE pr
    SET pr.PrefSeat = NULL
    FROM trm.PassengerReservations pr
    INNER JOIN trm.Reservations r1 ON pr.ReservationID = r1.ReservationID
    INNER JOIN inserted i ON pr.PrefSeat = i.Seat
    INNER JOIN trm.Reservations r2 ON i.ReservationID = r2.ReservationID
    WHERE 
        r1.FlightID = r2.FlightID  -- only same flight
        AND (pr.PassengerID <> i.PassengerID OR pr.ReservationID <> i.ReservationID);

    -- Step 2: Set the ticketed passenger’s PrefSeat to 'RES' (fulfilled)
    UPDATE pr
    SET pr.PrefSeat = 'RES'
    FROM trm.PassengerReservations pr
    INNER JOIN inserted i 
        ON pr.PassengerID = i.PassengerID
       AND pr.ReservationID = i.ReservationID
    WHERE pr.PrefSeat = i.Seat;
END;


	--Harry and Sammy have the same preferred seat on the same flight
	SELECT * FROM trm.PNR

	--Issue a ticket for Harry with his preferred seat on it 

INSERT INTO trm.Baggage VALUES ('15.00', 'loaded', '3', '4');

EXEC trm.IssueTicketAndEBoarding
    @ReservationID = 4,
    @PassengerID = 3,
    @FlightID = 4,
    @Seat = '10B',
    @Class = 'firstclass',
    @Fare = 350.00,
    @EmployeeID = 6,
    @Taxes = 20.00,
    @MealUpgrade = 0,   -- 1 = Yes, 0 = No
    @PrefSeat = 1;      -- 1 = Yes, 0 = No
	
	--See if the trigger worked and changed the PrefSeat of Harry to RES and Sammy to NULL 

SELECT * FROM trm.PNR


--Question 7: Identify the total number of baggages (which are checkedin) made on a specified date for a specific flight

CREATE FUNCTION trm.CheckedBaggageCountForFlight (@FlightID INT)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        f.FlightID,
        COUNT(b.BaggageID) AS TotalCheckedBaggageItems
    FROM 
        Flights f
    LEFT JOIN trm.Reservations r ON f.FlightID = r.FlightID
    LEFT JOIN trm.PassengerReservations pr ON pr.ReservationID = r.ReservationID
    LEFT JOIN trm.Baggage b 
        ON b.ReservationID = pr.ReservationID AND b.PassengerID = pr.PassengerID AND b.Status = 'Checked-in'
    WHERE 
        f.FlightID = @FlightID
    GROUP BY 
        f.FlightID
);

SELECT * FROM trm.CheckedBaggageCountForFlight(1);

--If you inspect all the tables now, you should see at least 7 rows in each 

--Creating a backup and ensuring the backup can be restored:

BACKUP DATABASE Airport TO DISK ='C:\Airport_Restore\Airportcheck.bak' WITH CHECKSUM

RESTORE VERIFYONLY FROM DISK='C:\Airport_Restore\Airportcheck.bak' WITH CHECKSUM;

-- Checking there are at least 7 rows in each table 

SELECT * FROM trm.Passengers

SELECT * FROM trm.Reservations

SELECT * FROM trm.PassengerReservations

SELECT * FROM trm.Tickets

SELECT * FROM trm.Baggage

SELECT * FROM trm.EBoarding

SELECT * FROM Flights

SELECT * FROM Employees
