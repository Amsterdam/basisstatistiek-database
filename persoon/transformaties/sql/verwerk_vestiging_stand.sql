insert into persoon.vestiging (persoon_id, land_id, gevestigd_op, type_id, kennisgegeven_op)
select
	distinct on(b.persoon_id)
	b.persoon_id,
	case when lndimm is not null then
		lndimm
	else
		6030
	end,
	case when vstned = 0 then
		to_timestamp(gbdtb8::char(8), 'YYYYMMDD')::timestamp without time zone
	else
		to_timestamp(vstned::char(8), 'YYYYMMDD')::timestamp without time zone
	end,
	1,
	to_timestamp((a.jaar || '010100000000')::char(16), 'YYYYMMDDHH24MISSMS')::timestamp without time zone as kennisgegeven_op
from
	bron.kw20151 as a
inner join
	persoon.persoon_id as b
on
	b.code = a.bsnumm or code = a.anummr;