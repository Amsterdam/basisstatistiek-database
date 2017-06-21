Definition of Done
==================

Een goede datatransformatie syntax moet aan een aantal eisen voldoen:

- Alle te transformeren gegevens moeten nieuw zijn voor de doeltabel.
- Er mag geen temporele redundantie optreden in de doeltabel na transformatie. [1]_.

Deze regels zorgen ervoor dat een transformatie geen andere gegevens mag opleveren als deze opnieuw gedraaid wordt met dezelfde brongegevens.

.. [1] Wanneer in een datatransformatie gegevens worden ingevoegd voor het nulpunt dan mag dit wel redundantie geven.
       Deze bronnen kunnen ons namelijk iets vertellen over de bekendheid van een gegeven in de historie voor het nulpunt.
       Oftewel, een gegeven blijkt al eerder bekend dan dat we met ons nulpunt suggereren.
