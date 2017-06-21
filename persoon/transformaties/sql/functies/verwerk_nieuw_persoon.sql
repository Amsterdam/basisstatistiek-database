CREATE OR REPLACE FUNCTION public.verwerk_nieuw_persoon() RETURNS TABLE (
	status1 varchar(255),
	aantal1 bigint,
	status2 varchar(255),
	aantal2 bigint
) AS
$BODY$
DECLARE
	--
	-- FIXME:
	--  De datum velden moeten correct gevuld worden.
	--
	stufcsvrij record;
	persoonrij record;
	persoonid bigint;
	nrrows int;
	bsn_type_id int;
	a_nummer_type_id int;
	aantal_voor_id bigint;
	aantal_na_id bigint;
	aantal_voor_persoon bigint;
	aantal_na_persoon bigint;
BEGIN
	aantal_voor_id := (select count(*) from persoon.persoon_id);
	aantal_voor_persoon := (select count(*) from persoon.persoon);
	--
	-- Selecteer de ID's van de verschillende interne sleutels
	--
	bsn_type_id := (select id from persoon.persoon_id_type where afkorting = 'BSN');
	a_nummer_type_id := (select id from persoon.persoon_id_type where afkorting = 'AN');
	FOR stufcsvrij IN
		--
		-- Selecteer alle rijen uit de bron waarvan we de bsn / anummer combinatie nog niet kennen.
		--
		select
			*
		from
			(select
				mutatiesoort,
				to_timestamp(tijdstipbericht::char(16), 'YYYYMMDDHH24MISSMS')::timestamp without time zone as tijdstipbericht,
				a_nummer,
				bs_nummer,
				fieldorder
			from
				bron.persoon_id
			) as a
			where
				a_nummer is not null
			and
				bs_nummer is not null
			and
				not exists (select
					1
				from
					(
					select
						persoon_id,
						code as a_nummer
					from
						persoon.persoon_id
					where
						type_id = a_nummer_type_id
					and
						a.a_nummer = code
					and
						a.tijdstipbericht = kennisgegeven_op
					) as b
				inner join
					(
					select
						persoon_id,
						code as bs_nummer
					from
						persoon.persoon_id
					where
						type_id = bsn_type_id
					and
						a.bs_nummer = code
					and
						a.tijdstipbericht = kennisgegeven_op
					) as c
				on
					b.persoon_id = c.persoon_id
				)
			order by tijdstipbericht, fieldorder
	LOOP
		--
		-- Kijk of we al een persoon kunnen identificeren aan de hand van het a-nummer of bs-nummer.
		-- Zo ja, dan voegen we de nieuwe informatie (wanneer nodig) toe aan deze persoon.
		--
		FOR persoonrij IN
			select
				distinct on(persoon_id, type_id)
				*
			from
				persoon.persoon_id as b
			where
				(
					b.code = stufcsvrij.bs_nummer
				and
					b.type_id = bsn_type_id
				)
			or
				(
					b.code = stufcsvrij.a_nummer
				and
					b.type_id = a_nummer_type_id
				)
		LOOP
			--
			-- Nieuwe informatie wordt alleen toegevoegd als we deze nog niet bij deze persoon hebben opgeslagen.
			--
			IF (select count(*) from persoon.persoon_id where code = stufcsvrij.bs_nummer and type_id = bsn_type_id and persoon_id = persoonrij.persoon_id) = 0 THEN
--			RAISE NOTICE 'voeg nieuw bs_nummer % aan persoon %', stufcsvrij.bs_nummer, persoonrij.persoon_id;
				insert into persoon.persoon_id (persoon_id, type_id, code, kennisgegeven_op) values (persoonrij.persoon_id, bsn_type_id, stufcsvrij.bs_nummer, stufcsvrij.tijdstipbericht);
			ELSE
-- 				RAISE NOTICE 'a_nummer % is al bekend voor persoon %', stufcsvrij.bs_nummer, persoonrij.persoon_id;
			END IF;
			IF (select count(*) from persoon.persoon_id where code = stufcsvrij.a_nummer and type_id = a_nummer_type_id and persoon_id = persoonrij.persoon_id) = 0 THEN
--			RAISE NOTICE 'voeg nieuw a_nummer % aan persoon %', stufcsvrij.a_nummer, persoonrij.persoon_id;
				insert into persoon.persoon_id (persoon_id, type_id, code, kennisgegeven_op) values (persoonrij.persoon_id, a_nummer_type_id, stufcsvrij.a_nummer, stufcsvrij.tijdstipbericht);
			ELSE
-- 				RAISE NOTICE 'bs_nummer % is al bekend voor persoon %', stufcsvrij.bs_nummer, persoonrij.persoon_id;
			END IF;
		END LOOP;
		IF NOT FOUND THEN
			--
			-- Als deze persoon nog niet bestaat, dan voegen we in.
			--
			insert into persoon.persoon default values returning id into persoonid;
			insert into persoon.persoon_id (persoon_id, type_id, code, kennisgegeven_op) values (persoonid, a_nummer_type_id, stufcsvrij.a_nummer, stufcsvrij.tijdstipbericht);
			insert into persoon.persoon_id (persoon_id, type_id, code, kennisgegeven_op) values (persoonid, bsn_type_id, stufcsvrij.bs_nummer, stufcsvrij.tijdstipbericht);
-- 			RAISE NOTICE 'nieuw persoon % met bs_nummer % en/of a_nummer %', persoonid, stufcsvrij.bs_nummer, stufcsvrij.a_nummer;
		END IF;
	END LOOP;
	aantal_na_id := (select count(*) from persoon.persoon_id);
	aantal_na_persoon := (select count(*) from persoon.persoon);

	RETURN QUERY SELECT 'aantal nieuwe rijen in persoon:'::varchar, (aantal_na_id - aantal_voor_id)::bigint, 'aantal nieuwe rijen in persoon_id'::varchar, (aantal_na_persoon - aantal_voor_persoon)::bigint;
END
$BODY$
LANGUAGE plpgsql;
