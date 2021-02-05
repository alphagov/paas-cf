DO $$
DECLARE
    installed_version text := NULL;
    upgrade_path text := NULL;
BEGIN
    IF NOT EXISTS (SELECT FROM pg_extension WHERE extname = 'postgis') THEN
        raise notice 'postgis is not installed. Stopping.';
        RETURN;
    END IF;

    SELECT extversion
    FROM pg_extension
    INTO installed_version
    WHERE extname = 'postgis';

    IF installed_version = '2.5.2' THEN
        raise notice '2.5.2 already installed';
        RETURN;
    ELSE
        raise notice 'current version is %. Will look to upgrade', installed_version;
    END IF;


    SELECT path
    FROM pg_extension_update_paths('postgis')
    INTO upgrade_path
    WHERE
        source = (SELECT extversion FROM pg_extension WHERE extname = 'postgis')
    AND target = '2.5.2';

    IF upgrade_path IS NULL THEN
        raise notice 'cannot upgrade postgis to 2.5.2. No upgrade path found from %', installed_version;
        RETURN;
    ELSE
        raise notice 'there is an upgrade path to 2.5.2: %', upgrade_path ;
        raise notice 'going to try upgrade to 2.5.2';

        ALTER EXTENSION postgis UPDATE TO '2.5.2';
    END IF;
END $$;
