insert into persoon.adres (persoon_id, straat_id, huisnummer, huisletter, huisnummertoevoeging, land_id, postcode4, postcode2, geldig_op, kennisgegeven_op)
select
	persoon_id,
	straatcode,
	huisnummer,
	huisletter,
	huisnummertoevoeging,
	landcode,
	postcode4::bigint,
	postcode2,
	geldig_op,
	kennisgegeven_op
from
	(
	select
		distinct on(b.persoon_id, a.straatcode, a.huisnummer, a.huisletter, a.huisnummertoevoeging, a.landcode, a.postcode, a.begindatumrelatie, a.tijdstipbericht)
		b.persoon_id,
		a.straatcode,
		a.huisnummer,
		a.huisletter,
		a.huisnummertoevoeging,
		a.landcode,
		substring(a.postcode, 1, 4) as postcode4,
		substring(a.postcode, 5, 2) as postcode2,
		to_timestamp(a.begindatumrelatie::char(8), 'YYYYMMDD')::timestamp without time zone as geldig_op,
		to_timestamp(a.tijdstipbericht::char(16), 'YYYYMMDDHH24MISSMS')::timestamp without time zone as kennisgegeven_op,
		fieldorder
	from
		(select
			referentienummer,
			mutatiesoort,
			"Tijdstip bericht" AS tijdstipbericht,
			unnest(ARRAY["O_a_nummer", "N_a_nummer"]) AS a_nummer,
			unnest(ARRAY["O_bsn", "N_bsn"]) AS bs_nummer,
			unnest(ARRAY["O_datumBeginRelatie", "N_datumBeginRelatie"]) AS begindatumrelatie,
			unnest(ARRAY["O_straatcode", "N_straatcode"]) AS straatcode,
			unnest(ARRAY["O_huisnummer", "N_huisnummer"]) AS huisnummer,
			unnest(ARRAY["O_huisletter", "N_huisletter"]) AS huisletter,
			unnest(ARRAY["O_huisnummer toevoeging", "N_huisnummer toevoeging"]) AS huisnummertoevoeging,
			unnest(ARRAY["O_landcode", "N_landcode"]) AS landcode,
			unnest(ARRAY["O_postcode", "N_postcode"]) AS postcode,
			unnest(ARRAY[0, 1]) AS fieldorder
		from
			bron.brp_stuf_csv as a
		) as a
	inner join
		persoon.persoon_id as b
	on
		b.code = a.bs_nummer or code = a.a_nummer
	where
		(straatcode is not null
	or
		huisnummer is not null
	or
		huisletter is not null
	or
		huisnummertoevoeging is not null
	or
		landcode is not null
	or
		postcode is not null)
	and
		not exists (select
			1
		from
			persoon.adres as z
		where
			z.kennisgegeven_op = to_timestamp(a.tijdstipbericht::char(16), 'YYYYMMDDHH24MISSMS')::timestamp without time zone
		and
			z.geldig_op = to_timestamp(a.begindatumrelatie::char(8), 'YYYYMMDD')::timestamp without time zone
		and
			z.persoon_id = b.persoon_id
		and
			coalesce(z.straat_id, -1) = coalesce(a.straatcode, -1)
		and
			coalesce(z.huisnummer, -1) = coalesce(a.huisnummer, -1)
		and
			coalesce(z.huisletter, '-') = coalesce(a.huisletter, '-')
		and
			coalesce(z.huisnummertoevoeging, '-') = coalesce(a.huisnummertoevoeging, '-')
		and
			coalesce(z.land_id, -1) = coalesce(a.landcode, -1)
		and
			coalesce(z.postcode4, -1) = coalesce(substring(a.postcode, 1, 4)::int, -1)
		and
			coalesce(z.postcode2, '-') = coalesce(substring(a.postcode, 5, 2), '-')
		)
	) as a
--
-- Omdat we geen geldigheidsdatum hebben is het belangrijk dat we oud - nieuw situatie
-- in de correcte volgorde opslaan, dan kunnen achteraf de interne sleutel gebruiken
-- om de correcte volgorde van de gegevens weer op te halen.
--
order by persoon_id, geldig_op, kennisgegeven_op, fieldorder
