CREATE TABLE status(
    id INT PRIMARY KEY NOT NULL,
    name VARCHAR(20),
    description VARCHAR(100),
    can_login BOOLEAN    
);

INSERT INTO status values(10,'Active','User can login, etc',TRUE);
INSERT INTO status values(20,'Suspended','Cannot login for a given reason',FALSE);
INSERT INTO status values(30,'Not Approved','Member need to be approved (email validation)',FALSE);
INSERT INTO status values(99,'Banned','Member has been banned',FALSE);
INSERT INTO status values(88,'Locked','Member is locked out due to failed logins',FALSE);