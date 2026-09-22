    
ALTER TABLE events
ADD COLUMN certificate_template_id BIGINT NULL;

ALTER TABLE events
ADD CONSTRAINT fk_event_certificate_template
    FOREIGN KEY (certificate_template_id)
    REFERENCES certificate_templates(id);

