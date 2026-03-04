ALTER TABLE pet 
ADD CONSTRAINT pet_age_positive 
CHECK (age > 0);

ALTER TABLE petshop
ADD CONSTRAINT pets_capacity_non_negative
CHECK (pets_capacity >= 0);
