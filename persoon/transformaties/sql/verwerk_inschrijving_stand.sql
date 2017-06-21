insert into persoon.inschrijving (persoon_id, gemeente_id, ingeschreven_op, kennisgegeven_op)
select
	distinct on(b.persoon_id)
	b.persoon_id,
	363,
	case when vstdgr = 0 then
		to_timestamp(gbdtb8::char(8), 'YYYYMMDD')::timestamp without time zone
	else
		to_timestamp(vstdgr::char(8), 'YYYYMMDD')::timestamp without time zone
	end,
	to_timestamp((a.jaar || '010100000000')::char(16), 'YYYYMMDDHH24MISSMS')::timestamp without time zone as kennisgegeven_op
from
	bron.kw20161 as a
inner join
	persoon.persoon_id as b
on
	b.code = a.bsnumm or code = a.anummr;
