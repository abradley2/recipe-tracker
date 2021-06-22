BEGIN;

INSERT INTO migration (current) VALUES ('1.sql');

CREATE TABLE ingredient
    ( id SERIAL PRIMARY KEY
    , name VARCHAR(255)
    , created_at TIMESTAMP WITH TIME ZONE
    );

CREATE TABLE recipe
    ( id SERIAL PRIMARY KEY
    , name VARCHAR(255)
    , instructions TEXT
    , created_at TIMESTAMP WITH TIME ZONE
    );

CREATE TABLE recipe_ingredient
    ( id SERIAL PRIMARY KEY
    , recipe_id INT
    , ingredient_id INT
    , quantity VARCHAR(255)
    , created_at TIMESTAMP WITH TIME ZONE
    );

ALTER TABLE ingredient ALTER COLUMN created_at SET DEFAULT now();
ALTER TABLE recipe ALTER COLUMN created_at SET DEFAULT now();
ALTER TABLE recipe_ingredient ALTER COLUMN created_at SET DEFAULT now();

ALTER TABLE recipe_ingredient
ADD
FOREIGN KEY (recipe_id) REFERENCES recipe(id);

ALTER TABLE recipe_ingredient
ADD
FOREIGN KEY (ingredient_id) REFERENCES ingredient(id);

COMMIT;
