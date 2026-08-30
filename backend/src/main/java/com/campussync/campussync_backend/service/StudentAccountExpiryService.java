    package com.campussync.campussync_backend.service;

    import java.time.LocalDate;
    import java.util.List;

    import org.springframework.stereotype.Service;
    import org.springframework.transaction.annotation.Transactional;

    import com.campussync.campussync_backend.entity.Student;
    import com.campussync.campussync_backend.entity.User;
    import com.campussync.campussync_backend.enums.UserStatus;
    import com.campussync.campussync_backend.repository.StudentRepository;

    @Service
    public class StudentAccountExpiryService {

        private final StudentRepository studentRepository;

        public StudentAccountExpiryService(
                StudentRepository studentRepository) {

            this.studentRepository = studentRepository;
        }

        @Transactional
        public void deactivateCompletedStudents() {

            int currentYear = LocalDate.now().getYear();

            List<Student> students = studentRepository.findAll();

            for (Student student : students) {

                Integer graduationYear =
                        student.getGraduationYear();

                // No graduation year → do nothing
                if (graduationYear == null) {
                    continue;
                }

                /*
                * Keep the account active during the graduation year.
                *
                * Example:
                * graduationYear = 2028
                * currentYear    = 2026
                * → account remains ACTIVE
                *
                * currentYear = 2029
                * → account becomes BLOCKED
                */
                if (graduationYear < currentYear) {

                    User user = student.getUser();

                    // Only deactivate currently active accounts
                    if (user.getStatus() == UserStatus.ACTIVE) {

                        user.setStatus(UserStatus.BLOCKED);

                        System.out.println(
                                "Automatically deactivated student account: "
                                        + user.getEmail()
                        );
                    }
                }
            }
        }
    }