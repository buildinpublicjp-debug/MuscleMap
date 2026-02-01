import SwiftUI

// MARK: - 筋肉パスデータ（正規化座標 0-1）
// 人体図の座標系: 幅1.0 × 高さ1.0（アスペクト比 3:5）
// 左右対称の筋肉は左右まとめて1つのパスで定義
// 各筋肉は隣接筋肉と共有辺を持ち、タップヒットエリアを十分確保

/// 人体図のパス定義
enum MusclePathData {

    // MARK: - フロントビュー（10筋肉）

    enum Front {

        // 大胸筋上部（左右）
        static func chestUpper(in rect: CGRect) -> Path {
            Path { p in
                // 左
                p.move(to: pt(0.34, 0.215, rect))
                p.addLine(to: pt(0.50, 0.210, rect))
                p.addLine(to: pt(0.50, 0.255, rect))
                p.addLine(to: pt(0.36, 0.260, rect))
                p.closeSubpath()
                // 右
                p.move(to: pt(0.66, 0.215, rect))
                p.addLine(to: pt(0.50, 0.210, rect))
                p.addLine(to: pt(0.50, 0.255, rect))
                p.addLine(to: pt(0.64, 0.260, rect))
                p.closeSubpath()
            }
        }

        // 大胸筋下部（左右）
        static func chestLower(in rect: CGRect) -> Path {
            Path { p in
                // 左
                p.move(to: pt(0.36, 0.260, rect))
                p.addLine(to: pt(0.50, 0.255, rect))
                p.addLine(to: pt(0.50, 0.305, rect))
                p.addQuadCurve(to: pt(0.38, 0.295, rect), control: pt(0.44, 0.310, rect))
                p.closeSubpath()
                // 右
                p.move(to: pt(0.64, 0.260, rect))
                p.addLine(to: pt(0.50, 0.255, rect))
                p.addLine(to: pt(0.50, 0.305, rect))
                p.addQuadCurve(to: pt(0.62, 0.295, rect), control: pt(0.56, 0.310, rect))
                p.closeSubpath()
            }
        }

        // 三角筋前部（左右）
        static func deltoidAnterior(in rect: CGRect) -> Path {
            Path { p in
                // 左
                p.move(to: pt(0.30, 0.195, rect))
                p.addQuadCurve(to: pt(0.34, 0.215, rect), control: pt(0.30, 0.205, rect))
                p.addLine(to: pt(0.36, 0.260, rect))
                p.addLine(to: pt(0.30, 0.250, rect))
                p.closeSubpath()
                // 右
                p.move(to: pt(0.70, 0.195, rect))
                p.addQuadCurve(to: pt(0.66, 0.215, rect), control: pt(0.70, 0.205, rect))
                p.addLine(to: pt(0.64, 0.260, rect))
                p.addLine(to: pt(0.70, 0.250, rect))
                p.closeSubpath()
            }
        }

        // 三角筋中部（左右）
        static func deltoidLateral(in rect: CGRect) -> Path {
            Path { p in
                // 左
                p.move(to: pt(0.28, 0.190, rect))
                p.addLine(to: pt(0.30, 0.195, rect))
                p.addLine(to: pt(0.30, 0.250, rect))
                p.addLine(to: pt(0.27, 0.240, rect))
                p.closeSubpath()
                // 右
                p.move(to: pt(0.72, 0.190, rect))
                p.addLine(to: pt(0.70, 0.195, rect))
                p.addLine(to: pt(0.70, 0.250, rect))
                p.addLine(to: pt(0.73, 0.240, rect))
                p.closeSubpath()
            }
        }

        // 上腕二頭筋（左右）
        static func biceps(in rect: CGRect) -> Path {
            Path { p in
                // 左
                p.move(to: pt(0.27, 0.250, rect))
                p.addLine(to: pt(0.32, 0.260, rect))
                p.addQuadCurve(to: pt(0.31, 0.350, rect), control: pt(0.33, 0.310, rect))
                p.addQuadCurve(to: pt(0.26, 0.345, rect), control: pt(0.28, 0.355, rect))
                p.closeSubpath()
                // 右
                p.move(to: pt(0.73, 0.250, rect))
                p.addLine(to: pt(0.68, 0.260, rect))
                p.addQuadCurve(to: pt(0.69, 0.350, rect), control: pt(0.67, 0.310, rect))
                p.addQuadCurve(to: pt(0.74, 0.345, rect), control: pt(0.72, 0.355, rect))
                p.closeSubpath()
            }
        }

        // 前腕筋群（左右）
        static func forearms(in rect: CGRect) -> Path {
            Path { p in
                // 左
                p.move(to: pt(0.26, 0.350, rect))
                p.addLine(to: pt(0.31, 0.355, rect))
                p.addQuadCurve(to: pt(0.30, 0.435, rect), control: pt(0.31, 0.400, rect))
                p.addQuadCurve(to: pt(0.25, 0.430, rect), control: pt(0.27, 0.440, rect))
                p.closeSubpath()
                // 右
                p.move(to: pt(0.74, 0.350, rect))
                p.addLine(to: pt(0.69, 0.355, rect))
                p.addQuadCurve(to: pt(0.70, 0.435, rect), control: pt(0.69, 0.400, rect))
                p.addQuadCurve(to: pt(0.75, 0.430, rect), control: pt(0.73, 0.440, rect))
                p.closeSubpath()
            }
        }

        // 腹直筋
        static func rectusAbdominis(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: pt(0.45, 0.305, rect))
                p.addLine(to: pt(0.55, 0.305, rect))
                p.addLine(to: pt(0.55, 0.430, rect))
                p.addQuadCurve(to: pt(0.45, 0.430, rect), control: pt(0.50, 0.440, rect))
                p.closeSubpath()
            }
        }

        // 腹斜筋（左右）
        static func obliques(in rect: CGRect) -> Path {
            Path { p in
                // 左
                p.move(to: pt(0.38, 0.300, rect))
                p.addLine(to: pt(0.45, 0.305, rect))
                p.addLine(to: pt(0.45, 0.430, rect))
                p.addLine(to: pt(0.40, 0.435, rect))
                p.closeSubpath()
                // 右
                p.move(to: pt(0.62, 0.300, rect))
                p.addLine(to: pt(0.55, 0.305, rect))
                p.addLine(to: pt(0.55, 0.430, rect))
                p.addLine(to: pt(0.60, 0.435, rect))
                p.closeSubpath()
            }
        }

        // 大腿四頭筋（左右）
        static func quadriceps(in rect: CGRect) -> Path {
            Path { p in
                // 左
                p.move(to: pt(0.39, 0.470, rect))
                p.addLine(to: pt(0.50, 0.465, rect))
                p.addQuadCurve(to: pt(0.49, 0.650, rect), control: pt(0.51, 0.560, rect))
                p.addLine(to: pt(0.40, 0.650, rect))
                p.addQuadCurve(to: pt(0.39, 0.470, rect), control: pt(0.37, 0.560, rect))
                // 右
                p.move(to: pt(0.61, 0.470, rect))
                p.addLine(to: pt(0.50, 0.465, rect))
                p.addQuadCurve(to: pt(0.51, 0.650, rect), control: pt(0.49, 0.560, rect))
                p.addLine(to: pt(0.60, 0.650, rect))
                p.addQuadCurve(to: pt(0.61, 0.470, rect), control: pt(0.63, 0.560, rect))
            }
        }

        // 腓腹筋（左右フロント）
        static func gastrocnemius(in rect: CGRect) -> Path {
            Path { p in
                // 左
                p.move(to: pt(0.40, 0.680, rect))
                p.addLine(to: pt(0.49, 0.680, rect))
                p.addQuadCurve(to: pt(0.48, 0.800, rect), control: pt(0.50, 0.740, rect))
                p.addQuadCurve(to: pt(0.41, 0.800, rect), control: pt(0.44, 0.810, rect))
                p.closeSubpath()
                // 右
                p.move(to: pt(0.60, 0.680, rect))
                p.addLine(to: pt(0.51, 0.680, rect))
                p.addQuadCurve(to: pt(0.52, 0.800, rect), control: pt(0.50, 0.740, rect))
                p.addQuadCurve(to: pt(0.59, 0.800, rect), control: pt(0.56, 0.810, rect))
                p.closeSubpath()
            }
        }
    }

    // MARK: - バックビュー（11筋肉）

    enum Back {

        // 僧帽筋上部
        static func trapsUpper(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: pt(0.42, 0.155, rect))
                p.addQuadCurve(to: pt(0.50, 0.175, rect), control: pt(0.46, 0.150, rect))
                p.addQuadCurve(to: pt(0.58, 0.155, rect), control: pt(0.54, 0.150, rect))
                p.addLine(to: pt(0.66, 0.200, rect))
                p.addLine(to: pt(0.50, 0.225, rect))
                p.addLine(to: pt(0.34, 0.200, rect))
                p.closeSubpath()
            }
        }

        // 僧帽筋中部・下部
        static func trapsMiddleLower(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: pt(0.40, 0.225, rect))
                p.addLine(to: pt(0.50, 0.225, rect))
                p.addLine(to: pt(0.60, 0.225, rect))
                p.addLine(to: pt(0.56, 0.320, rect))
                p.addQuadCurve(to: pt(0.50, 0.330, rect), control: pt(0.53, 0.330, rect))
                p.addQuadCurve(to: pt(0.44, 0.320, rect), control: pt(0.47, 0.330, rect))
                p.closeSubpath()
            }
        }

        // 広背筋（左右）
        static func lats(in rect: CGRect) -> Path {
            Path { p in
                // 左
                p.move(to: pt(0.34, 0.230, rect))
                p.addLine(to: pt(0.40, 0.225, rect))
                p.addLine(to: pt(0.44, 0.320, rect))
                p.addLine(to: pt(0.42, 0.400, rect))
                p.addQuadCurve(to: pt(0.35, 0.380, rect), control: pt(0.38, 0.400, rect))
                p.closeSubpath()
                // 右
                p.move(to: pt(0.66, 0.230, rect))
                p.addLine(to: pt(0.60, 0.225, rect))
                p.addLine(to: pt(0.56, 0.320, rect))
                p.addLine(to: pt(0.58, 0.400, rect))
                p.addQuadCurve(to: pt(0.65, 0.380, rect), control: pt(0.62, 0.400, rect))
                p.closeSubpath()
            }
        }

        // 脊柱起立筋
        static func erectorSpinae(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: pt(0.46, 0.250, rect))
                p.addLine(to: pt(0.54, 0.250, rect))
                p.addLine(to: pt(0.54, 0.420, rect))
                p.addQuadCurve(to: pt(0.46, 0.420, rect), control: pt(0.50, 0.430, rect))
                p.closeSubpath()
            }
        }

        // 三角筋後部（左右）
        static func deltoidPosterior(in rect: CGRect) -> Path {
            Path { p in
                // 左
                p.move(to: pt(0.28, 0.190, rect))
                p.addLine(to: pt(0.34, 0.200, rect))
                p.addLine(to: pt(0.34, 0.255, rect))
                p.addLine(to: pt(0.27, 0.245, rect))
                p.closeSubpath()
                // 右
                p.move(to: pt(0.72, 0.190, rect))
                p.addLine(to: pt(0.66, 0.200, rect))
                p.addLine(to: pt(0.66, 0.255, rect))
                p.addLine(to: pt(0.73, 0.245, rect))
                p.closeSubpath()
            }
        }

        // 上腕三頭筋（左右）
        static func triceps(in rect: CGRect) -> Path {
            Path { p in
                // 左
                p.move(to: pt(0.27, 0.255, rect))
                p.addLine(to: pt(0.33, 0.260, rect))
                p.addQuadCurve(to: pt(0.32, 0.355, rect), control: pt(0.34, 0.310, rect))
                p.addQuadCurve(to: pt(0.26, 0.350, rect), control: pt(0.29, 0.360, rect))
                p.closeSubpath()
                // 右
                p.move(to: pt(0.73, 0.255, rect))
                p.addLine(to: pt(0.67, 0.260, rect))
                p.addQuadCurve(to: pt(0.68, 0.355, rect), control: pt(0.66, 0.310, rect))
                p.addQuadCurve(to: pt(0.74, 0.350, rect), control: pt(0.71, 0.360, rect))
                p.closeSubpath()
            }
        }

        // 臀筋群（左右）
        static func glutes(in rect: CGRect) -> Path {
            Path { p in
                // 左
                p.move(to: pt(0.39, 0.420, rect))
                p.addLine(to: pt(0.50, 0.420, rect))
                p.addLine(to: pt(0.50, 0.495, rect))
                p.addQuadCurve(to: pt(0.39, 0.490, rect), control: pt(0.44, 0.505, rect))
                p.closeSubpath()
                // 右
                p.move(to: pt(0.61, 0.420, rect))
                p.addLine(to: pt(0.50, 0.420, rect))
                p.addLine(to: pt(0.50, 0.495, rect))
                p.addQuadCurve(to: pt(0.61, 0.490, rect), control: pt(0.56, 0.505, rect))
                p.closeSubpath()
            }
        }

        // ハムストリングス（左右）
        static func hamstrings(in rect: CGRect) -> Path {
            Path { p in
                // 左
                p.move(to: pt(0.40, 0.500, rect))
                p.addLine(to: pt(0.50, 0.495, rect))
                p.addLine(to: pt(0.49, 0.665, rect))
                p.addQuadCurve(to: pt(0.40, 0.660, rect), control: pt(0.44, 0.670, rect))
                p.closeSubpath()
                // 右
                p.move(to: pt(0.60, 0.500, rect))
                p.addLine(to: pt(0.50, 0.495, rect))
                p.addLine(to: pt(0.51, 0.665, rect))
                p.addQuadCurve(to: pt(0.60, 0.660, rect), control: pt(0.56, 0.670, rect))
                p.closeSubpath()
            }
        }

        // 内転筋群（左右）
        static func adductors(in rect: CGRect) -> Path {
            Path { p in
                // 左
                p.move(to: pt(0.46, 0.470, rect))
                p.addLine(to: pt(0.50, 0.465, rect))
                p.addLine(to: pt(0.50, 0.580, rect))
                p.addQuadCurve(to: pt(0.46, 0.575, rect), control: pt(0.48, 0.585, rect))
                p.closeSubpath()
                // 右
                p.move(to: pt(0.54, 0.470, rect))
                p.addLine(to: pt(0.50, 0.465, rect))
                p.addLine(to: pt(0.50, 0.580, rect))
                p.addQuadCurve(to: pt(0.54, 0.575, rect), control: pt(0.52, 0.585, rect))
                p.closeSubpath()
            }
        }

        // 腸腰筋（左右）
        static func hipFlexors(in rect: CGRect) -> Path {
            Path { p in
                // 左
                p.move(to: pt(0.42, 0.420, rect))
                p.addLine(to: pt(0.46, 0.420, rect))
                p.addLine(to: pt(0.46, 0.470, rect))
                p.addLine(to: pt(0.41, 0.470, rect))
                p.closeSubpath()
                // 右
                p.move(to: pt(0.58, 0.420, rect))
                p.addLine(to: pt(0.54, 0.420, rect))
                p.addLine(to: pt(0.54, 0.470, rect))
                p.addLine(to: pt(0.59, 0.470, rect))
                p.closeSubpath()
            }
        }

        // ヒラメ筋（左右バック）
        static func soleus(in rect: CGRect) -> Path {
            Path { p in
                // 左
                p.move(to: pt(0.41, 0.690, rect))
                p.addLine(to: pt(0.48, 0.690, rect))
                p.addLine(to: pt(0.47, 0.800, rect))
                p.addLine(to: pt(0.42, 0.800, rect))
                p.closeSubpath()
                // 右
                p.move(to: pt(0.59, 0.690, rect))
                p.addLine(to: pt(0.52, 0.690, rect))
                p.addLine(to: pt(0.53, 0.800, rect))
                p.addLine(to: pt(0.58, 0.800, rect))
                p.closeSubpath()
            }
        }
    }

    // MARK: - 人体シルエット

    static func bodyOutlineFront(in rect: CGRect) -> Path {
        Path { p in
            // 頭
            p.addEllipse(in: CGRect(
                x: rect.minX + rect.width * 0.43,
                y: rect.minY + rect.height * 0.020,
                width: rect.width * 0.14,
                height: rect.height * 0.085
            ))
            // 首
            p.move(to: pt(0.47, 0.105, rect))
            p.addLine(to: pt(0.53, 0.105, rect))
            p.addLine(to: pt(0.54, 0.160, rect))
            p.addLine(to: pt(0.46, 0.160, rect))
            p.closeSubpath()
            // 胴体
            p.move(to: pt(0.30, 0.190, rect))
            p.addQuadCurve(to: pt(0.50, 0.180, rect), control: pt(0.40, 0.175, rect))
            p.addQuadCurve(to: pt(0.70, 0.190, rect), control: pt(0.60, 0.175, rect))
            p.addLine(to: pt(0.62, 0.450, rect))
            p.addQuadCurve(to: pt(0.50, 0.460, rect), control: pt(0.56, 0.460, rect))
            p.addQuadCurve(to: pt(0.38, 0.450, rect), control: pt(0.44, 0.460, rect))
            p.closeSubpath()
            // 左腕
            p.move(to: pt(0.30, 0.195, rect))
            p.addQuadCurve(to: pt(0.24, 0.345, rect), control: pt(0.24, 0.265, rect))
            p.addLine(to: pt(0.22, 0.445, rect))
            p.addLine(to: pt(0.28, 0.445, rect))
            p.addQuadCurve(to: pt(0.34, 0.260, rect), control: pt(0.32, 0.345, rect))
            p.closeSubpath()
            // 右腕
            p.move(to: pt(0.70, 0.195, rect))
            p.addQuadCurve(to: pt(0.76, 0.345, rect), control: pt(0.76, 0.265, rect))
            p.addLine(to: pt(0.78, 0.445, rect))
            p.addLine(to: pt(0.72, 0.445, rect))
            p.addQuadCurve(to: pt(0.66, 0.260, rect), control: pt(0.68, 0.345, rect))
            p.closeSubpath()
            // 左脚
            p.move(to: pt(0.39, 0.455, rect))
            p.addLine(to: pt(0.50, 0.460, rect))
            p.addLine(to: pt(0.49, 0.870, rect))
            p.addLine(to: pt(0.39, 0.870, rect))
            p.closeSubpath()
            // 右脚
            p.move(to: pt(0.61, 0.455, rect))
            p.addLine(to: pt(0.50, 0.460, rect))
            p.addLine(to: pt(0.51, 0.870, rect))
            p.addLine(to: pt(0.61, 0.870, rect))
            p.closeSubpath()
        }
    }

    static func bodyOutlineBack(in rect: CGRect) -> Path {
        bodyOutlineFront(in: rect)
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

    /// フロントビューで表示する筋肉とそのパス（10筋肉）
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
        (.gastrocnemius, Front.gastrocnemius),
    ]

    /// バックビューで表示する筋肉とそのパス（11筋肉）
    static let backMuscles: [(muscle: Muscle, path: (CGRect) -> Path)] = [
        (.trapsUpper, Back.trapsUpper),
        (.trapsMiddleLower, Back.trapsMiddleLower),
        (.lats, Back.lats),
        (.erectorSpinae, Back.erectorSpinae),
        (.deltoidPosterior, Back.deltoidPosterior),
        (.triceps, Back.triceps),
        (.glutes, Back.glutes),
        (.hamstrings, Back.hamstrings),
        (.adductors, Back.adductors),
        (.hipFlexors, Back.hipFlexors),
        (.soleus, Back.soleus),
    ]
}
