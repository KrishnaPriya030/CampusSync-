CREATE TABLE notifications (
    id BIGINT NOT NULL AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    title VARCHAR(150) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) NOT NULL,
    event_id BIGINT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME NOT NULL,

    PRIMARY KEY (id),

    CONSTRAINT fk_notification_user
        FOREIGN KEY (user_id)
        REFERENCES users(id),

    CONSTRAINT fk_notification_event
        FOREIGN KEY (event_id)
        REFERENCES events(id)
);