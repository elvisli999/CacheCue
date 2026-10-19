import Foundation

/// One lesson of the guide: a few points and the one thing to take from them.
public struct Lesson: Identifiable, Equatable {
    public let id: String
    public let title: String
    /// One line, for the list.
    public let summary: String
    public let points: [String]
    public let takeaway: String
    /// Where the lesson's claims come from.
    public let source: URL
}

/// The guide: how Claude Code spends tokens, and how to spend fewer.
///
/// Every claim is from Anthropic's own pages on prompt caching and on managing costs;
/// where a lesson gives CacheCue's own rule of thumb, it says so.
public enum Guide {
    private static let costs = URL(string: "https://code.claude.com/docs/en/costs")!
    private static let caching = URL(string: "https://code.claude.com/docs/en/prompt-caching")!
    private static let project = URL(string: "https://github.com/elvisli999/CacheCue")!

    private static let order: [(id: String, source: URL)] = [
        ("context-cost", costs), ("cache-clock", caching), ("compact-cost", caching), ("best-moment", caching),
        ("compact-clear-rewind", caching), ("cache-breakers", caching), ("small-context", costs),
        ("reading-cachecue", project),
    ]

    public static func lessons(_ language: Language) -> [Lesson] {
        // Every language the app speaks has the lessons in it: no case falls back to English.
        let texts: [String: Text]
        switch language {
        case .en: texts = en
        case .zhHans: texts = zhHans
        case .zhHant: texts = zhHant
        case .ja: texts = ja
        case .ko: texts = ko
        case .de: texts = de
        case .fr: texts = fr
        case .es: texts = es
        case .pt: texts = pt
        case .it: texts = it
        case .nl: texts = nl
        case .sv: texts = sv
        case .pl: texts = pl
        case .ru: texts = ru
        case .tr: texts = tr
        case .id: texts = id
        case .vi: texts = vi
        case .th: texts = th
        case .hi: texts = hi
        case .ar: texts = ar
        }
        return order.compactMap { entry in
            guard let text = texts[entry.id] else { return nil }
            return Lesson(
                id: entry.id, title: text.title, summary: text.summary, points: text.points,
                takeaway: text.takeaway, source: entry.source)
        }
    }

    /// The lesson that explains a piece of advice; none while a turn is simply running.
    public static func lessonID(for kind: CompactAdvice.Kind) -> String? {
        switch kind {
        case .running: return nil
        case .nearFull, .worthIt: return "best-moment"
        case .notNeeded: return "compact-cost"
        case .beforeExpiry: return "cache-clock"
        case .cold, .optional: return "compact-clear-rewind"
        }
    }

    struct Text {
        let title: String
        let summary: String
        let points: [String]
        let takeaway: String
    }

    static let en: [String: Text] = [
        "context-cost": Text(
            title: "Why long sessions get expensive",
            summary: "Every request re-sends the whole conversation.",
            points: [
                "Claude Code keeps no memory between requests, so each one carries everything: the system prompt, your project context, every message and every tool result.",
                "Each time Claude uses tools, that is another request with the whole history in it. One prompt can mean dozens of requests.",
                "Prompt caching bills the unchanged part at the cached rate, a tenth of the normal input price or less. Cheap, but not free, and it grows with the context.",
                "So a one-line question in a session that has been open all day still pays for the whole conversation.",
            ],
            takeaway: "What you pay for, on every request, is the size of your context."),
        "cache-clock": Text(
            title: "Warm and cold: the cache has a clock",
            summary: "Stop for too long and the next message pays full price.",
            points: [
                "A cached conversation expires after a period of inactivity. Every request that reads it resets the timer, so the cache stays warm for as long as you keep working.",
                "On a Claude subscription, within your plan's usage, the main conversation's cache lasts one hour. On usage credits, an API key or a cloud provider it lasts five minutes by default.",
                "After it expires, your next message reprocesses the entire context: slower, and far more expensive. A one-hour cache write costs twice the base input price and a cache read a tenth or less, so that is at least 20 times the price.",
                "How much more depends on the model: 40 times on Opus 5.5 and Sonnet 5.5, 80 times on Fable 5.1, whose cache reads cost less. A five-minute cache is written at 1.25 times the base price, not twice. The promptCacheTtl setting picks the lifetime.",
                "CacheCue's clock is the time left. When it is about to run out and you are stepping away, that is the moment to act.",
            ],
            takeaway: "Keep working and the cache stays warm. Walk away past the limit and you pay for everything again."),
        "compact-cost": Text(
            title: "What /compact really costs",
            summary: "A fraction when the cache is warm, the full context when it is cold.",
            points: [
                "To write the summary, Claude Code sends one more request: your whole history plus an instruction to summarise it.",
                "While the cache is warm, that request reads your history from the cache. Compacting then costs a fraction of what the context size suggests.",
                "After the cache has expired there is nothing to read, so the same request reprocesses everything uncached. This is the most expensive time to compact.",
                "Either way, what follows is cheap: the next turn only has the short summary to cache.",
                "On a small context there is little to shed, so the summary request costs more than it saves.",
            ],
            takeaway: "Compact while the cache is warm, and only when there is enough to shed."),
        "best-moment": Text(
            title: "The best moment to compact",
            summary: "Between tasks, cache warm, context large.",
            points: [
                "At a natural break: one task is finished and the next has not started. Compacting discards detail, and mid-task that detail is what you are working from.",
                "Before you step away for longer than the clock has left. Compact first, then go. Coming back to a cold cache and compacting then is the costly order.",
                "When the context is large. CacheCue's rule of thumb is 100k tokens: from there, every request re-reads enough for compacting to pay for itself quickly.",
                "Before auto-compact does it for you. It triggers when the window is nearly full, at a moment it chooses, which may be the middle of a task.",
                "Tell it what to keep: /compact focus on the API changes and the failing tests.",
            ],
            takeaway: "Choose the moment yourself: between tasks, while the clock is still running."),
        "compact-clear-rewind": Text(
            title: "/compact, /clear or /rewind?",
            summary: "Three ways to shrink a conversation, for three situations.",
            points: [
                "/clear starts fresh and costs nothing. Use it when the next piece of work is unrelated. Run /rename first and you can /resume the old session later.",
                "/compact keeps the thread as a summary. Use it when you are continuing the same work and need what was decided, not every step that led there.",
                "/rewind goes back to an earlier turn. Use it to abandon a wrong path: the conversation up to that point is already cached, so nothing has to be rebuilt.",
                "Back after a long break? The cache is cold whatever you do. If you no longer need the history, /clear. On Pro and Max, Claude Code offers to resume a large session from a summary.",
            ],
            takeaway: "Clear for new work, compact to continue, rewind to undo."),
        "cache-breakers": Text(
            title: "What quietly empties the cache",
            summary: "Some harmless-looking actions cost one full-price turn.",
            points: [
                "Switching models with /model. Each model has its own cache, so the next request reads the whole history with no cache hits. The opusplan setting switches model every time you enter or leave plan mode.",
                "Changing effort level mid-session, on most models. Turning on fast mode, once per conversation.",
                "Upgrading Claude Code: the first conversation after an upgrade builds its cache from the start.",
                "Safe to do: editing files, changing permission mode, invoking skills and commands, /recap. Edits to CLAUDE.md are safe too, but only apply after /clear, /compact or a restart.",
            ],
            takeaway: "Pick your model and effort at the start of a session, then leave them alone."),
        "small-context": Text(
            title: "Keep the context small to begin with",
            summary: "The cheapest token is the one that never enters the context.",
            points: [
                "Hand verbose work to subagents: running tests, reading logs, fetching documentation. The output stays in their context and only a summary returns to yours.",
                "Be specific. \"Add input validation to the login function in auth.ts\" reads a few files; \"improve this codebase\" scans all of it.",
                "Keep CLAUDE.md short, under about 200 lines: it is loaded into every session. Move instructions for specific workflows into skills, which load only when used.",
                "Disable MCP servers you are not using, and run /context to see what is filling the window.",
            ],
            takeaway: "Less going in means less to re-read, and less to compact later."),
        "reading-cachecue": Text(
            title: "Reading CacheCue at a glance",
            summary: "What the gauges, the clock and the dot are telling you.",
            points: [
                "The 5h and 7d gauges: how much of each rate-limit window you have used. They turn amber at 70% and red at 90%.",
                "The clock: time left on the current session's cache. It reads live while a turn is running and exp once the cache has expired.",
                "The dot before the clock: there is something to act on now. The cache is about to expire, has expired, or the context is nearly full.",
                "The card at the top of this window says what to do and why. Its button copies /compact for you to paste into the session.",
                "With several sessions open, the limits are your account's; the clock and the advice belong to the session about to lose a cache worth keeping, or else to the one that last did something.",
                "A dot inside the crescent: some session is waiting for your permission or your reply. In the list it carries a raised hand.",
                "The figure beside the snowflake is what a session rewrites if its cache goes cold. A session already cold says what resuming it rewrites.",
                "Each session card has a choice for when its cache is about to go cold. Leave it; keep it warm, where CacheCue rereads the cache with a one-line request about 3 minutes before it runs out, up to 3 times in a row, adding nothing to the conversation; or compact, where CacheCue runs /compact for you once the session sits idle with about 5 minutes of cache left, which drops detail and cannot be undone. Both cost a little, so neither is on until you choose it. Where Claude Code compacts an idle terminal session itself, the card says so and CacheCue stays out of it.",
            ],
            takeaway: "No dot, nothing to do. A dot means open the window and read the card."),
    ]

    static let zhHans: [String: Text] = [
        "context-cost": Text(
            title: "为什么长会话越来越贵",
            summary: "每次请求都会把整段对话重新发一遍。",
            points: [
                "Claude Code 在两次请求之间不保留任何记忆,所以每次请求都带着全部内容:系统提示、项目上下文、每一条消息、每一个工具结果。",
                "Claude 每用一次工具,就是又一次带着完整历史的请求。你发一句话,背后可能是几十次请求。",
                "提示缓存让没变的部分按缓存价计费,只有正常输入价的十分之一甚至更低。便宜,但不是免费,而且随上下文一起变大。",
                "所以在一个开了一整天的会话里问一句话,付的仍然是整段对话的钱。",
            ],
            takeaway: "每次请求你付的,是整个上下文的大小。"),
        "cache-clock": Text(
            title: "冷与热:缓存有个钟",
            summary: "停太久,下一条消息就按全价算。",
            points: [
                "缓存的对话一段时间不用就会过期。每次读到它的请求都会把计时重置,所以只要你一直在干活,缓存就一直是热的。",
                "用 Claude 订阅、且在套餐额度内时,主对话的缓存保留 1 小时。用额外额度、API key 或云厂商时,默认只有 5 分钟。",
                "过期之后,你的下一条消息要把整个上下文重新处理一遍:更慢,也贵得多。1 小时缓存的写入价是基础输入价的 2 倍,读取价是十分之一或更低,所以至少贵 20 倍。",
                "贵多少倍取决于模型：Opus 5.5 和 Sonnet 5.5 是 40 倍，Fable 5.1 的缓存读取更便宜，是 80 倍。5 分钟缓存的写入价是基础价的 1.25 倍，不是 2 倍。用 promptCacheTtl 设置可以选缓存寿命。",
                "CacheCue 上的时钟就是剩余时间。它快走完、而你正要离开的时候,就是该动手的时候。",
            ],
            takeaway: "一直干活,缓存就一直热;离开超过时限,就得把全部内容再付一遍。"),
        "compact-cost": Text(
            title: "/compact 到底花多少",
            summary: "缓存热时只花一小部分,冷了就是整个上下文。",
            points: [
                "为了写出摘要,Claude Code 会多发一次请求:你的全部历史,加上一句“请总结”。",
                "缓存还热时,这次请求从缓存里读历史,所以压缩的花费只是上下文大小的一小部分。",
                "缓存过期后就没有东西可读了,同一个请求要把全部内容按未缓存重新处理。这是压缩最贵的时刻。",
                "无论哪种情况,之后都便宜:下一轮只需要缓存那份很短的摘要。",
                "上下文很小时没多少可丢的,这时总结请求的花费比省下的还多。",
            ],
            takeaway: "趁缓存还热时压缩,而且要等有足够多的内容可丢。"),
        "best-moment": Text(
            title: "什么时候压缩最划算",
            summary: "任务之间、缓存还热、上下文够大。",
            points: [
                "在自然的停顿点:一个任务做完,下一个还没开始。压缩会丢掉细节,而任务做到一半时,你靠的正是这些细节。",
                "在你要离开、而且离开的时间比时钟剩下的还长之前。先压缩再走。回来面对冷掉的缓存再压缩,是最费钱的顺序。",
                "在上下文够大的时候。CacheCue 的经验值是 10 万 token:从这里开始,每次请求重读的量足够让压缩很快回本。",
                "抢在自动压缩之前。它在窗口快满时触发,时机由它自己挑,可能正好在任务中途。",
                "告诉它保留什么:/compact 重点保留 API 改动和失败的测试。",
            ],
            takeaway: "自己挑时机:在任务之间,趁时钟还在走。"),
        "compact-clear-rewind": Text(
            title: "/compact、/clear 还是 /rewind?",
            summary: "三种缩小对话的办法,对应三种情况。",
            points: [
                "/clear 从头开始,不花钱。下一件事和现在无关时用它。先 /rename,以后还能用 /resume 找回这段会话。",
                "/compact 把来龙去脉留成一份摘要。继续做同一件事、需要的是“定了什么”而不是每一步过程时用它。",
                "/rewind 退回到之前的某一轮。用来放弃走错的路:那之前的对话已经在缓存里,不需要重建。",
                "隔了很久才回来?无论怎么做缓存都是冷的。不再需要历史就 /clear。Pro 和 Max 用户恢复大会话时,Claude Code 会提议从摘要恢复。",
            ],
            takeaway: "新任务用 clear,要继续用 compact,想反悔用 rewind。"),
        "cache-breakers": Text(
            title: "哪些操作会悄悄清空缓存",
            summary: "有些看起来无害的操作,要付一轮全价。",
            points: [
                "用 /model 换模型。每个模型有自己的缓存,下一次请求要把全部历史不走缓存地读一遍。opusplan 设置在每次进出计划模式时都会换模型。",
                "会话中途改 effort 级别(多数模型上如此)。开启 fast mode(每段对话一次)。",
                "升级 Claude Code:升级后的第一段对话要从头建缓存。",
                "可以放心做的:改文件、换权限模式、调用 skill 和命令、/recap。改 CLAUDE.md 也不伤缓存,但要等 /clear、/compact 或重启后才生效。",
            ],
            takeaway: "模型和 effort 在会话开始时选好,之后别动。"),
        "small-context": Text(
            title: "从源头让上下文保持小",
            summary: "最便宜的 token,是从没进过上下文的那个。",
            points: [
                "把输出冗长的活交给子代理:跑测试、读日志、查文档。输出留在它们的上下文里,回到你这边的只有摘要。",
                "把话说具体。“给 auth.ts 里的登录函数加输入校验”只读几个文件;“优化这个代码库”会把整个库扫一遍。",
                "CLAUDE.md 保持精简,大约 200 行以内:它会被加载进每一个会话。特定流程的说明挪到 skill 里,用到时才加载。",
                "停用不在用的 MCP 服务器;用 /context 看看是什么占满了窗口。",
            ],
            takeaway: "进来的少,要重读的就少,以后要压缩的也少。"),
        "reading-cachecue": Text(
            title: "看懂 CacheCue",
            summary: "竖条、时钟和圆点各自在说什么。",
            points: [
                "5h 和 7d 两根竖条:两个额度窗口各用了多少。到 70% 变琥珀色,到 90% 变红。",
                "时钟:当前会话的缓存还剩多久。一轮正在跑时显示 live,缓存过期后显示 exp。",
                "时钟前的圆点:现在有事要处理。缓存快过期、已经过期,或者上下文快满了。",
                "这个窗口顶部的卡片告诉你该做什么、为什么。卡片上的按钮会复制 /compact,粘贴到会话里即可。",
                "同时开着多个会话时,额度是整个账号的;时钟和建议属于缓存快要变冷、值得保住的那个会话,没有这样的会话时属于最近有动静的那个。",
                "月牙里的圆点:有会话在等你批准或回复。在列表里,那个会话带一个举手的图标。",
                "会话旁边雪花后的数字,是它的缓存冷掉后要重写的量。已经冷掉的会话会写明恢复它要重写多少。",
                "会话卡上可以选缓存快变冷时怎么办:不管;保温,CacheCue 在缓存到期前约 3 分钟发一条一句话的请求把缓存读一遍,最多连续 3 次,对话里不多出任何内容;或压缩,该会话空闲、缓存只剩约 5 分钟时替你运行 /compact,会丢掉细节且无法撤销。两者都要花一点钱,所以要你自己选。Claude Code 会在空闲时自己压缩的终端会话,卡片上会写明,CacheCue 不插手。",
            ],
            takeaway: "没有圆点就不用管;有圆点就点开窗口看卡片。"),
    ]

    static let zhHant: [String: Text] = [
        "context-cost": Text(
            title: "為什麼長對話越來越貴",
            summary: "每次請求都會把整段對話重新送一遍。",
            points: [
                "Claude Code 在兩次請求之間不保留任何記憶,所以每次請求都帶著全部內容:系統提示、專案上下文、每一則訊息、每一個工具結果。",
                "Claude 每用一次工具,就是又一次帶著完整歷史的請求。你送出一句話,背後可能是幾十次請求。",
                "提示快取讓沒變的部分按快取價計費,只有正常輸入價的十分之一甚至更低。便宜,但不是免費,而且隨上下文一起變大。",
                "所以在一個開了一整天的工作階段裡問一句話,付的仍然是整段對話的錢。",
            ],
            takeaway: "每次請求你付的,是整個上下文的大小。"),
        "cache-clock": Text(
            title: "冷與熱:快取有個鐘",
            summary: "停太久,下一則訊息就按全價算。",
            points: [
                "快取的對話一段時間不用就會過期。每次讀到它的請求都會把計時重設,所以只要你一直在工作,快取就一直是熱的。",
                "使用 Claude 訂閱、且在方案額度內時,主對話的快取保留 1 小時。使用額外額度、API key 或雲端供應商時,預設只有 5 分鐘。",
                "過期之後,你的下一則訊息要把整個上下文重新處理一遍:更慢,也貴得多。1 小時快取的寫入價是基礎輸入價的 2 倍,讀取價是十分之一或更低,所以至少貴 20 倍。",
                "貴多少倍取決於模型：Opus 5.5 和 Sonnet 5.5 是 40 倍，Fable 5.1 的快取讀取更便宜，是 80 倍。5 分鐘快取的寫入價是基礎價的 1.25 倍，不是 2 倍。用 promptCacheTtl 設定可以選快取壽命。",
                "CacheCue 上的時鐘就是剩餘時間。它快走完、而你正要離開的時候,就是該動手的時候。",
            ],
            takeaway: "一直工作,快取就一直熱;離開超過時限,就得把全部內容再付一遍。"),
        "compact-cost": Text(
            title: "/compact 到底花多少",
            summary: "快取熱時只花一小部分,冷了就是整個上下文。",
            points: [
                "為了寫出摘要,Claude Code 會多送一次請求:你的全部歷史,加上一句「請總結」。",
                "快取還熱時,這次請求從快取裡讀歷史,所以壓縮的花費只是上下文大小的一小部分。",
                "快取過期後就沒有東西可讀了,同一個請求要把全部內容按未快取重新處理。這是壓縮最貴的時刻。",
                "無論哪種情況,之後都便宜:下一輪只需要快取那份很短的摘要。",
                "上下文很小時沒多少可丟的,這時總結請求的花費比省下的還多。",
            ],
            takeaway: "趁快取還熱時壓縮,而且要等有足夠多的內容可丟。"),
        "best-moment": Text(
            title: "什麼時候壓縮最划算",
            summary: "任務之間、快取還熱、上下文夠大。",
            points: [
                "在自然的停頓點:一個任務做完,下一個還沒開始。壓縮會丟掉細節,而任務做到一半時,你靠的正是這些細節。",
                "在你要離開、而且離開的時間比時鐘剩下的還長之前。先壓縮再走。回來面對冷掉的快取再壓縮,是最花錢的順序。",
                "在上下文夠大的時候。CacheCue 的經驗值是 10 萬 token:從這裡開始,每次請求重讀的量足夠讓壓縮很快回本。",
                "搶在自動壓縮之前。它在視窗快滿時觸發,時機由它自己挑,可能正好在任務中途。",
                "告訴它保留什麼:/compact 重點保留 API 改動和失敗的測試。",
            ],
            takeaway: "自己挑時機:在任務之間,趁時鐘還在走。"),
        "compact-clear-rewind": Text(
            title: "/compact、/clear 還是 /rewind?",
            summary: "三種縮小對話的方法,對應三種情況。",
            points: [
                "/clear 從頭開始,不花錢。下一件事和現在無關時用它。先 /rename,以後還能用 /resume 找回這段工作階段。",
                "/compact 把來龍去脈留成一份摘要。繼續做同一件事、需要的是「決定了什麼」而不是每一步過程時用它。",
                "/rewind 退回到之前的某一輪。用來放棄走錯的路:那之前的對話已經在快取裡,不需要重建。",
                "隔了很久才回來?無論怎麼做快取都是冷的。不再需要歷史就 /clear。Pro 和 Max 使用者恢復大型工作階段時,Claude Code 會提議從摘要恢復。",
            ],
            takeaway: "新任務用 clear,要繼續用 compact,想反悔用 rewind。"),
        "cache-breakers": Text(
            title: "哪些操作會悄悄清空快取",
            summary: "有些看起來無害的操作,要付一輪全價。",
            points: [
                "用 /model 換模型。每個模型有自己的快取,下一次請求要把全部歷史不走快取地讀一遍。opusplan 設定在每次進出計畫模式時都會換模型。",
                "工作階段中途改 effort 等級(多數模型上如此)。開啟 fast mode(每段對話一次)。",
                "升級 Claude Code:升級後的第一段對話要從頭建立快取。",
                "可以放心做的:改檔案、換權限模式、呼叫 skill 和指令、/recap。改 CLAUDE.md 也不傷快取,但要等 /clear、/compact 或重新啟動後才生效。",
            ],
            takeaway: "模型和 effort 在工作階段開始時選好,之後別動。"),
        "small-context": Text(
            title: "從源頭讓上下文保持小",
            summary: "最便宜的 token,是從沒進過上下文的那個。",
            points: [
                "把輸出冗長的工作交給子代理:跑測試、讀日誌、查文件。輸出留在它們的上下文裡,回到你這邊的只有摘要。",
                "把話說具體。「替 auth.ts 裡的登入函式加上輸入驗證」只讀幾個檔案;「最佳化這個程式碼庫」會把整個庫掃一遍。",
                "CLAUDE.md 保持精簡,大約 200 行以內:它會被載入每一個工作階段。特定流程的說明移到 skill 裡,用到時才載入。",
                "停用沒在用的 MCP 伺服器;用 /context 看看是什麼佔滿了視窗。",
            ],
            takeaway: "進來的少,要重讀的就少,以後要壓縮的也少。"),
        "reading-cachecue": Text(
            title: "看懂 CacheCue",
            summary: "直條、時鐘和圓點各自在說什麼。",
            points: [
                "5h 和 7d 兩根直條:兩個額度視窗各用了多少。到 70% 變琥珀色,到 90% 變紅。",
                "時鐘:目前工作階段的快取還剩多久。一輪正在跑時顯示 live,快取過期後顯示 exp。",
                "時鐘前的圓點:現在有事要處理。快取快過期、已經過期,或者上下文快滿了。",
                "這個視窗頂部的卡片告訴你該做什麼、為什麼。卡片上的按鈕會複製 /compact,貼到工作階段裡即可。",
                "同時開著多個工作階段時,額度是整個帳號的;時鐘和建議屬於快取快要變冷、值得保住的那個工作階段,沒有這樣的工作階段時屬於最近有動靜的那個。",
                "月牙裡的圓點:有工作階段在等你批准或回覆。在清單裡,那個工作階段帶一個舉手的圖示。",
                "工作階段旁邊雪花後的數字,是它的快取冷掉後要重寫的量。已經冷掉的工作階段會寫明恢復它要重寫多少。",
                "工作階段卡片上可以選快取快變冷時怎麼辦:不管;保溫,CacheCue 在快取到期前約 3 分鐘送出一句話的請求把快取讀一遍,最多連續 3 次,對話裡不多出任何內容;或壓縮,該工作階段閒置、快取只剩約 5 分鐘時替你執行 /compact,會丟掉細節且無法復原。兩者都要花一點錢,所以要你自己選。Claude Code 會在閒置時自行壓縮的終端機工作階段,卡片上會寫明,CacheCue 不插手。",
            ],
            takeaway: "沒有圓點就不用管;有圓點就點開視窗看卡片。"),
    ]
}
