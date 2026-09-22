
ALTER TABLE certificates
ADD COLUMN certificate_template_id BIGINT NULL;

UPDATE certificates c
SET c.certificate_template_id = COALESCE(
    (
        SELECT e.certificate_template_id
        FROM events e
        WHERE e.id = c.event_id
    ),
    1
)
WHERE c.certificate_template_id IS NULL;

ALTER TABLE certificates
MODIFY COLUMN certificate_template_id BIGINT NOT NULL;

ALTER TABLE certificates
ADD CONSTRAINT fk_certificate_template
    FOREIGN KEY (certificate_template_id)
    REFERENCES certificate_templates(id);

