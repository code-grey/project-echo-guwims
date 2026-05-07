-- Insert test users (PIN: 1234)
INSERT INTO users (university_id, pin_hash, role) VALUES 
('student1', '$2a$10$aV/su/aFjuDTZaxE4jLPje07YOmpNAUFvB5wk9yQZWotIroBVRY2C', 'STUDENT'),
('admin1', '$2a$10$aV/su/aFjuDTZaxE4jLPje07YOmpNAUFvB5wk9yQZWotIroBVRY2C', 'ADMIN')
ON CONFLICT (university_id) DO NOTHING;
