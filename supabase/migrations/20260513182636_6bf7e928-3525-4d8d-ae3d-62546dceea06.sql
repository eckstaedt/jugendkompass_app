-- Update existing NULL titles to a placeholder before making the column NOT NULL
UPDATE messages SET title = '(Kein Titel)' WHERE title IS NULL;

-- Make title NOT NULL
ALTER TABLE messages ALTER COLUMN title SET NOT NULL;