Database documentatie
=====================

Tabellen
--------

Per tabel staat beschreven wat de uitgangspunten zijn voor de data die in de tabel hoort te staat. Bij het doen van selecties moet men erop kunnen vertrouwen dat de data voldoet aan deze criteria. Degene die de tabel vult moet zich aan deze criteria houden.

Algemene criteria
-----------------

#. Er moet een valide koppeling zijn met een persoon.
#. Alle gegevens moeten uniek identificeerbaar zijn.
#. Alle opgeslagen datums moeten geldig zijn.
#. Nagekomen (correctie-)records dienen ingevoegd te worden zodanig dat ze voldoen aan de sortering kennisgevingsdatum en id, waarbij de nieuwste kennisgevingsdatum onderaan komt, en bij gelijke kennisgevingsdatums aan de hand van het id een oud - nieuw sortering te herleiden is.
#. Als het gegeven een datum betreft dan moet er een temporele consistentie zijn met de geldigheidsdatum.
#. Er moet een temporele consistentie zijn tussen geldigheidsdatum en kennisgevingsdatum.
#. Er mag geen redundantie aan gegevens in de database staan. Temporeel opvolgende records moeten altijd verschillende informatie bevatten.

persoon.persoon
---------------

Het unieke ID van een persoon in onze database.

Specifieke criteria
^^^^^^^^^^^^^^^^^^^

#. Elke uniek persoon mag en moet maar één keer een uniek ID toegekend krijgen.

persoon.persoon_type_id
-----------------------

Deze categorietabel bevat verschillende soorten identificatiekenmerken van een persoon waarvan de waardes opgeslagen worden in de persoon.persoon_id tabel.

persoon.persoon_id
------------------

Alle unieke (externe) idenfiticatiekenmerken van een persoon. Dit betreft vrijwel altijd een burgerservicenummer en een administratie nummer.

persoon.persoon_verwijderd
--------------------------

De status administratief verwijderd van een persoon.

Aanvullende criteria
^^^^^^^^^^^^^^^^^^^^

#. Wanneer een persoon niet als administratief verwijderd is aangemerkt dan bevat deze geen record voor deze persoon.
#. Wanneer een persoon wel als administratief is aangemerkt, dan

   #. Is er een record met status ``true``
   #. Is er een geldigheidsdatum vanaf het moment dat de verwijdering geldt.

#. Wanneer een persoon niet meer als administratief verwijderd staat aangemerkt, dan

   #. Is er een record met status ``false``
   #. Is er een geldigheidsdatum vanaf het moment dat de verwijdering niet meer geldt.

#. Er dient een temporele consistentie te zijn wat betreft de geldigheid van de verwijdering.

persoon.inschrijving
--------------------

In welke gemeente is een persoon sinds wanneer ingeschreven (incl. Amsterdam).

Aanvullende criteria
^^^^^^^^^^^^^^^^^^^^

#. Er moet een sluitende volgorde van intergemeentelijke verhuisbewegingen zijn, volgens één van volgende criteria:

   #. Alle actuele intergemeentelijke verhuisbewegingen van een persoon zijn beschikbaar en volgen logisch op elkaar.
   #. Verhuisbewegingen van en naar Amsterdam volgen logisch op elkaar, waarbij verhuisbewegingen buiten Amsterdam buiten beschouwing blijven.

persoon.vestiging
-----------------

In welk land is een persoon sinds wanneer gevestigd (incl. Nederland). De temporele samenhang tussen gegevens bepaalt vervolgens of het een emigratie of immigratie betreft.

Aanvullende criteria
^^^^^^^^^^^^^^^^^^^^

#. Zowel de vestigingsdatum, vestigingsland als de kennisgevingsdatum moeten ten alle tijden gevuld zijn.
#. Er moet een sluitende volgorde van migratiebewegingen tussen Nederland en het buitenland zijn, volgens één van volgende criteria:

   #. Alle actuele migratiestromen van een persoon tussen Nederland en het buitenland zijn beschikbaar en volgen logisch op elkaar (waarbij immigratie en emigratie elkaar moeten afwisselen).
   #. Migratiestromen van het buitenland naar Amsterdam en vice versa volgen logisch op elkaar, waarbij andere migratiebewegingen buiten beschouwing blijven.

persoon.adres
-------------

Op welk adres is een persoon op welk moment woonachtig.

Aanvullende criteria
^^^^^^^^^^^^^^^^^^^^

#. Er dient altijd een huisnummer bekend te zijn.
#. Er dient ofwel een postcode6 ofwel een straat koppeling te zijn.
#. Verhuisbewegingen tussen gemeenten moeten temporeel consistent zijn.
#. Er dient ofwel een postcode6 ofwel een gemeente koppeling te zijn.

persoon.geboorte
----------------

De geboortedatum van een persoon.

persoon.sterfte
^^^^^^^^^^^^^^^

De sterftedatum van een persoon.

Aanvullende criteria
^^^^^^^^^^^^^^^^^^^^

#. De kennisgevingsdatum en geldigheidsdatum moeten altijd gevuld zijn.
#. De sterftedatum is gevuld met de datum van overlijden.
#. De sterftedatum is leeg wanneer het eerder gemelde overlijden van deze persoon ongedaan is gemaakt
