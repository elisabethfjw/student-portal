# university-portal
## Overview
Implemented a university system that manages student’s grades, program enrollment, course registration and graduation requirements 

## ER Diagram
<img title="ER diagram" alt="Alt text" src="/database design/ER.png">

## Features 
- Retrieve student information
- Register for course
  - Check if course prerequisites have been met before registration
  - Place student on waiting list if course is full
- Unregister from course
  - Register the next student on the waiting list for that course
