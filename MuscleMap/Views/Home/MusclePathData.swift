import SwiftUI

// MARK: - 筋肉パスデータ（正規化座標 0-1）
// 人体図の座標系: 幅1.0 × 高さ1.0
// 左右対称の筋肉は左右まとめて1つのパスで定義

/// 人体図のパス定義
enum MusclePathData {

    // MARK: - フロントビュー

    enum Front {

        // 大胸筋上部（左右）
        static func chestUpper(in rect: CGRect) -> Path {
            Path { p in
                // 左
                p.move(to: pt(0.38, 0.22, rect))
                p.addQuadCurve(to: pt(0.50, 0.215, rect), control: pt(0.44, 0.205, rect))
                p.addLine(to: pt(0.50, 0.245, rect))
                p.addQuadCurve(to: pt(0.38, 0.25, rect), control: pt(0.44, 0.25, rect))
                p.closeSubpath()
                // 右
                p.move(to: pt(0.62, 0.22, rect))
                p.addQuadCurve(to: pt(0.50, 0.215, rect), control: pt(0.56, 0.205, rect))
                p.addLine(to: pt(0.50, 0.245, rect))
                p.addQuadCurve(to: pt(0.62, 0.25, rect), control: pt(0.56, 0.25, rect))
                p.closeSubpath()
            }
        }

        // 大胸筋下部（左右）
        static func chestLower(in rect: CGRect) -> Path {
            Path { p in
                // 左
                p.move(to: pt(0.38, 0.25, rect))
                p.addQuadCurve(to: pt(0.50, 0.245, rect), control: pt(0.44, 0.25, rect))
                p.addLine(to: pt(0.50, 0.285, rect))
                p.addQuadCurve(to: pt(0.40, 0.275, rect), control: pt(0.45, 0.285, rect))
                p.closeSubpath()
                // 右
                p.move(to: pt(0.62, 0.25, rect))
                p.addQuadCurve(to: pt(0.50, 0.245, rect), control: pt(0.56, 0.25, rect))
                p.addLine(to: pt(0.50, 0.285, rect))
                p.addQuadCurve(to: pt(0.60, 0.275, rect), control: pt(0.55, 0.285, rect))
                p.closeSubpath()
            }
        }

        // 三角筋前部（左右）
        static func deltoidAnterior(in rect: CGRect) -> Path {
            Path { p in
                // 左
                p.move(to: pt(0.35, 0.195, rect))
                p.addQuadCurve(to: pt(0.38, 0.22, rect), control: pt(0.34, 0.21, rect))
                p.addLine(to: pt(0.38, 0.25, rect))
                p.addQuadCurve(to: pt(0.33, 0.23, rect), control: pt(0.35, 0.245, rect))
                p.closeSubpath()
                // 右
                p.move(to: pt(0.65, 0.195, rect))
                p.addQuadCurve(to: pt(0.62, 0.22, rect), control: pt(0.66, 0.21, rect))
                p.addLine(to: pt(0.62, 0.25, rect))
                p.addQuadCurve(to: pt(0.67, 0.23, rect), control: pt(0.65, 0.245, rect))
                p.closeSubpath()
            }
        }

        // 三角筋中部（左右）
        static func deltoidLateral(in rect: CGRect) -> Path {
            Path { p in
                // 左
                p.move(to: pt(0.33, 0.195, rect))
                p.addQuadCurve(to: pt(0.35, 0.195, rect), control: pt(0.34, 0.19, rect))
                p.addLine(to: pt(0.33, 0.23, rect))
                p.addQuadCurve(to: pt(0.31, 0.22, rect), control: pt(0.32, 0.23, rect))
                p.closeSubpath()
                // 右
                p.move(to: pt(0.67, 0.195, rect))
                p.addQuadCurve(to: pt(0.65, 0.195, rect), control: pt(0.66, 0.19, rect))
                p.addLine(to: pt(0.67, 0.23, rect))
                p.addQuadCurve(to: pt(0.69, 0.22, rect), control: pt(0.68, 0.23, rect))
                p.closeSubpath()
            }
        }

        // 上腕二頭筋（左右）
        static func biceps(in rect: CGRect) -> Path {
            Path { p in
                // 左
                p.move(to: pt(0.33, 0.24, rect))
                p.addQuadCurve(to: pt(0.35, 0.25, rect), control: pt(0.34, 0.24, rect))
                p.addLine(to: pt(0.34, 0.32, rect))
                p.addQuadCurve(to: pt(0.31, 0.32, rect), control: pt(0.325, 0.325, rect))
                p.closeSubpath()
                // 右
                p.move(to: pt(0.67, 0.24, rect))
                p.addQuadCurve(to: pt(0.65, 0.25, rect), control: pt(0.66, 0.24, rect))
                p.addLine(to: pt(0.66, 0.32, rect))
                p.addQuadCurve(to: pt(0.69, 0.32, rect), control: pt(0.675, 0.325, rect))
                p.closeSubpath()
            }
        }

        // 前腕筋群（左右フロント）
        static func forearms(in rect: CGRect) -> Path {
            Path { p in
                // 左
                p.move(to: pt(0.31, 0.325, rect))
                p.addLine(to: pt(0.34, 0.325, rect))
                p.addQuadCurve(to: pt(0.33, 0.40, rect), control: pt(0.34, 0.37, rect))
                p.addQuadCurve(to: pt(0.30, 0.40, rect), control: pt(0.31, 0.40, rect))
                p.closeSubpath()
                // 右
                p.move(to: pt(0.69, 0.325, rect))
                p.addLine(to: pt(0.66, 0.325, rect))
                p.addQuadCurve(to: pt(0.67, 0.40, rect), control: pt(0.66, 0.37, rect))
                p.addQuadCurve(to: pt(0.70, 0.40, rect), control: pt(0.69, 0.40, rect))
                p.closeSubpath()
            }
        }

        // 腹直筋
        static func rectusAbdominis(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: pt(0.46, 0.29, rect))
                p.addLine(to: pt(0.54, 0.29, rect))
                p.addLine(to: pt(0.54, 0.40, rect))
                p.addQuadCurve(to: pt(0.46, 0.40, rect), control: pt(0.50, 0.41, rect))
                p.closeSubpath()
            }
        }

        // 腹斜筋（左右）
        static func obliques(in rect: CGRect) -> Path {
            Path { p in
                // 左
                p.move(to: pt(0.40, 0.29, rect))
                p.addLine(to: pt(0.46, 0.29, rect))
                p.addLine(to: pt(0.46, 0.40, rect))
                p.addQuadCurve(to: pt(0.41, 0.40, rect), control: pt(0.43, 0.41, rect))
                p.closeSubpath()
                // 右
                p.move(to: pt(0.60, 0.29, rect))
                p.addLine(to: pt(0.54, 0.29, rect))
                p.addLine(to: pt(0.54, 0.40, rect))
                p.addQuadCurve(to: pt(0.59, 0.40, rect), control: pt(0.57, 0.41, rect))
                p.closeSubpath()
            }
        }

        // 大腿四頭筋（左右）
        static func quadriceps(in rect: CGRect) -> Path {
            Path { p in
                // 左
                p.move(to: pt(0.42, 0.44, rect))
                p.addLine(to: pt(0.49, 0.44, rect))
                p.addQuadCurve(to: pt(0.48, 0.60, rect), control: pt(0.50, 0.52, rect))
                p.addLine(to: pt(0.42, 0.60, rect))
                p.addQuadCurve(to: pt(0.42, 0.44, rect), control: pt(0.40, 0.52, rect))
                // 右
                p.move(to: pt(0.58, 0.44, rect))
                p.addLine(to: pt(0.51, 0.44, rect))
                p.addQuadCurve(to: pt(0.52, 0.60, rect), control: pt(0.50, 0.52, rect))
                p.addLine(to: pt(0.58, 0.60, rect))
                p.addQuadCurve(to: pt(0.58, 0.44, rect), control: pt(0.60, 0.52, rect))
            }
        }

        // 内転筋群（左右）
        static func adductors(in rect: CGRect) -> Path {
            Path { p in
                // 左
                p.move(to: pt(0.47, 0.44, rect))
                p.addLine(to: pt(0.49, 0.44, rect))
                p.addLine(to: pt(0.49, 0.55, rect))
                p.addQuadCurve(to: pt(0.47, 0.55, rect), control: pt(0.48, 0.56, rect))
                p.closeSubpath()
                // 右
                p.move(to: pt(0.53, 0.44, rect))
                p.addLine(to: pt(0.51, 0.44, rect))
                p.addLine(to: pt(0.51, 0.55, rect))
                p.addQuadCurve(to: pt(0.53, 0.55, rect), control: pt(0.52, 0.56, rect))
                p.closeSubpath()
            }
        }

        // 腸腰筋（左右）
        static func hipFlexors(in rect: CGRect) -> Path {
            Path { p in
                // 左
                p.move(to: pt(0.43, 0.40, rect))
                p.addLine(to: pt(0.47, 0.40, rect))
                p.addLine(to: pt(0.46, 0.44, rect))
                p.addLine(to: pt(0.42, 0.44, rect))
                p.closeSubpath()
                // 右
                p.move(to: pt(0.57, 0.40, rect))
                p.addLine(to: pt(0.53, 0.40, rect))
                p.addLine(to: pt(0.54, 0.44, rect))
                p.addLine(to: pt(0.58, 0.44, rect))
                p.closeSubpath()
            }
        }

        // 腓腹筋（左右フロント）
        static func gastrocnemius(in rect: CGRect) -> Path {
            Path { p in
                // 左
                p.move(to: pt(0.42, 0.64, rect))
                p.addLine(to: pt(0.47, 0.64, rect))
                p.addQuadCurve(to: pt(0.46, 0.76, rect), control: pt(0.47, 0.70, rect))
                p.addQuadCurve(to: pt(0.42, 0.76, rect), control: pt(0.44, 0.77, rect))
                p.closeSubpath()
                // 右
                p.move(to: pt(0.58, 0.64, rect))
                p.addLine(to: pt(0.53, 0.64, rect))
                p.addQuadCurve(to: pt(0.54, 0.76, rect), control: pt(0.53, 0.70, rect))
                p.addQuadCurve(to: pt(0.58, 0.76, rect), control: pt(0.56, 0.77, rect))
                p.closeSubpath()
            }
        }

        // ヒラメ筋（左右フロント）
        static func soleus(in rect: CGRect) -> Path {
            Path { p in
                // 左
                p.move(to: pt(0.43, 0.76, rect))
                p.addLine(to: pt(0.46, 0.76, rect))
                p.addLine(to: pt(0.455, 0.84, rect))
                p.addLine(to: pt(0.435, 0.84, rect))
                p.closeSubpath()
                // 右
                p.move(to: pt(0.57, 0.76, rect))
                p.addLine(to: pt(0.54, 0.76, rect))
                p.addLine(to: pt(0.545, 0.84, rect))
                p.addLine(to: pt(0.565, 0.84, rect))
                p.closeSubpath()
            }
        }
    }

    // MARK: - バックビュー

    enum Back {

        // 僧帽筋上部
        static func trapsUpper(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: pt(0.44, 0.155, rect))
                p.addQuadCurve(to: pt(0.50, 0.18, rect), control: pt(0.47, 0.155, rect))
                p.addQuadCurve(to: pt(0.56, 0.155, rect), control: pt(0.53, 0.155, rect))
                p.addQuadCurve(to: pt(0.62, 0.195, rect), control: pt(0.60, 0.17, rect))
                p.addLine(to: pt(0.50, 0.22, rect))
                p.addLine(to: pt(0.38, 0.195, rect))
                p.addQuadCurve(to: pt(0.44, 0.155, rect), control: pt(0.40, 0.17, rect))
            }
        }

        // 僧帽筋中部・下部
        static func trapsMiddleLower(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: pt(0.42, 0.22, rect))
                p.addLine(to: pt(0.50, 0.22, rect))
                p.addLine(to: pt(0.58, 0.22, rect))
                p.addLine(to: pt(0.55, 0.30, rect))
                p.addQuadCurve(to: pt(0.50, 0.31, rect), control: pt(0.52, 0.31, rect))
                p.addQuadCurve(to: pt(0.45, 0.30, rect), control: pt(0.48, 0.31, rect))
                p.closeSubpath()
            }
        }

        // 広背筋（左右）
        static func lats(in rect: CGRect) -> Path {
            Path { p in
                // 左
                p.move(to: pt(0.38, 0.23, rect))
                p.addLine(to: pt(0.42, 0.22, rect))
                p.addLine(to: pt(0.45, 0.30, rect))
                p.addLine(to: pt(0.44, 0.38, rect))
                p.addQuadCurve(to: pt(0.39, 0.36, rect), control: pt(0.41, 0.38, rect))
                p.closeSubpath()
                // 右
                p.move(to: pt(0.62, 0.23, rect))
                p.addLine(to: pt(0.58, 0.22, rect))
                p.addLine(to: pt(0.55, 0.30, rect))
                p.addLine(to: pt(0.56, 0.38, rect))
                p.addQuadCurve(to: pt(0.61, 0.36, rect), control: pt(0.59, 0.38, rect))
                p.closeSubpath()
            }
        }

        // 脊柱起立筋
        static func erectorSpinae(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: pt(0.47, 0.24, rect))
                p.addLine(to: pt(0.53, 0.24, rect))
                p.addLine(to: pt(0.53, 0.40, rect))
                p.addQuadCurve(to: pt(0.47, 0.40, rect), control: pt(0.50, 0.41, rect))
                p.closeSubpath()
            }
        }

        // 三角筋後部（左右）
        static func deltoidPosterior(in rect: CGRect) -> Path {
            Path { p in
                // 左
                p.move(to: pt(0.34, 0.195, rect))
                p.addQuadCurve(to: pt(0.38, 0.195, rect), control: pt(0.36, 0.19, rect))
                p.addLine(to: pt(0.38, 0.24, rect))
                p.addQuadCurve(to: pt(0.33, 0.23, rect), control: pt(0.35, 0.24, rect))
                p.closeSubpath()
                // 右
                p.move(to: pt(0.66, 0.195, rect))
                p.addQuadCurve(to: pt(0.62, 0.195, rect), control: pt(0.64, 0.19, rect))
                p.addLine(to: pt(0.62, 0.24, rect))
                p.addQuadCurve(to: pt(0.67, 0.23, rect), control: pt(0.65, 0.24, rect))
                p.closeSubpath()
            }
        }

        // 上腕三頭筋（左右）
        static func triceps(in rect: CGRect) -> Path {
            Path { p in
                // 左
                p.move(to: pt(0.32, 0.24, rect))
                p.addLine(to: pt(0.36, 0.24, rect))
                p.addLine(to: pt(0.35, 0.32, rect))
                p.addQuadCurve(to: pt(0.31, 0.32, rect), control: pt(0.33, 0.33, rect))
                p.closeSubpath()
                // 右
                p.move(to: pt(0.68, 0.24, rect))
                p.addLine(to: pt(0.64, 0.24, rect))
                p.addLine(to: pt(0.65, 0.32, rect))
                p.addQuadCurve(to: pt(0.69, 0.32, rect), control: pt(0.67, 0.33, rect))
                p.closeSubpath()
            }
        }

        // 臀筋群（左右）
        static func glutes(in rect: CGRect) -> Path {
            Path { p in
                // 左
                p.move(to: pt(0.41, 0.40, rect))
                p.addLine(to: pt(0.50, 0.40, rect))
                p.addLine(to: pt(0.50, 0.47, rect))
                p.addQuadCurve(to: pt(0.41, 0.47, rect), control: pt(0.45, 0.49, rect))
                p.closeSubpath()
                // 右
                p.move(to: pt(0.59, 0.40, rect))
                p.addLine(to: pt(0.50, 0.40, rect))
                p.addLine(to: pt(0.50, 0.47, rect))
                p.addQuadCurve(to: pt(0.59, 0.47, rect), control: pt(0.55, 0.49, rect))
                p.closeSubpath()
            }
        }

        // ハムストリングス（左右）
        static func hamstrings(in rect: CGRect) -> Path {
            Path { p in
                // 左
                p.move(to: pt(0.42, 0.47, rect))
                p.addLine(to: pt(0.49, 0.47, rect))
                p.addLine(to: pt(0.48, 0.63, rect))
                p.addQuadCurve(to: pt(0.42, 0.63, rect), control: pt(0.45, 0.64, rect))
                p.closeSubpath()
                // 右
                p.move(to: pt(0.58, 0.47, rect))
                p.addLine(to: pt(0.51, 0.47, rect))
                p.addLine(to: pt(0.52, 0.63, rect))
                p.addQuadCurve(to: pt(0.58, 0.63, rect), control: pt(0.55, 0.64, rect))
                p.closeSubpath()
            }
        }

        // 腓腹筋（左右バック）
        static func gastrocnemius(in rect: CGRect) -> Path {
            Path { p in
                // 左
                p.move(to: pt(0.42, 0.64, rect))
                p.addLine(to: pt(0.48, 0.64, rect))
                p.addQuadCurve(to: pt(0.47, 0.76, rect), control: pt(0.48, 0.70, rect))
                p.addQuadCurve(to: pt(0.42, 0.76, rect), control: pt(0.44, 0.77, rect))
                p.closeSubpath()
                // 右
                p.move(to: pt(0.58, 0.64, rect))
                p.addLine(to: pt(0.52, 0.64, rect))
                p.addQuadCurve(to: pt(0.53, 0.76, rect), control: pt(0.52, 0.70, rect))
                p.addQuadCurve(to: pt(0.58, 0.76, rect), control: pt(0.56, 0.77, rect))
                p.closeSubpath()
            }
        }

        // ヒラメ筋（左右バック）
        static func soleus(in rect: CGRect) -> Path {
            Path { p in
                // 左
                p.move(to: pt(0.43, 0.76, rect))
                p.addLine(to: pt(0.47, 0.76, rect))
                p.addLine(to: pt(0.46, 0.84, rect))
                p.addLine(to: pt(0.44, 0.84, rect))
                p.closeSubpath()
                // 右
                p.move(to: pt(0.57, 0.76, rect))
                p.addLine(to: pt(0.53, 0.76, rect))
                p.addLine(to: pt(0.54, 0.84, rect))
                p.addLine(to: pt(0.56, 0.84, rect))
                p.closeSubpath()
            }
        }
    }

    // MARK: - 人体シルエット

    static func bodyOutlineFront(in rect: CGRect) -> Path {
        Path { p in
            // 頭
            p.addEllipse(in: CGRect(
                x: rect.minX + rect.width * 0.44,
                y: rect.minY + rect.height * 0.02,
                width: rect.width * 0.12,
                height: rect.height * 0.08
            ))
            // 首
            p.move(to: pt(0.47, 0.10, rect))
            p.addLine(to: pt(0.53, 0.10, rect))
            p.addLine(to: pt(0.53, 0.15, rect))
            p.addLine(to: pt(0.47, 0.15, rect))
            p.closeSubpath()
            // 胴体
            p.move(to: pt(0.35, 0.19, rect))
            p.addQuadCurve(to: pt(0.50, 0.185, rect), control: pt(0.42, 0.18, rect))
            p.addQuadCurve(to: pt(0.65, 0.19, rect), control: pt(0.58, 0.18, rect))
            p.addLine(to: pt(0.60, 0.42, rect))
            p.addQuadCurve(to: pt(0.50, 0.43, rect), control: pt(0.55, 0.43, rect))
            p.addQuadCurve(to: pt(0.40, 0.42, rect), control: pt(0.45, 0.43, rect))
            p.closeSubpath()
            // 左腕
            p.move(to: pt(0.35, 0.195, rect))
            p.addQuadCurve(to: pt(0.30, 0.32, rect), control: pt(0.30, 0.25, rect))
            p.addLine(to: pt(0.28, 0.42, rect))
            p.addLine(to: pt(0.32, 0.42, rect))
            p.addQuadCurve(to: pt(0.37, 0.25, rect), control: pt(0.35, 0.32, rect))
            p.closeSubpath()
            // 右腕
            p.move(to: pt(0.65, 0.195, rect))
            p.addQuadCurve(to: pt(0.70, 0.32, rect), control: pt(0.70, 0.25, rect))
            p.addLine(to: pt(0.72, 0.42, rect))
            p.addLine(to: pt(0.68, 0.42, rect))
            p.addQuadCurve(to: pt(0.63, 0.25, rect), control: pt(0.65, 0.32, rect))
            p.closeSubpath()
            // 左脚
            p.move(to: pt(0.41, 0.42, rect))
            p.addLine(to: pt(0.50, 0.43, rect))
            p.addLine(to: pt(0.48, 0.85, rect))
            p.addLine(to: pt(0.41, 0.85, rect))
            p.closeSubpath()
            // 右脚
            p.move(to: pt(0.59, 0.42, rect))
            p.addLine(to: pt(0.50, 0.43, rect))
            p.addLine(to: pt(0.52, 0.85, rect))
            p.addLine(to: pt(0.59, 0.85, rect))
            p.closeSubpath()
        }
    }

    static func bodyOutlineBack(in rect: CGRect) -> Path {
        bodyOutlineFront(in: rect) // 背面も同じシルエット
    }

    // MARK: - ヘルパー

    private static func pt(_ x: Double, _ y: Double, _ rect: CGRect) -> CGPoint {
        CGPoint(
            x: rect.minX + rect.width * x,
            y: rect.minY + rect.height * y
        )
    }
}

// MARK: - Muscle → Path マッピング

extension MusclePathData {

    /// フロントビューで表示する筋肉とそのパス
    static let frontMuscles: [(muscle: Muscle, path: (CGRect) -> Path)] = [
        (.chestUpper, Front.chestUpper),
        (.chestLower, Front.chestLower),
        (.deltoidAnterior, Front.deltoidAnterior),
        (.deltoidLateral, Front.deltoidLateral),
        (.biceps, Front.biceps),
        (.forearms, Front.forearms),
        (.rectusAbdominis, Front.rectusAbdominis),
        (.obliques, Front.obliques),
        (.quadriceps, Front.quadriceps),
        (.adductors, Front.adductors),
        (.hipFlexors, Front.hipFlexors),
        (.gastrocnemius, Front.gastrocnemius),
        (.soleus, Front.soleus),
    ]

    /// バックビューで表示する筋肉とそのパス
    static let backMuscles: [(muscle: Muscle, path: (CGRect) -> Path)] = [
        (.trapsUpper, Back.trapsUpper),
        (.trapsMiddleLower, Back.trapsMiddleLower),
        (.lats, Back.lats),
        (.erectorSpinae, Back.erectorSpinae),
        (.deltoidPosterior, Back.deltoidPosterior),
        (.triceps, Back.triceps),
        (.glutes, Back.glutes),
        (.hamstrings, Back.hamstrings),
        (.gastrocnemius, Back.gastrocnemius),
        (.soleus, Back.soleus),
    ]
}
