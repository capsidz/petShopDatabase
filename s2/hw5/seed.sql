DO $$
DECLARE
    pet_record RECORD;
BEGIN
    FOR pet_record IN(
        SELECT * FROM (VALUES 
            (1, 'Барсик', 3, 1, 1, 1, 1),
            (2, 'Мурка', 2, 1, 2, 1, 1),
            (3, 'Кеша', 1, NULL, 4, 2, 2)
        ) AS t(id, name, age, owner_id, breed_id, food_id, petshop_id)
    )
    LOOP
        IF NOT EXISTS (SELECT 1 FROM pet WHERE id = pet_record.id) THEN
            INSERT INTO pet (id, name, age, owner_id, breed_id, food_id, petshop_id)
            VALUES (
                pet_record.id,
                pet_record.name,
                pet_record.age,
                pet_record.owner_id,
                pet_record.breed_id,
                pet_record.food_id,
                pet_record.petshop_id
            ); 
        END IF;
    END LOOP;
END $$;