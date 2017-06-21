drop materialized view bron.persoon_id;
create materialized view bron.persoon_id as
select 'T'::char(1) as mutatiesoort, (jaar || '010100000000') as tijdstipbericht, anummr as a_nummer, bsnumm as bs_nummer, 0 as fieldorder from bron.kw20141;


create index persoon_id_a_nummer_idx on bron.persoon_id(a_nummer);
create index persoon_id_bs_nummer_idx on bron.persoon_id(bs_nummer);

select * from verwerk_nieuw_persoon();