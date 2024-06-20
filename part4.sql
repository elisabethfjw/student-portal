SELECT
    json_build_object(
        'student', B.idnr,
        'name', B.name,
        'login', B.login,
        'program', B.program,
        'branch', B.branch,
        'finished', (
            SELECT json_agg(
                json_build_object(
                    'course', FC.courseName,
                    'code', FC.course,
                    'credits', FC.credits,
                    'grade', FC.grade
                )
            )
            FROM FinishedCourses FC
            WHERE FC.student = B.idnr
        ),
        'registered', COALESCE((
            SELECT json_agg(
                json_build_object(
                    'course', R.course,
                    'code', R.course,
                    'status', R.status,
                    'position', COALESCE(W.position, NULL)
                )
            )
            FROM Registrations R
            LEFT JOIN WaitingList W ON R.student = W.student AND R.course = W.course
            WHERE R.student = B.idnr
        ), '[]'),
        'seminarCourses', PTG.seminarCourses,
        'mathCredits', PTG.mathCredits,
        'totalCredits', PTG.totalCredits,
        'canGraduate', PTG.qualified
    ) AS jsondata
FROM BasicInformation B
JOIN PathToGraduation PTG ON B.idnr = PTG.student
WHERE B.idnr = ?;
