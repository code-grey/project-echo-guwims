# PostgreSQL 17 & PostGIS 3.5 Rules

1. **Spatial Types:** Use `geometry(Point, 4326)` for all coordinates. Do not use float latitude/longitude columns.
2. **Timezones:** Use `TIMESTAMPTZ` (UTC) exclusively.
3. **Ticket Enums:** Enforce `status` as an ENUM: 'REPORTED', 'CLUSTERED', 'DISPATCHED', 'RESOLVED'.
4. **Clustering:** Use `ST_DWithin` and `ST_SetSRID(ST_MakePoint(lng, lat), 4326)` for proximity calculations. Ensure queries cast coordinates geographically if required for accurate meter distances.

# PostgreSQL 17 & PostGIS 3.5 Rules for Project Echo

1. **UUIDv7 Mandate:** All primary keys utilize `uuid_generate_v7()`. Never generate UUIDv4s in the Go application layer; let the database handle insertion sequencing to prevent index fragmentation.
2. **Unified Identity:** The `users` table uses `university_id` (not `roll_number`). This accommodates both students and staff. Map the `user_role` ENUM strictly in Go.
3. **The Modularity Engine (`JSONB`):** The `reports` table replaces the concept of static tickets. Do not add domain-specific columns (like `waste_category` or `voltage_reading`) to the table schema. All custom data MUST be written to and read from the `metadata JSONB` column.
4. **Spatial Types:** Use `geometry(Point, 4326)` for all coordinates. Do not use float latitude/longitude columns. Ensure `sqlc` queries cast coordinates geographically using `ST_SetSRID(ST_MakePoint(lng, lat), 4326)` for accurate meter distances during `ST_DWithin` operations.
5. **Timezones:** Use `TIMESTAMPTZ` (UTC) exclusively. Do not rely on local server time.
