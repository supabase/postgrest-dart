INSERT INTO
    public.users (username, status, age_range, catchphrase)
VALUES
    ('supabot', 'ONLINE', '[1,2)'::int4range, 'fat cat'::tsvector),
    ('kiwicopple', 'OFFLINE', '[25,35)'::int4range, 'cat bat'::tsvector),
    ('awailas', 'ONLINE', '[25,35)'::int4range, 'bat rat'::tsvector),
    ('dragarcia', 'ONLINE', '[20,30)'::int4range, 'rat fat'::tsvector);

INSERT INTO
    public.channels (slug)
VALUES
    ('public'),
    ('random');

INSERT INTO
    public.messages (message, channel_id, username, inserted_at)
VALUES
    ('Hello World 👋', 1, 'supabot', '2021-06-25T04:28:21.598Z'),
    ('Perfection is attained, not when there is nothing more to add, but when there is nothing left to take away.', 2, 'supabot', '2021-06-29T04:28:21.598Z');

INSERT INTO
    personal.users (username, status, age_range)
VALUES
    ('supabot', 'ONLINE', '[1,2)'::int4range),
    ('kiwicopple', 'OFFLINE', '[25,35)'::int4range),
    ('awailas', 'ONLINE', '[25,35)'::int4range),
    ('dragarcia', 'ONLINE', '[20,30)'::int4range),
    ('leroyjenkins', 'ONLINE', '[20,40)'::int4range);

INSERT INTO
    public."TestTable" (slug)
VALUES
    ('public'),
    ('random');