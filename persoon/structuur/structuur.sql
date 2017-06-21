create schema if not exists persoon;
create schema if not exists bron;

create table if not exists persoon.persoon (
	id serial8 primary key
);

create table if not exists persoon.persoon_id_type (
	id serial8 primary key,
	afkorting varchar(255),
	waarde varchar(45),
	geldig_van timestamp not null,
	geldig_tot timestamp
);

create table if not exists persoon.geslacht_type (
	id serial8 primary key,
	type_id integer,
	afkorting varchar(45),
	waarde varchar(45),
	geldig_van timestamp not null,
	geldig_tot timestamp
);

create table if not exists persoon.persoon_id (
	id serial8 primary key,
	persoon_id bigint references persoon.persoon(id) on delete restrict on update cascade,
	type_id bigint references persoon.persoon_id_type(id) on delete restrict on update cascade,
	code bigint not null,
	geldig_op timestamp without time zone,
	geregistreerd_op timestamp without time zone,
	opgeslagen_op timestamp without time zone default current_timestamp,
	kennisgegeven_op timestamp without time zone
);

create index persoon_id_code_idx on persoon.persoon_id(code);
create index persoon_id_persoon_id_idx on persoon.persoon_id(persoon_id);

create table if not exists persoon.persoon_verwijderd (
	id serial8 primary key,
	persoon_id bigint references persoon.persoon(id) on delete restrict on update cascade,
	status boolean not null,
	geldig_op timestamp without time zone,
	geregistreerd_op timestamp without time zone,
	opgeslagen_op timestamp without time zone default current_timestamp,
	kennisgegeven_op timestamp without time zone
);

create table if not exists persoon.geboorte (
	id serial8 primary key,
	persoon_id bigint references persoon.persoon(id) on delete restrict on update cascade,
	datum timestamp not null,
	geldig_op timestamp without time zone,
	geregistreerd_op timestamp without time zone,
	opgeslagen_op timestamp without time zone default current_timestamp,
	kennisgegeven_op timestamp without time zone
);

create index persoon_geboorte_datum_idx on persoon.geboorte(datum);
create index persoon_geboorte_persoon_id_idx on persoon.geboorte(persoon_id);

create table if not exists persoon.geslacht (
	id serial8 primary key,
	persoon_id bigint references persoon.persoon(id) on delete restrict on update cascade,
	type_id integer references persoon.geslacht_type(id),
	geldig_op timestamp without time zone,
	geregistreerd_op timestamp without time zone,
	opgeslagen_op timestamp without time zone default current_timestamp,
	kennisgegeven_op timestamp without time zone
);

create table if not exists persoon.inschrijving (
	id serial8 primary key,
	persoon_id bigint references persoon.persoon(id) on delete restrict on update cascade,
	gemeente_id bigint null,
	ingeschreven_op timestamp null,
	geldig_op timestamp without time zone,
	geregistreerd_op timestamp without time zone,
	opgeslagen_op timestamp without time zone default current_timestamp,
	kennisgegeven_op timestamp without time zone
);

create index persoon_inschrijving_ingeschreven_op_idx on persoon.inschrijving(ingeschreven_op);
create index persoon_inschrijving_persoon_id_idx on persoon.inschrijving(persoon_id);

create table if not exists persoon.vestiging (
	id serial8 primary key,
	persoon_id bigint references persoon.persoon(id) on delete restrict on update cascade,
	land_id bigint null,
	type_id int not null,
	gevestigd_op timestamp null,
	geldig_op timestamp without time zone,
	geregistreerd_op timestamp without time zone,
	opgeslagen_op timestamp without time zone default current_timestamp,
	kennisgegeven_op timestamp without time zone
);

create index persoon_vestiging_gevestigd_op_idx on persoon.vestiging(gevestigd_op);
create index persoon_vestiging_persoon_id_idx on persoon.vestiging(persoon_id);

create table if not exists persoon.sterfte (
	id serial8 primary key,
	persoon_id bigint references persoon.persoon(id) on delete restrict on update cascade,
	overleden_op timestamp,
	geldig_op timestamp without time zone,
	geregistreerd_op timestamp without time zone,
	opgeslagen_op timestamp without time zone default current_timestamp,
	kennisgegeven_op timestamp without time zone
);

create index persoon_sterfte_datum_idx on persoon.sterfte(overleden_op);
create index persoon_sterfte_persoon_id_idx on persoon.sterfte(persoon_id);

create table persoon.adres (
	id serial,
	persoon_id bigint references persoon.persoon(id) on update cascade on delete restrict,
	bag_id bigint,
	straat_id bigint,
	gemeente_id bigint,
	land_id bigint,
	huisnummer int,
	huisletter char(3),
	huisnummertoevoeging varchar(255),
	postcode4 int,
	postcode2 char(2),
	geldig_op timestamp without time zone,
	geregistreerd_op timestamp without time zone,
	opgeslagen_op timestamp without time zone default current_timestamp,
	kennisgegeven_op timestamp without time zone
);

create index persoon_adres_persoon_id_idx on persoon.geboorte(persoon_id);

insert into persoon.persoon_id_type (afkorting, waarde, geldig_van, geldig_tot) values
	('BSN', 'Burgerservice nummer', '19000101', NULL),
	('AN', 'A nummer', '19000101', NULL),
	('SV', 'Sleutelverzendend', '19000101', NULL);

insert into persoon.geslacht_type (type_id, afkorting, waarde, geldig_van, geldig_tot) values
	(1, 'M', 'Man', '19000101', NULL),
	(2, 'V', 'Vrouw', '19000101', NULL),
	(3, 'O', 'Onbekend', '19000101', NULL);