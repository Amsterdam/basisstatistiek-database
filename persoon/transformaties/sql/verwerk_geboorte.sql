insert into persoon.geboorte (persoon_id, datum, kennisgegeven_op)
select
	persoon_id,
	datum,
	kennisgegeven_op
from
	(select
		persoon_id,
		datum,
		kennisgegeven_op,
		sortering,
		prioriteit
	from
		(select
			referentienummer,
			mutatiesoort,
			persoon_id,
			to_timestamp(a.datum::char(8), 'YYYYMMDD')::timestamp without time zone as datum,
			--
			-- Selecteer de voorgaande records, om ze te ontdubbelen.
			--
			lag(to_timestamp(a.datum::char(8), 'YYYYMMDD')::timestamp without time zone) over (order by persoon_id, tijdstipbericht, sortering, prioriteit) as p_datum,
			lag(persoon_id) over (order by persoon_id, tijdstipbericht, sortering, prioriteit) as p_persoon_id,
			a.tijdstipbericht as kennisgegeven_op,
			sortering,
			prioriteit,
			opslaan
		from
			(
			--
			-- Deze stap zorgt dat de tijdelijke union all tabel te gebruiken is
			-- in de volgende stap.
			--
			select
				*
			from
				(select
					referentienummer,
					mutatiesoort,
					to_timestamp(a.tijdstipbericht::char(16), 'YYYYMMDDHH24MISSMS')::timestamp without time zone as tijdstipbericht,
					b.persoon_id,
					o_datum,
					datum,
					sortering,
					0 as prioriteit,
					1 as opslaan
				from
					--
					-- Selecteer geboortedatum + kerngegevens uit csv
					--
					(select
						referentienummer,
						mutatiesoort,
						"Tijdstip bericht" AS tijdstipbericht,
						unnest(ARRAY["O_a_nummer", "N_a_nummer"]) as a_nummer,
						unnest(ARRAY["O_bsn", "N_bsn"]) as bs_nummer,
						"N_geboortedatum" as n_datum,
						"O_geboortedatum" as o_datum,
						unnest(ARRAY["O_geboortedatum", "N_geboortedatum"]) AS datum,
						unnest(ARRAY[0, 1]) as sortering
					from
						bron.brp_stuf_csv
					) as a
				inner join
					persoon.persoon_id as b
				on
					b.code = a.bs_nummer or code = a.a_nummer
				) as a
			union all
				--
				-- Selecteer de al opgeslagen gegevens.
				--
				select
					NULL as referentienummer,
					NULL as mutatiesoort,
					kennisgegeven_op as tijdstipbericht,
					persoon_id,
					to_char(datum, 'YYYYMMDD')::int as o_datum,
					to_char(datum, 'YYYYMMDD')::int as datum,
					0 as sortering,
					1 as prioriteit,
					0 as opslaan
				from
					persoon.geboorte
			order by
				persoon_id, tijdstipbericht, referentienummer, sortering
			) as a
		) as a
	where
		--
		-- Ontdubbel alle records, en filter alle records die we al opgeslagen hadden.
		--
		opslaan = 1
	and
		(
			(
				(datum != p_datum or p_datum is null)
			and
				persoon_id = p_persoon_id
			)
		or
			(persoon_id != p_persoon_id or p_persoon_id is null)
		)
	order by persoon_id, kennisgegeven_op, sortering, prioriteit
	) as a
--
-- Kijk van de definitief in te voegen set welke gegevens daadwerkelijk nieuw zijn.
--
where not exists
	(select
		1
	from
		persoon.geboorte as z
	where
		a.datum = z.datum
	and
		a.persoon_id = z.persoon_id
	and
		a.kennisgegeven_op = z.kennisgegeven_op
	)
order by persoon_id, kennisgegeven_op, sortering, prioriteit
