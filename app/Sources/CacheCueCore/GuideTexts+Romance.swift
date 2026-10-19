// The guide's lessons in French, Spanish, Portuguese and Italian. Same lessons, same points,
// as `Guide.en`.

extension Guide {
    static let fr: [String: Text] = [
        "context-cost": Text(
            title: "Pourquoi les longues sessions coûtent cher",
            summary: "Chaque requête renvoie toute la conversation.",
            points: [
                "Claude Code ne garde aucune mémoire entre deux requêtes : chacune transporte tout, le prompt système, le contexte du projet, chaque message et chaque résultat d’outil.",
                "Chaque fois que Claude utilise des outils, c’est une requête de plus avec tout l’historique. Une seule demande peut représenter des dizaines de requêtes.",
                "Le cache de prompts facture la partie inchangée au tarif du cache, un dixième du prix d’entrée normal ou moins. Bon marché, mais pas gratuit, et cela grossit avec le contexte.",
                "Une question d’une ligne dans une session ouverte depuis le matin paie donc pour toute la conversation.",
            ],
            takeaway: "Ce que vous payez, à chaque requête, c’est la taille de votre contexte."),
        "cache-clock": Text(
            title: "Chaud et froid : le cache a une horloge",
            summary: "Arrêtez-vous trop longtemps et le message suivant paie plein tarif.",
            points: [
                "Une conversation en cache expire après une période d’inactivité. Chaque requête qui la lit remet le minuteur à zéro : tant que vous travaillez, le cache reste chaud.",
                "Avec un abonnement Claude, dans la limite de votre forfait, le cache de la conversation principale dure une heure. Avec des crédits d’usage, une clé API ou un fournisseur cloud, il dure cinq minutes par défaut.",
                "Après expiration, votre message suivant retraite tout le contexte : plus lent, et bien plus cher. Une écriture de cache d’une heure coûte deux fois le prix d’entrée de base, une lecture un dixième ou moins : au moins 20 fois plus cher.",
                "L'écart dépend du modèle : 40 fois sur Opus 5.5 et Sonnet 5.5, 80 fois sur Fable 5.1, dont la lecture du cache coûte moins. Un cache de 5 minutes s'écrit à 1,25 fois le prix de base, et non au double. Le réglage promptCacheTtl choisit la durée de vie.",
                "L’horloge de CacheCue indique le temps restant. Quand elle arrive au bout et que vous vous éloignez, c’est le moment d’agir.",
            ],
            takeaway: "Continuez à travailler et le cache reste chaud. Dépassez la limite et vous repayez tout."),
        "compact-cost": Text(
            title: "Ce que /compact coûte vraiment",
            summary: "Une fraction quand le cache est chaud, tout le contexte quand il est froid.",
            points: [
                "Pour rédiger le résumé, Claude Code envoie une requête de plus : tout votre historique et une consigne de résumé.",
                "Tant que le cache est chaud, cette requête lit votre historique depuis le cache. Compacter coûte alors une fraction de ce que la taille du contexte laisse penser.",
                "Une fois le cache expiré, il n’y a plus rien à lire : la même requête retraite tout sans cache. C’est le moment le plus cher pour compacter.",
                "Dans les deux cas, la suite est bon marché : le tour suivant n’a que le court résumé à mettre en cache.",
                "Sur un petit contexte, il y a peu à alléger : la requête de résumé coûte plus qu’elle ne rapporte.",
            ],
            takeaway: "Compactez tant que le cache est chaud, et seulement s’il y a assez à alléger."),
        "best-moment": Text(
            title: "Le meilleur moment pour compacter",
            summary: "Entre deux tâches, cache chaud, contexte volumineux.",
            points: [
                "À une pause naturelle : une tâche est terminée, la suivante n’a pas commencé. Compacter élimine des détails, et en pleine tâche ce sont eux dont vous avez besoin.",
                "Avant de vous absenter plus longtemps que ce qu’il reste à l’horloge. Compactez d’abord, partez ensuite. Revenir sur un cache froid et compacter à ce moment-là, c’est l’ordre qui coûte cher.",
                "Quand le contexte est volumineux. La règle empirique de CacheCue est de 100k tokens : à partir de là, chaque requête relit assez pour que la compaction soit vite rentabilisée.",
                "Avant que la compaction automatique ne s’en charge. Elle se déclenche quand la fenêtre est presque pleine, au moment qu’elle choisit, peut-être en pleine tâche.",
                "Dites-lui quoi garder : /compact concentre-toi sur les changements d’API et les tests en échec.",
            ],
            takeaway: "Choisissez vous-même le moment : entre deux tâches, tant que l’horloge tourne."),
        "compact-clear-rewind": Text(
            title: "/compact, /clear ou /rewind ?",
            summary: "Trois façons de réduire une conversation, pour trois situations.",
            points: [
                "/clear repart de zéro et ne coûte rien. À utiliser quand le travail suivant n’a aucun rapport. Lancez /rename avant, et vous pourrez retrouver la session avec /resume.",
                "/compact garde le fil sous forme de résumé. À utiliser quand vous poursuivez le même travail et qu’il vous faut ce qui a été décidé, pas chaque étape.",
                "/rewind revient à un tour précédent. À utiliser pour abandonner une mauvaise piste : la conversation jusque-là est déjà en cache, rien n’est à reconstruire.",
                "De retour après une longue pause ? Le cache est froid quoi que vous fassiez. Si l’historique ne vous sert plus, /clear. Avec Pro et Max, Claude Code propose de reprendre une grande session à partir d’un résumé.",
            ],
            takeaway: "Clear pour un nouveau travail, compact pour continuer, rewind pour revenir en arrière."),
        "cache-breakers": Text(
            title: "Ce qui vide le cache sans prévenir",
            summary: "Certaines actions anodines coûtent un tour à plein tarif.",
            points: [
                "Changer de modèle avec /model. Chaque modèle a son propre cache : la requête suivante relit tout l’historique sans aucun succès de cache. Le réglage opusplan change de modèle à chaque entrée ou sortie du mode plan.",
                "Changer le niveau d’effort en cours de session, sur la plupart des modèles. Activer le fast mode, une fois par conversation.",
                "Mettre à jour Claude Code : la première conversation après une mise à jour reconstruit son cache depuis le début.",
                "Sans risque : modifier des fichiers, changer de mode de permission, invoquer des skills et des commandes, /recap. Modifier CLAUDE.md est sûr aussi, mais ne s’applique qu’après /clear, /compact ou un redémarrage.",
            ],
            takeaway: "Choisissez modèle et effort au début de la session, puis n’y touchez plus."),
        "small-context": Text(
            title: "Garder un contexte léger dès le départ",
            summary: "Le token le moins cher est celui qui n’entre jamais dans le contexte.",
            points: [
                "Confiez les tâches verbeuses à des sous-agents : lancer des tests, lire des journaux, récupérer de la documentation. La sortie reste dans leur contexte et seul un résumé revient dans le vôtre.",
                "Soyez précis. « Ajoute une validation des entrées à la fonction de connexion dans auth.ts » lit quelques fichiers ; « améliore ce code » parcourt tout.",
                "Gardez CLAUDE.md court, moins de 200 lignes environ : il est chargé dans chaque session. Déplacez les consignes propres à un flux de travail dans des skills, chargés seulement à l’usage.",
                "Désactivez les serveurs MCP inutilisés, et lancez /context pour voir ce qui remplit la fenêtre.",
            ],
            takeaway: "Moins il en entre, moins il y a à relire, et moins à compacter plus tard."),
        "reading-cachecue": Text(
            title: "Lire CacheCue d’un coup d’œil",
            summary: "Ce que disent les jauges, l’horloge et le point.",
            points: [
                "Les jauges 5h et 7d : la part utilisée de chaque fenêtre de limite. Elles passent à l’ambre à 70% et au rouge à 90%.",
                "L’horloge : le temps restant sur le cache de la session en cours. Elle affiche live pendant qu’un tour s’exécute et exp une fois le cache expiré.",
                "Le point devant l’horloge : il y a quelque chose à faire maintenant. Le cache va expirer, a expiré, ou le contexte est presque plein.",
                "La carte en haut de cette fenêtre dit quoi faire et pourquoi. Son bouton copie /compact, à coller dans la session.",
                "Avec plusieurs sessions ouvertes, les limites sont celles de votre compte ; l’horloge et le conseil sont ceux de la session dont le cache utile va refroidir, sinon de celle qui a agi en dernier.",
                "Un point dans le croissant : une session attend votre autorisation ou votre réponse. Dans la liste, elle porte une main levée.",
                "Le chiffre à côté du flocon est ce qu’une session réécrit si son cache refroidit. Une session déjà froide indique ce que la reprendre réécrit.",
                "Chaque carte de session propose un choix pour le moment où le cache va refroidir : ne rien faire ; le garder au chaud, CacheCue relisant le cache par une requête d’une ligne environ 3 minutes avant qu’il expire, jusqu’à 3 fois de suite, sans rien ajouter à la conversation ; ou compacter, CacheCue lançant /compact pour vous dès que la session est inactive et qu’il reste environ 5 minutes de cache, ce qui supprime des détails et ne s’annule pas. Les deux coûtent un peu, donc rien n’est activé tant que vous ne l’avez pas choisi. Quand Claude Code compacte lui-même une session de terminal inactive, la carte l’indique et CacheCue n’intervient pas.",
            ],
            takeaway: "Pas de point, rien à faire. Un point : ouvrez la fenêtre et lisez la carte."),
    ]

    static let es: [String: Text] = [
        "context-cost": Text(
            title: "Por qué las sesiones largas salen caras",
            summary: "Cada solicitud reenvía toda la conversación.",
            points: [
                "Claude Code no guarda memoria entre solicitudes, así que cada una lo lleva todo: el prompt del sistema, el contexto del proyecto, cada mensaje y cada resultado de herramienta.",
                "Cada vez que Claude usa herramientas, es otra solicitud con todo el historial dentro. Una sola petición puede suponer decenas de solicitudes.",
                "La caché de prompts cobra la parte que no cambió a la tarifa de caché, una décima parte del precio normal de entrada o menos. Barato, pero no gratis, y crece con el contexto.",
                "Así que una pregunta de una línea en una sesión abierta todo el día sigue pagando por toda la conversación.",
            ],
            takeaway: "Lo que pagas, en cada solicitud, es el tamaño de tu contexto."),
        "cache-clock": Text(
            title: "Caliente y fría: la caché tiene un reloj",
            summary: "Si paras demasiado, el siguiente mensaje paga precio completo.",
            points: [
                "Una conversación en caché caduca tras un periodo de inactividad. Cada solicitud que la lee reinicia el temporizador, así que la caché sigue caliente mientras trabajas.",
                "Con una suscripción de Claude, dentro del uso de tu plan, la caché de la conversación principal dura una hora. Con créditos de uso, una clave de API o un proveedor en la nube, dura cinco minutos por defecto.",
                "Cuando caduca, tu siguiente mensaje reprocesa todo el contexto: más lento y mucho más caro. Una escritura de caché de una hora cuesta el doble del precio base de entrada y una lectura una décima parte o menos: al menos 20 veces más.",
                "Cuánto más depende del modelo: 40 veces en Opus 5.5 y Sonnet 5.5, 80 veces en Fable 5.1, cuya lectura de caché cuesta menos. Una caché de 5 minutos se escribe a 1,25 veces el precio base, no al doble. El ajuste promptCacheTtl elige la duración.",
                "El reloj de CacheCue es el tiempo que queda. Cuando está a punto de agotarse y te vas, ese es el momento de actuar.",
            ],
            takeaway: "Sigue trabajando y la caché sigue caliente. Aléjate más del límite y lo pagas todo otra vez."),
        "compact-cost": Text(
            title: "Lo que cuesta de verdad /compact",
            summary: "Una fracción con la caché caliente; el contexto entero con la caché fría.",
            points: [
                "Para escribir el resumen, Claude Code envía una solicitud más: todo tu historial y la instrucción de resumirlo.",
                "Mientras la caché está caliente, esa solicitud lee tu historial desde la caché. Compactar cuesta entonces una fracción de lo que sugiere el tamaño del contexto.",
                "Cuando la caché ha caducado no hay nada que leer, y la misma solicitud lo reprocesa todo sin caché. Es el momento más caro para compactar.",
                "En ambos casos, lo que viene después es barato: el siguiente turno solo tiene que guardar en caché el resumen corto.",
                "Con un contexto pequeño hay poco que soltar, y la solicitud de resumen cuesta más de lo que ahorra.",
            ],
            takeaway: "Compacta con la caché caliente, y solo cuando haya suficiente que soltar."),
        "best-moment": Text(
            title: "El mejor momento para compactar",
            summary: "Entre tareas, con la caché caliente y el contexto grande.",
            points: [
                "En una pausa natural: una tarea ha terminado y la siguiente no ha empezado. Compactar descarta detalle, y a mitad de tarea ese detalle es con lo que trabajas.",
                "Antes de irte por más tiempo del que le queda al reloj. Compacta primero y vete después. Volver a una caché fría y compactar entonces es el orden caro.",
                "Cuando el contexto es grande. La regla práctica de CacheCue son 100k tokens: a partir de ahí, cada solicitud relee lo bastante para que compactar se amortice rápido.",
                "Antes de que lo haga la compactación automática. Se activa cuando la ventana está casi llena, en el momento que ella elige, quizá a mitad de tarea.",
                "Dile qué conservar: /compact céntrate en los cambios de la API y en los tests que fallan.",
            ],
            takeaway: "Elige tú el momento: entre tareas, mientras el reloj sigue corriendo."),
        "compact-clear-rewind": Text(
            title: "¿/compact, /clear o /rewind?",
            summary: "Tres formas de reducir una conversación, para tres situaciones.",
            points: [
                "/clear empieza de cero y no cuesta nada. Úsalo cuando el siguiente trabajo no tenga relación. Ejecuta antes /rename y podrás recuperar la sesión con /resume.",
                "/compact conserva el hilo en forma de resumen. Úsalo cuando sigues con el mismo trabajo y necesitas lo que se decidió, no cada paso.",
                "/rewind vuelve a un turno anterior. Úsalo para abandonar un camino equivocado: la conversación hasta ese punto ya está en caché, así que no hay nada que reconstruir.",
                "¿Vuelves tras una pausa larga? La caché está fría hagas lo que hagas. Si ya no necesitas el historial, /clear. En Pro y Max, Claude Code ofrece reanudar una sesión grande desde un resumen.",
            ],
            takeaway: "Clear para trabajo nuevo, compact para continuar, rewind para deshacer."),
        "cache-breakers": Text(
            title: "Lo que vacía la caché sin avisar",
            summary: "Algunas acciones que parecen inofensivas cuestan un turno a precio completo.",
            points: [
                "Cambiar de modelo con /model. Cada modelo tiene su propia caché, así que la siguiente solicitud lee todo el historial sin aciertos de caché. El ajuste opusplan cambia de modelo cada vez que entras o sales del modo plan.",
                "Cambiar el nivel de effort a mitad de sesión, en la mayoría de los modelos. Activar fast mode, una vez por conversación.",
                "Actualizar Claude Code: la primera conversación tras una actualización construye su caché desde el principio.",
                "Sin riesgo: editar archivos, cambiar el modo de permisos, invocar skills y comandos, /recap. Editar CLAUDE.md también es seguro, pero solo se aplica tras /clear, /compact o un reinicio.",
            ],
            takeaway: "Elige modelo y effort al empezar la sesión y luego no los toques."),
        "small-context": Text(
            title: "Mantén el contexto pequeño desde el principio",
            summary: "El token más barato es el que nunca entra en el contexto.",
            points: [
                "Delega el trabajo verboso en subagentes: ejecutar tests, leer registros, buscar documentación. La salida se queda en su contexto y a ti solo te vuelve un resumen.",
                "Sé específico. «Añade validación de entrada a la función de login en auth.ts» lee unos pocos archivos; «mejora este código» lo recorre todo.",
                "Mantén CLAUDE.md corto, por debajo de unas 200 líneas: se carga en cada sesión. Mueve las instrucciones de flujos concretos a skills, que solo se cargan cuando se usan.",
                "Desactiva los servidores MCP que no uses y ejecuta /context para ver qué está llenando la ventana.",
            ],
            takeaway: "Cuanto menos entra, menos hay que releer y menos que compactar después."),
        "reading-cachecue": Text(
            title: "Leer CacheCue de un vistazo",
            summary: "Qué te dicen los indicadores, el reloj y el punto.",
            points: [
                "Los indicadores 5h y 7d: cuánto has usado de cada ventana de límite. Pasan a ámbar al 70% y a rojo al 90%.",
                "El reloj: el tiempo que le queda a la caché de la sesión actual. Muestra live mientras se ejecuta un turno y exp cuando la caché ha caducado.",
                "El punto delante del reloj: hay algo que hacer ahora. La caché está a punto de caducar, ha caducado, o el contexto está casi lleno.",
                "La tarjeta de la parte superior de esta ventana dice qué hacer y por qué. Su botón copia /compact para que lo pegues en la sesión.",
                "Con varias sesiones abiertas, los límites son de tu cuenta; el reloj y el consejo son de la sesión cuya caché valiosa está por enfriarse o, si no hay ninguna, de la que actuó por última vez.",
                "Un punto dentro de la medialuna: alguna sesión espera tu permiso o tu respuesta. En la lista lleva una mano levantada.",
                "La cifra junto al copo de nieve es lo que una sesión reescribe si su caché se enfría. Una sesión ya fría indica lo que reescribe al reanudarla.",
                "Cada tarjeta de sesión ofrece qué hacer cuando la caché está por enfriarse: nada; mantenerla caliente, en cuyo caso CacheCue vuelve a leer la caché con una petición de una línea unos 3 minutos antes de que caduque, hasta 3 veces seguidas, sin añadir nada a la conversación; o compactar, en cuyo caso CacheCue ejecuta /compact por ti cuando la sesión está inactiva y quedan unos 5 minutos de caché, lo que descarta detalles y no se puede deshacer. Ambas cuestan un poco, así que ninguna está activa hasta que la elijas. Cuando Claude Code compacta por sí mismo una sesión de terminal inactiva, la tarjeta lo dice y CacheCue no interviene.",
            ],
            takeaway: "Sin punto, nada que hacer. Con punto, abre la ventana y lee la tarjeta."),
    ]

    static let pt: [String: Text] = [
        "context-cost": Text(
            title: "Por que sessões longas ficam caras",
            summary: "Cada requisição reenvia a conversa inteira.",
            points: [
                "O Claude Code não guarda memória entre requisições, então cada uma leva tudo: o prompt de sistema, o contexto do projeto, cada mensagem e cada resultado de ferramenta.",
                "Cada vez que o Claude usa ferramentas, é mais uma requisição com todo o histórico dentro. Um único pedido pode significar dezenas de requisições.",
                "O cache de prompts cobra a parte que não mudou pela tarifa de cache, um décimo do preço normal de entrada ou menos. Barato, mas não gratuito, e cresce com o contexto.",
                "Por isso, uma pergunta de uma linha em uma sessão aberta o dia todo ainda paga pela conversa inteira.",
            ],
            takeaway: "O que você paga, a cada requisição, é o tamanho do seu contexto."),
        "cache-clock": Text(
            title: "Quente e frio: o cache tem um relógio",
            summary: "Pare por tempo demais e a próxima mensagem paga preço cheio.",
            points: [
                "Uma conversa em cache expira após um período de inatividade. Cada requisição que a lê reinicia o temporizador, então o cache continua quente enquanto você trabalha.",
                "Em uma assinatura do Claude, dentro do uso do seu plano, o cache da conversa principal dura uma hora. Com créditos de uso, chave de API ou provedor de nuvem, dura cinco minutos por padrão.",
                "Depois que expira, sua próxima mensagem reprocessa o contexto inteiro: mais lento e muito mais caro. Uma escrita de cache de uma hora custa o dobro do preço base de entrada e uma leitura um décimo ou menos: pelo menos 20 vezes mais.",
                "Quanto mais depende do modelo: 40 vezes no Opus 5.5 e no Sonnet 5.5, 80 vezes no Fable 5.1, cuja leitura de cache custa menos. Um cache de 5 minutos é escrito a 1,25 vez o preço base, não ao dobro. A configuração promptCacheTtl escolhe a duração.",
                "O relógio do CacheCue é o tempo que resta. Quando está prestes a acabar e você vai se afastar, esse é o momento de agir.",
            ],
            takeaway: "Continue trabalhando e o cache fica quente. Afaste-se além do limite e você paga tudo de novo."),
        "compact-cost": Text(
            title: "Quanto o /compact realmente custa",
            summary: "Uma fração com o cache quente; o contexto inteiro com o cache frio.",
            points: [
                "Para escrever o resumo, o Claude Code envia mais uma requisição: todo o seu histórico e a instrução de resumi-lo.",
                "Enquanto o cache está quente, essa requisição lê o histórico a partir do cache. Compactar custa então uma fração do que o tamanho do contexto sugere.",
                "Depois que o cache expira não há o que ler, e a mesma requisição reprocessa tudo sem cache. É o momento mais caro para compactar.",
                "Em ambos os casos, o que vem depois é barato: o próximo turno só precisa colocar em cache o resumo curto.",
                "Em um contexto pequeno há pouco a descartar, e a requisição de resumo custa mais do que economiza.",
            ],
            takeaway: "Compacte com o cache quente, e só quando houver o bastante para descartar."),
        "best-moment": Text(
            title: "O melhor momento para compactar",
            summary: "Entre tarefas, com o cache quente e o contexto grande.",
            points: [
                "Em uma pausa natural: uma tarefa terminou e a próxima ainda não começou. Compactar descarta detalhes, e no meio da tarefa são esses detalhes que você está usando.",
                "Antes de se afastar por mais tempo do que resta no relógio. Compacte primeiro, saia depois. Voltar a um cache frio e compactar então é a ordem cara.",
                "Quando o contexto é grande. A regra prática do CacheCue é 100k tokens: a partir daí, cada requisição relê o bastante para a compactação se pagar rápido.",
                "Antes que a compactação automática faça isso por você. Ela dispara quando a janela está quase cheia, no momento que ela escolhe, talvez no meio de uma tarefa.",
                "Diga o que manter: /compact foque nas mudanças da API e nos testes que falham.",
            ],
            takeaway: "Escolha você o momento: entre tarefas, enquanto o relógio ainda corre."),
        "compact-clear-rewind": Text(
            title: "/compact, /clear ou /rewind?",
            summary: "Três jeitos de encolher uma conversa, para três situações.",
            points: [
                "/clear começa do zero e não custa nada. Use quando o próximo trabalho não tiver relação. Rode /rename antes e você poderá voltar à sessão com /resume.",
                "/compact mantém o fio como um resumo. Use quando estiver continuando o mesmo trabalho e precisar do que foi decidido, não de cada passo.",
                "/rewind volta a um turno anterior. Use para abandonar um caminho errado: a conversa até aquele ponto já está em cache, então nada precisa ser reconstruído.",
                "De volta após uma pausa longa? O cache está frio de qualquer forma. Se não precisa mais do histórico, /clear. No Pro e no Max, o Claude Code oferece retomar uma sessão grande a partir de um resumo.",
            ],
            takeaway: "Clear para trabalho novo, compact para continuar, rewind para desfazer."),
        "cache-breakers": Text(
            title: "O que esvazia o cache sem avisar",
            summary: "Algumas ações que parecem inofensivas custam um turno a preço cheio.",
            points: [
                "Trocar de modelo com /model. Cada modelo tem seu próprio cache, então a próxima requisição lê todo o histórico sem acertos de cache. A configuração opusplan troca de modelo toda vez que você entra ou sai do modo de plano.",
                "Mudar o nível de effort no meio da sessão, na maioria dos modelos. Ativar o fast mode, uma vez por conversa.",
                "Atualizar o Claude Code: a primeira conversa após uma atualização constrói o cache desde o início.",
                "Sem risco: editar arquivos, mudar o modo de permissão, invocar skills e comandos, /recap. Editar o CLAUDE.md também é seguro, mas só vale depois de /clear, /compact ou de reiniciar.",
            ],
            takeaway: "Escolha modelo e effort no início da sessão e depois não mexa."),
        "small-context": Text(
            title: "Mantenha o contexto pequeno desde o início",
            summary: "O token mais barato é o que nunca entra no contexto.",
            points: [
                "Passe o trabalho verboso para subagentes: rodar testes, ler logs, buscar documentação. A saída fica no contexto deles e só um resumo volta para o seu.",
                "Seja específico. “Adicione validação de entrada à função de login em auth.ts” lê poucos arquivos; “melhore este código” varre tudo.",
                "Mantenha o CLAUDE.md curto, abaixo de umas 200 linhas: ele é carregado em toda sessão. Mova instruções de fluxos específicos para skills, que só carregam quando usadas.",
                "Desative servidores MCP que não está usando e rode /context para ver o que está enchendo a janela.",
            ],
            takeaway: "Quanto menos entra, menos há para reler e menos para compactar depois."),
        "reading-cachecue": Text(
            title: "Lendo o CacheCue de relance",
            summary: "O que os medidores, o relógio e o ponto estão dizendo.",
            points: [
                "Os medidores 5h e 7d: quanto de cada janela de limite você usou. Ficam âmbar em 70% e vermelhos em 90%.",
                "O relógio: o tempo que resta no cache da sessão atual. Mostra live enquanto um turno está em execução e exp depois que o cache expira.",
                "O ponto antes do relógio: há algo a fazer agora. O cache está prestes a expirar, já expirou, ou o contexto está quase cheio.",
                "O cartão no topo desta janela diz o que fazer e por quê. O botão copia /compact para você colar na sessão.",
                "Com várias sessões abertas, os limites são da sua conta; o relógio e o conselho são da sessão cujo cache valioso está prestes a esfriar ou, se não houver, da que agiu por último.",
                "Um ponto dentro da lua crescente: alguma sessão espera sua permissão ou sua resposta. Na lista, ela traz uma mão levantada.",
                "O número ao lado do floco de neve é o que uma sessão reescreve se o cache esfriar. Uma sessão já fria mostra o que retomá-la reescreve.",
                "Cada cartão de sessão oferece o que fazer quando o cache está para esfriar: nada; mantê-lo aquecido, em que o CacheCue relê o cache com uma requisição de uma linha cerca de 3 minutos antes de expirar, até 3 vezes seguidas, sem adicionar nada à conversa; ou compactar, em que o CacheCue executa /compact por você quando a sessão está ociosa e restam cerca de 5 minutos de cache, o que descarta detalhes e não pode ser desfeito. As duas custam um pouco, por isso nenhuma fica ativa até você escolher. Quando o Claude Code compacta sozinho uma sessão de terminal ociosa, o cartão avisa e o CacheCue não interfere.",
            ],
            takeaway: "Sem ponto, nada a fazer. Com ponto, abra a janela e leia o cartão."),
    ]

    static let it: [String: Text] = [
        "context-cost": Text(
            title: "Perché le sessioni lunghe costano care",
            summary: "Ogni richiesta rimanda l’intera conversazione.",
            points: [
                "Claude Code non conserva memoria tra una richiesta e l’altra, quindi ognuna porta con sé tutto: il prompt di sistema, il contesto del progetto, ogni messaggio e ogni risultato degli strumenti.",
                "Ogni volta che Claude usa uno strumento, è un’altra richiesta con dentro tutta la cronologia. Una sola domanda può significare decine di richieste.",
                "La cache dei prompt fa pagare la parte invariata alla tariffa di cache, un decimo del normale prezzo di input o meno. Economico, ma non gratuito, e cresce con il contesto.",
                "Così una domanda di una riga in una sessione aperta da tutto il giorno paga comunque per l’intera conversazione.",
            ],
            takeaway: "Quello che paghi, a ogni richiesta, è la dimensione del tuo contesto."),
        "cache-clock": Text(
            title: "Calda e fredda: la cache ha un orologio",
            summary: "Fermati troppo a lungo e il messaggio successivo paga prezzo pieno.",
            points: [
                "Una conversazione in cache scade dopo un periodo di inattività. Ogni richiesta che la legge azzera il timer, quindi la cache resta calda finché continui a lavorare.",
                "Con un abbonamento Claude, entro l’utilizzo del tuo piano, la cache della conversazione principale dura un’ora. Con crediti d’uso, una chiave API o un provider cloud dura cinque minuti per impostazione predefinita.",
                "Dopo la scadenza, il messaggio successivo rielabora l’intero contesto: più lento e molto più caro. Una scrittura di cache da un’ora costa il doppio del prezzo base di input e una lettura un decimo o meno: almeno 20 volte tanto.",
                "Di quanto dipende dal modello: 40 volte su Opus 5.5 e Sonnet 5.5, 80 volte su Fable 5.1, la cui lettura della cache costa meno. Una cache da 5 minuti si scrive a 1,25 volte il prezzo base, non al doppio. L'impostazione promptCacheTtl sceglie la durata.",
                "L’orologio di CacheCue è il tempo rimasto. Quando sta per finire e ti stai allontanando, quello è il momento di agire.",
            ],
            takeaway: "Continua a lavorare e la cache resta calda. Allontanati oltre il limite e paghi tutto di nuovo."),
        "compact-cost": Text(
            title: "Quanto costa davvero /compact",
            summary: "Una frazione con la cache calda, l’intero contesto con la cache fredda.",
            points: [
                "Per scrivere il riepilogo, Claude Code invia un’altra richiesta: tutta la cronologia più l’istruzione di riassumerla.",
                "Finché la cache è calda, quella richiesta legge la cronologia dalla cache. Compattare costa allora una frazione di quanto suggerisce la dimensione del contesto.",
                "Dopo la scadenza della cache non c’è nulla da leggere, e la stessa richiesta rielabora tutto senza cache. È il momento più costoso per compattare.",
                "In entrambi i casi, quello che segue costa poco: il turno successivo deve mettere in cache solo il breve riepilogo.",
                "Con un contesto piccolo c’è poco da alleggerire, e la richiesta di riepilogo costa più di quanto fa risparmiare.",
            ],
            takeaway: "Compatta finché la cache è calda, e solo quando c’è abbastanza da alleggerire."),
        "best-moment": Text(
            title: "Il momento migliore per compattare",
            summary: "Tra un’attività e l’altra, cache calda, contesto grande.",
            points: [
                "A una pausa naturale: un’attività è finita e la successiva non è iniziata. Compattare scarta dettagli, e a metà lavoro sono proprio quelli su cui ti basi.",
                "Prima di allontanarti per più tempo di quanto ne resta sull’orologio. Prima compatta, poi vai. Tornare a una cache fredda e compattare allora è l’ordine costoso.",
                "Quando il contesto è grande. La regola pratica di CacheCue è 100k token: da lì in poi ogni richiesta rilegge abbastanza perché la compattazione si ripaghi in fretta.",
                "Prima che lo faccia la compattazione automatica. Scatta quando la finestra è quasi piena, nel momento che sceglie lei, magari a metà di un’attività.",
                "Dille cosa conservare: /compact concentrati sulle modifiche all’API e sui test che falliscono.",
            ],
            takeaway: "Scegli tu il momento: tra un’attività e l’altra, finché l’orologio corre."),
        "compact-clear-rewind": Text(
            title: "/compact, /clear o /rewind?",
            summary: "Tre modi per ridurre una conversazione, per tre situazioni.",
            points: [
                "/clear riparte da zero e non costa nulla. Usalo quando il lavoro successivo non c’entra. Esegui prima /rename e potrai riprendere la sessione con /resume.",
                "/compact conserva il filo sotto forma di riepilogo. Usalo quando continui lo stesso lavoro e ti serve ciò che è stato deciso, non ogni passaggio.",
                "/rewind torna a un turno precedente. Usalo per abbandonare una strada sbagliata: la conversazione fino a quel punto è già in cache, quindi non c’è nulla da ricostruire.",
                "Di ritorno dopo una lunga pausa? La cache è fredda qualunque cosa tu faccia. Se la cronologia non ti serve più, /clear. Con Pro e Max, Claude Code propone di riprendere una sessione grande da un riepilogo.",
            ],
            takeaway: "Clear per un lavoro nuovo, compact per continuare, rewind per tornare indietro."),
        "cache-breakers": Text(
            title: "Cosa svuota la cache senza avvisare",
            summary: "Alcune azioni dall’aria innocua costano un turno a prezzo pieno.",
            points: [
                "Cambiare modello con /model. Ogni modello ha la propria cache, quindi la richiesta successiva legge tutta la cronologia senza alcun riscontro in cache. L’impostazione opusplan cambia modello ogni volta che entri o esci dalla modalità piano.",
                "Cambiare il livello di effort a sessione in corso, sulla maggior parte dei modelli. Attivare il fast mode, una volta per conversazione.",
                "Aggiornare Claude Code: la prima conversazione dopo un aggiornamento costruisce la cache da capo.",
                "Senza rischi: modificare file, cambiare modalità di permesso, invocare skill e comandi, /recap. Anche modificare CLAUDE.md è sicuro, ma vale solo dopo /clear, /compact o un riavvio.",
            ],
            takeaway: "Scegli modello ed effort all’inizio della sessione, poi non toccarli."),
        "small-context": Text(
            title: "Tenere piccolo il contesto fin dall’inizio",
            summary: "Il token meno caro è quello che non entra mai nel contesto.",
            points: [
                "Affida il lavoro verboso ai subagenti: eseguire test, leggere log, recuperare documentazione. L’output resta nel loro contesto e a te torna solo un riepilogo.",
                "Sii specifico. «Aggiungi la validazione dell’input alla funzione di login in auth.ts» legge pochi file; «migliora questo codice» lo scorre tutto.",
                "Tieni CLAUDE.md corto, sotto le 200 righe circa: viene caricato in ogni sessione. Sposta le istruzioni per flussi specifici nelle skill, che si caricano solo quando servono.",
                "Disattiva i server MCP che non usi ed esegui /context per vedere cosa sta riempiendo la finestra.",
            ],
            takeaway: "Meno entra, meno c’è da rileggere e meno da compattare dopo."),
        "reading-cachecue": Text(
            title: "Leggere CacheCue a colpo d’occhio",
            summary: "Cosa dicono gli indicatori, l’orologio e il punto.",
            points: [
                "Gli indicatori 5h e 7d: quanto hai usato di ciascuna finestra di limite. Diventano ambra al 70% e rossi al 90%.",
                "L’orologio: il tempo rimasto alla cache della sessione corrente. Mostra live mentre un turno è in esecuzione ed exp quando la cache è scaduta.",
                "Il punto davanti all’orologio: c’è qualcosa da fare adesso. La cache sta per scadere, è scaduta, oppure il contesto è quasi pieno.",
                "La scheda in cima a questa finestra dice cosa fare e perché. Il suo pulsante copia /compact da incollare nella sessione.",
                "Con più sessioni aperte, i limiti sono del tuo account; l’orologio e il consiglio sono della sessione la cui cache utile sta per raffreddarsi, altrimenti di quella che ha agito per ultima.",
                "Un punto nella falce di luna: una sessione aspetta il tuo permesso o la tua risposta. Nell’elenco ha una mano alzata.",
                "La cifra accanto al fiocco di neve è ciò che una sessione riscrive se la cache si raffredda. Una sessione già fredda indica ciò che riprenderla riscrive.",
                "Ogni scheda di sessione offre una scelta per quando la cache sta per raffreddarsi: niente; tenerla calda, con CacheCue che rilegge la cache con una richiesta di una riga circa 3 minuti prima che scada, fino a 3 volte di fila, senza aggiungere nulla alla conversazione; oppure compattare, con CacheCue che esegue /compact per te quando la sessione è inattiva e restano circa 5 minuti di cache, il che elimina dettagli e non si può annullare. Entrambe costano un po’, quindi nessuna è attiva finché non la scegli. Quando Claude Code compatta da solo una sessione di terminale inattiva, la scheda lo dice e CacheCue non interviene.",
            ],
            takeaway: "Nessun punto, niente da fare. Un punto: apri la finestra e leggi la scheda."),
    ]
}
