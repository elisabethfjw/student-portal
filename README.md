# university-portal

## Database Schema
Students(**idnr**, name, login, program)  
UNIQUE (login)  

Branches(**name**, **program**)  

Courses(**code**, name, credits, department)  

LimitedCourses(**code**, capacity)  
code → Courses.code  

StudentBranches(**student**, branch, program)  
student → Students.idnr  
(branch, program) → Branches.(name, program)  
(student, program) → Students.(idnr, program)  

Classifications(**name**)  

Classified(**course**, **classification**)  
course → courses.code  
classification → Classifications.name  

MandatoryProgram(**course**, **program**)  
course → Courses.code  

MandatoryBranch(**course**, **branch**, **program**)  
course → Courses.code  
(branch, program) → Branches.(name, program)  

RecommendedBranch(**course**, **branch**, **program**)  
course → Courses.code  
(branch, program) → Branches.(name, program)  

Registered(**student**, **course**)  
student → Students.idnr  
course → Courses.code  

Taken(**student**, **course**, grade)  
student → Students.idnr  
course → Courses.code  

WaitingList(**student**, **course**, position)  
student → Students.idnr  
course → Limitedcourses.code  
UNIQUE (course, position)  

Department(**name**, abbreviation)  
UNIQUE (abbreviation)  

Program(**name**, abbreviation)  

Prerequisite(**course**, **prerequisite**)  
course → courses.code   
prerequisite → courses.code  