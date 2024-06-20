
-- PART 1
-- Students(_idnr_, name, login, program)
CREATE TABLE Students (
    idnr CHAR(10) NOT NULL,
    name TEXT NOT NULL,
    login VARCHAR(10) NOT NULL,
    program VARCHAR(50) NOT NULL, -- student always belongs to a program
    PRIMARY KEY (idnr),
    CONSTRAINT unique_login UNIQUE (login)  -- student login unique
);

-- PART 2 
CREATE TABLE Program (
    name TEXT NOT NULL,
    abbreviation TEXT NOT NULL,
    PRIMARY KEY (name)
);

CREATE TABLE Department (
    name TEXT NOT NULL,
    abbreviation TEXT NOT NULL,
    PRIMARY KEY (name),
    CONSTRAINT unique_abbrevation UNIQUE (abbreviation) -- department abbreviation unique
);
-- end of part 2

-- Branches(_name_, _program_)
CREATE TABLE Branches (
    name TEXT NOT NULL,
    program TEXT NOT NULL,
    PRIMARY KEY (name, program),
    FOREIGN KEY (program) REFERENCES Program(name)
);

-- Courses(_code_, name, credits, department)
CREATE TABLE Courses (
    code CHAR(6) NOT NULL, -- each course has unique 6 character code
    name TEXT NOT NULL,
    credits INTEGER NOT NULL,
    department VARCHAR(50) NOT NULL,
    PRIMARY KEY (code)
);

-- LimitedCourses(_code_, capacity)
-- code → Courses.code
CREATE TABLE LimitedCourses (
    code CHAR(6) NOT NULL,
    capacity INTEGER NOT NULL,
    PRIMARY KEY (code),
    FOREIGN KEY (code) REFERENCES Courses(code)
);

CREATE TABLE Prerequisite (
    course CHAR(6) NOT NULL,
    prerequisite CHAR(6) NOT NULL,
    PRIMARY KEY (course, prerequisite),
    FOREIGN KEY (course) REFERENCES Courses(code),
    FOREIGN KEY (prerequisite) REFERENCES Courses(code)
);

-- ON DELETE CASCADE ON UPDATE CASCADE: when idnr in Students deleted/ updated, student in StudentBranches deleted/ updated
-- StudentBranches(_student_, branch, program)
-- student → Students.idnr
-- (branch, program) → Branches.(name, program)
-- student can only have one branch and program
CREATE TABLE StudentBranches (
    student CHAR(10) NOT NULL,
    branch TEXT NOT NULL,
    program TEXT NOT NULL,
    PRIMARY KEY (student),
    FOREIGN KEY (student) REFERENCES Students(idnr),
    FOREIGN KEY (branch, program) REFERENCES Branches(name, program) ON UPDATE CASCADE
);

-- Classifications(_name_)
CREATE TABLE Classifications (
    name TEXT NOT NULL,
    PRIMARY KEY (name)
);  

-- Classified(_course_, _classification_)
-- course → courses.code
-- classification → Classifications.name
CREATE TABLE Classified (
    course CHAR(6) NOT NULL,
    classification TEXT NOT NULL,
    PRIMARY KEY (course, classification),
    FOREIGN KEY (course) REFERENCES Courses(code),
    FOREIGN KEY (classification) REFERENCES Classifications(name)
);

-- MandatoryProgram(_course_, _program_)
-- course → Courses.code
CREATE TABLE MandatoryProgram (
    course CHAR(6) NOT NULL,
    program VARCHAR(50) NOT NULL,
    PRIMARY KEY (course, program),
    FOREIGN KEY (course) REFERENCES Courses(code)
);  

-- MandatoryBranch(_course_, _branch_, _program_)
-- course → Courses.code
-- (branch, program) → Branches.(name, program)
CREATE TABLE MandatoryBranch (
    course CHAR(6) NOT NULL,
    branch TEXT NOT NULL,
    program TEXT NOT NULL,
    PRIMARY KEY (course, branch, program),
    FOREIGN KEY (course) REFERENCES Courses(code),
    FOREIGN KEY (branch, program) REFERENCES Branches(name, program)
);  

-- RecommendedBranch(_course_, _branch_, _program_)
-- course → Courses.code
-- (branch, program) → Branches.(name, program)
CREATE TABLE RecommendedBranch (
    course CHAR(6) NOT NULL,
    branch TEXT NOT NULL,
    program TEXT NOT NULL,
    PRIMARY KEY (course, branch, program),
    FOREIGN KEY (course) REFERENCES Courses(code),
    FOREIGN KEY (branch, program) REFERENCES Branches(name, program)
);

-- Registered(_student_, _course_)
-- student → Students.idnr
-- course → Courses.code
CREATE TABLE Registered (
    student CHAR(10) NOT NULL,
    course CHAR(6) NOT NULL,
    PRIMARY KEY (student, course),
    FOREIGN KEY (student) REFERENCES Students(idnr),
    FOREIGN KEY (course) REFERENCES Courses(code)
);

-- Taken(_student_, _course_, grade)
-- student → Students.idnr
-- course → Courses.code
CREATE TABLE Taken (
    student CHAR(10) NOT NULL,
    course CHAR(6) NOT NULL,
    grade CHAR(1) NOT NULL CHECK (grade IN ('U', '3', '4', '5')),
    PRIMARY KEY (student, course),
    FOREIGN KEY (student) REFERENCES Students(idnr),
    FOREIGN KEY (course) REFERENCES Courses(code)
); 

-- WaitingList(_student_, _course_, position)
-- student → Students.idnr
-- course → Limitedcourses.code
CREATE TABLE WaitingList (
    student CHAR(10) NOT NULL,
    course CHAR(6) NOT NULL,
    position INTEGER NOT NULL,
    PRIMARY KEY (student, course),
    FOREIGN KEY (student) REFERENCES Students(idnr),
    FOREIGN KEY (course) REFERENCES LimitedCourses(code),
    CONSTRAINT unique_waiting_list_entry UNIQUE (course, position),
    CHECK (position > 0)
);

