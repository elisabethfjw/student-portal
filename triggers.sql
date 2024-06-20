-- When a student tries to register for a course that is full, that student is added to the waiting list for the course
CREATE OR REPLACE FUNCTION add_to_registrations() RETURNS TRIGGER AS $$
BEGIN
    -- 1) check prerequisites
    -- 1a) check if the student is already registered
    IF (
        SELECT student
        FROM Registrations
        WHERE student = NEW.student
        AND course = NEW.course
    ) IS NOT NULL THEN
        RAISE EXCEPTION 'Student is already registered';
    END IF;
    -- 1b) check if student has passed course
    IF EXISTS (
        SELECT * -- DO NOT USE COUNT(*); "created a row"
        FROM Taken
        WHERE student = NEW.student
        AND course = NEW.course
        AND grade IN ('3', '4', '5')
    ) THEN
        RAISE EXCEPTION 'Student has passed the course';
    END IF;
    -- 1c) check if student meets the course prerequisites
    IF (
        SELECT COUNT(*)
        FROM Prerequisite
        WHERE course = NEW.course
        AND prerequisite NOT IN (
            SELECT course
            FROM Taken
            WHERE student = NEW.student
            AND grade IN ('3', '4', '5')
        )
    ) > 0 THEN
        RAISE EXCEPTION 'Student does not meet the prerequisites';
    END IF;
    -- 1d) check if student has fulfilled graduation requirements
    IF (
        SELECT qualified
        FROM PathToGraduation
        WHERE student = NEW.student
        AND qualified = 'TRUE'
    ) IS NOT NULL THEN
        RAISE EXCEPTION 'Student has fulfilled graduation requirements';
    END IF;
    -- 2) check if the course is full
    IF (
        SELECT COUNT(*)
        FROM Registered
        WHERE course = NEW.course
    ) >= (
        SELECT capacity
        FROM LimitedCourses
        WHERE code = NEW.course
    ) THEN
        -- 2a) if full, add the student to the waiting list
        INSERT INTO WaitingList VALUES (NEW.student, NEW.course, (
            SELECT COUNT(*)
            FROM WaitingList
            WHERE course = NEW.course
        ) + 1);
    ELSE
        -- 2b) if not full, register the student
        INSERT INTO Registered VALUES (NEW.student, NEW.course);
    END IF; 
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER add_to_registrations
    INSTEAD OF INSERT OR UPDATE ON Registrations  -- when user types insert/ update statement add_to_registrations is called
        FOR EACH ROW EXECUTE FUNCTION add_to_registrations();

-- When a student is removed from a course, the next student on the waiting list is registered for the course

CREATE OR REPLACE FUNCTION remove_from_registrations() RETURNS TRIGGER AS $$
DECLARE 
    WaitingListStudent INT;


BEGIN
    -- #1: if student is in waitinglist
    IF EXISTS (
        SELECT * 
        FROM WaitingList
        WHERE student = OLD.student 
        AND course = OLD.course 
    ) THEN 
        -- 1. If delete student from waiting list
        -- WaitingListStudent := SELECT position FROM WaitingList WHERE student = OLD.student AND course = OLD.course;
        SELECT position INTO WaitingListStudent
        FROM WaitingList
        WHERE student = OLD.student AND course = OLD.course;
        
        DELETE FROM WaitingList WHERE student = OLD.student AND course = OLD.course;
        -- update position of student by decrementing position of students behind deleted student 
        UPDATE WaitingList
        SET position = position - 1
            WHERE course = OLD.course AND position > (
                WaitingListStudent
            );
    END IF;

    -- #2: if student is in registered 
    IF EXISTS (
        SELECT * 
        FROM Registered 
        WHERE student = OLD.student 
        AND course = OLD.course 
    ) THEN 
        -- waitingListStudent variable to store student you are going to update 
        -- WaitingListStudent := SELECT position FROM WaitingList WHERE student = OLD.student AND course = OLD.course;
        SELECT position INTO WaitingListStudent
        FROM WaitingList
        WHERE student = OLD.student AND course = OLD.course;
        -- 2. if delete student from registered table 
        DELETE FROM Registered WHERE student = OLD.student;
        -- 1) If course is not full and student in waiting list: add student to registered and remove from waiting list
        IF (
            SELECT COUNT(*)
            FROM Registered
            WHERE course = OLD.course
        ) < (
            SELECT capacity
            FROM LimitedCourses
            WHERE code = OLD.course
        ) THEN 
            -- 1) if course not full
            -- 2a) check if there is a student in the waiting list 
            IF EXISTS (
                SELECT *
                FROM WaitingList
                WHERE course = OLD.course
            ) THEN
                -- 2a) if there is a student in the waiting list, register the student
                INSERT INTO Registered VALUES (
                    (SELECT student 
                    FROM WaitingList 
                    WHERE course = OLD.course 
                    ORDER BY position 
                    LIMIT 1),
                    OLD.course
                );
                -- 2b) remove the student from the waiting list
                DELETE FROM WaitingList 
                WHERE student = ( 
                    SELECT student 
                    FROM WaitingList 
                    WHERE course = OLD.course 
                    ORDER BY position 
                    LIMIT 1)
                AND course = OLD.course;
                -- 2c) update waiting list (decrement position of students behind deleted student)
                UPDATE WaitingList
                SET position = position - 1
                    WHERE course = OLD.course AND position > 1;
            END IF;
        END IF;
    END IF;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER remove_from_registrations
    INSTEAD OF DELETE ON Registrations -- when user types delete statement, remove_from_registrations is called
        FOR EACH ROW EXECUTE FUNCTION remove_from_registrations();
