-- name: CreateReport :one
INSERT INTO reports (reporter_id, location_geom, image_url, metadata)
VALUES ($1, ST_SetSRID(ST_MakePoint($2, $3), 4326), $4, $5)
RETURNING id, reporter_id, status, image_url, metadata, created_at, ST_X(location_geom::geometry) as longitude, ST_Y(location_geom::geometry) as latitude;

-- name: GetReportsWithinRadius :many
SELECT r.id, r.reporter_id, u.university_id as reporter_university_id, r.status, r.image_url, r.metadata, r.created_at, ST_X(r.location_geom::geometry) as longitude, ST_Y(r.location_geom::geometry) as latitude 
FROM reports r
JOIN users u ON r.reporter_id = u.id
WHERE ST_DWithin(r.location_geom::geography, ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography, $3);

-- name: GetReportByID :one
SELECT id, reporter_id, status, image_url, metadata, created_at, ST_X(location_geom::geometry) as longitude, ST_Y(location_geom::geometry) as latitude FROM reports WHERE id = $1;

-- name: UpdateReportStatus :exec
UPDATE reports SET status = $2 WHERE id = $1;

-- name: UpdateReportMetadata :exec
UPDATE reports SET metadata = $2 WHERE id = $1;

-- name: GetUserByUniversityID :one
SELECT * FROM users WHERE university_id = $1;

-- name: GetUserByID :one
SELECT * FROM users WHERE id = $1;

-- name: DeleteReport :exec
DELETE FROM reports WHERE id = $1;
