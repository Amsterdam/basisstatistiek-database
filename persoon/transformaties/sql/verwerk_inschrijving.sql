--
-- Interessante cases
-- - 691026853
-- - 510657515
--

insert into persoon.inschrijving (persoon_id, gemeente_id, ingeschreven_op, kennisgegeven_op)
select
	persoon_id,
	gemeente_id,
	ingeschreven_op,
	kennisgegeven_op
from
	(select
		distinct on (b.persoon_id, a.tijdstipbericht, a.fieldorder)
		b.persoon_id,
		a.gemeente_id,
		lag(gemeente_id) over (order by b.persoon_id, a.tijdstipbericht, a.fieldorder) as p_gemeente_id,
		lag(to_timestamp(a.ingeschreven_op::char(8), 'YYYYMMDD')::timestamp without time zone) over (order by b.persoon_id, a.tijdstipbericht, a.fieldorder) as p_ingeschreven_op,
		lag(b.persoon_id) over (order by b.persoon_id, a.tijdstipbericht, a.fieldorder) as p_persoon_id,
		to_timestamp(a.ingeschreven_op::char(8), 'YYYYMMDD')::timestamp without time zone as ingeschreven_op,
		to_timestamp(a.tijdstipbericht::char(16), 'YYYYMMDDHH24MISSMS')::timestamp without time zone as kennisgegeven_op,
		fieldorder,
		mutatiesoort,
		referentienummer
	from
		(select
			referentienummer,
			mutatiesoort,
			"Tijdstip bericht" AS tijdstipbericht,
			unnest(ARRAY["O_a_nummer", "N_a_nummer"]) AS a_nummer,
			unnest(ARRAY["O_bsn", "N_bsn"]) AS bs_nummer,
			"O_datumInschrijvingGemeente" as o_ingeschreven_op,
			"N_datumInschrijvingGemeente" as n_ingeschreven_op,
			"O_gemeenteVanInschrijving" as o_gemeente_id,
			"N_gemeenteVanInschrijving" as n_gemeente_id,
			unnest(ARRAY["O_gemeenteVanInschrijving", "N_gemeenteVanInschrijving"]) AS gemeente_id,
			unnest(ARRAY["O_datumInschrijvingGemeente", "N_datumInschrijvingGemeente"]) AS ingeschreven_op,
			unnest(ARRAY[0, 1]) AS fieldorder
		from
			bron.brp_stuf_csv
		) as a
	inner join
		persoon.persoon_id as b
	on
		b.code = a.bs_nummer or code = a.a_nummer
	where
		(
			--
			-- Als het een toevoeging betreft
			-- dan selecteren we alleen de nieuwe waarde.
			--
			(mutatiesoort = 'T' and fieldorder = 1)
		or
			--
			-- Als het een wijziging of correctie betreft
			-- dan verwerken we deze alleen als de correctie
			-- betrekking heeft op de inschrijvingsdatum
			-- of de gemeente van inschrijving. Oftewel
			-- als de oude en nieuwe inschrijvingsdatum of
			-- gemeente van inschrijving anders is.
			--
			(
				mutatiesoort in ('W', 'C')
			and
				(
					(
						o_ingeschreven_op != n_ingeschreven_op
					or
						o_ingeschreven_op is null
					or
						n_ingeschreven_op is null
					)
				or
					(
						o_gemeente_id != n_gemeente_id
					or
						o_gemeente_id is null
					or
						n_gemeente_id is null
					)
				)
			and
				--
				-- Een correctiebericht mag nooit corrigeren naar
				-- een onbekende waarde. Dus de relevante "nieuwe"
				-- velden moeten waardes bevatten.
				--
				(
					(
						fieldorder = 1
					and
						(
							gemeente_id is not null
						or
							ingeschreven_op is not null
						)
					)
				or
				--
				-- Ook als de "oude" velden gevuld zijn, dan moeten
				-- ze leiden tot velden die waardes bevatten in
				-- de nieuwe situatie.
				--
					(
						fieldorder = 0
					and
						(
							n_gemeente_id is not null
						or
							n_ingeschreven_op is not null
						)
					and
						(
							o_gemeente_id is not null
						or
							o_ingeschreven_op is not null
						)
					)
				)
			)
		)
	) as a
where
	not exists (select
		1
	from
		persoon.inschrijving as z
	where
		z.kennisgegeven_op = a.kennisgegeven_op
	and
		z.persoon_id = a.persoon_id
	and
		z.ingeschreven_op = a.ingeschreven_op
	and
		z.gemeente_id = a.gemeente_id
	)
and
	(
		(
			(
				(gemeente_id != p_gemeente_id or p_gemeente_id is null)
			or
				(ingeschreven_op != p_ingeschreven_op or p_ingeschreven_op is null)
			)
		and
			persoon_id = p_persoon_id
		)
	or
		(persoon_id != p_persoon_id or p_persoon_id is null)
	)
and
	(
			gemeente_id is not null
	or
			ingeschreven_op is not null
	)
order by persoon_id, kennisgegeven_op, fieldorder