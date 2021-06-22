BEGIN;

CREATE TABLE migration
    ( id SERIAL PRIMARY KEY
    , current VARCHAR(255)
    , timestamp TIMESTAMP WITH TIME ZONE
    )
;

ALTER TABLE migration ALTER COLUMN timestamp SET DEFAULT now();

INSERT INTO migration (current) VALUES ('0.sql');

COMMIT;