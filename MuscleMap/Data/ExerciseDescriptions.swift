import Foundation

// MARK: - 種目説明データ（静的辞書）

enum ExerciseDescriptions {
    
    struct ExerciseInfo {
        let description: String
        let formTips: [String]
    }
    
    /// 種目ID → 説明・フォームポイント
    static let data: [String: ExerciseInfo] = [
        // 胸
        "bench_press": ExerciseInfo(
            description: "バーベルを使った胸の代表的な種目。大胸筋全体を鍛えられる。",
            formTips: [
                "肩甲骨を寄せてアーチを作る",
                "バーは乳首のラインに下ろす",
                "肘は45度程度に開く"
            ]
        ),
        "incline_bench_press": ExerciseInfo(
            description: "インクラインベンチで行うプレス。大胸筋上部を重点的に鍛える。",
            formTips: [
                "ベンチ角度は30-45度",
                "鎖骨の方向にバーを下ろす",
                "肩がすくまないよう注意"
            ]
        ),
        "dumbbell_fly": ExerciseInfo(
            description: "ダンベルを使ったストレッチ種目。胸の広がりを作る。",
            formTips: [
                "肘は軽く曲げたまま固定",
                "胸を張ってストレッチを感じる",
                "トップで絞りすぎない"
            ]
        ),
        "push_up": ExerciseInfo(
            description: "自重で行える基本種目。どこでもできる。",
            formTips: [
                "体は一直線に保つ",
                "肩甲骨を寄せて胸を張る",
                "肘を外に開きすぎない"
            ]
        ),
        // 背中
        "deadlift": ExerciseInfo(
            description: "全身を使う最も重いリフト。背中・脚・体幹を総合的に鍛える。",
            formTips: [
                "背中は常にまっすぐ",
                "バーは体に近づけて引く",
                "膝と股関節を同時に伸ばす"
            ]
        ),
        "lat_pulldown": ExerciseInfo(
            description: "マシンで行う懸垂の代替種目。広背筋を鍛える。",
            formTips: [
                "胸を張って引く",
                "肘を体側に寄せる意識",
                "肩を下げたまま動作"
            ]
        ),
        "barbell_row": ExerciseInfo(
            description: "前傾姿勢でバーベルを引く。広背筋・僧帽筋を鍛える。",
            formTips: [
                "背中は水平に近い角度",
                "おへその方向に引く",
                "反動を使わない"
            ]
        ),
        "pull_up": ExerciseInfo(
            description: "自重で行う背中の王道種目。広背筋を強く刺激する。",
            formTips: [
                "肩甲骨を下げて引く",
                "あごをバーの上まで",
                "下ろすときもコントロール"
            ]
        ),
        // 肩
        "overhead_press": ExerciseInfo(
            description: "バーベルを頭上に押し上げる。三角筋全体を鍛える。",
            formTips: [
                "体幹をしっかり固める",
                "バーは顔の前を通す",
                "ロックアウトで止める"
            ]
        ),
        "lateral_raise": ExerciseInfo(
            description: "ダンベルを横に上げる。三角筋中部を集中的に鍛える。",
            formTips: [
                "肘を軽く曲げる",
                "小指側を上に向ける意識",
                "肩より上げすぎない"
            ]
        ),
        "face_pull": ExerciseInfo(
            description: "ケーブルを顔に向かって引く。三角筋後部・僧帽筋を鍛える。",
            formTips: [
                "肘を高く保つ",
                "外旋しながら引く",
                "ゆっくり戻す"
            ]
        ),
        // 腕
        "barbell_curl": ExerciseInfo(
            description: "バーベルで行う上腕二頭筋の基本種目。",
            formTips: [
                "肘の位置を固定",
                "反動を使わない",
                "下ろすときもゆっくり"
            ]
        ),
        "tricep_pushdown": ExerciseInfo(
            description: "ケーブルで行う上腕三頭筋の種目。",
            formTips: [
                "肘を体側に固定",
                "完全に伸ばしきる",
                "上げるときは肘から"
            ]
        ),
        "hammer_curl": ExerciseInfo(
            description: "縦持ちで行うカール。腕橈骨筋も鍛えられる。",
            formTips: [
                "手首は中立位置",
                "肘を固定して巻き上げる",
                "左右交互でもOK"
            ]
        ),
        // 脚
        "squat": ExerciseInfo(
            description: "下半身の王道種目。大腿四頭筋・臀筋を鍛える。",
            formTips: [
                "膝とつま先の向きを揃える",
                "しゃがむ深さは平行以上",
                "背中は丸めない"
            ]
        ),
        "leg_press": ExerciseInfo(
            description: "マシンで行うスクワットの代替種目。高重量が扱える。",
            formTips: [
                "腰をシートから浮かせない",
                "膝を完全に伸ばしきらない",
                "足幅で効く部位が変わる"
            ]
        ),
        "romanian_deadlift": ExerciseInfo(
            description: "膝を軽く曲げたまま行うデッドリフト。ハムストリングスを鍛える。",
            formTips: [
                "膝の角度は固定",
                "股関節から曲げる",
                "ハムのストレッチを感じる"
            ]
        ),
        "leg_curl": ExerciseInfo(
            description: "マシンで行うハムストリングスの種目。",
            formTips: [
                "お尻を浮かせない",
                "かかとをお尻に近づける",
                "戻すときもコントロール"
            ]
        ),
        "calf_raise": ExerciseInfo(
            description: "ふくらはぎを鍛える種目。腓腹筋・ヒラメ筋を鍛える。",
            formTips: [
                "しっかり上げきる",
                "ストレッチもしっかり",
                "膝は伸ばしたまま"
            ]
        ),
        // 腹筋
        "crunch": ExerciseInfo(
            description: "腹筋の基本種目。腹直筋上部を鍛える。",
            formTips: [
                "首を引っ張らない",
                "肩甲骨が浮く程度でOK",
                "腹筋を縮める意識"
            ]
        ),
        "plank": ExerciseInfo(
            description: "体幹を鍛えるアイソメトリック種目。",
            formTips: [
                "体は一直線に保つ",
                "お尻を上げすぎない",
                "呼吸を止めない"
            ]
        ),
        "leg_raise": ExerciseInfo(
            description: "脚を上げ下げする腹筋種目。腹直筋下部を鍛える。",
            formTips: [
                "腰を床につけたまま",
                "下ろすときゆっくり",
                "脚は完全に床につけない"
            ]
        ),
        "russian_twist": ExerciseInfo(
            description: "体を捻る腹筋種目。腹斜筋を鍛える。",
            formTips: [
                "上体は45度程度起こす",
                "胸ごと捻る",
                "足は浮かせても床でもOK"
            ]
        ),
    ]
    
    /// 種目IDから説明を取得
    static func info(for exerciseId: String) -> ExerciseInfo? {
        // そのまま検索
        if let info = data[exerciseId] {
            return info
        }
        // snake_case変換して検索
        let snakeCase = exerciseId.replacingOccurrences(
            of: "([a-z])([A-Z])",
            with: "$1_$2",
            options: .regularExpression
        ).lowercased()
        return data[snakeCase]
    }
}
