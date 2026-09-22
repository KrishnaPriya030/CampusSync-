
CREATE TABLE certificate_templates (
    id BIGINT NOT NULL AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    template_type VARCHAR(255) NOT NULL,
    background_url VARCHAR(255),
    organization_name VARCHAR(255),
    certificate_title VARCHAR(255),
    description TEXT,

    signature1_name VARCHAR(255),
    signature1_designation VARCHAR(255),
    signature1_image_url VARCHAR(255),

    signature2_name VARCHAR(255),
    signature2_designation VARCHAR(255),
    signature2_image_url VARCHAR(255),

    font VARCHAR(255),
    primary_color VARCHAR(255),
    secondary_color VARCHAR(255),

    PRIMARY KEY (id),

    CONSTRAINT uk_certificate_template_name
        UNIQUE (name)
);

