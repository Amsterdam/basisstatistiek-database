create or replace function geef_bag_informatie_voor_adres (
	_postcode char(6),
	_straatcode bigint,
	_huisnummer int,
	_huisletter char(1),
	_huisnummertoevoeging char(5),
	_geldig_op timestamp without time zone
) returns table (
	nummer_id bigint,
	object_id bigint,
	buurt_id bigint,
	buurtcode text,
	straatcode integer,
	postcode character(6)
) as $$
select
	distinct on(y.lv_bag_nag_id)
	y.lv_bag_nag_id,
	z.object_id,
	z.brt_id,
	(z.brtsdl_sdl_stadsdeelcode || z.buurtcode),
	y.straatcode,
	y.postcode
from
	--
	-- Zoek de nummeraanduiding die het dichts bij de
	-- betreffende datum ligt ongeacht of dit voor of
	-- na deze datum is.
	--
	(select
		*
	from
		bron.bag_num_ontdubbelt as z
	inner join
		bron.bag_ore as q
	on
		z.ore_id = q.ore_id
	where
		(_postcode is not null or _straatcode is not null)
	and
		coalesce(_huisnummer, -999) = coalesce(z.huisnummer, -999)
	and
		coalesce(lower(_huisletter), '-') = coalesce(lower(z.huisletter), '-')
	and
		coalesce(lower(trim(_huisnummertoevoeging)), '-') = coalesce(lower(z.huisnummertoevoeging), '-')
	and
		(
			(
				coalesce(substr(_postcode, 1, 4)::int, 0000) = coalesce(substring(z.postcode, 1, 4)::int, 0000)
			and
				coalesce(substr(_postcode, 5, 2), '-') = coalesce(substring(z.postcode, 5, 2), '-')
			)
		or
			coalesce(q.straatcode, 0) = coalesce(_straatcode, 0)
		)
	and
		z.geldig_op <= _geldig_op
	and
		z.statuscode != 17
	order by
		abs(extract('day' from (z.geldig_op - _geldig_op))::int)
	limit 1
	) as y
left join
	(select
		lv_bag_vot_id as object_id,
		lv_bag_nag_id as lv_bag_nag_id
	from
		bron.bag_aos
	union all
	select
		lv_bag_lps_id as object_id,
		lv_bag_nag_id as lv_bag_nag_id
	from
		bron.bag_als
	union all
	select
		lv_bag_sps_id as object_id,
		lv_bag_nag_id as lv_bag_nag_id
	from
		bron.bag_ass
	) as x
on
	y.lv_bag_nag_id = x.lv_bag_nag_id
--
-- Zoek vervolgens alle objectcycli die bij
-- de betreffende nummeraanduiding horen, met
-- uitzondering van die cycli die gekoppeld zijn
-- aan een oude buurtindeling. Het object met de
-- cycli die vervolgens het dichtsbij onze datum
-- ligt wordt geselecteerd.
--
left join lateral
	(select
		*
	from
		(select
			lv_bag_vot_id as object_id,
			brt_id,
			geldig_op,
			objectcyclusnr
		from
			bron.bag_vot
		where
			x.object_id = lv_bag_vot_id
		union all
		select
			lv_bag_lps_id as object_id,
			brt_id,
			ingangsdatum_cyclus as geldig_op,
			objectcyclusnr
		from
			bron.bag_lps
		where
			x.object_id = lv_bag_lps_id
		union all
		select
			lv_bag_sps_id as object_id,
			brt_id,
			ingangsdatum_cyclus as geldig_op,
			objectcyclusnr
		from
			bron.bag_sps
		where
			x.object_id = lv_bag_sps_id
		) as a
	left join
		bron.bag_brt as q
	on
		q.sleutelverzendend = a.brt_id
	and
		tijdvakgeldigheid_einddatumtijdvakgeldigheid is null
	where
		/*
		 * Door de left join van hierboven
		 * komen ook alle objectcycli naar
		 * voren die niet matchen met de
		 * laatste buurtindeling.
		 *
		 * We willen die objectcycli echter
		 * alleen terug zien wanneer er vanuit
		 * het object er geen brt_id te vinden
		 * was, anders mogen die objectcycli
		 * genegeerd worden voor de latere
		 * checks.
		 */
		(
			a.brt_id is not null
		and
			q.buurtcode is not null
		)
	or
		(
			a.brt_id is null
		)
	) as z
on true
where
	z.geldig_op <= _geldig_op
order by
	y.lv_bag_nag_id, z.object_id,
	abs(extract('day' from z.geldig_op - _geldig_op)::int),
	z.objectcyclusnr desc;
$$
language SQL stable;
