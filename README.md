# Project Echo (GU-WIMS) 🌍
**Smart Campus Waste Intelligence Platform for Gauhati University**

Built by Adrish Bora & Simanjit Hujuri (B.Tech CSE, 6th Semester).

Project Echo is a zero-infrastructure-cost, geospatial ticketing system designed to optimize university sanitation. It replaces static routing and manual reporting with automated spatial clustering and AI categorization.

## Architecture
- **Backend:** Go 1.26 (Hexagonal Architecture, standard `net/http`)
- **Database:** PostgreSQL 17 + PostGIS 3.5 (Supabase)
- **Mobile Client:** Flutter 3.2x (Dart 3, Riverpod, Isolate-driven compression)
- **Storage:** Cloudinary / Cloudflare R2 (Adapter pattern)

## Key Engineering Features
- **Air-Gapped Auth:** Custom Roll Number + PIN JWT engine bypassing OAuth restrictions.
- **BOLA Protection:** Strict object-level authorization enforced at the repository layer.
- **Spatial Deduplication:** PostGIS `ST_DWithin` algorithms to cluster redundant garbage reports within a 10-meter radius.
- **Data Integrity:** Client-side Dart Isolate compression that strictly preserves EXIF metadata (GPS/Timestamps) to prevent location spoofing.