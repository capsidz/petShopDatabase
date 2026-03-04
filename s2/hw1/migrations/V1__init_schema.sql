CREATE TABLE animal_type (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL
);

CREATE TABLE petshop (
    id              SERIAL PRIMARY KEY,
    address         VARCHAR(255) NOT NULL,
    name            VARCHAR(100) NOT NULL,
    pets_capacity   INT NOT NULL
);

CREATE TABLE employee (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    surname     VARCHAR(100) NOT NULL,
    profession  VARCHAR(100) NOT NULL
);

CREATE TABLE accessorie (
    id      SERIAL PRIMARY KEY,
    name    VARCHAR(100) NOT NULL
);

CREATE TABLE medication (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    description TEXT
);

CREATE TABLE food (
    id          SERIAL PRIMARY KEY,
    brand_name  VARCHAR(100) NOT NULL,
    food_type   VARCHAR(100) NOT NULL
);

CREATE TABLE breed (
    id              SERIAL PRIMARY KEY,
    breed_name      VARCHAR(100) NOT NULL,
    animal_type_id  INT NOT NULL REFERENCES animal_type(id),
    average_weight  NUMERIC(5,2)
);

CREATE TABLE client (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    surname         VARCHAR(100) NOT NULL,
    passport_data   VARCHAR(100) NOT NULL,
    petshop_id      INT NOT NULL REFERENCES petshop(id)
);


CREATE TABLE pet (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    age         INT,
    owner_id    INT REFERENCES client(id),
    breed_id    INT REFERENCES breed(id),
    food_id     INT REFERENCES food(id),
    petshop_id  INT REFERENCES petshop(id)
);

CREATE TABLE cage (
    id              SERIAL PRIMARY KEY,
    animal_type_id  INT REFERENCES animal_type(id),
    petshop_id      INT REFERENCES petshop(id),
    current_pet_id  INT REFERENCES pet(id)
);

CREATE TABLE cleaning_assignments (
    cleaner_id      INT NOT NULL REFERENCES employee(id),
    cage_id         INT NOT NULL REFERENCES cage(id),
    cleaning_date   DATE NOT NULL,
    is_completed    BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (cleaner_id, cage_id, cleaning_date)
);

CREATE TABLE keeper_assignments (
    keeper_id       INT NOT NULL REFERENCES employee(id),
    pet_id          INT NOT NULL REFERENCES pet(id),
    assignment_date DATE NOT NULL,
    PRIMARY KEY (keeper_id, pet_id, assignment_date)
);

CREATE TABLE pet_accessorie (
    pet_id          INT NOT NULL REFERENCES pet(id),
    accessorie_id   INT NOT NULL REFERENCES accessorie(id),
    PRIMARY KEY (pet_id, accessorie_id)
);


CREATE TABLE pet_medication (
    pet_id          INT NOT NULL REFERENCES pet(id),
    medication_id   INT NOT NULL REFERENCES medication(id),
    PRIMARY KEY (pet_id, medication_id)
);