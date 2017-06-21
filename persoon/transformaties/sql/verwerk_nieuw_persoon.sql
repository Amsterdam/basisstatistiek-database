drop materialized view bron.persoon_id;
create materialized view bron.persoon_id as
select
	distinct on (a.referentienummer, a.mutatiesoort, a.tijdstipbericht, a.a_nummer, a.bs_nummer)
	a.referentienummer,
	a.mutatiesoort,
	a.tijdstipbericht,
	a.a_nummer,
	a.bs_nummer,
	a.fieldorder
from
	(select
		referentienummer,
		mutatiesoort,
		"Tijdstip bericht" AS tijdstipbericht,
		unnest(ARRAY["O_a_nummer", "N_a_nummer"]) AS a_nummer,
		unnest(ARRAY["O_bsn", "N_bsn"]) AS bs_nummer,
		unnest(ARRAY[0, 1]) AS fieldorder
	from
		bron.brp_stuf_csv
	) as a
where
	a_nummer is not null
or
	bs_nummer is not null;

create index persoon_id_a_nummer_idx on bron.persoon_id(a_nummer);
create index persoon_id_bs_nummer_idx on bron.persoon_id(bs_nummer);

select * from verwerk_nieuw_persoon();
