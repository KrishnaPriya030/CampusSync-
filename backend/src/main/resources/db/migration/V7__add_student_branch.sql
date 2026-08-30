ALTER TABLE students
ADD COLUMN branch_id BIGINT NULL;

UPDATE students
SET branch_id = 1
WHERE department_id = 1;

ALTER TABLE students
ADD CONSTRAINT fk_student_branch
FOREIGN KEY (branch_id)
REFERENCES branches(id);

ALTER TABLE students
MODIFY COLUMN branch_id BIGINT NOT NULL;