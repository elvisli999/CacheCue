// The guide's lessons in Indonesian, Vietnamese, Thai, Hindi and Arabic. Same lessons, same
// points, as `Guide.en`.

extension Guide {
    static let id: [String: Text] = [
        "context-cost": Text(
            title: "Mengapa sesi panjang jadi mahal",
            summary: "Setiap permintaan mengirim ulang seluruh percakapan.",
            points: [
                "Claude Code tidak menyimpan ingatan di antara permintaan, jadi setiap permintaan membawa semuanya: prompt sistem, konteks proyek, setiap pesan, dan setiap hasil alat.",
                "Setiap kali Claude memakai alat, itu satu permintaan lagi dengan seluruh riwayat di dalamnya. Satu perintah bisa berarti puluhan permintaan.",
                "Prompt caching menagih bagian yang tidak berubah dengan tarif cache, sepersepuluh harga input normal atau kurang. Murah, tetapi tidak gratis, dan ikut membesar bersama konteks.",
                "Jadi pertanyaan satu baris dalam sesi yang terbuka seharian tetap membayar seluruh percakapan.",
            ],
            takeaway: "Yang Anda bayar, pada setiap permintaan, adalah ukuran konteks Anda."),
        "cache-clock": Text(
            title: "Hangat dan dingin: cache punya jam",
            summary: "Berhenti terlalu lama, pesan berikutnya membayar harga penuh.",
            points: [
                "Percakapan yang di-cache kedaluwarsa setelah tidak dipakai beberapa waktu. Setiap permintaan yang membacanya mengulang hitungan, jadi cache tetap hangat selama Anda terus bekerja.",
                "Dengan langganan Claude, dalam batas pemakaian paket, cache percakapan utama bertahan satu jam. Dengan kredit pemakaian, kunci API, atau penyedia cloud, bawaannya lima menit.",
                "Setelah kedaluwarsa, pesan berikutnya memproses ulang seluruh konteks: lebih lambat dan jauh lebih mahal. Penulisan cache satu jam berbiaya dua kali harga input dasar, sedangkan pembacaan sepersepuluh atau kurang, jadi setidaknya 20 kali lipat.",
                "Berapa kali lipatnya bergantung pada model: 40 kali pada Opus 5.5 dan Sonnet 5.5, 80 kali pada Fable 5.1 yang pembacaan cache-nya lebih murah. Cache 5 menit ditulis seharga 1,25 kali harga dasar, bukan dua kali. Pengaturan promptCacheTtl memilih masa hidupnya.",
                "Jam di CacheCue adalah waktu yang tersisa. Saat waktunya hampir habis dan Anda hendak pergi, itulah saatnya bertindak.",
            ],
            takeaway: "Terus bekerja dan cache tetap hangat. Pergi melewati batas, dan Anda membayar semuanya lagi."),
        "compact-cost": Text(
            title: "Berapa sebenarnya biaya /compact",
            summary: "Sebagian kecil saat cache hangat, seluruh konteks saat dingin.",
            points: [
                "Untuk menulis ringkasan, Claude Code mengirim satu permintaan lagi: seluruh riwayat Anda ditambah instruksi untuk meringkasnya.",
                "Selama cache hangat, permintaan itu membaca riwayat dari cache. Memadatkan lalu hanya berbiaya sebagian kecil dari yang tersirat oleh ukuran konteks.",
                "Setelah cache kedaluwarsa tidak ada yang bisa dibaca, sehingga permintaan yang sama memproses ulang semuanya tanpa cache. Inilah saat paling mahal untuk memadatkan.",
                "Dalam kedua kasus, selanjutnya murah: giliran berikutnya hanya perlu men-cache ringkasan yang pendek.",
                "Pada konteks kecil, hanya sedikit yang bisa dibuang, jadi permintaan ringkasan lebih mahal daripada penghematannya.",
            ],
            takeaway: "Padatkan selagi cache hangat, dan hanya bila cukup banyak yang bisa dibuang."),
        "best-moment": Text(
            title: "Saat terbaik untuk memadatkan",
            summary: "Di antara tugas, cache hangat, konteks besar.",
            points: [
                "Pada jeda alami: satu tugas selesai dan tugas berikutnya belum dimulai. Memadatkan membuang detail, dan di tengah tugas justru detail itulah yang Anda pakai.",
                "Sebelum Anda pergi lebih lama daripada sisa waktu di jam. Padatkan dulu, baru pergi. Kembali ke cache yang dingin lalu memadatkan adalah urutan yang mahal.",
                "Saat konteks besar. Patokan CacheCue adalah 100k token: dari situ, setiap permintaan membaca ulang cukup banyak sehingga pemadatan cepat balik modal.",
                "Sebelum pemadatan otomatis melakukannya untuk Anda. Ia berjalan saat jendela hampir penuh, pada waktu yang dipilihnya sendiri, mungkin di tengah tugas.",
                "Beri tahu apa yang harus dipertahankan: /compact fokus pada perubahan API dan tes yang gagal.",
            ],
            takeaway: "Pilih sendiri waktunya: di antara tugas, selagi jam masih berjalan."),
        "compact-clear-rewind": Text(
            title: "/compact, /clear, atau /rewind?",
            summary: "Tiga cara mengecilkan percakapan, untuk tiga situasi.",
            points: [
                "/clear memulai dari awal dan tidak berbiaya apa pun. Pakai saat pekerjaan berikutnya tidak berkaitan. Jalankan /rename dulu, dan nanti Anda bisa kembali ke sesi itu dengan /resume.",
                "/compact menyimpan alur sebagai ringkasan. Pakai saat Anda melanjutkan pekerjaan yang sama dan yang dibutuhkan adalah apa yang sudah diputuskan, bukan setiap langkahnya.",
                "/rewind kembali ke giliran sebelumnya. Pakai untuk meninggalkan jalur yang salah: percakapan sampai titik itu sudah ada di cache, jadi tidak ada yang perlu dibangun ulang.",
                "Kembali setelah jeda panjang? Cache sudah dingin apa pun yang Anda lakukan. Jika riwayat tidak lagi dibutuhkan, /clear. Di Pro dan Max, Claude Code menawarkan melanjutkan sesi besar dari ringkasan.",
            ],
            takeaway: "Clear untuk pekerjaan baru, compact untuk melanjutkan, rewind untuk membatalkan."),
        "cache-breakers": Text(
            title: "Apa yang diam-diam mengosongkan cache",
            summary: "Beberapa tindakan yang tampak sepele berbiaya satu giliran harga penuh.",
            points: [
                "Mengganti model dengan /model. Setiap model punya cache sendiri, jadi permintaan berikutnya membaca seluruh riwayat tanpa cache hit. Pengaturan opusplan mengganti model setiap kali Anda masuk atau keluar dari mode rencana.",
                "Mengubah tingkat effort di tengah sesi, pada kebanyakan model. Menyalakan fast mode, sekali per percakapan.",
                "Memperbarui Claude Code: percakapan pertama setelah pembaruan membangun cache dari awal.",
                "Aman dilakukan: mengedit berkas, mengganti mode izin, memanggil skill dan perintah, /recap. Mengedit CLAUDE.md juga aman, tetapi baru berlaku setelah /clear, /compact, atau mulai ulang.",
            ],
            takeaway: "Pilih model dan effort di awal sesi, lalu jangan diubah."),
        "small-context": Text(
            title: "Jaga konteks tetap kecil sejak awal",
            summary: "Token termurah adalah yang tidak pernah masuk ke konteks.",
            points: [
                "Serahkan pekerjaan yang keluarannya panjang kepada subagen: menjalankan tes, membaca log, mengambil dokumentasi. Keluarannya tinggal di konteks mereka dan hanya ringkasan yang kembali ke konteks Anda.",
                "Jadilah spesifik. “Tambahkan validasi input ke fungsi login di auth.ts” membaca beberapa berkas; “perbaiki basis kode ini” memindai semuanya.",
                "Jaga CLAUDE.md tetap pendek, di bawah sekitar 200 baris: berkas itu dimuat ke setiap sesi. Pindahkan instruksi alur kerja tertentu ke skill, yang hanya dimuat saat dipakai.",
                "Nonaktifkan server MCP yang tidak Anda pakai, dan jalankan /context untuk melihat apa yang memenuhi jendela.",
            ],
            takeaway: "Makin sedikit yang masuk, makin sedikit yang dibaca ulang dan dipadatkan nanti."),
        "reading-cachecue": Text(
            title: "Membaca CacheCue sekilas",
            summary: "Apa yang dikatakan pengukur, jam, dan titik.",
            points: [
                "Pengukur 5h dan 7d: seberapa banyak tiap jendela batas yang sudah terpakai. Berubah kuning tua di 70% dan merah di 90%.",
                "Jam: sisa waktu cache sesi saat ini. Menampilkan live saat giliran sedang berjalan dan exp setelah cache kedaluwarsa.",
                "Titik di depan jam: ada yang perlu dilakukan sekarang. Cache hampir kedaluwarsa, sudah kedaluwarsa, atau konteks hampir penuh.",
                "Kartu di bagian atas jendela ini mengatakan apa yang harus dilakukan dan mengapa. Tombolnya menyalin /compact untuk ditempel ke sesi.",
                "Saat beberapa sesi terbuka, batas adalah milik akun Anda; jam dan saran adalah milik sesi yang cache berharganya hampir dingin, atau jika tidak ada, sesi yang terakhir beraktivitas.",
                "Titik di dalam bulan sabit: ada sesi yang menunggu izin atau jawaban Anda. Di daftar, sesi itu bertanda tangan terangkat.",
                "Angka di samping kepingan salju adalah yang ditulis ulang sesi jika cache-nya dingin. Sesi yang sudah dingin menunjukkan apa yang ditulis ulang saat dilanjutkan.",
                "Setiap kartu sesi punya pilihan untuk saat cache hampir dingin: biarkan; jaga hangat, CacheCue membaca ulang cache dengan permintaan satu baris sekitar 3 menit sebelum kedaluwarsa, paling banyak 3 kali berturut-turut, tanpa menambah apa pun ke percakapan; atau padatkan, CacheCue menjalankan /compact untuk Anda saat sesi diam dan cache tersisa sekitar 5 menit, yang membuang detail dan tidak bisa dibatalkan. Keduanya ada biayanya, jadi tidak ada yang aktif sampai Anda memilihnya. Jika Claude Code memadatkan sendiri sesi terminal yang diam, kartu akan menyebutkannya dan CacheCue tidak ikut campur.",
            ],
            takeaway: "Tanpa titik, tidak ada yang perlu dilakukan. Ada titik: buka jendela dan baca kartunya."),
    ]

    static let vi: [String: Text] = [
        "context-cost": Text(
            title: "Vì sao phiên dài lại tốn kém",
            summary: "Mỗi yêu cầu đều gửi lại toàn bộ cuộc trò chuyện.",
            points: [
                "Claude Code không ghi nhớ gì giữa các yêu cầu, nên mỗi yêu cầu mang theo tất cả: prompt hệ thống, ngữ cảnh dự án, mọi tin nhắn và mọi kết quả công cụ.",
                "Mỗi lần Claude dùng công cụ là thêm một yêu cầu chứa toàn bộ lịch sử. Một câu lệnh có thể thành hàng chục yêu cầu.",
                "Bộ nhớ đệm prompt tính phần không đổi theo giá cache, bằng một phần mười giá đầu vào thông thường hoặc ít hơn. Rẻ, nhưng không miễn phí, và tăng theo ngữ cảnh.",
                "Vì vậy một câu hỏi một dòng trong phiên đã mở cả ngày vẫn phải trả cho toàn bộ cuộc trò chuyện.",
            ],
            takeaway: "Thứ bạn trả, ở mỗi yêu cầu, là kích thước ngữ cảnh của bạn."),
        "cache-clock": Text(
            title: "Ấm và lạnh: cache có đồng hồ",
            summary: "Dừng quá lâu, tin nhắn kế tiếp sẽ trả đủ giá.",
            points: [
                "Cuộc trò chuyện trong cache sẽ hết hạn sau một thời gian không dùng. Mỗi yêu cầu đọc nó sẽ đặt lại đồng hồ, nên cache vẫn ấm chừng nào bạn còn làm việc.",
                "Với gói thuê bao Claude, trong hạn mức của gói, cache của cuộc trò chuyện chính tồn tại một giờ. Với tín dụng sử dụng, khóa API hoặc nhà cung cấp đám mây, mặc định là năm phút.",
                "Sau khi hết hạn, tin nhắn kế tiếp phải xử lý lại toàn bộ ngữ cảnh: chậm hơn và đắt hơn nhiều. Ghi cache một giờ tốn gấp đôi giá đầu vào cơ bản, còn đọc cache chỉ một phần mười hoặc ít hơn, tức là đắt hơn ít nhất 20 lần.",
                "Đắt hơn bao nhiêu lần tùy vào mô hình: 40 lần với Opus 5.5 và Sonnet 5.5, 80 lần với Fable 5.1 vì đọc cache ở đó rẻ hơn. Cache 5 phút được ghi với giá 1,25 lần giá gốc, không phải gấp đôi. Thiết lập promptCacheTtl chọn thời gian sống.",
                "Đồng hồ của CacheCue là thời gian còn lại. Khi nó sắp hết mà bạn chuẩn bị rời đi, đó là lúc cần hành động.",
            ],
            takeaway: "Cứ làm việc thì cache vẫn ấm. Rời đi quá giới hạn thì bạn trả lại tất cả."),
        "compact-cost": Text(
            title: "/compact thực sự tốn bao nhiêu",
            summary: "Một phần nhỏ khi cache ấm, toàn bộ ngữ cảnh khi cache lạnh.",
            points: [
                "Để viết bản tóm tắt, Claude Code gửi thêm một yêu cầu: toàn bộ lịch sử của bạn kèm chỉ dẫn tóm tắt.",
                "Khi cache còn ấm, yêu cầu đó đọc lịch sử từ cache. Khi ấy việc nén chỉ tốn một phần nhỏ so với kích thước ngữ cảnh gợi ra.",
                "Sau khi cache hết hạn thì không còn gì để đọc, nên chính yêu cầu đó xử lý lại mọi thứ mà không có cache. Đây là lúc nén đắt nhất.",
                "Dù trường hợp nào, những gì theo sau đều rẻ: lượt kế tiếp chỉ cần lưu cache bản tóm tắt ngắn.",
                "Với ngữ cảnh nhỏ thì chẳng có mấy thứ để bỏ, nên yêu cầu tóm tắt tốn hơn phần tiết kiệm được.",
            ],
            takeaway: "Nén khi cache còn ấm, và chỉ khi có đủ thứ để bỏ."),
        "best-moment": Text(
            title: "Thời điểm tốt nhất để nén",
            summary: "Giữa các việc, cache còn ấm, ngữ cảnh lớn.",
            points: [
                "Ở một điểm dừng tự nhiên: một việc đã xong và việc kế chưa bắt đầu. Nén sẽ bỏ đi chi tiết, mà giữa chừng công việc thì chính những chi tiết đó là thứ bạn đang dựa vào.",
                "Trước khi bạn rời đi lâu hơn thời gian còn lại trên đồng hồ. Nén trước rồi hãy đi. Quay lại với cache đã lạnh rồi mới nén là trình tự tốn kém.",
                "Khi ngữ cảnh lớn. Quy tắc kinh nghiệm của CacheCue là 100k token: từ mức đó, mỗi yêu cầu đọc lại đủ nhiều để việc nén nhanh chóng hoàn vốn.",
                "Trước khi tự động nén làm thay bạn. Nó kích hoạt khi cửa sổ gần đầy, vào thời điểm nó tự chọn, có thể ngay giữa một việc.",
                "Hãy nói cần giữ gì: /compact tập trung vào các thay đổi API và các bài kiểm thử đang lỗi.",
            ],
            takeaway: "Tự chọn thời điểm: giữa các việc, khi đồng hồ vẫn còn chạy."),
        "compact-clear-rewind": Text(
            title: "/compact, /clear hay /rewind?",
            summary: "Ba cách thu nhỏ cuộc trò chuyện cho ba tình huống.",
            points: [
                "/clear bắt đầu lại từ đầu và không tốn gì. Dùng khi việc kế tiếp không liên quan. Chạy /rename trước, sau này bạn có thể quay lại phiên đó bằng /resume.",
                "/compact giữ mạch công việc dưới dạng bản tóm tắt. Dùng khi bạn tiếp tục cùng một việc và cần những gì đã quyết định, chứ không phải từng bước đã qua.",
                "/rewind quay về một lượt trước đó. Dùng để bỏ một hướng đi sai: cuộc trò chuyện đến điểm đó đã nằm trong cache, nên không phải dựng lại gì.",
                "Quay lại sau một quãng nghỉ dài? Cache đã lạnh dù bạn làm gì. Nếu không cần lịch sử nữa thì /clear. Với Pro và Max, Claude Code đề nghị tiếp tục phiên lớn từ một bản tóm tắt.",
            ],
            takeaway: "Clear cho việc mới, compact để tiếp tục, rewind để quay lại."),
        "cache-breakers": Text(
            title: "Những thứ âm thầm làm trống cache",
            summary: "Vài thao tác trông vô hại lại tốn một lượt giá đầy đủ.",
            points: [
                "Đổi mô hình bằng /model. Mỗi mô hình có cache riêng, nên yêu cầu kế tiếp đọc toàn bộ lịch sử mà không trúng cache. Thiết lập opusplan đổi mô hình mỗi lần bạn vào hoặc ra khỏi chế độ lập kế hoạch.",
                "Đổi mức effort giữa phiên, trên hầu hết mô hình. Bật fast mode, một lần cho mỗi cuộc trò chuyện.",
                "Nâng cấp Claude Code: cuộc trò chuyện đầu tiên sau khi nâng cấp phải dựng cache từ đầu.",
                "An toàn: sửa tệp, đổi chế độ quyền, gọi skill và lệnh, /recap. Sửa CLAUDE.md cũng an toàn, nhưng chỉ có hiệu lực sau /clear, /compact hoặc khởi động lại.",
            ],
            takeaway: "Chọn mô hình và effort khi bắt đầu phiên, rồi để yên."),
        "small-context": Text(
            title: "Giữ ngữ cảnh nhỏ ngay từ đầu",
            summary: "Token rẻ nhất là token không bao giờ vào ngữ cảnh.",
            points: [
                "Giao việc nhiều đầu ra cho tác tử con: chạy kiểm thử, đọc log, lấy tài liệu. Đầu ra nằm lại trong ngữ cảnh của chúng và chỉ bản tóm tắt quay về ngữ cảnh của bạn.",
                "Hãy cụ thể. “Thêm kiểm tra đầu vào cho hàm đăng nhập trong auth.ts” chỉ đọc vài tệp; “cải thiện mã nguồn này” quét toàn bộ.",
                "Giữ CLAUDE.md ngắn, dưới khoảng 200 dòng: nó được nạp vào mọi phiên. Chuyển hướng dẫn cho quy trình cụ thể sang skill, vốn chỉ nạp khi dùng tới.",
                "Tắt các máy chủ MCP không dùng, và chạy /context để xem thứ gì đang chiếm cửa sổ.",
            ],
            takeaway: "Đưa vào càng ít thì đọc lại càng ít, và sau này phải nén càng ít."),
        "reading-cachecue": Text(
            title: "Đọc CacheCue trong nháy mắt",
            summary: "Thước đo, đồng hồ và dấu chấm đang nói gì với bạn.",
            points: [
                "Thước đo 5h và 7d: bạn đã dùng bao nhiêu trong mỗi khung giới hạn. Chuyển màu hổ phách ở 70% và đỏ ở 90%.",
                "Đồng hồ: thời gian còn lại của cache trong phiên hiện tại. Hiện live khi một lượt đang chạy và exp khi cache đã hết hạn.",
                "Dấu chấm trước đồng hồ: có việc cần làm ngay. Cache sắp hết hạn, đã hết hạn, hoặc ngữ cảnh gần đầy.",
                "Thẻ ở đầu cửa sổ này cho biết nên làm gì và vì sao. Nút của nó sao chép /compact để bạn dán vào phiên.",
                "Khi mở nhiều phiên, giới hạn là của tài khoản; đồng hồ và lời khuyên thuộc về phiên có cache đáng giữ sắp nguội, nếu không có thì thuộc về phiên hoạt động gần nhất.",
                "Chấm trong hình trăng lưỡi liềm: có phiên đang chờ bạn cấp quyền hoặc trả lời. Trong danh sách, phiên đó có biểu tượng bàn tay giơ lên.",
                "Con số cạnh bông tuyết là lượng mà phiên phải ghi lại nếu cache nguội. Phiên đã nguội sẽ cho biết việc tiếp tục phải ghi lại bao nhiêu.",
                "Mỗi thẻ phiên có lựa chọn cho lúc cache sắp nguội: để yên; giữ ấm, CacheCue đọc lại cache bằng một yêu cầu một dòng khoảng 3 phút trước khi hết hạn, tối đa 3 lần liên tiếp, không thêm gì vào cuộc trò chuyện; hoặc nén, CacheCue chạy /compact giúp bạn khi phiên rảnh và cache còn khoảng 5 phút, việc này bỏ bớt chi tiết và không thể hoàn tác. Cả hai đều tốn một chút, nên không cái nào bật cho đến khi bạn chọn. Khi Claude Code tự nén một phiên terminal đang rảnh, thẻ sẽ ghi rõ và CacheCue không can thiệp.",
            ],
            takeaway: "Không có dấu chấm thì không cần làm gì. Có dấu chấm thì mở cửa sổ và đọc thẻ."),
    ]

    static let th: [String: Text] = [
        "context-cost": Text(
            title: "ทำไมเซสชันยาวจึงแพงขึ้น",
            summary: "ทุกคำขอจะส่งบทสนทนาทั้งหมดซ้ำอีกครั้ง",
            points: [
                "Claude Code ไม่เก็บความจำระหว่างคำขอ ทุกคำขอจึงพาทุกอย่างไปด้วย ได้แก่ system prompt บริบทของโปรเจกต์ ทุกข้อความ และทุกผลลัพธ์ของเครื่องมือ",
                "ทุกครั้งที่ Claude ใช้เครื่องมือ ก็คืออีกหนึ่งคำขอที่มีประวัติทั้งหมดอยู่ข้างใน คำสั่งเดียวอาจกลายเป็นหลายสิบคำขอ",
                "Prompt caching คิดค่าส่วนที่ไม่เปลี่ยนในอัตราแคช คือหนึ่งในสิบของราคาอินพุตปกติหรือน้อยกว่า ถูก แต่ไม่ฟรี และโตตามบริบท",
                "ดังนั้นคำถามบรรทัดเดียวในเซสชันที่เปิดมาทั้งวันก็ยังต้องจ่ายสำหรับบทสนทนาทั้งหมด",
            ],
            takeaway: "สิ่งที่คุณจ่ายในทุกคำขอคือขนาดของบริบท"),
        "cache-clock": Text(
            title: "อุ่นกับเย็น: แคชมีนาฬิกา",
            summary: "หยุดนานเกินไป ข้อความถัดไปจะจ่ายเต็มราคา",
            points: [
                "บทสนทนาที่อยู่ในแคชจะหมดอายุเมื่อไม่ได้ใช้ช่วงหนึ่ง ทุกคำขอที่อ่านแคชจะรีเซ็ตตัวจับเวลา แคชจึงอุ่นอยู่ตราบที่คุณยังทำงาน",
                "เมื่อใช้การสมัครสมาชิก Claude ภายในโควตาของแพ็กเกจ แคชของบทสนทนาหลักอยู่ได้หนึ่งชั่วโมง เมื่อใช้เครดิตการใช้งาน คีย์ API หรือผู้ให้บริการคลาวด์ ค่าเริ่มต้นคือห้านาที",
                "หลังหมดอายุ ข้อความถัดไปต้องประมวลผลบริบททั้งหมดใหม่ ช้ากว่าและแพงกว่ามาก การเขียนแคชแบบหนึ่งชั่วโมงมีค่าใช้จ่ายสองเท่าของราคาอินพุตพื้นฐาน ส่วนการอ่านแคชคือหนึ่งในสิบหรือน้อยกว่า จึงแพงกว่าอย่างน้อย 20 เท่า",
                "แพงกว่ากี่เท่าขึ้นอยู่กับโมเดล: 40 เท่าบน Opus 5.5 และ Sonnet 5.5 และ 80 เท่าบน Fable 5.1 ซึ่งอ่านแคชถูกกว่า แคช 5 นาทีเขียนที่ 1.25 เท่าของราคาพื้นฐาน ไม่ใช่ 2 เท่า การตั้งค่า promptCacheTtl ใช้เลือกอายุของแคช",
                "นาฬิกาของ CacheCue คือเวลาที่เหลือ เมื่อใกล้หมดและคุณกำลังจะลุกไป นั่นคือจังหวะที่ควรลงมือ",
            ],
            takeaway: "ทำงานต่อไปแคชก็อุ่นอยู่ ลุกไปนานเกินกำหนดก็ต้องจ่ายทั้งหมดอีกรอบ"),
        "compact-cost": Text(
            title: "/compact มีค่าใช้จ่ายจริงเท่าไร",
            summary: "เพียงเศษเสี้ยวเมื่อแคชอุ่น ทั้งบริบทเมื่อแคชเย็น",
            points: [
                "เพื่อเขียนสรุป Claude Code จะส่งอีกหนึ่งคำขอ คือประวัติทั้งหมดของคุณพร้อมคำสั่งให้สรุป",
                "ขณะที่แคชยังอุ่น คำขอนั้นจะอ่านประวัติจากแคช การบีบอัดจึงมีค่าใช้จ่ายเพียงเศษเสี้ยวของที่ขนาดบริบทบอกไว้",
                "หลังแคชหมดอายุจะไม่มีอะไรให้อ่าน คำขอเดียวกันจึงประมวลผลทุกอย่างใหม่โดยไม่ใช้แคช นี่คือช่วงที่การบีบอัดแพงที่สุด",
                "ไม่ว่ากรณีใด หลังจากนั้นจะถูกลง รอบถัดไปต้องแคชเพียงสรุปสั้น ๆ",
                "ในบริบทขนาดเล็กมีให้ตัดทิ้งไม่มาก คำขอสรุปจึงเปลืองกว่าที่ประหยัดได้",
            ],
            takeaway: "บีบอัดขณะที่แคชยังอุ่น และเฉพาะเมื่อมีให้ตัดทิ้งมากพอ"),
        "best-moment": Text(
            title: "จังหวะที่ดีที่สุดในการบีบอัด",
            summary: "ระหว่างงาน แคชยังอุ่น บริบทใหญ่",
            points: [
                "ที่จุดพักตามธรรมชาติ คืองานหนึ่งเสร็จแล้วและงานถัดไปยังไม่เริ่ม การบีบอัดจะทิ้งรายละเอียด และระหว่างทำงานรายละเอียดนั้นคือสิ่งที่คุณใช้อยู่",
                "ก่อนที่คุณจะลุกไปนานกว่าเวลาที่เหลือบนนาฬิกา บีบอัดก่อนแล้วค่อยไป การกลับมาเจอแคชที่เย็นแล้วค่อยบีบอัดคือลำดับที่แพง",
                "เมื่อบริบทใหญ่ หลักประมาณของ CacheCue คือ 100k โทเค็น ตั้งแต่จุดนั้นทุกคำขออ่านซ้ำมากพอที่การบีบอัดจะคุ้มทุนอย่างรวดเร็ว",
                "ก่อนที่การบีบอัดอัตโนมัติจะทำแทนคุณ มันจะทำงานเมื่อหน้าต่างเกือบเต็ม ในจังหวะที่มันเลือกเอง ซึ่งอาจเป็นกลางงาน",
                "บอกมันว่าต้องเก็บอะไรไว้: /compact เน้นการเปลี่ยนแปลง API และเทสต์ที่ล้มเหลว",
            ],
            takeaway: "เลือกจังหวะเอง: ระหว่างงาน ขณะที่นาฬิกายังเดินอยู่"),
        "compact-clear-rewind": Text(
            title: "/compact, /clear หรือ /rewind?",
            summary: "สามวิธีย่อบทสนทนา สำหรับสามสถานการณ์",
            points: [
                "/clear เริ่มใหม่และไม่มีค่าใช้จ่าย ใช้เมื่องานถัดไปไม่เกี่ยวข้องกัน สั่ง /rename ก่อน แล้วภายหลังจะกลับมาที่เซสชันนั้นได้ด้วย /resume",
                "/compact เก็บเรื่องราวไว้เป็นสรุป ใช้เมื่อคุณทำงานเดิมต่อและต้องการสิ่งที่ตัดสินใจไปแล้ว ไม่ใช่ทุกขั้นตอนที่ผ่านมา",
                "/rewind ย้อนกลับไปยังรอบก่อนหน้า ใช้เพื่อทิ้งเส้นทางที่ผิด บทสนทนาจนถึงจุดนั้นอยู่ในแคชแล้ว จึงไม่ต้องสร้างอะไรใหม่",
                "กลับมาหลังพักนาน? ไม่ว่าทำอะไรแคชก็เย็นแล้ว ถ้าไม่ต้องใช้ประวัติอีกให้ /clear ใน Pro และ Max Claude Code จะเสนอให้กลับมาทำเซสชันขนาดใหญ่ต่อจากสรุป",
            ],
            takeaway: "Clear สำหรับงานใหม่ compact เพื่อทำต่อ rewind เพื่อย้อนกลับ"),
        "cache-breakers": Text(
            title: "สิ่งที่ล้างแคชอย่างเงียบ ๆ",
            summary: "บางการกระทำที่ดูไม่มีพิษภัยมีค่าใช้จ่ายหนึ่งรอบเต็มราคา",
            points: [
                "การสลับโมเดลด้วย /model แต่ละโมเดลมีแคชของตัวเอง คำขอถัดไปจึงอ่านประวัติทั้งหมดโดยไม่ได้ใช้แคชเลย การตั้งค่า opusplan จะสลับโมเดลทุกครั้งที่เข้าหรือออกจากโหมดวางแผน",
                "การเปลี่ยนระดับ effort กลางเซสชัน ในโมเดลส่วนใหญ่ การเปิด fast mode หนึ่งครั้งต่อบทสนทนา",
                "การอัปเกรด Claude Code บทสนทนาแรกหลังอัปเกรดจะสร้างแคชใหม่ตั้งแต่ต้น",
                "ทำได้อย่างปลอดภัย: แก้ไขไฟล์ เปลี่ยนโหมดสิทธิ์ เรียกใช้ skill และคำสั่ง /recap การแก้ CLAUDE.md ก็ปลอดภัยเช่นกัน แต่จะมีผลหลัง /clear, /compact หรือการเริ่มใหม่เท่านั้น",
            ],
            takeaway: "เลือกโมเดลและ effort ตอนเริ่มเซสชัน แล้วอย่าไปแตะอีก"),
        "small-context": Text(
            title: "ทำให้บริบทเล็กตั้งแต่ต้น",
            summary: "โทเค็นที่ถูกที่สุดคือโทเค็นที่ไม่เคยเข้าไปในบริบท",
            points: [
                "ส่งงานที่มีเอาต์พุตยาวให้ subagent ทำ เช่น รันเทสต์ อ่านล็อก ดึงเอกสาร เอาต์พุตจะอยู่ในบริบทของมัน และมีเพียงสรุปที่กลับมายังบริบทของคุณ",
                "ระบุให้ชัดเจน “เพิ่มการตรวจสอบอินพุตในฟังก์ชันล็อกอินใน auth.ts” อ่านเพียงไม่กี่ไฟล์ ส่วน “ปรับปรุงโค้ดเบสนี้” จะสแกนทั้งหมด",
                "ทำให้ CLAUDE.md สั้น ไม่เกินประมาณ 200 บรรทัด เพราะมันถูกโหลดเข้าทุกเซสชัน ย้ายคำแนะนำสำหรับขั้นตอนงานเฉพาะไปไว้ใน skill ซึ่งจะโหลดเมื่อใช้งานเท่านั้น",
                "ปิดเซิร์ฟเวอร์ MCP ที่ไม่ได้ใช้ และสั่ง /context เพื่อดูว่าอะไรกำลังกินพื้นที่หน้าต่าง",
            ],
            takeaway: "ยิ่งใส่เข้าไปน้อย ก็ยิ่งต้องอ่านซ้ำน้อย และต้องบีบอัดทีหลังน้อยลง"),
        "reading-cachecue": Text(
            title: "อ่าน CacheCue ได้ในพริบตา",
            summary: "มาตรวัด นาฬิกา และจุดกำลังบอกอะไรคุณ",
            points: [
                "มาตรวัด 5h และ 7d: คุณใช้โควตาแต่ละช่วงไปเท่าไร จะเปลี่ยนเป็นสีอำพันที่ 70% และสีแดงที่ 90%",
                "นาฬิกา: เวลาที่เหลือของแคชในเซสชันปัจจุบัน แสดง live ขณะที่รอบกำลังทำงาน และ exp เมื่อแคชหมดอายุแล้ว",
                "จุดหน้านาฬิกา: มีสิ่งที่ต้องทำตอนนี้ แคชกำลังจะหมดอายุ หมดอายุแล้ว หรือบริบทเกือบเต็ม",
                "การ์ดด้านบนของหน้าต่างนี้บอกว่าควรทำอะไรและเพราะอะไร ปุ่มบนการ์ดจะคัดลอก /compact ให้คุณนำไปวางในเซสชัน",
                "เมื่อเปิดหลายเซสชัน โควตาเป็นของบัญชีคุณ ส่วนนาฬิกาและคำแนะนำเป็นของเซสชันที่แคชซึ่งควรเก็บไว้ใกล้จะเย็น หากไม่มีก็เป็นของเซสชันที่ทำงานล่าสุด",
                "จุดในรูปจันทร์เสี้ยว: มีเซสชันกำลังรอการอนุญาตหรือคำตอบจากคุณ ในรายการ เซสชันนั้นจะมีไอคอนมือยกขึ้น",
                "ตัวเลขข้างเกล็ดหิมะคือปริมาณที่เซสชันต้องเขียนใหม่หากแคชเย็นลง เซสชันที่เย็นแล้วจะบอกว่าการกลับมาใช้ต่อต้องเขียนใหม่เท่าไร",
                "การ์ดเซสชันแต่ละใบให้เลือกว่าจะทำอย่างไรเมื่อแคชใกล้เย็น: ปล่อยไว้; รักษาความอุ่น โดย CacheCue อ่านแคชซ้ำด้วยคำขอบรรทัดเดียวราว 3 นาทีก่อนหมดอายุ ติดต่อกันได้สูงสุด 3 ครั้ง โดยไม่เพิ่มอะไรลงในบทสนทนา; หรือบีบอัด โดย CacheCue รัน /compact แทนคุณเมื่อเซสชันว่างและแคชเหลือราว 5 นาที ซึ่งจะทิ้งรายละเอียดและย้อนกลับไม่ได้ ทั้งสองแบบมีค่าใช้จ่ายเล็กน้อย จึงปิดอยู่จนกว่าคุณจะเลือกเอง ถ้า Claude Code บีบอัดเซสชันเทอร์มินัลที่ว่างอยู่เอง การ์ดจะบอกไว้และ CacheCue จะไม่เข้าไปยุ่ง",
            ],
            takeaway: "ไม่มีจุดก็ไม่ต้องทำอะไร มีจุดให้เปิดหน้าต่างแล้วอ่านการ์ด"),
    ]

    static let hi: [String: Text] = [
        "context-cost": Text(
            title: "लंबे सत्र महँगे क्यों हो जाते हैं",
            summary: "हर अनुरोध पूरी बातचीत दोबारा भेजता है।",
            points: [
                "Claude Code अनुरोधों के बीच कुछ याद नहीं रखता, इसलिए हर अनुरोध सब कुछ साथ ले जाता है: सिस्टम प्रॉम्प्ट, प्रोजेक्ट का संदर्भ, हर संदेश और हर टूल का नतीजा।",
                "जब भी Claude टूल इस्तेमाल करता है, वह पूरे इतिहास के साथ एक और अनुरोध होता है। एक निर्देश का मतलब दर्जनों अनुरोध हो सकता है।",
                "प्रॉम्प्ट कैशिंग न बदले हुए हिस्से का शुल्क कैश दर पर लेती है, यानी सामान्य इनपुट कीमत का दसवाँ हिस्सा या उससे कम। सस्ता है, पर मुफ़्त नहीं, और संदर्भ के साथ बढ़ता है।",
                "इसलिए दिन भर खुले सत्र में एक पंक्ति का सवाल भी पूरी बातचीत की कीमत चुकाता है।",
            ],
            takeaway: "हर अनुरोध पर आप जो चुकाते हैं, वह आपके संदर्भ का आकार है।"),
        "cache-clock": Text(
            title: "गर्म और ठंडा: कैश की एक घड़ी है",
            summary: "ज़्यादा देर रुके तो अगला संदेश पूरी कीमत चुकाएगा।",
            points: [
                "कैश की हुई बातचीत कुछ समय निष्क्रिय रहने पर समाप्त हो जाती है। उसे पढ़ने वाला हर अनुरोध टाइमर रीसेट करता है, इसलिए जब तक आप काम करते रहते हैं कैश गर्म रहता है।",
                "Claude सब्सक्रिप्शन पर, प्लान के उपयोग के भीतर, मुख्य बातचीत का कैश एक घंटा चलता है। उपयोग क्रेडिट, API कुंजी या क्लाउड प्रदाता पर यह डिफ़ॉल्ट रूप से पाँच मिनट चलता है।",
                "समाप्त होने के बाद आपका अगला संदेश पूरे संदर्भ को दोबारा प्रोसेस करता है: धीमा और कहीं ज़्यादा महँगा। एक घंटे के कैश की लिखाई मूल इनपुट कीमत से दोगुनी पड़ती है और पढ़ाई दसवाँ हिस्सा या कम, यानी कम से कम 20 गुना महँगा।",
                "कितना गुना महँगा, यह मॉडल पर निर्भर है: Opus 5.5 और Sonnet 5.5 पर 40 गुना, Fable 5.1 पर 80 गुना, जहाँ कैश पढ़ना और सस्ता है। 5 मिनट का कैश मूल कीमत के 1.25 गुना पर लिखा जाता है, दोगुने पर नहीं। promptCacheTtl सेटिंग कैश की अवधि चुनती है।",
                "CacheCue की घड़ी बचा हुआ समय है। जब वह ख़त्म होने वाला हो और आप उठकर जा रहे हों, वही कदम उठाने का समय है।",
            ],
            takeaway: "काम करते रहें तो कैश गर्म रहता है। सीमा से ज़्यादा दूर रहे तो सब कुछ दोबारा चुकाना पड़ेगा।"),
        "compact-cost": Text(
            title: "/compact की असली कीमत",
            summary: "कैश गर्म हो तो थोड़ा सा, ठंडा हो तो पूरा संदर्भ।",
            points: [
                "सारांश लिखने के लिए Claude Code एक और अनुरोध भेजता है: आपका पूरा इतिहास और उसे सारांशित करने का निर्देश।",
                "जब तक कैश गर्म है, वह अनुरोध आपका इतिहास कैश से पढ़ता है। तब कॉम्पैक्ट करने की कीमत संदर्भ के आकार से लगने वाले अंदाज़े का एक छोटा हिस्सा होती है।",
                "कैश समाप्त होने के बाद पढ़ने को कुछ नहीं बचता, इसलिए वही अनुरोध सब कुछ बिना कैश के दोबारा प्रोसेस करता है। कॉम्पैक्ट करने का यह सबसे महँगा समय है।",
                "दोनों स्थितियों में आगे का काम सस्ता है: अगले टर्न को सिर्फ़ छोटा सारांश कैश करना होता है।",
                "छोटे संदर्भ में हटाने को कम होता है, इसलिए सारांश का अनुरोध बचत से ज़्यादा महँगा पड़ता है।",
            ],
            takeaway: "कैश गर्म रहते कॉम्पैक्ट करें, और तभी जब हटाने को काफ़ी कुछ हो।"),
        "best-moment": Text(
            title: "कॉम्पैक्ट करने का सबसे अच्छा समय",
            summary: "कामों के बीच, कैश गर्म, संदर्भ बड़ा।",
            points: [
                "स्वाभाविक ठहराव पर: एक काम पूरा हो गया और अगला शुरू नहीं हुआ। कॉम्पैक्ट करने से ब्योरे हट जाते हैं, और काम के बीच में आप उन्हीं ब्योरों के सहारे चल रहे होते हैं।",
                "घड़ी में बचे समय से ज़्यादा देर के लिए जाने से पहले। पहले कॉम्पैक्ट करें, फिर जाएँ। ठंडे कैश पर लौटकर तब कॉम्पैक्ट करना महँगा क्रम है।",
                "जब संदर्भ बड़ा हो। CacheCue का मोटा नियम 100k टोकन है: वहाँ से हर अनुरोध इतना दोबारा पढ़ता है कि कॉम्पैक्ट करने की कीमत जल्दी वसूल हो जाती है।",
                "इससे पहले कि ऑटो-कॉम्पैक्ट आपके लिए कर दे। वह तब चलता है जब विंडो लगभग भर जाती है, अपने चुने हुए समय पर, शायद काम के बीच में।",
                "बताएँ कि क्या रखना है: /compact API के बदलावों और विफल हो रहे टेस्ट पर ध्यान दो।",
            ],
            takeaway: "समय ख़ुद चुनें: कामों के बीच, जब घड़ी अभी चल रही हो।"),
        "compact-clear-rewind": Text(
            title: "/compact, /clear या /rewind?",
            summary: "बातचीत छोटी करने के तीन तरीक़े, तीन स्थितियों के लिए।",
            points: [
                "/clear नए सिरे से शुरू करता है और इसकी कोई कीमत नहीं। तब इस्तेमाल करें जब अगला काम असंबंधित हो। पहले /rename चलाएँ, फिर बाद में /resume से उस सत्र पर लौट सकते हैं।",
                "/compact सिलसिले को सारांश के रूप में रखता है। तब इस्तेमाल करें जब आप वही काम जारी रख रहे हों और आपको यह चाहिए कि क्या तय हुआ, न कि हर क़दम।",
                "/rewind पिछले किसी टर्न पर लौटता है। ग़लत रास्ता छोड़ने के लिए इस्तेमाल करें: उस बिंदु तक की बातचीत पहले से कैश में है, इसलिए कुछ दोबारा बनाना नहीं पड़ता।",
                "लंबे अंतराल के बाद लौटे हैं? आप कुछ भी करें, कैश ठंडा है। इतिहास की ज़रूरत नहीं रही तो /clear। Pro और Max पर Claude Code बड़े सत्र को सारांश से फिर शुरू करने की पेशकश करता है।",
            ],
            takeaway: "नए काम के लिए clear, जारी रखने के लिए compact, वापस जाने के लिए rewind।"),
        "cache-breakers": Text(
            title: "क्या चुपचाप कैश ख़ाली कर देता है",
            summary: "कुछ मामूली दिखने वाले काम एक पूरी कीमत वाला टर्न ले लेते हैं।",
            points: [
                "/model से मॉडल बदलना। हर मॉडल का अपना कैश होता है, इसलिए अगला अनुरोध पूरा इतिहास बिना कैश हिट के पढ़ता है। opusplan सेटिंग हर बार प्लान मोड में जाने या निकलने पर मॉडल बदलती है।",
                "सत्र के बीच में effort स्तर बदलना, ज़्यादातर मॉडलों पर। fast mode चालू करना, हर बातचीत में एक बार।",
                "Claude Code अपग्रेड करना: अपग्रेड के बाद की पहली बातचीत अपना कैश शुरू से बनाती है।",
                "सुरक्षित काम: फ़ाइलें संपादित करना, अनुमति मोड बदलना, skill और कमांड चलाना, /recap। CLAUDE.md में बदलाव भी सुरक्षित हैं, पर वे /clear, /compact या रीस्टार्ट के बाद ही लागू होते हैं।",
            ],
            takeaway: "मॉडल और effort सत्र की शुरुआत में चुनें, फिर उन्हें न छेड़ें।"),
        "small-context": Text(
            title: "शुरू से ही संदर्भ छोटा रखें",
            summary: "सबसे सस्ता टोकन वह है जो संदर्भ में कभी आता ही नहीं।",
            points: [
                "ज़्यादा आउटपुट वाला काम सबएजेंट को सौंपें: टेस्ट चलाना, लॉग पढ़ना, दस्तावेज़ लाना। आउटपुट उनके संदर्भ में रहता है और आपके पास सिर्फ़ सारांश लौटता है।",
                "स्पष्ट रहें। “auth.ts के लॉगिन फ़ंक्शन में इनपुट वैलिडेशन जोड़ो” कुछ फ़ाइलें पढ़ता है; “इस कोडबेस को बेहतर करो” सब कुछ छान डालता है।",
                "CLAUDE.md छोटा रखें, लगभग 200 पंक्तियों से कम: यह हर सत्र में लोड होता है। ख़ास कार्यप्रवाहों के निर्देश skill में ले जाएँ, जो इस्तेमाल होने पर ही लोड होते हैं।",
                "जिन MCP सर्वरों का इस्तेमाल नहीं कर रहे उन्हें बंद करें, और /context चलाकर देखें कि विंडो किससे भर रही है।",
            ],
            takeaway: "जितना कम अंदर जाएगा, उतना कम दोबारा पढ़ना होगा और बाद में उतना कम कॉम्पैक्ट करना होगा।"),
        "reading-cachecue": Text(
            title: "एक नज़र में CacheCue पढ़ना",
            summary: "गेज, घड़ी और बिंदु आपको क्या बता रहे हैं।",
            points: [
                "5h और 7d गेज: हर सीमा-अवधि का कितना हिस्सा आपने इस्तेमाल किया। ये 70% पर एम्बर और 90% पर लाल हो जाते हैं।",
                "घड़ी: मौजूदा सत्र के कैश में बचा समय। टर्न चलते समय live दिखती है और कैश समाप्त होने पर exp।",
                "घड़ी से पहले का बिंदु: अभी कुछ करना है। कैश समाप्त होने वाला है, समाप्त हो चुका है, या संदर्भ लगभग भर गया है।",
                "इस विंडो के ऊपर का कार्ड बताता है कि क्या करना है और क्यों। उसका बटन /compact कॉपी करता है, जिसे आप सत्र में पेस्ट कर सकते हैं।",
                "कई सत्र खुले हों तो सीमाएँ आपके खाते की होती हैं; घड़ी और सलाह उस सत्र की होती है जिसका काम का कैश ठंडा होने वाला है, और ऐसा कोई न हो तो उस सत्र की जिसने आख़िर में कुछ किया।",
                "अर्धचंद्र के भीतर बिंदु: कोई सत्र आपकी अनुमति या जवाब का इंतज़ार कर रहा है। सूची में उस सत्र पर उठे हाथ का चिह्न होता है।",
                "बर्फ़ के फाहे के पास की संख्या वह है जो सत्र अपना कैश ठंडा होने पर दोबारा लिखेगा। पहले से ठंडा सत्र बताता है कि उसे फिर शुरू करने पर कितना दोबारा लिखा जाएगा।",
                "हर सत्र कार्ड पर चुन सकते हैं कि कैश ठंडा होने वाला हो तो क्या करें: कुछ नहीं; गर्म रखें, जिसमें CacheCue समाप्ति से लगभग 3 मिनट पहले एक पंक्ति के अनुरोध से कैश दोबारा पढ़ता है, लगातार अधिकतम 3 बार, बातचीत में कुछ जोड़े बिना; या कॉम्पैक्ट करें, जिसमें सत्र निष्क्रिय हो और कैश के लगभग 5 मिनट बचे हों तो CacheCue आपके लिए /compact चलाता है, जिससे ब्योरे हट जाते हैं और इसे वापस नहीं किया जा सकता। दोनों में थोड़ा खर्च होता है, इसलिए जब तक आप न चुनें कोई चालू नहीं रहता। जहाँ Claude Code निष्क्रिय टर्मिनल सत्र को खुद कॉम्पैक्ट करता है, वहाँ कार्ड यह बताता है और CacheCue दखल नहीं देता।",
            ],
            takeaway: "बिंदु नहीं तो कुछ करना नहीं। बिंदु हो तो विंडो खोलें और कार्ड पढ़ें।"),
    ]

    static let ar: [String: Text] = [
        "context-cost": Text(
            title: "لماذا تصبح الجلسات الطويلة مكلفة",
            summary: "كل طلب يعيد إرسال المحادثة كاملة.",
            points: [
                "لا يحتفظ Claude Code بأي ذاكرة بين الطلبات، لذلك يحمل كل طلب كل شيء: موجّه النظام، وسياق المشروع، وكل رسالة، وكل نتيجة أداة.",
                "في كل مرة يستخدم Claude الأدوات، يكون ذلك طلبًا آخر بداخله السجل كله. أمر واحد قد يعني عشرات الطلبات.",
                "يحاسب التخزين المؤقت للموجّهات الجزء غير المتغيّر بسعر الكاش، أي عُشر سعر الإدخال العادي أو أقل. رخيص، لكنه ليس مجانيًا، ويكبر مع السياق.",
                "لذلك فإن سؤالًا من سطر واحد في جلسة مفتوحة طوال اليوم يدفع ثمن المحادثة كلها.",
            ],
            takeaway: "ما تدفعه مع كل طلب هو حجم سياقك."),
        "cache-clock": Text(
            title: "دافئ وبارد: للكاش ساعة",
            summary: "توقّف طويلًا وستدفع الرسالة التالية السعر الكامل.",
            points: [
                "تنتهي صلاحية المحادثة المخزّنة بعد فترة من عدم النشاط. كل طلب يقرؤها يعيد ضبط المؤقت، فيبقى الكاش دافئًا ما دمت تعمل.",
                "مع اشتراك Claude، ضمن استخدام خطتك، يدوم كاش المحادثة الرئيسية ساعة واحدة. ومع أرصدة الاستخدام أو مفتاح API أو مزوّد سحابي يدوم خمس دقائق افتراضيًا.",
                "بعد انتهائه، تعيد رسالتك التالية معالجة السياق كله: أبطأ وأغلى بكثير. كتابة كاش الساعة تكلّف ضعف سعر الإدخال الأساسي، والقراءة عُشره أو أقل، أي 20 ضعفًا على الأقل.",
                "مقدار الزيادة يعتمد على النموذج: 40 ضعفاً على Opus 5.5 وSonnet 5.5، و80 ضعفاً على Fable 5.1 حيث قراءة الكاش أرخص. كاش الـ5 دقائق يُكتب بسعر 1.25 من السعر الأساسي لا بضعفه. إعداد promptCacheTtl يختار مدة البقاء.",
                "ساعة CacheCue هي الوقت المتبقي. حين يوشك على الانتهاء وأنت تهمّ بالابتعاد، فتلك لحظة التصرّف.",
            ],
            takeaway: "واصل العمل ويبقى الكاش دافئًا. ابتعد أكثر من الحدّ وستدفع ثمن كل شيء من جديد."),
        "compact-cost": Text(
            title: "كم يكلّف /compact فعلًا",
            summary: "جزء يسير حين يكون الكاش دافئًا، والسياق كله حين يكون باردًا.",
            points: [
                "لكتابة الملخّص، يرسل Claude Code طلبًا إضافيًا: سجلّك كله مع تعليمة بتلخيصه.",
                "ما دام الكاش دافئًا، يقرأ ذلك الطلب سجلّك من الكاش. عندها يكلّف الضغط جزءًا يسيرًا مما يوحي به حجم السياق.",
                "بعد انتهاء الكاش لا يوجد ما يُقرأ، فيعيد الطلب نفسه معالجة كل شيء دون كاش. هذا أغلى وقت للضغط.",
                "في الحالتين، ما يليه رخيص: الجولة التالية لا تخزّن سوى الملخّص القصير.",
                "في سياق صغير لا يوجد الكثير للتخلّص منه، فيكلّف طلب التلخيص أكثر مما يوفّر.",
            ],
            takeaway: "اضغط والكاش دافئ، وفقط حين يوجد ما يكفي للتخلّص منه."),
        "best-moment": Text(
            title: "أفضل لحظة للضغط",
            summary: "بين المهام، والكاش دافئ، والسياق كبير.",
            points: [
                "عند توقّف طبيعي: مهمة انتهت والتالية لم تبدأ. الضغط يتخلّص من التفاصيل، وفي منتصف المهمة تلك التفاصيل هي ما تعمل به.",
                "قبل أن تبتعد مدة أطول مما بقي على الساعة. اضغط أولًا ثم اذهب. العودة إلى كاش بارد ثم الضغط حينها هو الترتيب المكلف.",
                "حين يكون السياق كبيرًا. قاعدة CacheCue التقريبية هي 100k توكن: من هناك يعيد كل طلب قراءة ما يكفي ليستردّ الضغط كلفته سريعًا.",
                "قبل أن يفعلها الضغط التلقائي عنك. يعمل حين تكاد النافذة تمتلئ، في لحظة يختارها هو، وربما في منتصف مهمة.",
                "أخبره بما يجب الاحتفاظ به: /compact ركّز على تغييرات الـ API والاختبارات الفاشلة.",
            ],
            takeaway: "اختر اللحظة بنفسك: بين المهام، والساعة ما زالت تعمل."),
        "compact-clear-rewind": Text(
            title: "/compact أم /clear أم /rewind؟",
            summary: "ثلاث طرق لتصغير المحادثة، لثلاث حالات.",
            points: [
                "/clear يبدأ من جديد ولا يكلّف شيئًا. استخدمه حين يكون العمل التالي غير مرتبط. نفّذ /rename أولًا لتتمكّن لاحقًا من العودة إلى الجلسة بـ /resume.",
                "/compact يحتفظ بالخيط على هيئة ملخّص. استخدمه حين تواصل العمل نفسه وتحتاج ما تقرّر، لا كل خطوة أوصلت إليه.",
                "/rewind يعود إلى جولة سابقة. استخدمه للتخلّي عن مسار خاطئ: المحادثة حتى تلك النقطة مخزّنة أصلًا، فلا شيء يُعاد بناؤه.",
                "عدت بعد استراحة طويلة؟ الكاش بارد مهما فعلت. إن لم تعد تحتاج السجل فاستخدم /clear. في Pro و Max يعرض Claude Code استئناف الجلسة الكبيرة من ملخّص.",
            ],
            takeaway: "clear للعمل الجديد، compact للمتابعة، rewind للتراجع."),
        "cache-breakers": Text(
            title: "ما الذي يفرغ الكاش بصمت",
            summary: "بعض الإجراءات التي تبدو بريئة تكلّف جولة بالسعر الكامل.",
            points: [
                "تبديل النموذج بـ /model. لكل نموذج كاش خاص به، فيقرأ الطلب التالي السجل كله دون أي إصابة في الكاش. إعداد opusplan يبدّل النموذج في كل مرة تدخل وضع التخطيط أو تخرج منه.",
                "تغيير مستوى effort في منتصف الجلسة، في معظم النماذج. تشغيل fast mode، مرة واحدة لكل محادثة.",
                "ترقية Claude Code: أول محادثة بعد الترقية تبني كاشها من البداية.",
                "آمن: تعديل الملفات، تغيير وضع الأذونات، استدعاء skills والأوامر، /recap. تعديل CLAUDE.md آمن أيضًا، لكنه لا يسري إلا بعد /clear أو /compact أو إعادة التشغيل.",
            ],
            takeaway: "اختر النموذج ومستوى effort في بداية الجلسة ثم اتركهما."),
        "small-context": Text(
            title: "أبقِ السياق صغيرًا من البداية",
            summary: "أرخص توكن هو الذي لا يدخل السياق أبدًا.",
            points: [
                "أسنِد الأعمال كثيرة المخرجات إلى وكلاء فرعيين: تشغيل الاختبارات، قراءة السجلات، جلب التوثيق. تبقى المخرجات في سياقهم ولا يعود إلى سياقك سوى ملخّص.",
                "كن محدّدًا. «أضف التحقق من المدخلات إلى دالة تسجيل الدخول في auth.ts» يقرأ بضعة ملفات؛ أما «حسّن هذه الشيفرة» فيمسحها كلها.",
                "أبقِ CLAUDE.md قصيرًا، أقل من نحو 200 سطر: فهو يُحمَّل في كل جلسة. انقل تعليمات سير العمل المحدّدة إلى skills، التي لا تُحمَّل إلا عند استخدامها.",
                "عطّل خوادم MCP التي لا تستخدمها، وشغّل /context لترى ما الذي يملأ النافذة.",
            ],
            takeaway: "كلما قلّ ما يدخل، قلّ ما يُعاد قراءته وما يُضغط لاحقًا."),
        "reading-cachecue": Text(
            title: "قراءة CacheCue بنظرة",
            summary: "ما الذي تخبرك به المؤشرات والساعة والنقطة.",
            points: [
                "مؤشّرا 5h و 7d: كم استخدمت من كل نافذة حدّ. يتحوّلان إلى الكهرماني عند 70% وإلى الأحمر عند 90%.",
                "الساعة: الوقت المتبقي لكاش الجلسة الحالية. تعرض live أثناء تنفيذ جولة و exp بعد انتهاء الكاش.",
                "النقطة قبل الساعة: هناك ما يجب فعله الآن. الكاش يوشك على الانتهاء، أو انتهى، أو السياق شبه ممتلئ.",
                "البطاقة أعلى هذه النافذة تقول ماذا تفعل ولماذا. زرّها ينسخ /compact لتلصقه في الجلسة.",
                "عند فتح عدة جلسات، الحدود تخص حسابك؛ أما الساعة والنصيحة فتخصان الجلسة التي يوشك كاشها المهم أن يبرد، وإن لم توجد فالجلسة التي كانت آخر من نشط.",
                "نقطة داخل الهلال: هناك جلسة تنتظر إذنك أو ردّك. في القائمة تحمل تلك الجلسة رمز يد مرفوعة.",
                "الرقم بجانب ندفة الثلج هو ما تعيد الجلسة كتابته إذا برد كاشها. والجلسة التي بردت فعلًا تبيّن ما يعيد استئنافها كتابته.",
                "في كل بطاقة جلسة تختار ما يحدث حين يوشك الكاش أن يبرد: لا شيء؛ أو إبقاؤه دافئًا، فيعيد CacheCue قراءة الكاش بطلب من سطر واحد قبل انتهائه بنحو 3 دقائق، حتى 3 مرات متتالية، دون إضافة شيء إلى المحادثة؛ أو الضغط، فيشغّل CacheCue الأمر /compact نيابةً عنك عندما تكون الجلسة خاملة ويتبقى من الكاش نحو 5 دقائق، وهذا يحذف تفاصيل ولا يمكن التراجع عنه. لكليهما كلفة صغيرة، لذا لا يعمل أي منهما حتى تختاره. وحين يضغط Claude Code بنفسه جلسة طرفية خاملة، تذكر البطاقة ذلك ولا يتدخل CacheCue.",
            ],
            takeaway: "لا نقطة، لا شيء لتفعله. وجود نقطة يعني: افتح النافذة واقرأ البطاقة."),
    ]
}
