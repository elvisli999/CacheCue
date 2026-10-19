// The guide's lessons in Polish, Russian and Turkish. Same lessons, same points, as `Guide.en`.

extension Guide {
    static let pl: [String: Text] = [
        "context-cost": Text(
            title: "Dlaczego długie sesje robią się drogie",
            summary: "Każde żądanie wysyła od nowa całą rozmowę.",
            points: [
                "Claude Code nie pamięta niczego między żądaniami, więc każde niesie wszystko: prompt systemowy, kontekst projektu, każdą wiadomość i każdy wynik narzędzia.",
                "Za każdym razem, gdy Claude używa narzędzi, powstaje kolejne żądanie z całą historią w środku. Jedno polecenie może oznaczać dziesiątki żądań.",
                "Cache promptów rozlicza niezmienioną część po stawce cache, czyli jednej dziesiątej zwykłej ceny wejścia lub mniej. Tanio, ale nie za darmo, i rośnie razem z kontekstem.",
                "Dlatego jednozdaniowe pytanie w sesji otwartej od rana i tak płaci za całą rozmowę.",
            ],
            takeaway: "Przy każdym żądaniu płacisz za rozmiar swojego kontekstu."),
        "cache-clock": Text(
            title: "Ciepły i zimny: cache ma zegar",
            summary: "Zbyt długa przerwa i następna wiadomość płaci pełną cenę.",
            points: [
                "Rozmowa w cache wygasa po okresie bezczynności. Każde żądanie, które ją odczytuje, zeruje licznik, więc cache pozostaje ciepły, dopóki pracujesz.",
                "W subskrypcji Claude, w ramach limitu planu, cache głównej rozmowy trwa godzinę. Przy kredytach użycia, kluczu API lub dostawcy chmury domyślnie trwa pięć minut.",
                "Po wygaśnięciu następna wiadomość przetwarza cały kontekst od nowa: wolniej i znacznie drożej. Zapis godzinnego cache kosztuje dwukrotność bazowej ceny wejścia, a odczyt jedną dziesiątą lub mniej, czyli co najmniej 20 razy drożej.",
                "O ile drożej, zależy od modelu: 40 razy w Opus 5.5 i Sonnet 5.5, 80 razy w Fable 5.1, gdzie odczyt z pamięci podręcznej kosztuje mniej. 5-minutowa pamięć podręczna jest zapisywana po 1,25 ceny bazowej, a nie podwójnej. Ustawienie promptCacheTtl wybiera czas życia.",
                "Zegar CacheCue pokazuje, ile czasu zostało. Gdy czas się kończy, a ty właśnie odchodzisz, to jest moment, żeby działać.",
            ],
            takeaway: "Pracuj dalej, a cache pozostanie ciepły. Odejdź na dłużej niż limit, a zapłacisz za wszystko jeszcze raz."),
        "compact-cost": Text(
            title: "Ile naprawdę kosztuje /compact",
            summary: "Ułamek przy ciepłym cache, cały kontekst przy zimnym.",
            points: [
                "Aby napisać podsumowanie, Claude Code wysyła jeszcze jedno żądanie: całą historię i polecenie jej streszczenia.",
                "Dopóki cache jest ciepły, to żądanie czyta historię z cache. Kompaktowanie kosztuje wtedy ułamek tego, co sugeruje rozmiar kontekstu.",
                "Po wygaśnięciu cache nie ma czego czytać, więc to samo żądanie przetwarza wszystko bez cache. To najdroższy moment na kompaktowanie.",
                "W obu przypadkach potem jest tanio: następna tura ma do zapisania w cache tylko krótkie podsumowanie.",
                "Przy małym kontekście niewiele da się odrzucić, więc żądanie podsumowania kosztuje więcej, niż oszczędza.",
            ],
            takeaway: "Kompaktuj, póki cache jest ciepły, i tylko wtedy, gdy jest co odrzucić."),
        "best-moment": Text(
            title: "Najlepszy moment na kompaktowanie",
            summary: "Między zadaniami, przy ciepłym cache i dużym kontekście.",
            points: [
                "W naturalnej przerwie: jedno zadanie skończone, następne jeszcze niezaczęte. Kompaktowanie odrzuca szczegóły, a w środku zadania to właśnie na nich pracujesz.",
                "Zanim odejdziesz na dłużej, niż zostało na zegarze. Najpierw kompaktuj, potem idź. Powrót do zimnego cache i kompaktowanie dopiero wtedy to kosztowna kolejność.",
                "Gdy kontekst jest duży. Praktyczna reguła CacheCue to 100k tokenów: od tego progu każde żądanie czyta ponownie tyle, że kompaktowanie szybko się zwraca.",
                "Zanim zrobi to za ciebie automatyczne kompaktowanie. Uruchamia się, gdy okno jest prawie pełne, w chwili, którą samo wybiera, być może w środku zadania.",
                "Powiedz, co zachować: /compact skup się na zmianach w API i na testach, które nie przechodzą.",
            ],
            takeaway: "Wybierz moment sam: między zadaniami, póki zegar jeszcze chodzi."),
        "compact-clear-rewind": Text(
            title: "/compact, /clear czy /rewind?",
            summary: "Trzy sposoby na zmniejszenie rozmowy, na trzy sytuacje.",
            points: [
                "/clear zaczyna od zera i nic nie kosztuje. Użyj, gdy następna praca nie ma związku z obecną. Najpierw wykonaj /rename, a później wrócisz do sesji przez /resume.",
                "/compact zachowuje wątek w postaci podsumowania. Użyj, gdy kontynuujesz tę samą pracę i potrzebujesz tego, co ustalono, a nie każdego kroku.",
                "/rewind wraca do wcześniejszej tury. Użyj, by porzucić złą ścieżkę: rozmowa do tego miejsca jest już w cache, więc niczego nie trzeba odbudowywać.",
                "Wracasz po długiej przerwie? Cache jest zimny, cokolwiek zrobisz. Jeśli historia nie jest już potrzebna, /clear. W planach Pro i Max Claude Code proponuje wznowienie dużej sesji z podsumowania.",
            ],
            takeaway: "Clear do nowej pracy, compact do kontynuacji, rewind do cofnięcia."),
        "cache-breakers": Text(
            title: "Co po cichu opróżnia cache",
            summary: "Niektóre niewinnie wyglądające działania kosztują jedną turę w pełnej cenie.",
            points: [
                "Zmiana modelu przez /model. Każdy model ma własny cache, więc następne żądanie czyta całą historię bez trafień w cache. Ustawienie opusplan zmienia model przy każdym wejściu do trybu planowania i wyjściu z niego.",
                "Zmiana poziomu effort w trakcie sesji, na większości modeli. Włączenie fast mode, raz na rozmowę.",
                "Aktualizacja Claude Code: pierwsza rozmowa po aktualizacji buduje cache od początku.",
                "Bezpieczne: edycja plików, zmiana trybu uprawnień, wywoływanie skilli i poleceń, /recap. Edycja CLAUDE.md też jest bezpieczna, ale zadziała dopiero po /clear, /compact lub restarcie.",
            ],
            takeaway: "Wybierz model i effort na początku sesji, a potem ich nie ruszaj."),
        "small-context": Text(
            title: "Utrzymuj mały kontekst od początku",
            summary: "Najtańszy token to ten, który nigdy nie trafia do kontekstu.",
            points: [
                "Rozwlekłą pracę oddaj subagentom: uruchamianie testów, czytanie logów, pobieranie dokumentacji. Wynik zostaje w ich kontekście, a do ciebie wraca tylko podsumowanie.",
                "Bądź konkretny. „Dodaj walidację danych wejściowych do funkcji logowania w auth.ts” czyta kilka plików; „ulepsz ten kod” przeszukuje wszystko.",
                "Trzymaj CLAUDE.md krótki, poniżej około 200 linii: jest ładowany do każdej sesji. Instrukcje dla konkretnych procesów przenieś do skilli, które ładują się tylko wtedy, gdy są używane.",
                "Wyłącz serwery MCP, których nie używasz, i uruchom /context, żeby zobaczyć, co wypełnia okno.",
            ],
            takeaway: "Im mniej wchodzi, tym mniej trzeba czytać ponownie i mniej później kompaktować."),
        "reading-cachecue": Text(
            title: "CacheCue na pierwszy rzut oka",
            summary: "Co mówią wskaźniki, zegar i kropka.",
            points: [
                "Wskaźniki 5h i 7d: ile wykorzystałeś z każdego okna limitu. Przy 70% robią się bursztynowe, przy 90% czerwone.",
                "Zegar: czas, jaki został cache bieżącej sesji. Pokazuje live, gdy trwa tura, i exp, gdy cache wygasł.",
                "Kropka przed zegarem: jest coś do zrobienia teraz. Cache zaraz wygaśnie, już wygasł albo kontekst jest prawie pełny.",
                "Karta u góry tego okna mówi, co zrobić i dlaczego. Jej przycisk kopiuje /compact do wklejenia w sesji.",
                "Przy kilku otwartych sesjach limity dotyczą twojego konta; zegar i rada należą do sesji, której cenna pamięć podręczna zaraz wystygnie, a jeśli takiej nie ma, do tej, która ostatnio coś zrobiła.",
                "Kropka w sierpie księżyca: któraś sesja czeka na twoją zgodę lub odpowiedź. Na liście ma podniesioną dłoń.",
                "Liczba obok płatka śniegu to tyle, ile sesja przepisze, gdy jej pamięć podręczna wystygnie. Sesja już zimna pokazuje, ile przepisze jej wznowienie.",
                "Na każdej karcie sesji wybierasz, co zrobić, gdy pamięć podręczna ma wystygnąć: nic; utrzymywać ciepłą, wtedy CacheCue około 3 minut przed wygaśnięciem ponownie odczytuje pamięć jednowierszowym zapytaniem, najwyżej 3 razy z rzędu, nic nie dodając do rozmowy; albo kompaktować, wtedy CacheCue uruchamia /compact za ciebie, gdy sesja jest bezczynna i zostało około 5 minut pamięci podręcznej, co usuwa szczegóły i nie da się cofnąć. Obie opcje trochę kosztują, więc żadna nie jest włączona, dopóki jej nie wybierzesz. Gdy Claude Code sam kompaktuje bezczynną sesję w terminalu, karta to mówi, a CacheCue się nie wtrąca.",
            ],
            takeaway: "Nie ma kropki, nie ma nic do zrobienia. Kropka znaczy: otwórz okno i przeczytaj kartę."),
    ]

    static let ru: [String: Text] = [
        "context-cost": Text(
            title: "Почему длинные сессии дорожают",
            summary: "Каждый запрос заново отправляет весь разговор.",
            points: [
                "Claude Code ничего не помнит между запросами, поэтому каждый несёт всё: системный промпт, контекст проекта, каждое сообщение и каждый результат инструмента.",
                "Каждый раз, когда Claude использует инструменты, это ещё один запрос со всей историей внутри. Одна просьба может означать десятки запросов.",
                "Кэширование промптов тарифицирует неизменившуюся часть по цене кэша: десятая часть обычной цены ввода или меньше. Дёшево, но не бесплатно, и растёт вместе с контекстом.",
                "Поэтому вопрос в одну строку в сессии, открытой весь день, всё равно оплачивает весь разговор.",
            ],
            takeaway: "При каждом запросе вы платите за размер своего контекста."),
        "cache-clock": Text(
            title: "Тёплый и холодный: у кэша есть часы",
            summary: "Остановитесь слишком надолго — и следующее сообщение пойдёт по полной цене.",
            points: [
                "Кэшированный разговор истекает после периода бездействия. Каждый запрос, который его читает, сбрасывает таймер, так что кэш остаётся тёплым, пока вы работаете.",
                "По подписке Claude, в пределах лимита тарифа, кэш основного разговора живёт один час. На кредитах использования, с API-ключом или у облачного провайдера по умолчанию пять минут.",
                "После истечения следующее сообщение заново обрабатывает весь контекст: медленнее и намного дороже. Запись часового кэша стоит вдвое дороже базовой цены ввода, а чтение — десятую часть или меньше, то есть минимум в 20 раз дороже.",
                "Во сколько раз дороже, зависит от модели: в 40 раз на Opus 5.5 и Sonnet 5.5, в 80 раз на Fable 5.1, где чтение из кэша дешевле. 5-минутный кэш записывается по 1,25 базовой цены, а не по двойной. Срок жизни выбирает настройка promptCacheTtl.",
                "Часы CacheCue показывают оставшееся время. Когда оно на исходе, а вы собираетесь отойти, пора действовать.",
            ],
            takeaway: "Продолжайте работать, и кэш останется тёплым. Отойдёте дольше лимита — заплатите за всё заново."),
        "compact-cost": Text(
            title: "Сколько на самом деле стоит /compact",
            summary: "Малую долю при тёплом кэше и весь контекст при холодном.",
            points: [
                "Чтобы написать сводку, Claude Code отправляет ещё один запрос: всю вашу историю и указание её обобщить.",
                "Пока кэш тёплый, этот запрос читает историю из кэша. Тогда сжатие стоит малую долю того, что подсказывает размер контекста.",
                "Когда кэш истёк, читать нечего, и тот же запрос обрабатывает всё заново без кэша. Это самое дорогое время для сжатия.",
                "В обоих случаях дальше дёшево: следующему ходу нужно закэшировать только короткую сводку.",
                "При маленьком контексте отбрасывать почти нечего, и запрос на сводку стоит больше, чем экономит.",
            ],
            takeaway: "Сжимайте, пока кэш тёплый, и только когда есть что отбросить."),
        "best-moment": Text(
            title: "Лучший момент для сжатия",
            summary: "Между задачами, кэш тёплый, контекст большой.",
            points: [
                "На естественной паузе: одна задача закончена, следующая ещё не начата. Сжатие отбрасывает детали, а посреди задачи вы работаете именно с ними.",
                "Перед тем как отойти дольше, чем осталось на часах. Сначала сожмите, потом уходите. Вернуться к холодному кэшу и сжимать уже тогда — дорогой порядок.",
                "Когда контекст большой. Эмпирическое правило CacheCue — 100k токенов: начиная с этого объёма каждый запрос перечитывает достаточно, чтобы сжатие быстро окупилось.",
                "До того как автосжатие сделает это за вас. Оно срабатывает, когда окно почти заполнено, в момент, который выбирает само, возможно посреди задачи.",
                "Скажите, что сохранить: /compact сосредоточься на изменениях API и падающих тестах.",
            ],
            takeaway: "Выбирайте момент сами: между задачами, пока часы ещё идут."),
        "compact-clear-rewind": Text(
            title: "/compact, /clear или /rewind?",
            summary: "Три способа уменьшить разговор для трёх ситуаций.",
            points: [
                "/clear начинает с чистого листа и ничего не стоит. Используйте, когда следующая работа не связана с текущей. Сначала выполните /rename, и позже сможете вернуться к сессии через /resume.",
                "/compact сохраняет нить в виде сводки. Используйте, когда продолжаете ту же работу и вам нужно то, что было решено, а не каждый шаг.",
                "/rewind возвращает к более раннему ходу. Используйте, чтобы отказаться от неверного пути: разговор до этой точки уже в кэше, пересобирать ничего не нужно.",
                "Вернулись после долгого перерыва? Кэш холодный, что бы вы ни делали. Если история больше не нужна, /clear. На Pro и Max Claude Code предлагает возобновить большую сессию из сводки.",
            ],
            takeaway: "Clear для новой работы, compact чтобы продолжить, rewind чтобы отменить."),
        "cache-breakers": Text(
            title: "Что незаметно опустошает кэш",
            summary: "Некоторые безобидные на вид действия стоят одного хода по полной цене.",
            points: [
                "Смена модели через /model. У каждой модели свой кэш, поэтому следующий запрос читает всю историю без попаданий в кэш. Настройка opusplan меняет модель при каждом входе в режим плана и выходе из него.",
                "Смена уровня effort посреди сессии, на большинстве моделей. Включение fast mode, один раз за разговор.",
                "Обновление Claude Code: первый разговор после обновления строит кэш с самого начала.",
                "Безопасно: редактировать файлы, менять режим разрешений, вызывать скиллы и команды, /recap. Правки CLAUDE.md тоже безопасны, но применяются только после /clear, /compact или перезапуска.",
            ],
            takeaway: "Выберите модель и effort в начале сессии и больше их не трогайте."),
        "small-context": Text(
            title: "Держите контекст маленьким с самого начала",
            summary: "Самый дешёвый токен — тот, что не попал в контекст.",
            points: [
                "Отдавайте многословную работу субагентам: запуск тестов, чтение логов, получение документации. Вывод остаётся в их контексте, а к вам возвращается только сводка.",
                "Будьте конкретны. «Добавь проверку ввода в функцию входа в auth.ts» читает несколько файлов; «улучши эту кодовую базу» просматривает всё.",
                "Держите CLAUDE.md коротким, примерно до 200 строк: он загружается в каждую сессию. Инструкции для конкретных процессов перенесите в скиллы, которые загружаются только при использовании.",
                "Отключите MCP-серверы, которыми не пользуетесь, и запустите /context, чтобы увидеть, что заполняет окно.",
            ],
            takeaway: "Чем меньше попадает внутрь, тем меньше перечитывать и тем меньше потом сжимать."),
        "reading-cachecue": Text(
            title: "CacheCue с одного взгляда",
            summary: "О чём говорят индикаторы, часы и точка.",
            points: [
                "Индикаторы 5h и 7d: сколько вы израсходовали в каждом окне лимита. На 70% они становятся янтарными, на 90% красными.",
                "Часы: сколько осталось жить кэшу текущей сессии. Показывают live, пока идёт ход, и exp, когда кэш истёк.",
                "Точка перед часами: сейчас есть что сделать. Кэш вот-вот истечёт, уже истёк или контекст почти заполнен.",
                "Карточка вверху этого окна говорит, что делать и почему. Её кнопка копирует /compact, чтобы вставить в сессию.",
                "Когда открыто несколько сессий, лимиты общие для аккаунта; часы и совет относятся к сессии, чей ценный кэш вот-вот остынет, а если такой нет, к той, что была активна последней.",
                "Точка внутри полумесяца: какая-то сессия ждёт вашего разрешения или ответа. В списке у неё значок поднятой руки.",
                "Число рядом со снежинкой показывает, сколько сессия перепишет, если её кэш остынет. Уже остывшая сессия показывает, сколько перепишет её возобновление.",
                "На карточке сессии можно выбрать, что делать, когда кэш вот-вот остынет: ничего; держать тёплым — CacheCue примерно за 3 минуты до истечения перечитывает кэш однострочным запросом, не больше 3 раз подряд, ничего не добавляя в разговор; или сжать — CacheCue запускает /compact за вас, когда сессия простаивает и кэшу осталось около 5 минут; сжатие отбрасывает детали, и его нельзя отменить. Оба варианта немного стоят, поэтому ни один не включён, пока вы его не выберете. Если Claude Code сам сжимает простаивающую сессию в терминале, карточка так и пишет, а CacheCue не вмешивается.",
            ],
            takeaway: "Нет точки — делать нечего. Есть точка — откройте окно и прочитайте карточку."),
    ]

    static let tr: [String: Text] = [
        "context-cost": Text(
            title: "Uzun oturumlar neden pahalılaşır",
            summary: "Her istek tüm konuşmayı yeniden gönderir.",
            points: [
                "Claude Code istekler arasında hiçbir şey hatırlamaz, bu yüzden her istek her şeyi taşır: sistem istemi, proje bağlamı, her mesaj ve her araç sonucu.",
                "Claude her araç kullandığında, içinde tüm geçmişin bulunduğu bir istek daha gider. Tek bir komut onlarca istek anlamına gelebilir.",
                "İstem önbelleği değişmeyen kısmı önbellek tarifesinden ücretlendirir: normal girdi fiyatının onda biri ya da daha azı. Ucuz ama bedava değil, üstelik bağlamla birlikte büyür.",
                "Bu yüzden bütün gün açık kalmış bir oturumda sorulan tek satırlık bir soru bile tüm konuşmanın bedelini öder.",
            ],
            takeaway: "Her istekte ödediğiniz şey, bağlamınızın boyutudur."),
        "cache-clock": Text(
            title: "Sıcak ve soğuk: önbelleğin bir saati var",
            summary: "Çok uzun ara verirseniz sonraki mesaj tam fiyat öder.",
            points: [
                "Önbelleğe alınmış bir konuşma, bir süre kullanılmayınca sona erer. Onu okuyan her istek sayacı sıfırlar; çalışmaya devam ettiğiniz sürece önbellek sıcak kalır.",
                "Claude aboneliğinde, planınızın kullanım sınırı içinde, ana konuşmanın önbelleği bir saat dayanır. Kullanım kredilerinde, API anahtarında veya bulut sağlayıcıda varsayılan olarak beş dakikadır.",
                "Süre dolduktan sonra bir sonraki mesajınız tüm bağlamı yeniden işler: daha yavaş ve çok daha pahalı. Bir saatlik önbellek yazımı temel girdi fiyatının iki katına, okuma ise onda birine veya daha azına mal olur; yani en az 20 kat.",
                "Kaç kat olduğu modele bağlıdır: Opus 5.5 ve Sonnet 5.5'te 40 kat, önbellek okuması daha ucuz olan Fable 5.1'de 80 kat. 5 dakikalık önbellek, taban fiyatın iki katına değil 1,25 katına yazılır. Ömrü promptCacheTtl ayarı belirler.",
                "CacheCue’nun saati kalan süredir. Süre bitmek üzereyken siz de ayrılıyorsanız, harekete geçme anı odur.",
            ],
            takeaway: "Çalışmaya devam edin, önbellek sıcak kalsın. Sınırdan uzun ayrılırsanız her şeyi yeniden ödersiniz."),
        "compact-cost": Text(
            title: "/compact gerçekte neye mal olur",
            summary: "Önbellek sıcakken küçük bir kısmı, soğukken tüm bağlamı.",
            points: [
                "Özeti yazmak için Claude Code bir istek daha gönderir: tüm geçmişiniz ve onu özetleme talimatı.",
                "Önbellek sıcakken bu istek geçmişinizi önbellekten okur. O zaman sıkıştırma, bağlam boyutunun düşündürdüğünün küçük bir kısmına mal olur.",
                "Önbelleğin süresi dolduktan sonra okunacak bir şey kalmaz ve aynı istek her şeyi önbelleksiz yeniden işler. Sıkıştırmanın en pahalı olduğu an budur.",
                "Her iki durumda da sonrası ucuzdur: bir sonraki turun önbelleğe alacağı tek şey kısa özettir.",
                "Küçük bir bağlamda atılacak pek bir şey yoktur; özet isteği kazandırdığından fazlasına mal olur.",
            ],
            takeaway: "Önbellek sıcakken ve atılacak yeterince şey varken sıkıştırın."),
        "best-moment": Text(
            title: "Sıkıştırmak için en iyi an",
            summary: "Görevler arasında, önbellek sıcak, bağlam büyük.",
            points: [
                "Doğal bir duraklamada: bir görev bitmiş, sıradaki başlamamış. Sıkıştırma ayrıntıları atar; görevin ortasında ise üzerinde çalıştığınız şey tam da o ayrıntılardır.",
                "Saatte kalan süreden daha uzun ayrılmadan önce. Önce sıkıştırın, sonra gidin. Soğuk bir önbelleğe dönüp o zaman sıkıştırmak pahalı olan sıradır.",
                "Bağlam büyük olduğunda. CacheCue’nun pratik kuralı 100k token’dır: bu noktadan sonra her istek, sıkıştırmanın kendini çabucak amorti etmesine yetecek kadar yeniden okur.",
                "Otomatik sıkıştırma sizin yerinize yapmadan önce. Pencere neredeyse dolduğunda, kendi seçtiği bir anda devreye girer; belki de bir görevin ortasında.",
                "Neyin kalacağını söyleyin: /compact API değişikliklerine ve başarısız testlere odaklan.",
            ],
            takeaway: "Anı kendiniz seçin: görevler arasında, saat hâlâ işlerken."),
        "compact-clear-rewind": Text(
            title: "/compact, /clear yoksa /rewind mi?",
            summary: "Bir konuşmayı küçültmenin üç yolu, üç durum için.",
            points: [
                "/clear sıfırdan başlar ve hiçbir şeye mal olmaz. Sıradaki iş bununla ilgisizse kullanın. Önce /rename çalıştırırsanız oturuma sonra /resume ile dönebilirsiniz.",
                "/compact konuyu bir özet olarak saklar. Aynı işe devam ediyorsanız ve size her adım değil, alınan kararlar gerekiyorsa kullanın.",
                "/rewind önceki bir tura döner. Yanlış bir yoldan vazgeçmek için kullanın: o noktaya kadarki konuşma zaten önbellektedir, yeniden kurulacak bir şey yoktur.",
                "Uzun bir aradan sonra mı döndünüz? Ne yaparsanız yapın önbellek soğuktur. Geçmişe artık ihtiyacınız yoksa /clear. Pro ve Max’te Claude Code, büyük bir oturumu özetten sürdürmeyi önerir.",
            ],
            takeaway: "Yeni iş için clear, devam etmek için compact, geri almak için rewind."),
        "cache-breakers": Text(
            title: "Önbelleği sessizce boşaltan şeyler",
            summary: "Zararsız görünen bazı işlemler tam fiyatlı bir tura mal olur.",
            points: [
                "/model ile model değiştirmek. Her modelin kendi önbelleği vardır; sonraki istek tüm geçmişi önbellek isabeti olmadan okur. opusplan ayarı, plan moduna her girip çıktığınızda modeli değiştirir.",
                "Oturumun ortasında effort düzeyini değiştirmek, çoğu modelde. fast mode’u açmak, konuşma başına bir kez.",
                "Claude Code’u güncellemek: güncellemeden sonraki ilk konuşma önbelleğini baştan kurar.",
                "Güvenli olanlar: dosya düzenlemek, izin modunu değiştirmek, skill ve komut çağırmak, /recap. CLAUDE.md düzenlemek de güvenlidir, ancak yalnızca /clear, /compact veya yeniden başlatmadan sonra geçerli olur.",
            ],
            takeaway: "Modeli ve effort’u oturumun başında seçin, sonra dokunmayın."),
        "small-context": Text(
            title: "Bağlamı en baştan küçük tutun",
            summary: "En ucuz token, bağlama hiç girmeyen token’dır.",
            points: [
                "Çıktısı bol işleri alt ajanlara verin: test çalıştırmak, günlük okumak, belge getirmek. Çıktı onların bağlamında kalır, size yalnızca bir özet döner.",
                "Net olun. “auth.ts içindeki giriş fonksiyonuna girdi doğrulaması ekle” birkaç dosya okur; “bu kod tabanını iyileştir” hepsini tarar.",
                "CLAUDE.md’yi kısa tutun, yaklaşık 200 satırın altında: her oturuma yüklenir. Belirli iş akışlarına ait talimatları, yalnızca kullanıldığında yüklenen skill’lere taşıyın.",
                "Kullanmadığınız MCP sunucularını devre dışı bırakın ve pencereyi neyin doldurduğunu görmek için /context çalıştırın.",
            ],
            takeaway: "İçeri ne kadar az girerse, yeniden okunacak ve sonra sıkıştırılacak şey o kadar az olur."),
        "reading-cachecue": Text(
            title: "CacheCue’yu bir bakışta okumak",
            summary: "Göstergeler, saat ve nokta size ne söylüyor.",
            points: [
                "5h ve 7d göstergeleri: her limit penceresinin ne kadarını kullandığınız. %70’te kehribar, %90’da kırmızı olurlar.",
                "Saat: geçerli oturumun önbelleğinde kalan süre. Bir tur çalışırken live, önbelleğin süresi dolunca exp gösterir.",
                "Saatin önündeki nokta: şimdi yapılacak bir şey var. Önbellek dolmak üzere, dolmuş ya da bağlam neredeyse dolu.",
                "Bu pencerenin üstündeki kart ne yapmanız gerektiğini ve nedenini söyler. Düğmesi /compact’ı kopyalar; oturuma yapıştırın.",
                "Birden çok oturum açıkken limitler hesabına aittir; saat ve öneri, değerli önbelleği soğumak üzere olan oturuma, öyle bir oturum yoksa en son işlem yapana aittir.",
                "Hilalin içindeki nokta: bir oturum iznini veya yanıtını bekliyor. Listede o oturumda kalkmış bir el simgesi bulunur.",
                "Kar tanesinin yanındaki sayı, önbelleği soğursa oturumun yeniden yazacağı miktardır. Zaten soğumuş bir oturum, devam etmenin neyi yeniden yazacağını gösterir.",
                "Her oturum kartında önbellek soğumak üzereyken ne olacağını seçersin: hiçbir şey; sıcak tutmak, yani CacheCue süre dolmadan yaklaşık 3 dakika önce önbelleği tek satırlık bir istekle yeniden okur, art arda en fazla 3 kez, konuşmaya hiçbir şey eklemeden; ya da sıkıştırmak, yani oturum boştayken ve önbelleğin yaklaşık 5 dakikası kaldığında CacheCue senin yerine /compact çalıştırır; bu ayrıntıları atar ve geri alınamaz. İkisinin de küçük bir maliyeti var, bu yüzden sen seçene kadar hiçbiri açık değildir. Claude Code boştaki bir terminal oturumunu kendisi sıkıştırıyorsa kart bunu söyler ve CacheCue karışmaz.",
            ],
            takeaway: "Nokta yoksa yapılacak bir şey yok. Nokta varsa pencereyi açın ve kartı okuyun."),
    ]
}
