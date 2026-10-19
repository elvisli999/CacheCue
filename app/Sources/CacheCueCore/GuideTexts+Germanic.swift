// The guide's lessons in German, Dutch and Swedish. Same lessons, same points, as `Guide.en`.

extension Guide {
    static let de: [String: Text] = [
        "context-cost": Text(
            title: "Warum lange Sitzungen teuer werden",
            summary: "Jede Anfrage schickt das ganze Gespräch erneut mit.",
            points: [
                "Claude Code merkt sich zwischen zwei Anfragen nichts. Jede Anfrage trägt deshalb alles mit: den Systemprompt, den Projektkontext, jede Nachricht und jedes Tool-Ergebnis.",
                "Jedes Mal, wenn Claude Tools benutzt, ist das eine weitere Anfrage mit dem gesamten Verlauf. Ein einziger Auftrag kann Dutzende Anfragen bedeuten.",
                "Prompt-Caching berechnet den unveränderten Teil zum Cache-Tarif, einem Zehntel des normalen Eingabepreises oder weniger. Günstig, aber nicht kostenlos, und es wächst mit dem Kontext.",
                "Eine einzeilige Frage in einer Sitzung, die den ganzen Tag offen war, bezahlt also trotzdem für das gesamte Gespräch.",
            ],
            takeaway: "Was du bei jeder Anfrage bezahlst, ist die Größe deines Kontexts."),
        "cache-clock": Text(
            title: "Warm und kalt: Der Cache hat eine Uhr",
            summary: "Wer zu lange pausiert, zahlt für die nächste Nachricht den vollen Preis.",
            points: [
                "Ein gecachtes Gespräch läuft nach einer Zeit der Inaktivität ab. Jede Anfrage, die es liest, setzt den Timer zurück. Solange du arbeitest, bleibt der Cache warm.",
                "Mit einem Claude-Abo, innerhalb des im Tarif enthaltenen Kontingents, hält der Cache des Hauptgesprächs eine Stunde. Mit Nutzungsguthaben, einem API-Schlüssel oder einem Cloud-Anbieter sind es standardmäßig fünf Minuten.",
                "Nach dem Ablauf verarbeitet deine nächste Nachricht den gesamten Kontext neu: langsamer und deutlich teurer. Ein Cache-Schreibvorgang für eine Stunde kostet das Doppelte des Basis-Eingabepreises, ein Lesevorgang ein Zehntel oder weniger: mindestens das 20-Fache.",
                "Wie viel teurer, hängt vom Modell ab: 40-mal bei Opus 5.5 und Sonnet 5.5, 80-mal bei Fable 5.1, dessen Cache-Lesen günstiger ist. Ein 5-Minuten-Cache wird zum 1,25-Fachen des Basispreises geschrieben, nicht zum Doppelten. Die Einstellung promptCacheTtl wählt die Lebensdauer.",
                "Die Uhr von CacheCue zeigt die verbleibende Zeit. Wenn sie fast abgelaufen ist und du gerade weggehst, ist das der Moment zu handeln.",
            ],
            takeaway: "Arbeite weiter und der Cache bleibt warm. Bleibst du länger weg als erlaubt, zahlst du alles noch einmal."),
        "compact-cost": Text(
            title: "Was /compact wirklich kostet",
            summary: "Einen Bruchteil bei warmem Cache, den ganzen Kontext bei kaltem.",
            points: [
                "Um die Zusammenfassung zu schreiben, schickt Claude Code eine weitere Anfrage: deinen gesamten Verlauf plus die Anweisung, ihn zusammenzufassen.",
                "Solange der Cache warm ist, liest diese Anfrage deinen Verlauf aus dem Cache. Komprimieren kostet dann nur einen Bruchteil dessen, was die Kontextgröße vermuten lässt.",
                "Ist der Cache abgelaufen, gibt es nichts zu lesen, und dieselbe Anfrage verarbeitet alles ungecacht neu. Das ist der teuerste Zeitpunkt zum Komprimieren.",
                "In beiden Fällen wird es danach günstig: Der nächste Zug muss nur die kurze Zusammenfassung cachen.",
                "Bei kleinem Kontext gibt es wenig abzuwerfen. Die Zusammenfassungsanfrage kostet dann mehr, als sie spart.",
            ],
            takeaway: "Komprimiere, solange der Cache warm ist, und nur, wenn es genug abzuwerfen gibt."),
        "best-moment": Text(
            title: "Der beste Moment zum Komprimieren",
            summary: "Zwischen zwei Aufgaben, Cache warm, Kontext groß.",
            points: [
                "An einem natürlichen Haltepunkt: Eine Aufgabe ist fertig, die nächste hat noch nicht begonnen. Komprimieren verwirft Details, und mitten in der Aufgabe sind es genau diese Details, mit denen du arbeitest.",
                "Bevor du länger weggehst, als die Uhr noch anzeigt. Erst komprimieren, dann gehen. Zu einem kalten Cache zurückzukommen und dann zu komprimieren, ist die teure Reihenfolge.",
                "Wenn der Kontext groß ist. Die Faustregel von CacheCue sind 100k Tokens: Ab dort liest jede Anfrage so viel neu ein, dass sich das Komprimieren schnell bezahlt macht.",
                "Bevor die automatische Komprimierung es für dich tut. Sie springt an, wenn das Fenster fast voll ist, zu einem Zeitpunkt, den sie selbst wählt, womöglich mitten in einer Aufgabe.",
                "Sag, was erhalten bleiben soll: /compact konzentriere dich auf die API-Änderungen und die fehlschlagenden Tests.",
            ],
            takeaway: "Wähle den Moment selbst: zwischen zwei Aufgaben, solange die Uhr noch läuft."),
        "compact-clear-rewind": Text(
            title: "/compact, /clear oder /rewind?",
            summary: "Drei Wege, ein Gespräch zu verkleinern, für drei Situationen.",
            points: [
                "/clear fängt neu an und kostet nichts. Nimm es, wenn die nächste Arbeit nichts mit der jetzigen zu tun hat. Führe vorher /rename aus, dann findest du die Sitzung später mit /resume wieder.",
                "/compact behält den roten Faden als Zusammenfassung. Nimm es, wenn du an derselben Sache weiterarbeitest und brauchst, was entschieden wurde, nicht jeden Schritt dorthin.",
                "/rewind geht zu einem früheren Zug zurück. Nimm es, um einen falschen Weg aufzugeben: Das Gespräch bis dorthin liegt schon im Cache, es muss nichts neu aufgebaut werden.",
                "Zurück nach einer langen Pause? Der Cache ist kalt, egal was du tust. Brauchst du den Verlauf nicht mehr, dann /clear. Mit Pro und Max bietet Claude Code an, eine große Sitzung aus einer Zusammenfassung fortzusetzen.",
            ],
            takeaway: "Clear für Neues, compact zum Weitermachen, rewind zum Zurücknehmen."),
        "cache-breakers": Text(
            title: "Was den Cache unbemerkt leert",
            summary: "Manche harmlos wirkenden Aktionen kosten einen Zug zum vollen Preis.",
            points: [
                "Das Modell mit /model wechseln. Jedes Modell hat seinen eigenen Cache, die nächste Anfrage liest also den gesamten Verlauf ohne Cache-Treffer. Die Einstellung opusplan wechselt das Modell bei jedem Betreten und Verlassen des Planmodus.",
                "Die effort-Stufe mitten in der Sitzung ändern, bei den meisten Modellen. Den fast mode einschalten, einmal pro Gespräch.",
                "Claude Code aktualisieren: Das erste Gespräch nach einem Update baut seinen Cache von vorn auf.",
                "Unbedenklich: Dateien bearbeiten, den Berechtigungsmodus wechseln, Skills und Befehle aufrufen, /recap. Auch Änderungen an CLAUDE.md sind unbedenklich, wirken aber erst nach /clear, /compact oder einem Neustart.",
            ],
            takeaway: "Wähle Modell und effort am Anfang der Sitzung und lass sie dann in Ruhe."),
        "small-context": Text(
            title: "Den Kontext von Anfang an klein halten",
            summary: "Das günstigste Token ist das, das nie in den Kontext gelangt.",
            points: [
                "Gib ausgabeintensive Arbeit an Subagenten ab: Tests ausführen, Logs lesen, Dokumentation holen. Die Ausgabe bleibt in deren Kontext, zu dir kommt nur eine Zusammenfassung zurück.",
                "Werde konkret. „Füge der Login-Funktion in auth.ts eine Eingabevalidierung hinzu“ liest ein paar Dateien, „verbessere diese Codebasis“ durchsucht alles.",
                "Halte CLAUDE.md kurz, unter etwa 200 Zeilen: Die Datei wird in jede Sitzung geladen. Verschiebe Anweisungen für bestimmte Abläufe in Skills, die nur bei Bedarf geladen werden.",
                "Deaktiviere MCP-Server, die du nicht benutzt, und sieh mit /context nach, was das Fenster füllt.",
            ],
            takeaway: "Je weniger hineinkommt, desto weniger muss neu gelesen und später komprimiert werden."),
        "reading-cachecue": Text(
            title: "CacheCue auf einen Blick lesen",
            summary: "Was dir die Balken, die Uhr und der Punkt sagen.",
            points: [
                "Die Balken 5h und 7d: wie viel du von jedem Limit-Zeitfenster verbraucht hast. Ab 70% werden sie bernsteinfarben, ab 90% rot.",
                "Die Uhr: die verbleibende Zeit für den Cache der aktuellen Sitzung. Sie zeigt live, während ein Zug läuft, und exp, sobald der Cache abgelaufen ist.",
                "Der Punkt vor der Uhr: Es gibt jetzt etwas zu tun. Der Cache läuft gleich ab, ist abgelaufen, oder der Kontext ist fast voll.",
                "Die Karte oben in diesem Fenster sagt, was zu tun ist und warum. Ihre Schaltfläche kopiert /compact zum Einfügen in die Sitzung.",
                "Bei mehreren offenen Sitzungen gelten die Limits für dein Konto; Uhr und Rat gehören zu der Sitzung, deren lohnender Cache gleich kalt wird, sonst zu der, die zuletzt etwas getan hat.",
                "Ein Punkt in der Mondsichel: Eine Sitzung wartet auf deine Erlaubnis oder deine Antwort. In der Liste trägt sie eine erhobene Hand.",
                "Die Zahl neben der Schneeflocke ist das, was eine Sitzung neu schreibt, wenn ihr Cache kalt wird. Eine bereits kalte Sitzung sagt, was das Fortsetzen neu schreibt.",
                "Auf jeder Sitzungskarte wählst du, was kurz vor dem Kaltwerden des Caches passiert: nichts; Warmhalten, dabei liest CacheCue den Cache etwa 3 Minuten vor Ablauf mit einer einzeiligen Anfrage erneut, höchstens 3-mal hintereinander, ohne dem Gespräch etwas hinzuzufügen; oder Komprimieren, dabei führt CacheCue /compact für dich aus, sobald die Sitzung ruht und noch etwa 5 Minuten Cache bleiben, was Details verwirft und sich nicht rückgängig machen lässt. Beides kostet ein wenig, deshalb ist nichts davon an, bis du es wählst. Komprimiert Claude Code eine ruhende Terminalsitzung selbst, sagt die Karte das, und CacheCue hält sich heraus.",
            ],
            takeaway: "Kein Punkt, nichts zu tun. Ein Punkt heißt: Fenster öffnen und die Karte lesen."),
    ]

    static let nl: [String: Text] = [
        "context-cost": Text(
            title: "Waarom lange sessies duur worden",
            summary: "Elk verzoek stuurt het hele gesprek opnieuw mee.",
            points: [
                "Claude Code onthoudt niets tussen twee verzoeken, dus elk verzoek draagt alles mee: de systeemprompt, je projectcontext, elk bericht en elk toolresultaat.",
                "Telkens als Claude tools gebruikt, is dat nog een verzoek met de hele geschiedenis erin. Eén opdracht kan tientallen verzoeken betekenen.",
                "Prompt caching rekent het ongewijzigde deel af tegen het cachetarief, een tiende van de normale invoerprijs of minder. Goedkoop, maar niet gratis, en het groeit mee met de context.",
                "Een vraag van één regel in een sessie die de hele dag openstaat, betaalt dus nog steeds voor het hele gesprek.",
            ],
            takeaway: "Wat je bij elk verzoek betaalt, is de omvang van je context."),
        "cache-clock": Text(
            title: "Warm en koud: de cache heeft een klok",
            summary: "Stop je te lang, dan betaalt het volgende bericht de volle prijs.",
            points: [
                "Een gecachet gesprek verloopt na een periode van inactiviteit. Elk verzoek dat het leest, zet de timer terug. Zolang je doorwerkt, blijft de cache warm.",
                "Met een Claude-abonnement, binnen het verbruik van je plan, blijft de cache van het hoofdgesprek een uur geldig. Met gebruikstegoed, een API-sleutel of een cloudprovider is dat standaard vijf minuten.",
                "Na het verlopen verwerkt je volgende bericht de hele context opnieuw: trager en veel duurder. Een cache-schrijfactie van een uur kost twee keer de basisinvoerprijs en een leesactie een tiende of minder: minstens 20 keer zo duur.",
                "Hoeveel duurder hangt af van het model: 40 keer bij Opus 5.5 en Sonnet 5.5, 80 keer bij Fable 5.1, waar cache lezen goedkoper is. Een cache van 5 minuten wordt geschreven tegen 1,25 keer de basisprijs, niet het dubbele. De instelling promptCacheTtl kiest de levensduur.",
                "De klok van CacheCue is de resterende tijd. Als die bijna om is en je net wegloopt, is dat het moment om iets te doen.",
            ],
            takeaway: "Werk door en de cache blijft warm. Blijf je langer weg dan de limiet, dan betaal je alles opnieuw."),
        "compact-cost": Text(
            title: "Wat /compact echt kost",
            summary: "Een fractie bij een warme cache, de hele context bij een koude.",
            points: [
                "Om de samenvatting te schrijven stuurt Claude Code nog één verzoek: je hele geschiedenis plus de opdracht om die samen te vatten.",
                "Zolang de cache warm is, leest dat verzoek je geschiedenis uit de cache. Compacten kost dan een fractie van wat de contextgrootte doet vermoeden.",
                "Als de cache verlopen is, valt er niets te lezen en verwerkt hetzelfde verzoek alles ongecachet opnieuw. Dit is het duurste moment om te compacten.",
                "In beide gevallen is het daarna goedkoop: de volgende beurt hoeft alleen de korte samenvatting te cachen.",
                "Bij een kleine context valt er weinig weg te gooien, en dan kost het samenvattingsverzoek meer dan het oplevert.",
            ],
            takeaway: "Compact terwijl de cache warm is, en alleen als er genoeg weg te gooien valt."),
        "best-moment": Text(
            title: "Het beste moment om te compacten",
            summary: "Tussen taken, cache warm, context groot.",
            points: [
                "Bij een natuurlijke pauze: één taak is klaar en de volgende is nog niet begonnen. Compacten gooit details weg, en midden in een taak zijn dat precies de details waarmee je werkt.",
                "Voordat je langer wegblijft dan de klok nog aangeeft. Eerst compacten, dan gaan. Terugkomen bij een koude cache en dan compacten is de dure volgorde.",
                "Als de context groot is. De vuistregel van CacheCue is 100k tokens: vanaf daar leest elk verzoek genoeg opnieuw om compacten snel terug te verdienen.",
                "Voordat automatisch compacten het voor je doet. Dat start als het venster bijna vol is, op een moment dat het zelf kiest, misschien midden in een taak.",
                "Zeg wat bewaard moet blijven: /compact richt je op de API-wijzigingen en de falende tests.",
            ],
            takeaway: "Kies het moment zelf: tussen taken, terwijl de klok nog loopt."),
        "compact-clear-rewind": Text(
            title: "/compact, /clear of /rewind?",
            summary: "Drie manieren om een gesprek te verkleinen, voor drie situaties.",
            points: [
                "/clear begint opnieuw en kost niets. Gebruik het als het volgende werk er niets mee te maken heeft. Voer eerst /rename uit, dan kun je de sessie later terugvinden met /resume.",
                "/compact bewaart de draad als samenvatting. Gebruik het als je met hetzelfde werk doorgaat en nodig hebt wat er besloten is, niet elke stap ernaartoe.",
                "/rewind gaat terug naar een eerdere beurt. Gebruik het om een verkeerd pad los te laten: het gesprek tot dat punt staat al in de cache, dus er hoeft niets opnieuw opgebouwd te worden.",
                "Terug na een lange pauze? De cache is koud, wat je ook doet. Heb je de geschiedenis niet meer nodig, dan /clear. Met Pro en Max biedt Claude Code aan een grote sessie vanuit een samenvatting te hervatten.",
            ],
            takeaway: "Clear voor nieuw werk, compact om door te gaan, rewind om terug te draaien."),
        "cache-breakers": Text(
            title: "Wat de cache ongemerkt leegmaakt",
            summary: "Sommige onschuldig ogende acties kosten één beurt tegen de volle prijs.",
            points: [
                "Van model wisselen met /model. Elk model heeft zijn eigen cache, dus het volgende verzoek leest de hele geschiedenis zonder cachetreffers. De instelling opusplan wisselt van model telkens als je de planmodus in- of uitgaat.",
                "Het effort-niveau midden in een sessie wijzigen, bij de meeste modellen. Fast mode aanzetten, één keer per gesprek.",
                "Claude Code bijwerken: het eerste gesprek na een update bouwt zijn cache vanaf het begin op.",
                "Veilig: bestanden bewerken, de permissiemodus wijzigen, skills en opdrachten aanroepen, /recap. CLAUDE.md bewerken is ook veilig, maar werkt pas na /clear, /compact of een herstart.",
            ],
            takeaway: "Kies model en effort aan het begin van een sessie en blijf er daarna vanaf."),
        "small-context": Text(
            title: "Houd de context vanaf het begin klein",
            summary: "Het goedkoopste token is het token dat nooit in de context komt.",
            points: [
                "Geef werk met veel uitvoer aan subagents: tests draaien, logs lezen, documentatie ophalen. De uitvoer blijft in hun context en alleen een samenvatting komt bij jou terug.",
                "Wees specifiek. ‘Voeg invoervalidatie toe aan de loginfunctie in auth.ts’ leest een paar bestanden; ‘verbeter deze codebase’ doorzoekt alles.",
                "Houd CLAUDE.md kort, onder ongeveer 200 regels: het wordt in elke sessie geladen. Verplaats instructies voor specifieke werkwijzen naar skills, die alleen laden wanneer ze gebruikt worden.",
                "Schakel MCP-servers uit die je niet gebruikt, en voer /context uit om te zien wat het venster vult.",
            ],
            takeaway: "Hoe minder erin gaat, hoe minder er opnieuw gelezen en later gecompact hoeft te worden."),
        "reading-cachecue": Text(
            title: "CacheCue in één oogopslag",
            summary: "Wat de meters, de klok en de stip je vertellen.",
            points: [
                "De meters 5h en 7d: hoeveel je van elk limietvenster hebt gebruikt. Ze worden amber bij 70% en rood bij 90%.",
                "De klok: de resterende tijd van de cache van de huidige sessie. Die toont live terwijl een beurt loopt en exp zodra de cache verlopen is.",
                "De stip voor de klok: er is nu iets te doen. De cache verloopt bijna, is verlopen, of de context is bijna vol.",
                "De kaart bovenaan dit venster zegt wat je moet doen en waarom. De knop kopieert /compact om in de sessie te plakken.",
                "Met meerdere sessies open zijn de limieten van je account; de klok en het advies horen bij de sessie waarvan de waardevolle cache bijna koud is, en anders bij de sessie die het laatst iets deed.",
                "Een stip in de maansikkel: een sessie wacht op je toestemming of je antwoord. In de lijst heeft die een opgestoken hand.",
                "Het getal naast de sneeuwvlok is wat een sessie herschrijft als haar cache koud wordt. Een sessie die al koud is, zegt wat hervatten herschrijft.",
                "Op elke sessiekaart kies je wat er gebeurt als de cache bijna koud wordt: niets; warm houden, waarbij CacheCue de cache zo'n 3 minuten voor het verlopen opnieuw leest met een verzoek van één regel, hoogstens 3 keer achter elkaar, zonder iets aan het gesprek toe te voegen; of compacten, waarbij CacheCue /compact voor je uitvoert zodra de sessie stilstaat en er nog ongeveer 5 minuten cache over zijn, wat details weggooit en niet ongedaan kan worden gemaakt. Beide kosten iets, dus geen van beide staat aan tot je het kiest. Compact Claude Code een stilstaande terminalsessie zelf, dan zegt de kaart dat en blijft CacheCue erbuiten.",
            ],
            takeaway: "Geen stip, niets te doen. Een stip betekent: open het venster en lees de kaart."),
    ]

    static let sv: [String: Text] = [
        "context-cost": Text(
            title: "Varför långa sessioner blir dyra",
            summary: "Varje förfrågan skickar hela konversationen på nytt.",
            points: [
                "Claude Code minns ingenting mellan förfrågningar, så varje förfrågan bär med sig allt: systemprompten, projektkontexten, varje meddelande och varje verktygsresultat.",
                "Varje gång Claude använder verktyg blir det ytterligare en förfrågan med hela historiken i. En enda uppmaning kan innebära dussintals förfrågningar.",
                "Promptcachning debiterar den oförändrade delen till cachepris, en tiondel av det normala inmatningspriset eller mindre. Billigt, men inte gratis, och det växer med kontexten.",
                "En fråga på en rad i en session som varit öppen hela dagen betalar alltså ändå för hela konversationen.",
            ],
            takeaway: "Det du betalar för, vid varje förfrågan, är storleken på din kontext."),
        "cache-clock": Text(
            title: "Varm och kall: cachen har en klocka",
            summary: "Stannar du för länge betalar nästa meddelande fullt pris.",
            points: [
                "En cachad konversation går ut efter en tids inaktivitet. Varje förfrågan som läser den nollställer timern, så cachen förblir varm så länge du arbetar.",
                "Med en Claude-prenumeration, inom din plans användning, varar huvudkonversationens cache i en timme. Med användningskrediter, en API-nyckel eller en molnleverantör varar den som standard i fem minuter.",
                "När den har gått ut bearbetar ditt nästa meddelande hela kontexten på nytt: långsammare och mycket dyrare. En cacheskrivning på en timme kostar dubbla baspriset för inmatning och en läsning en tiondel eller mindre: minst 20 gånger priset.",
                "Hur mycket dyrare beror på modellen: 40 gånger på Opus 5.5 och Sonnet 5.5, 80 gånger på Fable 5.1, där cacheläsning kostar mindre. En 5-minuterscache skrivs till 1,25 gånger baspriset, inte det dubbla. Inställningen promptCacheTtl väljer livslängden.",
                "CacheCues klocka är tiden som är kvar. När den håller på att ta slut och du är på väg bort är det dags att agera.",
            ],
            takeaway: "Fortsätt arbeta så håller sig cachen varm. Går du längre än gränsen betalar du för allt igen."),
        "compact-cost": Text(
            title: "Vad /compact egentligen kostar",
            summary: "En bråkdel när cachen är varm, hela kontexten när den är kall.",
            points: [
                "För att skriva sammanfattningen skickar Claude Code en förfrågan till: hela din historik plus en instruktion att sammanfatta den.",
                "Medan cachen är varm läser den förfrågan din historik från cachen. Då kostar komprimeringen en bråkdel av vad kontextens storlek antyder.",
                "När cachen har gått ut finns inget att läsa, så samma förfrågan bearbetar allt på nytt utan cache. Det är den dyraste tidpunkten att komprimera.",
                "I båda fallen blir det billigt efteråt: nästa tur behöver bara cacha den korta sammanfattningen.",
                "I en liten kontext finns lite att göra sig av med, så sammanfattningsförfrågan kostar mer än den sparar.",
            ],
            takeaway: "Komprimera medan cachen är varm, och bara när det finns tillräckligt att göra sig av med."),
        "best-moment": Text(
            title: "Bästa tillfället att komprimera",
            summary: "Mellan uppgifter, varm cache, stor kontext.",
            points: [
                "Vid en naturlig paus: en uppgift är klar och nästa har inte börjat. Komprimering kastar detaljer, och mitt i en uppgift är det just de detaljerna du arbetar utifrån.",
                "Innan du går iväg längre än klockan har kvar. Komprimera först, gå sedan. Att komma tillbaka till en kall cache och komprimera då är den dyra ordningen.",
                "När kontexten är stor. CacheCues tumregel är 100k tokens: därifrån läser varje förfrågan om så mycket att komprimeringen snabbt betalar sig.",
                "Innan den automatiska komprimeringen gör det åt dig. Den startar när fönstret nästan är fullt, vid en tidpunkt den själv väljer, kanske mitt i en uppgift.",
                "Tala om vad som ska behållas: /compact fokusera på API-ändringarna och de misslyckade testerna.",
            ],
            takeaway: "Välj tillfället själv: mellan uppgifter, medan klockan fortfarande går."),
        "compact-clear-rewind": Text(
            title: "/compact, /clear eller /rewind?",
            summary: "Tre sätt att krympa en konversation, för tre situationer.",
            points: [
                "/clear börjar om och kostar ingenting. Använd det när nästa arbete inte hänger ihop med det här. Kör /rename först, så kan du hitta tillbaka till sessionen med /resume.",
                "/compact behåller tråden som en sammanfattning. Använd det när du fortsätter med samma arbete och behöver det som bestämdes, inte varje steg dit.",
                "/rewind går tillbaka till en tidigare tur. Använd det för att överge ett felaktigt spår: konversationen fram till dess finns redan i cachen, så inget behöver byggas om.",
                "Tillbaka efter en lång paus? Cachen är kall vad du än gör. Behöver du inte historiken längre, kör /clear. Med Pro och Max erbjuder Claude Code att återuppta en stor session från en sammanfattning.",
            ],
            takeaway: "Clear för nytt arbete, compact för att fortsätta, rewind för att ångra."),
        "cache-breakers": Text(
            title: "Det som tömmer cachen i tysthet",
            summary: "Vissa oskyldiga åtgärder kostar en tur till fullt pris.",
            points: [
                "Att byta modell med /model. Varje modell har sin egen cache, så nästa förfrågan läser hela historiken utan cacheträffar. Inställningen opusplan byter modell varje gång du går in i eller ur planläget.",
                "Att ändra effort-nivå mitt i sessionen, på de flesta modeller. Att slå på fast mode, en gång per konversation.",
                "Att uppgradera Claude Code: den första konversationen efter en uppgradering bygger sin cache från början.",
                "Ofarligt: att redigera filer, byta behörighetsläge, anropa skills och kommandon, /recap. Att redigera CLAUDE.md är också ofarligt, men gäller först efter /clear, /compact eller en omstart.",
            ],
            takeaway: "Välj modell och effort i början av sessionen och låt dem sedan vara."),
        "small-context": Text(
            title: "Håll kontexten liten från början",
            summary: "Den billigaste token är den som aldrig hamnar i kontexten.",
            points: [
                "Lämna över utskriftstunga jobb till subagenter: köra tester, läsa loggar, hämta dokumentation. Utdatan stannar i deras kontext och bara en sammanfattning kommer tillbaka till din.",
                "Var specifik. ”Lägg till indatavalidering i inloggningsfunktionen i auth.ts” läser några få filer; ”förbättra den här kodbasen” går igenom allt.",
                "Håll CLAUDE.md kort, under ungefär 200 rader: den läses in i varje session. Flytta instruktioner för särskilda arbetsflöden till skills, som bara läses in när de används.",
                "Stäng av MCP-servrar du inte använder, och kör /context för att se vad som fyller fönstret.",
            ],
            takeaway: "Ju mindre som kommer in, desto mindre att läsa om och desto mindre att komprimera senare."),
        "reading-cachecue": Text(
            title: "Läs av CacheCue med en blick",
            summary: "Vad mätarna, klockan och pricken säger dig.",
            points: [
                "Mätarna 5h och 7d: hur mycket du har använt av varje gränsfönster. De blir bärnstensfärgade vid 70% och röda vid 90%.",
                "Klockan: tiden som är kvar på den aktuella sessionens cache. Den visar live medan en tur körs och exp när cachen har gått ut.",
                "Pricken framför klockan: det finns något att göra nu. Cachen går snart ut, har gått ut, eller så är kontexten nästan full.",
                "Kortet högst upp i det här fönstret säger vad du ska göra och varför. Knappen kopierar /compact så att du kan klistra in det i sessionen.",
                "Med flera sessioner öppna gäller gränserna ditt konto; klockan och rådet hör till den session vars värdefulla cache snart blir kall, annars till den som senast gjorde något.",
                "En prick i månskäran: någon session väntar på ditt tillstånd eller ditt svar. I listan har den en uppräckt hand.",
                "Siffran bredvid snöflingan är vad en session skriver om ifall dess cache blir kall. En session som redan är kall visar vad det skriver om att återuppta den.",
                "På varje sessionskort väljer du vad som händer när cachen snart blir kall: inget; håll varm, där CacheCue läser cachen igen med en enradig begäran ungefär 3 minuter innan den går ut, högst 3 gånger i rad, utan att något läggs till i konversationen; eller komprimera, där CacheCue kör /compact åt dig när sessionen är inaktiv och ungefär 5 minuter av cachen återstår, vilket tar bort detaljer och inte kan ångras. Båda kostar lite, så inget av dem är på förrän du väljer det. Där Claude Code själv komprimerar en inaktiv terminalsession säger kortet det, och CacheCue håller sig utanför.",
            ],
            takeaway: "Ingen prick, inget att göra. En prick betyder: öppna fönstret och läs kortet."),
    ]
}
