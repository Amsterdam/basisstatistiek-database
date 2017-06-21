insert into persoon.sterfte (persoon_id, overleden_op, kennisgegeven_op)
select
	persoon_id,
	datum,
	kennisgegeven_op
from
	(select
		b.persoon_id,
		tijdstipbericht,
		mutatiesoort,
		lag(to_timestamp(a.datum::char(8), 'YYYYMMDD')::timestamp without time zone) over (order by b.persoon_id, a.tijdstipbericht, a.fieldorder) as p_datum,
		lag(b.persoon_id) over (order by b.persoon_id, a.tijdstipbericht, a.fieldorder) as p_persoon_id,
		to_timestamp(a.datum::char(8), 'YYYYMMDD')::timestamp without time zone as datum,
		to_timestamp(a.tijdstipbericht::char(16), 'YYYYMMDDHH24MISSMS')::timestamp without time zone as kennisgegeven_op,
		fieldorder
	from
		(select
			referentienummer,
			mutatiesoort,
			"Tijdstip bericht" AS tijdstipbericht,
			unnest(ARRAY["O_a_nummer", "N_a_nummer"]) AS a_nummer,
			unnest(ARRAY["O_bsn", "N_bsn"]) AS bs_nummer,
			"O_datum_overlijden" as n_datum,
			"N_datum_overlijden" as o_datum,
			unnest(ARRAY["O_datum_overlijden", "N_datum_overlijden"]) AS datum,
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
			-- betrekking heeft op de geboortedatum. Oftewel
			-- als de oude en nieuwe geboortedatum anders zijn.
			--
			(
					mutatiesoort in ('W', 'C')
			and
					(
							o_datum != n_datum
					or
							o_datum is null
					or
							n_datum is null
					)
			)
		)
	) as a
where
	not exists (select
		1
	from
		persoon.sterfte as z
	where
		z.kennisgegeven_op = a.kennisgegeven_op
	and
		z.persoon_id = a.persoon_id
	and
		z.overleden_op = a.datum
	)
and
	(
		(
			(
				(
					(datum != p_datum or p_datum is null)
				and
					persoon_id = p_persoon_id
				)
			or
				(persoon_id != p_persoon_id or p_persoon_id is null)
			)
		and
			datum is not null
		)
	or
		--
		-- Wanneer na een wijziging over overlijden een toevoegingsbericht volgt,
		-- dan wordt daarmee de vorige overlijden ongedaan gemaakt.
		--
		(
			to_timestamp(tijdstipbericht::char(8), 'YYYYMMDD')::timestamp without time zone > p_datum
		and
			(persoon_id = p_persoon_id or p_persoon_id is null)
		and
			mutatiesoort = 'T'
		)
	)
order by persoon_id, kennisgegeven_op, fieldorder
