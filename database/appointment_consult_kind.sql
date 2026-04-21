-- Optional migration if your appointments table does not persist consultation mode.
-- Flutter sends `consultKind`: "VIDEO" (online) or "IN_PERSON" (clinic) when booking.
-- Rename table/column to match your ORM (e.g. snake_case vs camelCase).

-- PostgreSQL-style:
-- ALTER TABLE appointments
--   ADD COLUMN IF NOT EXISTS consult_kind VARCHAR(32) NOT NULL DEFAULT 'IN_PERSON';
-- CREATE INDEX IF NOT EXISTS idx_appointments_consult_kind ON appointments (consult_kind);
