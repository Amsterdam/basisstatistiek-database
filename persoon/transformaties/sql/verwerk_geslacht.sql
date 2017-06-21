insert into persoon.geslacht (persoon_id, type_id, kennisgegeven_op)
select
	persoon_id,
	type_id,
	kennisgegeven_op
from
	(select
		persoon_id,
		type_id,
		kennisgegeven_op,
		sortering,
		prioriteit
	from
		(select
			referentienummer,
			mutatiesoort,
			persoon_id,
			geslacht,
			--
			-- Selecteer de voorgaande records, om ze te ontdubbelen.
			--
			lag(a.geslacht) over (order by persoon_id, tijdstipbericht, sortering, prioriteit) as p_geslacht,
			lag(persoon_id) over (order by persoon_id, tijdstipbericht, sortering, prioriteit) as p_persoon_id,
			a.tijdstipbericht as kennisgegeven_op,
			sortering,
			prioriteit,
			opslaan,
			type_id
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
					o_geslacht,
					geslacht,
					sortering,
					0 as prioriteit,
					1 as opslaan,
					c.type_id
				from
					--
					-- Selecteer geslacht + kerngegevens uit csv
					--
					(select
						referentienummer,
						mutatiesoort,
						"Tijdstip bericht" as tijdstipbericht,
						unnest(ARRAY["O_a_nummer", "N_a_nummer"]) as a_nummer,
						unnest(ARRAY["O_bsn", "N_bsn"]) as bs_nummer,
						"N_geslachtsaanduiding" as n_geslacht,
						"O_geslachtsaanduiding" as o_geslacht,
						unnest(ARRAY["O_geslachtsaanduiding", "N_geslachtsaanduiding"]) as geslacht,
						unnest(ARRAY[0, 1]) as sortering
					from
						bron.brp_stuf_csv
					) as a
				inner join
					persoon.persoon_id as b
				on
					b.code = a.bs_nummer or code = a.a_nummer
				inner join
					persoon.geslacht_type as c
				on
					a.geslacht = c.afkorting
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
					b.afkorting as o_geslacht,
					b.afkorting as geslacht,
					0 as sortering,
					1 as prioriteit,
					0 as opslaan,
					b.type_id
				from
					persoon.geslacht as a
				inner join
					persoon.geslacht_type as b
				on
					a.type_id = b.type_id
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
				(geslacht != p_geslacht or p_geslacht is null)
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
		persoon.geslacht as z
	where
		a.type_id = z.type_id
	and
		a.persoon_id = z.persoon_id
	and
		a.kennisgegeven_op = z.kennisgegeven_op
	)
order by persoon_id, kennisgegeven_op, sortering, prioriteit