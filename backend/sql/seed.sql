-- Insert test users (PIN: 1234)
INSERT INTO users (university_id, pin_hash, role) VALUES 
('student1', '$2a$10$eqJRJvB2h0T.qQif3pM0uuDVfCGRI67TE1ipprk0HC5FVxs6Ueswm', 'STUDENT'),
('admin1', '$2a$10$eqJRJvB2h0T.qQif3pM0uuDVfCGRI67TE1ipprk0HC5FVxs6Ueswm', 'ADMIN')
ON CONFLICT (university_id) DO NOTHING;
