-- BasicInformation(idnr, name, login, program, branch): 
CREATE VIEW BasicInformation AS 
    SELECT Students.idnr AS idnr, Students.name AS name, Students.login AS login, Students.program AS program, StudentBranches.branch AS branch
    FROM Students 
    LEFT JOIN StudentBranches
    ON Students.idnr = StudentBranches.student;

-- FinishedCourses(student, course, courseName, grade, credits): 
CREATE VIEW FinishedCourses AS 
    SELECT Taken.student AS student, Taken.course AS course, Courses.name AS courseName, Taken.grade AS grade, Courses.credits AS credits
    FROM Taken
    JOIN Courses
    ON Taken.course = Courses.code;

-- Registrations(student, course, status): all registered and waiting students for all courses, along with their waiting status ('registered' or 'waiting').
CREATE VIEW Registrations AS
    SELECT
        Students.idnr AS student,
        Courses.code AS course,
        CASE
            WHEN WaitingList.student IS NOT NULL THEN 'waiting'
            WHEN Registered.student IS NOT NULL THEN 'registered'
        END AS status
    FROM Students
    JOIN Courses ON TRUE
    LEFT JOIN WaitingList 
        ON Students.idnr = WaitingList.student 
        AND Courses.code = WaitingList.course
    LEFT JOIN Registered 
        ON Students.idnr = Registered.student 
        AND Courses.code = Registered.course
    WHERE
        WaitingList.student IS NOT NULL 
        OR Registered.student IS NOT NULL;

-- PathToGraduation(student, totalCredits, mandatoryLeft, mathCredits, seminarCourses, qualified): for all students, their path to graduation, i.e. a view with columns for:
-- Helper View: PassedCourses (student, course, credits)
CREATE VIEW PassedCourses AS
    SELECT Taken.student AS student, Taken.course AS course, Courses.credits AS credits
    FROM Taken
    JOIN Courses ON Taken.course = Courses.code
    WHERE Taken.grade IN ('3', '4', '5');

CREATE VIEW UnreadMandatory AS 
    WITH MandatoryCourses AS (
        SELECT S.idnr AS student, MP.course AS course 
            FROM MandatoryProgram MP
            LEFT JOIN Students S ON MP.program = S.program
        UNION
        SELECT SB.student AS student, MB.course AS course
            FROM MandatoryBranch MB
            LEFT JOIN StudentBranches SB ON MB.branch = SB.branch
    )
    SELECT MC.student, MC.course
        FROM MandatoryCourses MC
    EXCEPT 
    SELECT PC.student, PC.course
        FROM PassedCourses PC;

CREATE VIEW PassedCoursesProgram AS 
    SELECT PC.student AS student, PC.course AS course, PC.credits AS credits, S.program AS program
    FROM PassedCourses PC
    LEFT JOIN Students S ON PC.student = S.idnr;

-- Helper View: RecommendedCourses (student, course, credits)
CREATE VIEW RecommendedCourses AS
    WITH PassedCoursesProgram AS (
        SELECT PC.student AS student, PC.course AS course, S.program AS program, PC.credits AS credits, S.branch AS branch
        FROM PassedCourses PC
        LEFT JOIN BasicInformation S ON PC.student = S.idnr
        ORDER BY PC.student
    )
    SELECT PCP.student, PCP.course, PCP.credits
    FROM PassedCoursesProgram PCP 
    WHERE (PCP.course, PCP.program) IN (SELECT RB.course, RB.program FROM RecommendedBranch RB)
      AND PCP.student IN (SELECT S.idnr FROM BasicInformation S WHERE S.program = PCP.program AND S.branch = PCP.branch);

-- Helper View: RecommendedCredits
CREATE VIEW RecommendedCredits AS
    SELECT RC.student AS student, COALESCE(SUM(RC.credits), 0) AS totalRecommendedCredits
    FROM RecommendedCourses RC
    GROUP BY RC.student;

-- Helper View: StudentsWithCredits
CREATE VIEW TotalCredits AS
    SELECT Students.idnr AS student, COALESCE(SUM(PassedCourses.credits), 0) AS totalCredits
    FROM Students
    LEFT JOIN PassedCourses ON Students.idnr = PassedCourses.student
    GROUP BY Students.idnr;

-- Helper View: Number of unread mandatory courses
CREATE VIEW UnreadMandatoryCount AS
    SELECT UM.student AS student, COALESCE(COUNT(UM.course), 0) AS mandatoryLeft
    FROM UnreadMandatory UM
    GROUP BY UM.student
    ORDER BY UM.student;

-- Helper View: Number of math credits
CREATE VIEW MathCredits AS 
    SELECT student, COALESCE(SUM(CASE WHEN C.classification = 'math' THEN PC.credits ELSE 0 END), 0) AS mathCredits
    FROM PassedCourses PC
    JOIN Classified C ON PC.course = C.course
    GROUP BY student;

-- -- Helper View: Number of seminar courses
CREATE VIEW SeminarCourses AS 
    SELECT S.idnr as student, COALESCE(SUM(CASE WHEN C.classification = 'seminar' THEN 1 ELSE 0 END), 0) AS seminarCourses
    FROM Students S
    LEFT JOIN PassedCourses PC ON PC.student = S.idnr
    LEFT JOIN Classified C ON PC.course = C.course
    GROUP BY S.idnr;
    
CREATE VIEW PathToGraduation AS 
    SELECT
        S.idnr AS student,
        COALESCE(TC.totalCredits, 0) AS totalCredits,
        COALESCE(UMC.mandatoryLeft, 0) AS mandatoryLeft,
        COALESCE(MC.mathCredits, 0) AS mathCredits,
        COALESCE(SC.seminarCourses, 0) AS seminarCourses,
        CASE
            WHEN COALESCE(UMC.mandatoryLeft, 0) = 0 AND COALESCE(RC.totalRecommendedCredits, 0) >= 10 AND COALESCE(MC.mathCredits, 0) >= 20 AND COALESCE(SC.seminarCourses, 0) >= 1 THEN TRUE
            ELSE FALSE
        END AS qualified
    FROM Students S
    LEFT JOIN TotalCredits TC ON S.idnr = TC.student
    LEFT JOIN UnreadMandatoryCount UMC ON S.idnr = UMC.student
    LEFT JOIN MathCredits MC ON S.idnr = MC.student
    LEFT JOIN SeminarCourses SC ON S.idnr = SC.student 
    LEFT JOIN RecommendedCredits RC ON S.idnr = RC.student
    ORDER BY CAST(S.idnr AS bigint);

