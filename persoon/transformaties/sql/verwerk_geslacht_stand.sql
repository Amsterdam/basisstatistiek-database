insert into persoon.geslacht (persoon_id, type_id, kennisgegeven_op)
select
	distinct on(b.persoon_id)
	b.persoon_id,
	c.type_id,
	to_timestamp((a.jaar || '010100000000')::char(16), 'YYYYMMDDHH24MISSMS')::timestamp without time zone as kennisgegeven_op
from
	bron.kw20161 as a
inner join
	persoon.persoon_id as b
on
	b.code = a.bsnumm or code = a.anummr
inner join
	persoon.geslacht_type as c
on
	a.gslcha = c.afkorting;