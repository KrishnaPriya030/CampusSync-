
INSERT INTO certificate_templates (
    name,
    template_type,
    organization_name,
    certificate_title,
    description,
    font,
    primary_color,
    secondary_color
)
VALUES
(
    'Classic Participation',
    'PARTICIPATION',
    'CampusSync',
    'Certificate of Participation',
    'This certificate is proudly presented to {{studentName}} for participating in {{eventName}}.',
    'Helvetica',
    '#1F4E79',
    '#D9EAF7'
),
(
    'Modern Achievement',
    'ACHIEVEMENT',
    'CampusSync',
    'Certificate of Achievement',
    'This certificate is awarded to {{studentName}} for outstanding achievement in {{eventName}}.',
    'Helvetica-Bold',
    '#8B5A00',
    '#F4D58D'
),
(
    'Professional Workshop',
    'WORKSHOP',
    'CampusSync',
    'Certificate of Completion',
    'This certificate is presented to {{studentName}} for successfully completing {{eventName}}.',
    'Helvetica',
    '#2F6B3F',
    '#DCEFE1'
);

