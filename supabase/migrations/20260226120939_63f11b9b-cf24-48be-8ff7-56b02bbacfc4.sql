DELETE FROM content
WHERE content_type = 'video'
AND id NOT IN (SELECT content_id FROM videos);