insert into persoon.vestiging (persoon_id, land_id, type_id, gevestigd_op, kennisgegeven_op)
select
	persoon_id,
	land_id,
	type_id,
	gevestigd_op,
	kennisgegeven_op
from
	(select
		distinct on (b.persoon_id, a.tijdstipbericht, a.fieldorder)
		b.persoon_id,
		bs_nummer,
		land_id,
		a.type_id,
		lag(land_id) over (order by b.persoon_id, a.tijdstipbericht, a.fieldorder) as p_land_id,
		lag(to_timestamp(a.gevestigd_op::char(8), 'YYYYMMDD')::timestamp without time zone) over (order by b.persoon_id, a.tijdstipbericht, a.fieldorder) as p_gevestigd_op,
		lag(b.persoon_id) over (order by b.persoon_id, a.tijdstipbericht, a.fieldorder) as p_persoon_id,
		to_timestamp(a.gevestigd_op::char(8), 'YYYYMMDD')::timestamp without time zone as gevestigd_op,
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
			coalesce("O_landVanImmigratie", "O_land van emigratie") as o_land_id,
			coalesce("N_landVanImmigratie", "N_land van emigratie") as n_land_id,
			case when coalesce("O_landVanImmigratie", "O_land van emigratie") = "O_land van emigratie" then
				"O_datumBeginRelatie"
			else
				"O_datumVestigingNederland"
			end as o_gevestigd_op,
			case when coalesce("N_landVanImmigratie", "N_land van emigratie") = "N_land van emigratie" then
				"N_datumBeginRelatie"
			else
				"N_datumVestigingNederland"
			end as n_gevestigd_op,
			case when coalesce("N_landVanImmigratie", "N_land van emigratie") = "N_land van emigratie" then
				0
			else
				1
			end as type_id,
			unnest(ARRAY[coalesce("O_landVanImmigratie", "O_land van emigratie"), coalesce("N_landVanImmigratie", "N_land van emigratie")]) AS land_id,
			unnest(ARRAY[
				case when coalesce("O_landVanImmigratie", "O_land van emigratie") = "O_land van emigratie" then
					"O_datumBeginRelatie"
				else
					"O_datumVestigingNederland"
				end,
				case when coalesce("N_landVanImmigratie", "N_land van emigratie") = "N_land van emigratie" then
					"N_datumBeginRelatie"
				else
					"N_datumVestigingNederland"
				end]) as gevestigd_op,
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
						o_gevestigd_op != n_gevestigd_op
					or
						o_gevestigd_op is null
					or
						n_gevestigd_op is null
					)
				or
					(
						o_land_id != n_land_id
					or
						o_land_id is null
					or
						n_land_id is null
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
							land_id is not null
						or
							gevestigd_op is not null
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
							n_land_id is not null
						or
							n_gevestigd_op is not null
						)
					and
						(
							o_land_id is not null
						or
							o_gevestigd_op is not null
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
		persoon.vestiging as z
	where
		z.kennisgegeven_op = a.kennisgegeven_op
	and
		z.persoon_id = a.persoon_id
	and
		z.gevestigd_op = a.gevestigd_op
	and
		z.land_id = a.land_id
	and
		z.type_id = a.type_id
	)
and
	(
		(
			(
				(land_id != p_land_id or p_land_id is null)
			or
				(gevestigd_op != p_gevestigd_op or p_gevestigd_op is null)
			)
		and
			persoon_id = p_persoon_id
		)
	or
		(persoon_id != p_persoon_id or p_persoon_id is null)
	)
and
	(
		land_id is not null
	or
		gevestigd_op is not null
	)
order by persoon_id, kennisgegeven_op, fieldorder