CREATE TABLE departments (

    id BIGINT AUTO_INCREMENT PRIMARY KEY,

    name VARCHAR(100) NOT NULL,

    code VARCHAR(20) NOT NULL UNIQUE,

    active BOOLEAN NOT NULL

);
CREATE TABLE organizations (

    id BIGINT AUTO_INCREMENT PRIMARY KEY,

    name VARCHAR(150) NOT NULL,

    code VARCHAR(20) NOT NULL UNIQUE,

    organization_type VARCHAR(30) NOT NULL,

    description VARCHAR(500),

    active BOOLEAN NOT NULL

);

CREATE TABLE users (

    id BIGINT AUTO_INCREMENT PRIMARY KEY,

    name VARCHAR(100) NOT NULL,

    email VARCHAR(150) NOT NULL UNIQUE,
    phone_number VARCHAR(15) NOT NULL,

    password VARCHAR(255) NOT NULL,

    role VARCHAR(20) NOT NULL,

    status VARCHAR(20) NOT NULL,

    created_at TIMESTAMP NOT NULL

);
CREATE TABLE students (

    id BIGINT AUTO_INCREMENT PRIMARY KEY,

    user_id BIGINT NOT NULL UNIQUE,

    register_number VARCHAR(30) NOT NULL UNIQUE,

    department_id BIGINT NOT NULL,

    semester INT NOT NULL,

    internal BOOLEAN NOT NULL,

    college_name VARCHAR(150),

    CONSTRAINT fk_student_user
        FOREIGN KEY (user_id)
        REFERENCES users(id),

    CONSTRAINT fk_student_department
        FOREIGN KEY (department_id)
        REFERENCES departments(id)

);

CREATE TABLE organizers (

    id BIGINT AUTO_INCREMENT PRIMARY KEY,

    user_id BIGINT NOT NULL UNIQUE,

    organization_id BIGINT NOT NULL,

    designation VARCHAR(100) NOT NULL,

    CONSTRAINT fk_organizer_user
        FOREIGN KEY (user_id)
        REFERENCES users(id),

    CONSTRAINT fk_organizer_organization
        FOREIGN KEY (organization_id)
        REFERENCES organizations(id)

);