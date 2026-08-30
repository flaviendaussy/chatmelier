-- Create users in auth.users (simulated, usually done via Supabase auth endpoints, but we use raw SQL for seed)
INSERT INTO auth.users (id, email) VALUES 
('11111111-1111-1111-1111-111111111111', 'user1@example.com'),
('22222222-2222-2222-2222-222222222222', 'user2@example.com');

-- Profiles and Cellars are auto-created by triggers, but let's assume we update the default cellar
-- Since triggers might run, let's just insert wines and bottles directly and use a specific cellar ID if we want, or rely on the trigger.
-- For seed data, it's safer to just create a shared cellar explicitly if triggers are disabled, but they are enabled.
-- Let's just create a shared cellar and link members.
INSERT INTO cellars (id, name, owner_id) VALUES ('33333333-3333-3333-3333-333333333333', 'Our Shared Cellar', '11111111-1111-1111-1111-111111111111');
INSERT INTO cellar_members (cellar_id, user_id, role) VALUES 
('33333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', 'admin'),
('33333333-3333-3333-3333-333333333333', '22222222-2222-2222-2222-222222222222', 'editor');

INSERT INTO wines (id, name, vintage, wine_type, country, region, producer, ideal_drinking_start, ideal_drinking_end, peak_drinking_end) VALUES
('44444444-4444-4444-4444-444444444441', 'Château Margaux', 2010, 'red', 'France', 'Bordeaux', 'Château Margaux', 2025, 2040, 2050),
('44444444-4444-4444-4444-444444444442', 'Domaine de la Romanée-Conti', 2015, 'red', 'France', 'Burgundy', 'DRC', 2025, 2045, 2055),
('44444444-4444-4444-4444-444444444443', 'Sassicaia', 2018, 'red', 'Italy', 'Tuscany', 'Tenuta San Guido', 2024, 2038, 2045),
('44444444-4444-4444-4444-444444444444', 'Cloudy Bay Sauvignon Blanc', 2023, 'white', 'New Zealand', 'Marlborough', 'Cloudy Bay', 2023, 2026, 2028),
('44444444-4444-4444-4444-444444444445', 'Dom Pérignon', 2012, 'sparkling', 'France', 'Champagne', 'Moët & Chandon', 2020, 2035, 2040);

INSERT INTO bottles (cellar_id, wine_id, added_by, owner_id, quantity, status, purchase_price) VALUES
('33333333-3333-3333-3333-333333333333', '44444444-4444-4444-4444-444444444441', '11111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 2, 'in_cellar', 800.00),
('33333333-3333-3333-3333-333333333333', '44444444-4444-4444-4444-444444444442', '11111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 1, 'in_cellar', 4000.00),
('33333333-3333-3333-3333-333333333333', '44444444-4444-4444-4444-444444444444', '22222222-2222-2222-2222-222222222222', '22222222-2222-2222-2222-222222222222', 6, 'in_cellar', 35.00);