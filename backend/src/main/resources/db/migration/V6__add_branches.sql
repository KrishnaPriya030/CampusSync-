CREATE TABLE branches (

    id BIGINT AUTO_INCREMENT PRIMARY KEY,

    department_id BIGINT NOT NULL,

    name VARCHAR(100) NOT NULL,

    code VARCHAR(20) NOT NULL,

    active BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT uk_branch_code
        UNIQUE (code),

    CONSTRAINT fk_branch_department
        FOREIGN KEY (department_id)
        REFERENCES departments(id)

);