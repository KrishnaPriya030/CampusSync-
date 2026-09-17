    package com.campussync.campussync_backend.repository;

    import java.util.Optional;

    import org.springframework.data.jpa.repository.JpaRepository;

    import com.campussync.campussync_backend.entity.DepartmentHead;

    public interface DepartmentHeadRepository
            extends JpaRepository<DepartmentHead, Long> {

        Optional<DepartmentHead> findByUserId(Long userId);

        Optional<DepartmentHead> findByDepartmentId(Long departmentId);

        boolean existsByDepartmentId(Long departmentId);
    }