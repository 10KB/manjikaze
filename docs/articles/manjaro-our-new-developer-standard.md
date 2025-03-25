# Manjaro: Onze nieuwe standaard voor developers

De afgelopen 12 jaar hebben we bij 10KB veel verschillende besturingssystemen gebruikt. Van Windows met Ubuntu in VirtualBox, tot WSL, macOS, en native Ubuntu desktops... We hebben het allemaal gezien. Deze diversiteit bracht ons veel kennis en gaf ons toegang tot de beste ontwikkelervaring. Maar nu ons team groter is geworden, geeft deze versplintering ook uitdagingen die we nu willen aanpakken.

## De evolutie van onze ontwikkelomgevingen

We begonnen ooit op Windows-machines, omdat we hiermee de snelst beschikare hardware konden combineren met goede multi-monitor support. Toen we met Ruby gingen ontwikkeling introduceerden we Linux. Eerst via virtuele machines, toen WSL, en uiteindelijk stapten veel developers over op native Ubuntu.

Een bewuste keuze die we al jaren geleden maakten,  was om macOS links te laten liggen. Hoewel  Apple-hardware en -software ongetwijfeld kwaliteiten  hebben, past de gesloten aard ervan minder goed bij  onze tweaker-cultuur. Bovendien wilden we niet de beperkingen accepteren van relatief dure hardware die soms jaren achterliep qua prestaties en mogelijkheden.

Windows is sterk geëvolueerd als ontwikkelplatform met WSL en Docker-integratie. Toch blijft de performance van een native Linux-systeem superieur, wat voor ons cruciaal is. Dit is ook een van de redenen waarom we kiezen voor krachtige desktops in plaats van laptops - we willen geen compromissen sluiten als het gaat om rekenkracht.

Na al die jaren met verschillende systemen is het nu tijd voor de volgende stap: standaardisatie op Manjaro Linux.

## De knelpunten van onze huidige setup

Onze huidige situatie brengt meerdere problemen met zich mee:

1. **Verouderde systemen**: Sommige ontwikkelaars werken nog op oude Ubuntu- of Windows-versies, wat niet past bij ons technische profiel.
2. **Inconsistente updates**: Er is geen eenduidig updatebeleid, waardoor verschillende machines op verschillende patchniveaus zitten.
3. **Beveiligingsrisico's**: De diversiteit maakt het moeilijk om een consistent beveiligingsbeleid te handhaven.
4. **Inefficiënte kennisdeling**: Optimalisaties en configuratie-verbeteringen worden niet gemakkelijk gedeeld.

Daarnaast willen we de ISO27001-certificering behalen, wat een meer gestructureerde benadering van onze IT-infrastructuur vereist.

## Waarom Manjaro perfect past bij onze behoeften

Waar Ubuntu zich meer en meer richt op de eindgebruiker, kiezen wij bewust voor een iets technischere benadering met Manjaro. Niet omdat we houden van complexiteit, maar omdat we geloven dat dit beter aansluit bij de technische capaciteiten van ons team.

Ubuntu zet sterk in op technologieën als Snap en Flatpak. Een keuze die misschien logisch is voor consumenten, maar frustrerend werkt voor ontwikkelaars. Waarom? Het `apt`-ecosysteem fragmentariseert, opstarten van packages duurt langer, en de integratie met het systeem laat soms te wensen over.

Manjaro, gebaseerd op Arch Linux, biedt ons wat we nodig hebben:

1. **Rolling release model**: Altijd toegang tot de nieuwste ontwikkeltools.
2. **Pacman en AUR**: Een krachtige package manager met toegang tot vrijwel alle software die we nodig hebben.
3. **Technische gemeenschap**: Een community die gericht is op optimalisatie en het delen van kennis.
4. **Vrije window manager keuze**: Van de standaard GNOME-desktop tot alternatieven zoals i3.

## Technische voordelen

Het verschil tussen Ubuntu's LTS-model en Manjaro's rolling releases ervaren we dagelijks. Met Manjaro hebben we altijd de laatste versies van Docker, Git en andere tools - inclusief security updates en prestatieverbeteringen.

Met de officiële repositories en de Arch User  Repository (AUR) hebben we altijd alles direct  beschikbaar. Geen gedoe meer met handmatig PPAs  toevoegen, custom .deb-bestanden downloaden of  handmatig binaries uit een Github release kopieren  naar je systeem.

We integreren Yubikeys voor multifactor  authenticatie, full disk encryption en  GPG-toepassing, wat we naadloos integreren met  Manjaro.

Natuurlijk is geen enkel systeem perfect, en Manjaro heeft ook aandachtspunten. Het rolling release model vereist regelmatige updates; dit kan soms leiden tot package conflicts. Ook is de leercurve iets steiler voor wie alleen Windows of Ubuntu gewend is. Deze uitdagingen wegen echter niet op tegen de voordelen, en we geloven dat ze goed te managen zijn met goede documentatie en ondersteuning.

## Community en kennisdeling

Een van de belangrijkste redenen om te standaardiseren op één besturingssysteem is het creëren van een interne community rondom optimalisatie en kennis. Als iedereen hetzelfde basissysteem gebruikt, kunnen we:

1. Configuratie-verbeteringen gemakkelijk delen
2. Elkaar helpen bij bekende problemen
3. Samen leren en groeien in onze systeemkennis

Onze provisioning repository is niet bedoeld als een top-down dictaat, maar als een gezamenlijk project waaraan iedereen kan bijdragen. Net zoals bij open source projecten geloven we dat de beste ideeën komen wanneer gebruikers zelf problemen kunnen oplossen en hun oplossingen kunnen delen.

## Toekomstvisie

De overstap naar Manjaro is meer dan alleen een technische keuze - het is een investering in onze toekomst, die bijdraagt aan:

1. **ISO27001-certificering**: Met een uniform platform kunnen we beveiligingsmaatregelen eenvoudiger implementeren en controleren.
2. **Verhoogde productiviteit**: Door geoptimaliseerde ontwikkelomgevingen.
3. **Sterkere technische cultuur**: Bevorderen van continue verbetering en kennisdeling.

## Conclusie

De keuze voor Manjaro als onze developer standaard  is geen technische gril, maar een weloverwogen  beslissing. Deze keuze is gebaseerd op jarenlange  ervaring met verschillende systemen én uitvoerige  interne tests Ikzelf (Roland) werk al een half jaar met dit systeem, en ook Olaf test het enkele maanden.

Zoals DHH schreef over hun overstap naar Linux bij 37signals: "Het is niet omdat het gemakkelijk is, maar omdat het de moeite waard is." Wij geloven ook dat deze investering zich zal terugbetalen in de komende jaren. Het stelt ons in staat om consistenter, veiliger en efficiënter te werken - precies wat we nodig hebben om als technisch team te blijven groeien.
