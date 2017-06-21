insert into persoon.adres (persoon_id, straat_id, huisnummer, huisletter, huisnummertoevoeging, land_id, postcode4, postcode2, geldig_op, kennisgegeven_op)
select
	distinct on(b.persoon_id)
	b.persoon_id,
	strkod,
	huisnr,
	huislt,
	hstoev,
	NULL,
	substring(pttkod, 1, 4)::int,
	substring(pttkod, 5, 2),
	case when vstdta != 0 then
		to_timestamp(vstdta::char(8), 'YYYYMMDD')::timestamp without time zone
	else
		NULL
	end,
	to_timestamp((a.jaar || '010100000000')::char(16), 'YYYYMMDDHH24MISSMS')::timestamp without time zone as kennisgegeven_op
from
	bron.kw20161 as a
inner join
	persoon.persoon_id as b
on
	b.code = a.bsnumm or code = a.anummr;