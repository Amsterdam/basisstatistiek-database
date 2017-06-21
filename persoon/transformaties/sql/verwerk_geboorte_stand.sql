insert into persoon.geboorte (persoon_id, datum, kennisgegeven_op)
select
	distinct on(b.persoon_id)
	b.persoon_id,
	to_timestamp(a.gbdtb8::char(8), 'YYYYMMDD')::timestamp without time zone as datum,
	to_timestamp((a.jaar || '010100000000')::char(16), 'YYYYMMDDHH24MISSMS')::timestamp without time zone as kennisgegeven_op
from
	bron.kw20161 as a
inner join
	persoon.persoon_id as b
on
	b.code = a.bsnumm or code = a.anummr;