import SwiftUI

// MARK: - ウィジェット用Muscle enum（メインアプリと同一rawValue）

enum Muscle: String, CaseIterable {
    // 胸（2）
    case chestUpper = "chest_upper"
    case chestLower = "chest_lower"
    // 背中（4）
    case lats = "lats"
    case trapsUpper = "traps_upper"
    case trapsMiddleLower = "traps_middle_lower"
    case erectorSpinae = "erector_spinae"
    // 肩（3）
    case deltoidAnterior = "deltoid_anterior"
    case deltoidLateral = "deltoid_lateral"
    case deltoidPosterior = "deltoid_posterior"
    // 腕（3）
    case biceps = "biceps"
    case triceps = "triceps"
    case forearms = "forearms"
    // 体幹（2）
    case rectusAbdominis = "rectus_abdominis"
    case obliques = "obliques"
    // 下半身（7）
    case glutes = "glutes"
    case quadriceps = "quadriceps"
    case hamstrings = "hamstrings"
    case adductors = "adductors"
    case hipFlexors = "hip_flexors"
    case gastrocnemius = "gastrocnemius"
    case soleus = "soleus"
}

// MARK: - 筋肉パスデータ（CodeCanyon SVGベース）
// Source: Interactive Human Body Muscle Diagram by visian-systems
// License: Extended Commercial License
// Original ViewBox: 0 0 248.333 557.994
// 座標は正規化 (0-1) → pt() で CGRect にスケール

enum MusclePathData {

    // MARK: - フロントビュー

    enum Front {
        // 大胸筋上部（2パーツ: muscle-0, muscle-24）
        static func chestUpper(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: pt(0.3143, 0.2447, rect))
                p.addCurve(to: pt(0.4116, 0.2830, rect), control1: pt(0.3384, 0.2906, rect), control2: pt(0.4116, 0.2830, rect))
                p.addCurve(to: pt(0.4908, 0.2733, rect), control1: pt(0.4673, 0.2802, rect), control2: pt(0.4908, 0.2733, rect))
                p.addCurve(to: pt(0.4821, 0.2033, rect), control1: pt(0.5163, 0.2664, rect), control2: pt(0.4888, 0.2106, rect))
                p.addCurve(to: pt(0.4746, 0.1967, rect), control1: pt(0.4806, 0.2017, rect), control2: pt(0.4780, 0.1990, rect))
                p.addCurve(to: pt(0.4624, 0.1936, rect), control1: pt(0.4710, 0.1942, rect), control2: pt(0.4705, 0.1942, rect))
                p.addCurve(to: pt(0.4456, 0.1932, rect), control1: pt(0.4568, 0.1932, rect), control2: pt(0.4513, 0.1932, rect))
                p.addCurve(to: pt(0.3657, 0.2006, rect), control1: pt(0.4189, 0.1935, rect), control2: pt(0.3883, 0.1944, rect))
                p.addCurve(to: pt(0.3359, 0.2115, rect), control1: pt(0.3549, 0.2036, rect), control2: pt(0.3442, 0.2073, rect))
                p.addCurve(to: pt(0.3193, 0.2213, rect), control1: pt(0.3293, 0.2148, rect), control2: pt(0.3245, 0.2175, rect))
                p.addCurve(to: pt(0.3143, 0.2447, rect), control1: pt(0.3193, 0.2213, rect), control2: pt(0.3076, 0.2355, rect))
                p.closeSubpath()
                p.move(to: pt(0.7038, 0.2447, rect))
                p.addCurve(to: pt(0.6064, 0.2830, rect), control1: pt(0.6796, 0.2906, rect), control2: pt(0.6064, 0.2830, rect))
                p.addCurve(to: pt(0.5272, 0.2733, rect), control1: pt(0.5507, 0.2802, rect), control2: pt(0.5272, 0.2733, rect))
                p.addCurve(to: pt(0.5360, 0.2033, rect), control1: pt(0.5017, 0.2664, rect), control2: pt(0.5293, 0.2106, rect))
                p.addCurve(to: pt(0.5434, 0.1967, rect), control1: pt(0.5374, 0.2017, rect), control2: pt(0.5400, 0.1990, rect))
                p.addCurve(to: pt(0.5556, 0.1936, rect), control1: pt(0.5470, 0.1942, rect), control2: pt(0.5475, 0.1942, rect))
                p.addCurve(to: pt(0.5724, 0.1932, rect), control1: pt(0.5612, 0.1932, rect), control2: pt(0.5667, 0.1932, rect))
                p.addCurve(to: pt(0.6523, 0.2006, rect), control1: pt(0.5991, 0.1935, rect), control2: pt(0.6297, 0.1944, rect))
                p.addCurve(to: pt(0.6822, 0.2115, rect), control1: pt(0.6631, 0.2036, rect), control2: pt(0.6738, 0.2073, rect))
                p.addCurve(to: pt(0.6987, 0.2213, rect), control1: pt(0.6888, 0.2148, rect), control2: pt(0.6935, 0.2175, rect))
                p.addCurve(to: pt(0.7038, 0.2447, rect), control1: pt(0.6987, 0.2213, rect), control2: pt(0.7105, 0.2355, rect))
                p.closeSubpath()
            }
        }

        // 大胸筋下部（2パーツ: muscle-3, muscle-25）
        static func chestLower(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: pt(0.2633, 0.1901, rect))
                p.addCurve(to: pt(0.2985, 0.1906, rect), control1: pt(0.2633, 0.1901, rect), control2: pt(0.2797, 0.1882, rect))
                p.addCurve(to: pt(0.3985, 0.1894, rect), control1: pt(0.2985, 0.1906, rect), control2: pt(0.3851, 0.1901, rect))
                p.addCurve(to: pt(0.3005, 0.2372, rect), control1: pt(0.3985, 0.1894, rect), control2: pt(0.3126, 0.2010, rect))
                p.addCurve(to: pt(0.2925, 0.2512, rect), control1: pt(0.3005, 0.2372, rect), control2: pt(0.2971, 0.2478, rect))
                p.addCurve(to: pt(0.2128, 0.3028, rect), control1: pt(0.2878, 0.2546, rect), control2: pt(0.2513, 0.2656, rect))
                p.addCurve(to: pt(0.2075, 0.2736, rect), control1: pt(0.2128, 0.3028, rect), control2: pt(0.2096, 0.2775, rect))
                p.addCurve(to: pt(0.2075, 0.2264, rect), control1: pt(0.2055, 0.2697, rect), control2: pt(0.2032, 0.2380, rect))
                p.addCurve(to: pt(0.2633, 0.1901, rect), control1: pt(0.2111, 0.2169, rect), control2: pt(0.2324, 0.1947, rect))
                p.closeSubpath()
                p.move(to: pt(0.7548, 0.1901, rect))
                p.addCurve(to: pt(0.7195, 0.1906, rect), control1: pt(0.7548, 0.1901, rect), control2: pt(0.7383, 0.1882, rect))
                p.addCurve(to: pt(0.6195, 0.1894, rect), control1: pt(0.7195, 0.1906, rect), control2: pt(0.6330, 0.1901, rect))
                p.addCurve(to: pt(0.7175, 0.2372, rect), control1: pt(0.6195, 0.1894, rect), control2: pt(0.7054, 0.2010, rect))
                p.addCurve(to: pt(0.7256, 0.2512, rect), control1: pt(0.7175, 0.2372, rect), control2: pt(0.7209, 0.2478, rect))
                p.addCurve(to: pt(0.8053, 0.3028, rect), control1: pt(0.7303, 0.2546, rect), control2: pt(0.7667, 0.2656, rect))
                p.addCurve(to: pt(0.8105, 0.2736, rect), control1: pt(0.8053, 0.3028, rect), control2: pt(0.8085, 0.2775, rect))
                p.addCurve(to: pt(0.8105, 0.2264, rect), control1: pt(0.8125, 0.2697, rect), control2: pt(0.8148, 0.2380, rect))
                p.addCurve(to: pt(0.7548, 0.1901, rect), control1: pt(0.8069, 0.2169, rect), control2: pt(0.7856, 0.1947, rect))
                p.closeSubpath()
            }
        }

        // 三角筋前部（2パーツ: muscle-18, muscle-40）
        static func deltoidAnterior(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: pt(0.4301, 0.1417, rect))
                p.addCurve(to: pt(0.4329, 0.1584, rect), control1: pt(0.4313, 0.1472, rect), control2: pt(0.4322, 0.1528, rect))
                p.addCurve(to: pt(0.4323, 0.1717, rect), control1: pt(0.4333, 0.1628, rect), control2: pt(0.4326, 0.1672, rect))
                p.addCurve(to: pt(0.4291, 0.1816, rect), control1: pt(0.4322, 0.1748, rect), control2: pt(0.4338, 0.1790, rect))
                p.addCurve(to: pt(0.3842, 0.1857, rect), control1: pt(0.4200, 0.1866, rect), control2: pt(0.3966, 0.1857, rect))
                p.addCurve(to: pt(0.3370, 0.1860, rect), control1: pt(0.3684, 0.1858, rect), control2: pt(0.3527, 0.1859, rect))
                p.addCurve(to: pt(0.2936, 0.1816, rect), control1: pt(0.3222, 0.1861, rect), control2: pt(0.3085, 0.1816, rect))
                p.addCurve(to: pt(0.3181, 0.1756, rect), control1: pt(0.2936, 0.1816, rect), control2: pt(0.3054, 0.1787, rect))
                p.addCurve(to: pt(0.3581, 0.1623, rect), control1: pt(0.3309, 0.1724, rect), control2: pt(0.3520, 0.1646, rect))
                p.addCurve(to: pt(0.4301, 0.1417, rect), control1: pt(0.3642, 0.1601, rect), control2: pt(0.4185, 0.1446, rect))
                p.closeSubpath()
                p.move(to: pt(0.5879, 0.1417, rect))
                p.addCurve(to: pt(0.5852, 0.1584, rect), control1: pt(0.5867, 0.1472, rect), control2: pt(0.5858, 0.1528, rect))
                p.addCurve(to: pt(0.5857, 0.1717, rect), control1: pt(0.5847, 0.1628, rect), control2: pt(0.5854, 0.1672, rect))
                p.addCurve(to: pt(0.5890, 0.1816, rect), control1: pt(0.5859, 0.1748, rect), control2: pt(0.5842, 0.1790, rect))
                p.addCurve(to: pt(0.6339, 0.1857, rect), control1: pt(0.5980, 0.1866, rect), control2: pt(0.6214, 0.1857, rect))
                p.addCurve(to: pt(0.6810, 0.1860, rect), control1: pt(0.6496, 0.1858, rect), control2: pt(0.6653, 0.1859, rect))
                p.addCurve(to: pt(0.7244, 0.1816, rect), control1: pt(0.6959, 0.1861, rect), control2: pt(0.7095, 0.1816, rect))
                p.addCurve(to: pt(0.6999, 0.1756, rect), control1: pt(0.7244, 0.1816, rect), control2: pt(0.7126, 0.1787, rect))
                p.addCurve(to: pt(0.6600, 0.1623, rect), control1: pt(0.6871, 0.1724, rect), control2: pt(0.6661, 0.1646, rect))
                p.addCurve(to: pt(0.5879, 0.1417, rect), control1: pt(0.6539, 0.1601, rect), control2: pt(0.5996, 0.1446, rect))
                p.closeSubpath()
            }
        }

        // 上腕二頭筋（4パーツ: muscle-7, muscle-29, muscle-19, muscle-41）
        static func biceps(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: pt(0.3205, 0.2587, rect))
                p.addCurve(to: pt(0.3919, 0.2902, rect), control1: pt(0.3205, 0.2587, rect), control2: pt(0.3240, 0.2831, rect))
                p.addLine(to: pt(0.3884, 0.2927, rect))
                p.addCurve(to: pt(0.3924, 0.3092, rect), control1: pt(0.3884, 0.2927, rect), control2: pt(0.3980, 0.3028, rect))
                p.addCurve(to: pt(0.3809, 0.3161, rect), control1: pt(0.3869, 0.3157, rect), control2: pt(0.3809, 0.3161, rect))
                p.addCurve(to: pt(0.3935, 0.3290, rect), control1: pt(0.3809, 0.3161, rect), control2: pt(0.3930, 0.3230, rect))
                p.addCurve(to: pt(0.3849, 0.3399, rect), control1: pt(0.3940, 0.3350, rect), control2: pt(0.3914, 0.3386, rect))
                p.addCurve(to: pt(0.3346, 0.3268, rect), control1: pt(0.3849, 0.3399, rect), control2: pt(0.3507, 0.3380, rect))
                p.addCurve(to: pt(0.3315, 0.3180, rect), control1: pt(0.3346, 0.3268, rect), control2: pt(0.3315, 0.3219, rect))
                p.addCurve(to: pt(0.3200, 0.2955, rect), control1: pt(0.3315, 0.3180, rect), control2: pt(0.3200, 0.3140, rect))
                p.addCurve(to: pt(0.3174, 0.2912, rect), control1: pt(0.3200, 0.2955, rect), control2: pt(0.3185, 0.2942, rect))
                p.addCurve(to: pt(0.3205, 0.2587, rect), control1: pt(0.3164, 0.2882, rect), control2: pt(0.3109, 0.2741, rect))
                p.closeSubpath()
                p.move(to: pt(0.6976, 0.2587, rect))
                p.addCurve(to: pt(0.6261, 0.2902, rect), control1: pt(0.6976, 0.2587, rect), control2: pt(0.6940, 0.2831, rect))
                p.addLine(to: pt(0.6296, 0.2927, rect))
                p.addCurve(to: pt(0.6256, 0.3092, rect), control1: pt(0.6296, 0.2927, rect), control2: pt(0.6200, 0.3028, rect))
                p.addCurve(to: pt(0.6371, 0.3161, rect), control1: pt(0.6311, 0.3157, rect), control2: pt(0.6371, 0.3161, rect))
                p.addCurve(to: pt(0.6246, 0.3290, rect), control1: pt(0.6371, 0.3161, rect), control2: pt(0.6251, 0.3230, rect))
                p.addCurve(to: pt(0.6331, 0.3399, rect), control1: pt(0.6241, 0.3350, rect), control2: pt(0.6266, 0.3386, rect))
                p.addCurve(to: pt(0.6835, 0.3268, rect), control1: pt(0.6331, 0.3399, rect), control2: pt(0.6673, 0.3380, rect))
                p.addCurve(to: pt(0.6865, 0.3180, rect), control1: pt(0.6835, 0.3268, rect), control2: pt(0.6865, 0.3219, rect))
                p.addCurve(to: pt(0.6981, 0.2955, rect), control1: pt(0.6865, 0.3180, rect), control2: pt(0.6981, 0.3140, rect))
                p.addCurve(to: pt(0.7006, 0.2912, rect), control1: pt(0.6981, 0.2955, rect), control2: pt(0.6996, 0.2942, rect))
                p.addCurve(to: pt(0.6976, 0.2587, rect), control1: pt(0.7016, 0.2882, rect), control2: pt(0.7071, 0.2741, rect))
                p.closeSubpath()
                p.move(to: pt(0.3092, 0.3142, rect))
                p.addCurve(to: pt(0.3035, 0.2488, rect), control1: pt(0.3156, 0.3006, rect), control2: pt(0.3149, 0.2651, rect))
                p.addCurve(to: pt(0.3001, 0.2498, rect), control1: pt(0.3035, 0.2488, rect), control2: pt(0.3025, 0.2487, rect))
                p.addLine(to: pt(0.3002, 0.2497, rect))
                p.addCurve(to: pt(0.2857, 0.2567, rect), control1: pt(0.3002, 0.2497, rect), control2: pt(0.2941, 0.2533, rect))
                p.addCurve(to: pt(0.2099, 0.3091, rect), control1: pt(0.2774, 0.2602, rect), control2: pt(0.2404, 0.2797, rect))
                p.addCurve(to: pt(0.1948, 0.3581, rect), control1: pt(0.2099, 0.3091, rect), control2: pt(0.1992, 0.3311, rect))
                p.addCurve(to: pt(0.2126, 0.3741, rect), control1: pt(0.1948, 0.3581, rect), control2: pt(0.1989, 0.3640, rect))
                p.addCurve(to: pt(0.2391, 0.3639, rect), control1: pt(0.2126, 0.3741, rect), control2: pt(0.2334, 0.3659, rect))
                p.addCurve(to: pt(0.2440, 0.3638, rect), control1: pt(0.2391, 0.3639, rect), control2: pt(0.2417, 0.3634, rect))
                p.addCurve(to: pt(0.2871, 0.3806, rect), control1: pt(0.2522, 0.3717, rect), control2: pt(0.2871, 0.3806, rect))
                p.addLine(to: pt(0.2881, 0.3654, rect))
                p.addCurve(to: pt(0.2673, 0.3498, rect), control1: pt(0.2881, 0.3654, rect), control2: pt(0.2646, 0.3568, rect))
                p.addCurve(to: pt(0.3092, 0.3142, rect), control1: pt(0.2700, 0.3427, rect), control2: pt(0.3029, 0.3278, rect))
                p.closeSubpath()
                p.move(to: pt(0.7088, 0.3142, rect))
                p.addCurve(to: pt(0.7145, 0.2488, rect), control1: pt(0.7024, 0.3006, rect), control2: pt(0.7031, 0.2651, rect))
                p.addCurve(to: pt(0.7179, 0.2498, rect), control1: pt(0.7145, 0.2488, rect), control2: pt(0.7155, 0.2487, rect))
                p.addLine(to: pt(0.7179, 0.2497, rect))
                p.addCurve(to: pt(0.7323, 0.2567, rect), control1: pt(0.7179, 0.2497, rect), control2: pt(0.7239, 0.2533, rect))
                p.addCurve(to: pt(0.8081, 0.3091, rect), control1: pt(0.7407, 0.2602, rect), control2: pt(0.7776, 0.2797, rect))
                p.addCurve(to: pt(0.8232, 0.3581, rect), control1: pt(0.8081, 0.3091, rect), control2: pt(0.8189, 0.3311, rect))
                p.addCurve(to: pt(0.8054, 0.3741, rect), control1: pt(0.8232, 0.3581, rect), control2: pt(0.8191, 0.3640, rect))
                p.addCurve(to: pt(0.7789, 0.3639, rect), control1: pt(0.8054, 0.3741, rect), control2: pt(0.7846, 0.3659, rect))
                p.addCurve(to: pt(0.7741, 0.3638, rect), control1: pt(0.7789, 0.3639, rect), control2: pt(0.7763, 0.3634, rect))
                p.addCurve(to: pt(0.7309, 0.3806, rect), control1: pt(0.7658, 0.3717, rect), control2: pt(0.7309, 0.3806, rect))
                p.addLine(to: pt(0.7299, 0.3654, rect))
                p.addCurve(to: pt(0.7507, 0.3498, rect), control1: pt(0.7299, 0.3654, rect), control2: pt(0.7534, 0.3568, rect))
                p.addCurve(to: pt(0.7088, 0.3142, rect), control1: pt(0.7481, 0.3427, rect), control2: pt(0.7152, 0.3278, rect))
                p.closeSubpath()
            }
        }

        // 前腕筋群（4パーツ: muscle-22, muscle-44, muscle-6, muscle-28）
        static func forearms(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: pt(0.2097, 0.3753, rect))
                p.addCurve(to: pt(0.1860, 0.3520, rect), control1: pt(0.1970, 0.3668, rect), control2: pt(0.1898, 0.3578, rect))
                p.addCurve(to: pt(0.1851, 0.3551, rect), control1: pt(0.1858, 0.3535, rect), control2: pt(0.1854, 0.3545, rect))
                p.addCurve(to: pt(0.1631, 0.3835, rect), control1: pt(0.1823, 0.3595, rect), control2: pt(0.1756, 0.3621, rect))
                p.addCurve(to: pt(0.1624, 0.3930, rect), control1: pt(0.1624, 0.3876, rect), control2: pt(0.1621, 0.3910, rect))
                p.addCurve(to: pt(0.1594, 0.4763, rect), control1: pt(0.1634, 0.4006, rect), control2: pt(0.1594, 0.4763, rect))
                p.addCurve(to: pt(0.2022, 0.4091, rect), control1: pt(0.1629, 0.4645, rect), control2: pt(0.1921, 0.4295, rect))
                p.addCurve(to: pt(0.2097, 0.3753, rect), control1: pt(0.2122, 0.3887, rect), control2: pt(0.2097, 0.3753, rect))
                p.closeSubpath()
                p.move(to: pt(0.8083, 0.3753, rect))
                p.addCurve(to: pt(0.8320, 0.3520, rect), control1: pt(0.8210, 0.3668, rect), control2: pt(0.8283, 0.3578, rect))
                p.addCurve(to: pt(0.8330, 0.3551, rect), control1: pt(0.8323, 0.3535, rect), control2: pt(0.8326, 0.3545, rect))
                p.addCurve(to: pt(0.8549, 0.3835, rect), control1: pt(0.8357, 0.3595, rect), control2: pt(0.8424, 0.3621, rect))
                p.addCurve(to: pt(0.8556, 0.3930, rect), control1: pt(0.8556, 0.3876, rect), control2: pt(0.8559, 0.3910, rect))
                p.addCurve(to: pt(0.8586, 0.4763, rect), control1: pt(0.8546, 0.4006, rect), control2: pt(0.8586, 0.4763, rect))
                p.addCurve(to: pt(0.8158, 0.4091, rect), control1: pt(0.8551, 0.4645, rect), control2: pt(0.8259, 0.4295, rect))
                p.addCurve(to: pt(0.8083, 0.3753, rect), control1: pt(0.8058, 0.3887, rect), control2: pt(0.8083, 0.3753, rect))
                p.closeSubpath()
                p.move(to: pt(0.2122, 0.3777, rect))
                p.addCurve(to: pt(0.2203, 0.3732, rect), control1: pt(0.2122, 0.3777, rect), control2: pt(0.2141, 0.3746, rect))
                p.addCurve(to: pt(0.2404, 0.3657, rect), control1: pt(0.2266, 0.3717, rect), control2: pt(0.2404, 0.3657, rect))
                p.addCurve(to: pt(0.2862, 0.3825, rect), control1: pt(0.2404, 0.3657, rect), control2: pt(0.2555, 0.3755, rect))
                p.addCurve(to: pt(0.2742, 0.4223, rect), control1: pt(0.2862, 0.3825, rect), control2: pt(0.2872, 0.4109, rect))
                p.addCurve(to: pt(0.2269, 0.4855, rect), control1: pt(0.2611, 0.4338, rect), control2: pt(0.2269, 0.4855, rect))
                p.addCurve(to: pt(0.1804, 0.4876, rect), control1: pt(0.2269, 0.4855, rect), control2: pt(0.1984, 0.4884, rect))
                p.addCurve(to: pt(0.1609, 0.4855, rect), control1: pt(0.1669, 0.4870, rect), control2: pt(0.1609, 0.4855, rect))
                p.addCurve(to: pt(0.1750, 0.4550, rect), control1: pt(0.1609, 0.4855, rect), control2: pt(0.1690, 0.4631, rect))
                p.addCurve(to: pt(0.2122, 0.3777, rect), control1: pt(0.1810, 0.4470, rect), control2: pt(0.2208, 0.4041, rect))
                p.closeSubpath()
                p.move(to: pt(0.8058, 0.3777, rect))
                p.addCurve(to: pt(0.7977, 0.3732, rect), control1: pt(0.8058, 0.3777, rect), control2: pt(0.8039, 0.3746, rect))
                p.addCurve(to: pt(0.7776, 0.3657, rect), control1: pt(0.7914, 0.3717, rect), control2: pt(0.7776, 0.3657, rect))
                p.addCurve(to: pt(0.7318, 0.3825, rect), control1: pt(0.7776, 0.3657, rect), control2: pt(0.7625, 0.3755, rect))
                p.addCurve(to: pt(0.7439, 0.4223, rect), control1: pt(0.7318, 0.3825, rect), control2: pt(0.7308, 0.4109, rect))
                p.addCurve(to: pt(0.7911, 0.4855, rect), control1: pt(0.7569, 0.4338, rect), control2: pt(0.7911, 0.4855, rect))
                p.addCurve(to: pt(0.8377, 0.4876, rect), control1: pt(0.7911, 0.4855, rect), control2: pt(0.8196, 0.4884, rect))
                p.addCurve(to: pt(0.8571, 0.4855, rect), control1: pt(0.8511, 0.4870, rect), control2: pt(0.8571, 0.4855, rect))
                p.addCurve(to: pt(0.8430, 0.4550, rect), control1: pt(0.8571, 0.4855, rect), control2: pt(0.8491, 0.4631, rect))
                p.addCurve(to: pt(0.8058, 0.3777, rect), control1: pt(0.8370, 0.4470, rect), control2: pt(0.7972, 0.4041, rect))
                p.closeSubpath()
            }
        }

        // 腹直筋（6パーツ: muscle-10, muscle-32, muscle-11, muscle-33, muscle-12, muscle-34）
        static func rectusAbdominis(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: pt(0.5002, 0.2848, rect))
                p.addCurve(to: pt(0.5057, 0.2908, rect), control1: pt(0.5002, 0.2848, rect), control2: pt(0.5057, 0.2885, rect))
                p.addCurve(to: pt(0.5057, 0.3071, rect), control1: pt(0.5057, 0.2932, rect), control2: pt(0.5057, 0.3071, rect))
                p.addCurve(to: pt(0.4966, 0.3129, rect), control1: pt(0.5057, 0.3071, rect), control2: pt(0.5052, 0.3105, rect))
                p.addCurve(to: pt(0.4232, 0.3285, rect), control1: pt(0.4881, 0.3152, rect), control2: pt(0.4272, 0.3268, rect))
                p.addCurve(to: pt(0.4075, 0.3300, rect), control1: pt(0.4191, 0.3303, rect), control2: pt(0.4106, 0.3315, rect))
                p.addCurve(to: pt(0.4015, 0.3193, rect), control1: pt(0.4045, 0.3285, rect), control2: pt(0.4015, 0.3253, rect))
                p.addCurve(to: pt(0.4201, 0.2904, rect), control1: pt(0.4015, 0.3133, rect), control2: pt(0.3985, 0.2981, rect))
                p.addCurve(to: pt(0.5002, 0.2848, rect), control1: pt(0.4418, 0.2827, rect), control2: pt(0.4901, 0.2829, rect))
                p.closeSubpath()
                p.move(to: pt(0.5179, 0.2848, rect))
                p.addCurve(to: pt(0.5123, 0.2908, rect), control1: pt(0.5179, 0.2848, rect), control2: pt(0.5123, 0.2885, rect))
                p.addCurve(to: pt(0.5123, 0.3071, rect), control1: pt(0.5123, 0.2932, rect), control2: pt(0.5123, 0.3071, rect))
                p.addCurve(to: pt(0.5214, 0.3129, rect), control1: pt(0.5123, 0.3071, rect), control2: pt(0.5128, 0.3105, rect))
                p.addCurve(to: pt(0.5949, 0.3285, rect), control1: pt(0.5299, 0.3152, rect), control2: pt(0.5908, 0.3268, rect))
                p.addCurve(to: pt(0.6105, 0.3300, rect), control1: pt(0.5989, 0.3303, rect), control2: pt(0.6075, 0.3315, rect))
                p.addCurve(to: pt(0.6165, 0.3193, rect), control1: pt(0.6135, 0.3285, rect), control2: pt(0.6165, 0.3253, rect))
                p.addCurve(to: pt(0.5979, 0.2904, rect), control1: pt(0.6165, 0.3133, rect), control2: pt(0.6195, 0.2981, rect))
                p.addCurve(to: pt(0.5179, 0.2848, rect), control1: pt(0.5762, 0.2827, rect), control2: pt(0.5279, 0.2829, rect))
                p.closeSubpath()
                p.move(to: pt(0.5012, 0.3223, rect))
                p.addCurve(to: pt(0.4916, 0.3178, rect), control1: pt(0.5012, 0.3223, rect), control2: pt(0.4997, 0.3185, rect))
                p.addCurve(to: pt(0.4654, 0.3221, rect), control1: pt(0.4836, 0.3172, rect), control2: pt(0.4654, 0.3221, rect))
                p.addLine(to: pt(0.4166, 0.3341, rect))
                p.addCurve(to: pt(0.4106, 0.3348, rect), control1: pt(0.4166, 0.3341, rect), control2: pt(0.4126, 0.3348, rect))
                p.addCurve(to: pt(0.4091, 0.3453, rect), control1: pt(0.4086, 0.3348, rect), control2: pt(0.4091, 0.3440, rect))
                p.addCurve(to: pt(0.4126, 0.3532, rect), control1: pt(0.4091, 0.3465, rect), control2: pt(0.4091, 0.3510, rect))
                p.addCurve(to: pt(0.4388, 0.3500, rect), control1: pt(0.4161, 0.3553, rect), control2: pt(0.4322, 0.3510, rect))
                p.addCurve(to: pt(0.4911, 0.3463, rect), control1: pt(0.4453, 0.3489, rect), control2: pt(0.4775, 0.3457, rect))
                p.addCurve(to: pt(0.5037, 0.3414, rect), control1: pt(0.5047, 0.3470, rect), control2: pt(0.5037, 0.3414, rect))
                p.addCurve(to: pt(0.5012, 0.3223, rect), control1: pt(0.5037, 0.3414, rect), control2: pt(0.5047, 0.3264, rect))
                p.closeSubpath()
                p.move(to: pt(0.5168, 0.3223, rect))
                p.addCurve(to: pt(0.5264, 0.3178, rect), control1: pt(0.5168, 0.3223, rect), control2: pt(0.5184, 0.3185, rect))
                p.addCurve(to: pt(0.5526, 0.3221, rect), control1: pt(0.5345, 0.3172, rect), control2: pt(0.5526, 0.3221, rect))
                p.addLine(to: pt(0.6014, 0.3341, rect))
                p.addCurve(to: pt(0.6075, 0.3348, rect), control1: pt(0.6014, 0.3341, rect), control2: pt(0.6054, 0.3348, rect))
                p.addCurve(to: pt(0.6090, 0.3453, rect), control1: pt(0.6095, 0.3348, rect), control2: pt(0.6090, 0.3440, rect))
                p.addCurve(to: pt(0.6054, 0.3532, rect), control1: pt(0.6090, 0.3465, rect), control2: pt(0.6090, 0.3510, rect))
                p.addCurve(to: pt(0.5793, 0.3500, rect), control1: pt(0.6019, 0.3553, rect), control2: pt(0.5858, 0.3510, rect))
                p.addCurve(to: pt(0.5269, 0.3463, rect), control1: pt(0.5727, 0.3489, rect), control2: pt(0.5405, 0.3457, rect))
                p.addCurve(to: pt(0.5143, 0.3414, rect), control1: pt(0.5133, 0.3470, rect), control2: pt(0.5143, 0.3414, rect))
                p.addCurve(to: pt(0.5168, 0.3223, rect), control1: pt(0.5143, 0.3414, rect), control2: pt(0.5133, 0.3264, rect))
                p.closeSubpath()
                p.move(to: pt(0.4836, 0.3493, rect))
                p.addCurve(to: pt(0.5037, 0.3530, rect), control1: pt(0.4836, 0.3493, rect), control2: pt(0.5012, 0.3487, rect))
                p.addCurve(to: pt(0.5042, 0.3697, rect), control1: pt(0.5062, 0.3573, rect), control2: pt(0.5047, 0.3678, rect))
                p.addCurve(to: pt(0.4841, 0.3800, rect), control1: pt(0.5037, 0.3716, rect), control2: pt(0.4941, 0.3783, rect))
                p.addCurve(to: pt(0.4272, 0.3819, rect), control1: pt(0.4740, 0.3817, rect), control2: pt(0.4483, 0.3800, rect))
                p.addCurve(to: pt(0.4156, 0.3789, rect), control1: pt(0.4272, 0.3819, rect), control2: pt(0.4161, 0.3834, rect))
                p.addCurve(to: pt(0.4146, 0.3590, rect), control1: pt(0.4151, 0.3744, rect), control2: pt(0.4116, 0.3607, rect))
                p.addCurve(to: pt(0.4836, 0.3493, rect), control1: pt(0.4176, 0.3573, rect), control2: pt(0.4569, 0.3502, rect))
                p.closeSubpath()
                p.move(to: pt(0.5345, 0.3493, rect))
                p.addCurve(to: pt(0.5143, 0.3530, rect), control1: pt(0.5345, 0.3493, rect), control2: pt(0.5168, 0.3487, rect))
                p.addCurve(to: pt(0.5138, 0.3697, rect), control1: pt(0.5118, 0.3573, rect), control2: pt(0.5133, 0.3678, rect))
                p.addCurve(to: pt(0.5340, 0.3800, rect), control1: pt(0.5143, 0.3716, rect), control2: pt(0.5239, 0.3783, rect))
                p.addCurve(to: pt(0.5908, 0.3819, rect), control1: pt(0.5440, 0.3817, rect), control2: pt(0.5697, 0.3800, rect))
                p.addCurve(to: pt(0.6024, 0.3789, rect), control1: pt(0.5908, 0.3819, rect), control2: pt(0.6019, 0.3834, rect))
                p.addCurve(to: pt(0.6034, 0.3590, rect), control1: pt(0.6029, 0.3744, rect), control2: pt(0.6064, 0.3607, rect))
                p.addCurve(to: pt(0.5345, 0.3493, rect), control1: pt(0.6004, 0.3573, rect), control2: pt(0.5611, 0.3502, rect))
                p.closeSubpath()
            }
        }

        // 腹斜筋（4パーツ: muscle-9, muscle-31, muscle-13, muscle-35）
        static func obliques(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: pt(0.3544, 0.3829, rect))
                p.addCurve(to: pt(0.3955, 0.3914, rect), control1: pt(0.3544, 0.3829, rect), control2: pt(0.3597, 0.3865, rect))
                p.addCurve(to: pt(0.4055, 0.4025, rect), control1: pt(0.3955, 0.3914, rect), control2: pt(0.4060, 0.3941, rect))
                p.addCurve(to: pt(0.4156, 0.4450, rect), control1: pt(0.4050, 0.4108, rect), control2: pt(0.4081, 0.4369, rect))
                p.addCurve(to: pt(0.3460, 0.4129, rect), control1: pt(0.4156, 0.4450, rect), control2: pt(0.3676, 0.4278, rect))
                p.addCurve(to: pt(0.3507, 0.3886, rect), control1: pt(0.3460, 0.4129, rect), control2: pt(0.3497, 0.3915, rect))
                p.addCurve(to: pt(0.3544, 0.3829, rect), control1: pt(0.3517, 0.3857, rect), control2: pt(0.3510, 0.3856, rect))
                p.closeSubpath()
                p.move(to: pt(0.6637, 0.3829, rect))
                p.addCurve(to: pt(0.6226, 0.3914, rect), control1: pt(0.6637, 0.3829, rect), control2: pt(0.6583, 0.3865, rect))
                p.addCurve(to: pt(0.6125, 0.4025, rect), control1: pt(0.6226, 0.3914, rect), control2: pt(0.6120, 0.3941, rect))
                p.addCurve(to: pt(0.6024, 0.4450, rect), control1: pt(0.6130, 0.4108, rect), control2: pt(0.6100, 0.4369, rect))
                p.addCurve(to: pt(0.6720, 0.4129, rect), control1: pt(0.6024, 0.4450, rect), control2: pt(0.6504, 0.4278, rect))
                p.addCurve(to: pt(0.6673, 0.3886, rect), control1: pt(0.6720, 0.4129, rect), control2: pt(0.6684, 0.3915, rect))
                p.addCurve(to: pt(0.6637, 0.3829, rect), control1: pt(0.6663, 0.3857, rect), control2: pt(0.6670, 0.3856, rect))
                p.closeSubpath()
                p.move(to: pt(0.4810, 0.3834, rect))
                p.addCurve(to: pt(0.5012, 0.3928, rect), control1: pt(0.4810, 0.3834, rect), control2: pt(0.5007, 0.3885, rect))
                p.addCurve(to: pt(0.5022, 0.4450, rect), control1: pt(0.5017, 0.3971, rect), control2: pt(0.5022, 0.4332, rect))
                p.addCurve(to: pt(0.5012, 0.5021, rect), control1: pt(0.5022, 0.4539, rect), control2: pt(0.5045, 0.4998, rect))
                p.addCurve(to: pt(0.4810, 0.5007, rect), control1: pt(0.5012, 0.5021, rect), control2: pt(0.4871, 0.5012, rect))
                p.addCurve(to: pt(0.4624, 0.4918, rect), control1: pt(0.4750, 0.5001, rect), control2: pt(0.4643, 0.4935, rect))
                p.addCurve(to: pt(0.4227, 0.4407, rect), control1: pt(0.4569, 0.4866, rect), control2: pt(0.4332, 0.4624, rect))
                p.addCurve(to: pt(0.4151, 0.3971, rect), control1: pt(0.4197, 0.4346, rect), control2: pt(0.4111, 0.4040, rect))
                p.addCurve(to: pt(0.4292, 0.3843, rect), control1: pt(0.4191, 0.3903, rect), control2: pt(0.4218, 0.3845, rect))
                p.addCurve(to: pt(0.4810, 0.3834, rect), control1: pt(0.4366, 0.3840, rect), control2: pt(0.4732, 0.3846, rect))
                p.closeSubpath()
                p.move(to: pt(0.5370, 0.3834, rect))
                p.addCurve(to: pt(0.5168, 0.3928, rect), control1: pt(0.5370, 0.3834, rect), control2: pt(0.5173, 0.3885, rect))
                p.addCurve(to: pt(0.5158, 0.4450, rect), control1: pt(0.5163, 0.3971, rect), control2: pt(0.5158, 0.4332, rect))
                p.addCurve(to: pt(0.5168, 0.5021, rect), control1: pt(0.5158, 0.4539, rect), control2: pt(0.5135, 0.4998, rect))
                p.addCurve(to: pt(0.5370, 0.5007, rect), control1: pt(0.5168, 0.5021, rect), control2: pt(0.5309, 0.5012, rect))
                p.addCurve(to: pt(0.5556, 0.4918, rect), control1: pt(0.5430, 0.5001, rect), control2: pt(0.5537, 0.4935, rect))
                p.addCurve(to: pt(0.5954, 0.4407, rect), control1: pt(0.5611, 0.4866, rect), control2: pt(0.5848, 0.4624, rect))
                p.addCurve(to: pt(0.6029, 0.3971, rect), control1: pt(0.5983, 0.4346, rect), control2: pt(0.6069, 0.4040, rect))
                p.addCurve(to: pt(0.5888, 0.3843, rect), control1: pt(0.5989, 0.3903, rect), control2: pt(0.5962, 0.3845, rect))
                p.addCurve(to: pt(0.5370, 0.3834, rect), control1: pt(0.5814, 0.3840, rect), control2: pt(0.5449, 0.3846, rect))
                p.closeSubpath()
            }
        }

        // 大腿四頭筋（4パーツ: muscle-20, muscle-42, muscle-21, muscle-43）
        static func quadriceps(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: pt(0.4781, 0.6919, rect))
                p.addCurve(to: pt(0.4948, 0.6029, rect), control1: pt(0.4780, 0.6775, rect), control2: pt(0.4929, 0.6159, rect))
                p.addCurve(to: pt(0.4943, 0.5203, rect), control1: pt(0.4967, 0.5899, rect), control2: pt(0.4943, 0.5203, rect))
                p.addCurve(to: pt(0.4116, 0.4573, rect), control1: pt(0.4545, 0.5096, rect), control2: pt(0.4277, 0.4692, rect))
                p.addCurve(to: pt(0.3741, 0.4394, rect), control1: pt(0.4045, 0.4521, rect), control2: pt(0.3819, 0.4421, rect))
                p.addCurve(to: pt(0.3594, 0.4343, rect), control1: pt(0.3696, 0.4379, rect), control2: pt(0.3625, 0.4360, rect))
                p.addCurve(to: pt(0.3451, 0.4200, rect), control1: pt(0.3527, 0.4306, rect), control2: pt(0.3451, 0.4200, rect))
                p.addCurve(to: pt(0.3471, 0.4436, rect), control1: pt(0.3371, 0.4238, rect), control2: pt(0.3403, 0.4277, rect))
                p.addCurve(to: pt(0.3565, 0.4600, rect), control1: pt(0.3505, 0.4513, rect), control2: pt(0.3512, 0.4573, rect))
                p.addCurve(to: pt(0.4398, 0.5442, rect), control1: pt(0.4212, 0.4923, rect), control2: pt(0.4295, 0.5260, rect))
                p.addCurve(to: pt(0.4634, 0.6223, rect), control1: pt(0.4458, 0.5550, rect), control2: pt(0.4563, 0.5981, rect))
                p.addCurve(to: pt(0.4695, 0.6647, rect), control1: pt(0.4658, 0.6302, rect), control2: pt(0.4693, 0.6464, rect))
                p.addCurve(to: pt(0.4530, 0.6980, rect), control1: pt(0.4686, 0.6912, rect), control2: pt(0.4546, 0.6957, rect))
                p.addCurve(to: pt(0.4518, 0.7233, rect), control1: pt(0.4514, 0.7005, rect), control2: pt(0.4464, 0.7136, rect))
                p.addCurve(to: pt(0.4651, 0.7345, rect), control1: pt(0.4572, 0.7330, rect), control2: pt(0.4651, 0.7345, rect))
                p.addCurve(to: pt(0.4781, 0.6919, rect), control1: pt(0.4651, 0.7345, rect), control2: pt(0.4782, 0.6986, rect))
                p.closeSubpath()
                p.move(to: pt(0.5399, 0.6919, rect))
                p.addCurve(to: pt(0.5232, 0.6029, rect), control1: pt(0.5400, 0.6775, rect), control2: pt(0.5251, 0.6159, rect))
                p.addCurve(to: pt(0.5237, 0.5203, rect), control1: pt(0.5213, 0.5899, rect), control2: pt(0.5237, 0.5203, rect))
                p.addCurve(to: pt(0.6064, 0.4573, rect), control1: pt(0.5635, 0.5096, rect), control2: pt(0.5903, 0.4692, rect))
                p.addCurve(to: pt(0.6439, 0.4394, rect), control1: pt(0.6135, 0.4521, rect), control2: pt(0.6361, 0.4421, rect))
                p.addCurve(to: pt(0.6586, 0.4343, rect), control1: pt(0.6484, 0.4379, rect), control2: pt(0.6555, 0.4360, rect))
                p.addCurve(to: pt(0.6729, 0.4200, rect), control1: pt(0.6653, 0.4306, rect), control2: pt(0.6729, 0.4200, rect))
                p.addCurve(to: pt(0.6709, 0.4436, rect), control1: pt(0.6809, 0.4238, rect), control2: pt(0.6777, 0.4277, rect))
                p.addCurve(to: pt(0.6615, 0.4600, rect), control1: pt(0.6675, 0.4513, rect), control2: pt(0.6668, 0.4573, rect))
                p.addCurve(to: pt(0.5783, 0.5442, rect), control1: pt(0.5968, 0.4923, rect), control2: pt(0.5885, 0.5260, rect))
                p.addCurve(to: pt(0.5546, 0.6223, rect), control1: pt(0.5722, 0.5550, rect), control2: pt(0.5618, 0.5981, rect))
                p.addCurve(to: pt(0.5485, 0.6647, rect), control1: pt(0.5523, 0.6302, rect), control2: pt(0.5487, 0.6464, rect))
                p.addCurve(to: pt(0.5650, 0.6980, rect), control1: pt(0.5494, 0.6912, rect), control2: pt(0.5634, 0.6957, rect))
                p.addCurve(to: pt(0.5662, 0.7233, rect), control1: pt(0.5667, 0.7005, rect), control2: pt(0.5716, 0.7136, rect))
                p.addCurve(to: pt(0.5529, 0.7345, rect), control1: pt(0.5609, 0.7330, rect), control2: pt(0.5529, 0.7345, rect))
                p.addCurve(to: pt(0.5399, 0.6919, rect), control1: pt(0.5529, 0.7345, rect), control2: pt(0.5398, 0.6986, rect))
                p.closeSubpath()
                p.move(to: pt(0.4384, 0.5547, rect))
                p.addCurve(to: pt(0.4567, 0.6234, rect), control1: pt(0.4384, 0.5547, rect), control2: pt(0.4513, 0.6054, rect))
                p.addCurve(to: pt(0.4317, 0.7004, rect), control1: pt(0.4609, 0.6374, rect), control2: pt(0.4810, 0.6968, rect))
                p.addCurve(to: pt(0.3867, 0.6822, rect), control1: pt(0.4009, 0.6976, rect), control2: pt(0.3908, 0.6864, rect))
                p.addCurve(to: pt(0.3693, 0.6712, rect), control1: pt(0.3827, 0.6780, rect), control2: pt(0.3693, 0.6712, rect))
                p.addCurve(to: pt(0.3388, 0.6549, rect), control1: pt(0.3445, 0.6634, rect), control2: pt(0.3388, 0.6549, rect))
                p.addCurve(to: pt(0.3116, 0.5160, rect), control1: pt(0.3182, 0.6331, rect), control2: pt(0.2990, 0.5816, rect))
                p.addCurve(to: pt(0.3223, 0.5009, rect), control1: pt(0.3116, 0.5160, rect), control2: pt(0.3171, 0.5058, rect))
                p.addCurve(to: pt(0.3539, 0.4633, rect), control1: pt(0.3377, 0.4865, rect), control2: pt(0.3498, 0.4683, rect))
                p.addCurve(to: pt(0.4384, 0.5547, rect), control1: pt(0.3539, 0.4633, rect), control2: pt(0.4049, 0.4776, rect))
                p.closeSubpath()
                p.move(to: pt(0.5796, 0.5547, rect))
                p.addCurve(to: pt(0.5613, 0.6234, rect), control1: pt(0.5796, 0.5547, rect), control2: pt(0.5667, 0.6054, rect))
                p.addCurve(to: pt(0.5863, 0.7004, rect), control1: pt(0.5571, 0.6374, rect), control2: pt(0.5370, 0.6968, rect))
                p.addCurve(to: pt(0.6313, 0.6822, rect), control1: pt(0.6172, 0.6976, rect), control2: pt(0.6272, 0.6864, rect))
                p.addCurve(to: pt(0.6487, 0.6712, rect), control1: pt(0.6353, 0.6780, rect), control2: pt(0.6487, 0.6712, rect))
                p.addCurve(to: pt(0.6792, 0.6549, rect), control1: pt(0.6736, 0.6634, rect), control2: pt(0.6792, 0.6549, rect))
                p.addCurve(to: pt(0.7064, 0.5160, rect), control1: pt(0.6998, 0.6331, rect), control2: pt(0.7190, 0.5816, rect))
                p.addCurve(to: pt(0.6957, 0.5009, rect), control1: pt(0.7064, 0.5160, rect), control2: pt(0.7009, 0.5058, rect))
                p.addCurve(to: pt(0.6642, 0.4633, rect), control1: pt(0.6803, 0.4865, rect), control2: pt(0.6682, 0.4683, rect))
                p.addCurve(to: pt(0.5796, 0.5547, rect), control1: pt(0.6642, 0.4633, rect), control2: pt(0.6132, 0.4776, rect))
                p.closeSubpath()
            }
        }

        // 腸腰筋（2パーツ: muscle-23, muscle-45）
        static func hipFlexors(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: pt(0.3340, 0.4276, rect))
                p.addCurve(to: pt(0.3426, 0.4600, rect), control1: pt(0.3340, 0.4276, rect), control2: pt(0.3426, 0.4530, rect))
                p.addCurve(to: pt(0.3382, 0.4757, rect), control1: pt(0.3426, 0.4669, rect), control2: pt(0.3410, 0.4724, rect))
                p.addCurve(to: pt(0.3045, 0.5163, rect), control1: pt(0.3355, 0.4791, rect), control2: pt(0.3102, 0.5063, rect))
                p.addCurve(to: pt(0.3520, 0.6745, rect), control1: pt(0.2987, 0.5263, rect), control2: pt(0.2865, 0.6410, rect))
                p.addCurve(to: pt(0.3460, 0.6941, rect), control1: pt(0.3520, 0.6745, rect), control2: pt(0.3530, 0.6886, rect))
                p.addCurve(to: pt(0.3399, 0.6909, rect), control1: pt(0.3389, 0.6997, rect), control2: pt(0.3406, 0.6924, rect))
                p.addCurve(to: pt(0.3325, 0.6744, rect), control1: pt(0.3379, 0.6861, rect), control2: pt(0.3360, 0.6804, rect))
                p.addCurve(to: pt(0.2896, 0.5193, rect), control1: pt(0.3285, 0.6674, rect), control2: pt(0.2693, 0.6064, rect))
                p.addCurve(to: pt(0.3340, 0.4276, rect), control1: pt(0.3067, 0.4458, rect), control2: pt(0.3340, 0.4276, rect))
                p.closeSubpath()
                p.move(to: pt(0.6840, 0.4276, rect))
                p.addCurve(to: pt(0.6754, 0.4600, rect), control1: pt(0.6840, 0.4276, rect), control2: pt(0.6755, 0.4530, rect))
                p.addCurve(to: pt(0.6798, 0.4757, rect), control1: pt(0.6754, 0.4669, rect), control2: pt(0.6770, 0.4724, rect))
                p.addCurve(to: pt(0.7135, 0.5163, rect), control1: pt(0.6825, 0.4791, rect), control2: pt(0.7078, 0.5063, rect))
                p.addCurve(to: pt(0.6660, 0.6745, rect), control1: pt(0.7193, 0.5263, rect), control2: pt(0.7315, 0.6410, rect))
                p.addCurve(to: pt(0.6721, 0.6941, rect), control1: pt(0.6660, 0.6745, rect), control2: pt(0.6650, 0.6886, rect))
                p.addCurve(to: pt(0.6781, 0.6909, rect), control1: pt(0.6792, 0.6997, rect), control2: pt(0.6774, 0.6924, rect))
                p.addCurve(to: pt(0.6855, 0.6744, rect), control1: pt(0.6801, 0.6861, rect), control2: pt(0.6820, 0.6804, rect))
                p.addCurve(to: pt(0.7284, 0.5193, rect), control1: pt(0.6895, 0.6674, rect), control2: pt(0.7487, 0.6064, rect))
                p.addCurve(to: pt(0.6840, 0.4276, rect), control1: pt(0.7113, 0.4458, rect), control2: pt(0.6840, 0.4276, rect))
                p.closeSubpath()
            }
        }

        // 腓腹筋（2パーツ: muscle-15, muscle-37）
        static func gastrocnemius(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: pt(0.3613, 0.7288, rect))
                p.addCurve(to: pt(0.3935, 0.7584, rect), control1: pt(0.3613, 0.7288, rect), control2: pt(0.3839, 0.7407, rect))
                p.addCurve(to: pt(0.4576, 0.9246, rect), control1: pt(0.3997, 0.7699, rect), control2: pt(0.4576, 0.9246, rect))
                p.addCurve(to: pt(0.4353, 0.9118, rect), control1: pt(0.4576, 0.9246, rect), control2: pt(0.4512, 0.9299, rect))
                p.addCurve(to: pt(0.3837, 0.8425, rect), control1: pt(0.4194, 0.8936, rect), control2: pt(0.3892, 0.8502, rect))
                p.addCurve(to: pt(0.3592, 0.7888, rect), control1: pt(0.3782, 0.8348, rect), control2: pt(0.3625, 0.8135, rect))
                p.addCurve(to: pt(0.3613, 0.7288, rect), control1: pt(0.3558, 0.7641, rect), control2: pt(0.3492, 0.7290, rect))
                p.closeSubpath()
                p.move(to: pt(0.6567, 0.7288, rect))
                p.addCurve(to: pt(0.6246, 0.7584, rect), control1: pt(0.6567, 0.7288, rect), control2: pt(0.6341, 0.7407, rect))
                p.addCurve(to: pt(0.5604, 0.9246, rect), control1: pt(0.6183, 0.7699, rect), control2: pt(0.5604, 0.9246, rect))
                p.addCurve(to: pt(0.5827, 0.9118, rect), control1: pt(0.5604, 0.9246, rect), control2: pt(0.5668, 0.9299, rect))
                p.addCurve(to: pt(0.6343, 0.8425, rect), control1: pt(0.5986, 0.8936, rect), control2: pt(0.6288, 0.8502, rect))
                p.addCurve(to: pt(0.6589, 0.7888, rect), control1: pt(0.6399, 0.8348, rect), control2: pt(0.6555, 0.8135, rect))
                p.addCurve(to: pt(0.6567, 0.7288, rect), control1: pt(0.6622, 0.7641, rect), control2: pt(0.6688, 0.7290, rect))
                p.closeSubpath()
            }
        }

        // ヒラメ筋（2パーツ: muscle-16, muscle-38）
        static func soleus(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: pt(0.4131, 0.8972, rect))
                p.addCurve(to: pt(0.4217, 0.9336, rect), control1: pt(0.4131, 0.8972, rect), control2: pt(0.4340, 0.9306, rect))
                p.addCurve(to: pt(0.3979, 0.9144, rect), control1: pt(0.4094, 0.9366, rect), control2: pt(0.4051, 0.9262, rect))
                p.addCurve(to: pt(0.3765, 0.8738, rect), control1: pt(0.3906, 0.9027, rect), control2: pt(0.3765, 0.8738, rect))
                p.addCurve(to: pt(0.3438, 0.8066, rect), control1: pt(0.3765, 0.8738, rect), control2: pt(0.3462, 0.8160, rect))
                p.addCurve(to: pt(0.3477, 0.7354, rect), control1: pt(0.3415, 0.7971, rect), control2: pt(0.3414, 0.7545, rect))
                p.addCurve(to: pt(0.3577, 0.8095, rect), control1: pt(0.3477, 0.7354, rect), control2: pt(0.3451, 0.7878, rect))
                p.addCurve(to: pt(0.4131, 0.8972, rect), control1: pt(0.3703, 0.8311, rect), control2: pt(0.4131, 0.8972, rect))
                p.closeSubpath()
                p.move(to: pt(0.6049, 0.8972, rect))
                p.addCurve(to: pt(0.5963, 0.9336, rect), control1: pt(0.6049, 0.8972, rect), control2: pt(0.5840, 0.9306, rect))
                p.addCurve(to: pt(0.6202, 0.9144, rect), control1: pt(0.6086, 0.9366, rect), control2: pt(0.6129, 0.9262, rect))
                p.addCurve(to: pt(0.6415, 0.8738, rect), control1: pt(0.6274, 0.9027, rect), control2: pt(0.6415, 0.8738, rect))
                p.addCurve(to: pt(0.6742, 0.8066, rect), control1: pt(0.6415, 0.8738, rect), control2: pt(0.6718, 0.8160, rect))
                p.addCurve(to: pt(0.6703, 0.7354, rect), control1: pt(0.6766, 0.7971, rect), control2: pt(0.6766, 0.7545, rect))
                p.addCurve(to: pt(0.6603, 0.8095, rect), control1: pt(0.6703, 0.7354, rect), control2: pt(0.6729, 0.7878, rect))
                p.addCurve(to: pt(0.6049, 0.8972, rect), control1: pt(0.6477, 0.8311, rect), control2: pt(0.6049, 0.8972, rect))
                p.closeSubpath()
            }
        }

    }

    // MARK: - バックビュー

    enum Back {
        // 僧帽筋上部（2パーツ: bMuscle-0, bMuscle-18）
        static func trapsUpper(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: pt(0.3752, 0.1923, rect))
                p.addCurve(to: pt(0.3222, 0.1890, rect), control1: pt(0.3752, 0.1923, rect), control2: pt(0.3443, 0.1911, rect))
                p.addCurve(to: pt(0.2700, 0.1829, rect), control1: pt(0.3039, 0.1873, rect), control2: pt(0.2784, 0.1840, rect))
                p.addCurve(to: pt(0.2686, 0.1834, rect), control1: pt(0.2694, 0.1831, rect), control2: pt(0.2689, 0.1832, rect))
                p.addCurve(to: pt(0.2117, 0.2092, rect), control1: pt(0.2686, 0.1834, rect), control2: pt(0.2319, 0.1908, rect))
                p.addCurve(to: pt(0.2023, 0.2679, rect), control1: pt(0.1922, 0.2270, rect), control2: pt(0.1978, 0.2586, rect))
                p.addLine(to: pt(0.2054, 0.2667, rect))
                p.addCurve(to: pt(0.2342, 0.2282, rect), control1: pt(0.2054, 0.2667, rect), control2: pt(0.2228, 0.2380, rect))
                p.addCurve(to: pt(0.2987, 0.2079, rect), control1: pt(0.2456, 0.2183, rect), control2: pt(0.2792, 0.2097, rect))
                p.addCurve(to: pt(0.3664, 0.1977, rect), control1: pt(0.3181, 0.2061, rect), control2: pt(0.3477, 0.2019, rect))
                p.addCurve(to: pt(0.3752, 0.1923, rect), control1: pt(0.3852, 0.1935, rect), control2: pt(0.3752, 0.1923, rect))
                p.closeSubpath()
                p.move(to: pt(0.6235, 0.1923, rect))
                p.addCurve(to: pt(0.6766, 0.1890, rect), control1: pt(0.6235, 0.1923, rect), control2: pt(0.6544, 0.1911, rect))
                p.addCurve(to: pt(0.7287, 0.1829, rect), control1: pt(0.6948, 0.1873, rect), control2: pt(0.7203, 0.1840, rect))
                p.addCurve(to: pt(0.7301, 0.1834, rect), control1: pt(0.7293, 0.1831, rect), control2: pt(0.7298, 0.1832, rect))
                p.addCurve(to: pt(0.7870, 0.2092, rect), control1: pt(0.7301, 0.1834, rect), control2: pt(0.7668, 0.1908, rect))
                p.addCurve(to: pt(0.7964, 0.2679, rect), control1: pt(0.8065, 0.2270, rect), control2: pt(0.8009, 0.2586, rect))
                p.addLine(to: pt(0.7933, 0.2667, rect))
                p.addCurve(to: pt(0.7645, 0.2282, rect), control1: pt(0.7933, 0.2667, rect), control2: pt(0.7759, 0.2380, rect))
                p.addCurve(to: pt(0.7000, 0.2079, rect), control1: pt(0.7531, 0.2183, rect), control2: pt(0.7195, 0.2097, rect))
                p.addCurve(to: pt(0.6323, 0.1977, rect), control1: pt(0.6806, 0.2061, rect), control2: pt(0.6510, 0.2019, rect))
                p.addCurve(to: pt(0.6235, 0.1923, rect), control1: pt(0.6135, 0.1935, rect), control2: pt(0.6235, 0.1923, rect))
                p.closeSubpath()
            }
        }

        // 僧帽筋中部・下部（2パーツ: bMuscle-32, bMuscle-33）
        static func trapsMiddleLower(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: pt(0.4847, 0.2062, rect))
                p.addCurve(to: pt(0.4831, 0.2385, rect), control1: pt(0.4910, 0.2142, rect), control2: pt(0.4863, 0.2260, rect))
                p.addCurve(to: pt(0.4755, 0.2974, rect), control1: pt(0.4790, 0.2542, rect), control2: pt(0.4754, 0.2947, rect))
                p.addCurve(to: pt(0.4785, 0.3328, rect), control1: pt(0.4760, 0.3088, rect), control2: pt(0.4785, 0.3328, rect))
                p.addCurve(to: pt(0.4416, 0.3073, rect), control1: pt(0.4785, 0.3328, rect), control2: pt(0.4450, 0.3097, rect))
                p.addCurve(to: pt(0.4034, 0.2751, rect), control1: pt(0.4383, 0.3049, rect), control2: pt(0.4034, 0.2751, rect))
                p.addCurve(to: pt(0.3879, 0.2613, rect), control1: pt(0.4034, 0.2751, rect), control2: pt(0.3879, 0.2643, rect))
                p.addCurve(to: pt(0.4025, 0.2217, rect), control1: pt(0.3879, 0.2583, rect), control2: pt(0.3960, 0.2316, rect))
                p.addCurve(to: pt(0.4131, 0.2065, rect), control1: pt(0.4059, 0.2165, rect), control2: pt(0.4060, 0.2148, rect))
                p.addCurve(to: pt(0.4232, 0.1874, rect), control1: pt(0.4284, 0.1884, rect), control2: pt(0.4232, 0.1874, rect))
                p.addCurve(to: pt(0.4233, 0.1874, rect), control1: pt(0.4232, 0.1874, rect), control2: pt(0.4232, 0.1874, rect))
                p.addCurve(to: pt(0.4208, 0.1861, rect), control1: pt(0.4223, 0.1869, rect), control2: pt(0.4208, 0.1861, rect))
                p.addCurve(to: pt(0.4116, 0.1818, rect), control1: pt(0.4208, 0.1861, rect), control2: pt(0.4170, 0.1836, rect))
                p.addCurve(to: pt(0.3899, 0.1789, rect), control1: pt(0.4003, 0.1782, rect), control2: pt(0.3946, 0.1789, rect))
                p.addCurve(to: pt(0.3421, 0.1787, rect), control1: pt(0.3852, 0.1789, rect), control2: pt(0.3617, 0.1803, rect))
                p.addCurve(to: pt(0.3056, 0.1748, rect), control1: pt(0.3312, 0.1778, rect), control2: pt(0.3207, 0.1766, rect))
                p.addCurve(to: pt(0.3492, 0.1628, rect), control1: pt(0.3176, 0.1720, rect), control2: pt(0.3364, 0.1674, rect))
                p.addCurve(to: pt(0.4201, 0.1366, rect), control1: pt(0.3673, 0.1563, rect), control2: pt(0.4201, 0.1366, rect))
                p.addCurve(to: pt(0.4214, 0.1348, rect), control1: pt(0.4206, 0.1361, rect), control2: pt(0.4210, 0.1355, rect))
                p.addCurve(to: pt(0.4282, 0.1326, rect), control1: pt(0.4238, 0.1342, rect), control2: pt(0.4262, 0.1334, rect))
                p.addCurve(to: pt(0.4523, 0.1192, rect), control1: pt(0.4376, 0.1287, rect), control2: pt(0.4490, 0.1240, rect))
                p.addCurve(to: pt(0.4570, 0.1004, rect), control1: pt(0.4557, 0.1144, rect), control2: pt(0.4570, 0.1060, rect))
                p.addCurve(to: pt(0.4691, 0.0908, rect), control1: pt(0.4570, 0.0947, rect), control2: pt(0.4651, 0.0914, rect))
                p.addCurve(to: pt(0.4832, 0.0959, rect), control1: pt(0.4691, 0.0908, rect), control2: pt(0.4812, 0.0890, rect))
                p.addCurve(to: pt(0.4819, 0.1234, rect), control1: pt(0.4852, 0.1027, rect), control2: pt(0.4846, 0.1177, rect))
                p.addCurve(to: pt(0.4654, 0.1478, rect), control1: pt(0.4792, 0.1290, rect), control2: pt(0.4668, 0.1460, rect))
                p.addCurve(to: pt(0.4638, 0.1513, rect), control1: pt(0.4646, 0.1489, rect), control2: pt(0.4642, 0.1502, rect))
                p.addCurve(to: pt(0.4617, 0.1661, rect), control1: pt(0.4621, 0.1562, rect), control2: pt(0.4614, 0.1612, rect))
                p.addCurve(to: pt(0.4847, 0.2062, rect), control1: pt(0.4617, 0.1661, rect), control2: pt(0.4611, 0.1762, rect))
                p.closeSubpath()
                p.move(to: pt(0.5127, 0.2062, rect))
                p.addCurve(to: pt(0.5143, 0.2385, rect), control1: pt(0.5064, 0.2142, rect), control2: pt(0.5111, 0.2260, rect))
                p.addCurve(to: pt(0.5219, 0.2974, rect), control1: pt(0.5184, 0.2542, rect), control2: pt(0.5220, 0.2947, rect))
                p.addCurve(to: pt(0.5189, 0.3328, rect), control1: pt(0.5214, 0.3088, rect), control2: pt(0.5189, 0.3328, rect))
                p.addCurve(to: pt(0.5558, 0.3073, rect), control1: pt(0.5189, 0.3328, rect), control2: pt(0.5524, 0.3097, rect))
                p.addCurve(to: pt(0.5940, 0.2751, rect), control1: pt(0.5591, 0.3049, rect), control2: pt(0.5940, 0.2751, rect))
                p.addCurve(to: pt(0.6095, 0.2613, rect), control1: pt(0.5940, 0.2751, rect), control2: pt(0.6095, 0.2643, rect))
                p.addCurve(to: pt(0.5949, 0.2217, rect), control1: pt(0.6095, 0.2583, rect), control2: pt(0.6014, 0.2316, rect))
                p.addCurve(to: pt(0.5843, 0.2065, rect), control1: pt(0.5914, 0.2165, rect), control2: pt(0.5913, 0.2148, rect))
                p.addCurve(to: pt(0.5742, 0.1874, rect), control1: pt(0.5690, 0.1884, rect), control2: pt(0.5742, 0.1874, rect))
                p.addCurve(to: pt(0.5741, 0.1874, rect), control1: pt(0.5742, 0.1874, rect), control2: pt(0.5741, 0.1874, rect))
                p.addCurve(to: pt(0.5766, 0.1861, rect), control1: pt(0.5751, 0.1869, rect), control2: pt(0.5766, 0.1861, rect))
                p.addCurve(to: pt(0.5858, 0.1818, rect), control1: pt(0.5766, 0.1861, rect), control2: pt(0.5804, 0.1836, rect))
                p.addCurve(to: pt(0.6075, 0.1789, rect), control1: pt(0.5971, 0.1782, rect), control2: pt(0.6028, 0.1789, rect))
                p.addCurve(to: pt(0.6553, 0.1787, rect), control1: pt(0.6122, 0.1789, rect), control2: pt(0.6356, 0.1803, rect))
                p.addCurve(to: pt(0.6918, 0.1748, rect), control1: pt(0.6662, 0.1778, rect), control2: pt(0.6767, 0.1766, rect))
                p.addCurve(to: pt(0.6482, 0.1628, rect), control1: pt(0.6797, 0.1720, rect), control2: pt(0.6610, 0.1674, rect))
                p.addCurve(to: pt(0.5773, 0.1366, rect), control1: pt(0.6301, 0.1563, rect), control2: pt(0.5773, 0.1366, rect))
                p.addCurve(to: pt(0.5760, 0.1348, rect), control1: pt(0.5768, 0.1361, rect), control2: pt(0.5764, 0.1355, rect))
                p.addCurve(to: pt(0.5692, 0.1326, rect), control1: pt(0.5736, 0.1342, rect), control2: pt(0.5712, 0.1334, rect))
                p.addCurve(to: pt(0.5450, 0.1192, rect), control1: pt(0.5598, 0.1287, rect), control2: pt(0.5484, 0.1240, rect))
                p.addCurve(to: pt(0.5403, 0.1004, rect), control1: pt(0.5417, 0.1144, rect), control2: pt(0.5403, 0.1060, rect))
                p.addCurve(to: pt(0.5283, 0.0908, rect), control1: pt(0.5403, 0.0947, rect), control2: pt(0.5323, 0.0914, rect))
                p.addCurve(to: pt(0.5142, 0.0959, rect), control1: pt(0.5283, 0.0908, rect), control2: pt(0.5162, 0.0890, rect))
                p.addCurve(to: pt(0.5155, 0.1234, rect), control1: pt(0.5122, 0.1027, rect), control2: pt(0.5128, 0.1177, rect))
                p.addCurve(to: pt(0.5320, 0.1478, rect), control1: pt(0.5182, 0.1290, rect), control2: pt(0.5306, 0.1460, rect))
                p.addCurve(to: pt(0.5336, 0.1513, rect), control1: pt(0.5328, 0.1489, rect), control2: pt(0.5331, 0.1502, rect))
                p.addCurve(to: pt(0.5357, 0.1661, rect), control1: pt(0.5353, 0.1562, rect), control2: pt(0.5360, 0.1612, rect))
                p.addCurve(to: pt(0.5127, 0.2062, rect), control1: pt(0.5357, 0.1661, rect), control2: pt(0.5363, 0.1762, rect))
                p.closeSubpath()
            }
        }

        // 広背筋（2パーツ: bMuscle-4, bMuscle-34）
        static func lats(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: pt(0.4580, 0.4294, rect))
                p.addCurve(to: pt(0.4660, 0.4400, rect), control1: pt(0.4601, 0.4316, rect), control2: pt(0.4641, 0.4370, rect))
                p.addCurve(to: pt(0.4685, 0.4444, rect), control1: pt(0.4669, 0.4414, rect), control2: pt(0.4681, 0.4428, rect))
                p.addLine(to: pt(0.3902, 0.4214, rect))
                p.addCurve(to: pt(0.3829, 0.4039, rect), control1: pt(0.3902, 0.4214, rect), control2: pt(0.3889, 0.4109, rect))
                p.addCurve(to: pt(0.3474, 0.3738, rect), control1: pt(0.3768, 0.3970, rect), control2: pt(0.3484, 0.3759, rect))
                p.addCurve(to: pt(0.3285, 0.3617, rect), control1: pt(0.3468, 0.3725, rect), control2: pt(0.3362, 0.3662, rect))
                p.addCurve(to: pt(0.3215, 0.3469, rect), control1: pt(0.3271, 0.3566, rect), control2: pt(0.3246, 0.3510, rect))
                p.addCurve(to: pt(0.3120, 0.3275, rect), control1: pt(0.3168, 0.3408, rect), control2: pt(0.3133, 0.3314, rect))
                p.addCurve(to: pt(0.3147, 0.3240, rect), control1: pt(0.3125, 0.3270, rect), control2: pt(0.3133, 0.3261, rect))
                p.addCurve(to: pt(0.3202, 0.2997, rect), control1: pt(0.3172, 0.3200, rect), control2: pt(0.3197, 0.3084, rect))
                p.addCurve(to: pt(0.3172, 0.2665, rect), control1: pt(0.3207, 0.2909, rect), control2: pt(0.3172, 0.2665, rect))
                p.addCurve(to: pt(0.3200, 0.2648, rect), control1: pt(0.3172, 0.2665, rect), control2: pt(0.3182, 0.2650, rect))
                p.addCurve(to: pt(0.3721, 0.2636, rect), control1: pt(0.3217, 0.2646, rect), control2: pt(0.3721, 0.2636, rect))
                p.addCurve(to: pt(0.3821, 0.2637, rect), control1: pt(0.3721, 0.2636, rect), control2: pt(0.3796, 0.2630, rect))
                p.addCurve(to: pt(0.3902, 0.2683, rect), control1: pt(0.3846, 0.2644, rect), control2: pt(0.3902, 0.2683, rect))
                p.addCurve(to: pt(0.4015, 0.2784, rect), control1: pt(0.3902, 0.2683, rect), control2: pt(0.4013, 0.2769, rect))
                p.addCurve(to: pt(0.4262, 0.3010, rect), control1: pt(0.4018, 0.2798, rect), control2: pt(0.4237, 0.2985, rect))
                p.addCurve(to: pt(0.4778, 0.3371, rect), control1: pt(0.4350, 0.3096, rect), control2: pt(0.4480, 0.3146, rect))
                p.addCurve(to: pt(0.4820, 0.3463, rect), control1: pt(0.4778, 0.3371, rect), control2: pt(0.4838, 0.3409, rect))
                p.addCurve(to: pt(0.4664, 0.3581, rect), control1: pt(0.4807, 0.3503, rect), control2: pt(0.4727, 0.3559, rect))
                p.addCurve(to: pt(0.4423, 0.3689, rect), control1: pt(0.4578, 0.3612, rect), control2: pt(0.4474, 0.3646, rect))
                p.addCurve(to: pt(0.4309, 0.3838, rect), control1: pt(0.4361, 0.3741, rect), control2: pt(0.4320, 0.3780, rect))
                p.addCurve(to: pt(0.4580, 0.4294, rect), control1: pt(0.4309, 0.3838, rect), control2: pt(0.4315, 0.4018, rect))
                p.closeSubpath()
                p.move(to: pt(0.5397, 0.4294, rect))
                p.addCurve(to: pt(0.5317, 0.4400, rect), control1: pt(0.5376, 0.4316, rect), control2: pt(0.5336, 0.4370, rect))
                p.addCurve(to: pt(0.5293, 0.4444, rect), control1: pt(0.5308, 0.4414, rect), control2: pt(0.5296, 0.4428, rect))
                p.addLine(to: pt(0.6075, 0.4214, rect))
                p.addCurve(to: pt(0.6148, 0.4039, rect), control1: pt(0.6075, 0.4214, rect), control2: pt(0.6088, 0.4109, rect))
                p.addCurve(to: pt(0.6503, 0.3738, rect), control1: pt(0.6209, 0.3970, rect), control2: pt(0.6493, 0.3759, rect))
                p.addCurve(to: pt(0.6692, 0.3617, rect), control1: pt(0.6510, 0.3725, rect), control2: pt(0.6615, 0.3662, rect))
                p.addCurve(to: pt(0.6763, 0.3469, rect), control1: pt(0.6706, 0.3566, rect), control2: pt(0.6731, 0.3510, rect))
                p.addCurve(to: pt(0.6857, 0.3275, rect), control1: pt(0.6809, 0.3408, rect), control2: pt(0.6844, 0.3314, rect))
                p.addCurve(to: pt(0.6831, 0.3240, rect), control1: pt(0.6852, 0.3270, rect), control2: pt(0.6844, 0.3261, rect))
                p.addCurve(to: pt(0.6775, 0.2997, rect), control1: pt(0.6805, 0.3200, rect), control2: pt(0.6780, 0.3084, rect))
                p.addCurve(to: pt(0.6805, 0.2665, rect), control1: pt(0.6770, 0.2909, rect), control2: pt(0.6805, 0.2665, rect))
                p.addCurve(to: pt(0.6778, 0.2648, rect), control1: pt(0.6805, 0.2665, rect), control2: pt(0.6795, 0.2650, rect))
                p.addCurve(to: pt(0.6257, 0.2636, rect), control1: pt(0.6760, 0.2646, rect), control2: pt(0.6257, 0.2636, rect))
                p.addCurve(to: pt(0.6156, 0.2637, rect), control1: pt(0.6257, 0.2636, rect), control2: pt(0.6181, 0.2630, rect))
                p.addCurve(to: pt(0.6076, 0.2683, rect), control1: pt(0.6131, 0.2644, rect), control2: pt(0.6076, 0.2683, rect))
                p.addCurve(to: pt(0.5962, 0.2784, rect), control1: pt(0.6076, 0.2683, rect), control2: pt(0.5965, 0.2769, rect))
                p.addCurve(to: pt(0.5716, 0.3010, rect), control1: pt(0.5960, 0.2798, rect), control2: pt(0.5741, 0.2985, rect))
                p.addCurve(to: pt(0.5200, 0.3371, rect), control1: pt(0.5627, 0.3096, rect), control2: pt(0.5497, 0.3146, rect))
                p.addCurve(to: pt(0.5157, 0.3463, rect), control1: pt(0.5200, 0.3371, rect), control2: pt(0.5139, 0.3409, rect))
                p.addCurve(to: pt(0.5313, 0.3581, rect), control1: pt(0.5170, 0.3503, rect), control2: pt(0.5250, 0.3559, rect))
                p.addCurve(to: pt(0.5554, 0.3689, rect), control1: pt(0.5399, 0.3612, rect), control2: pt(0.5503, 0.3646, rect))
                p.addCurve(to: pt(0.5669, 0.3838, rect), control1: pt(0.5616, 0.3741, rect), control2: pt(0.5657, 0.3780, rect))
                p.addCurve(to: pt(0.5397, 0.4294, rect), control1: pt(0.5669, 0.3838, rect), control2: pt(0.5662, 0.4018, rect))
                p.closeSubpath()
            }
        }

        // 脊柱起立筋（4パーツ: bMuscle-5, bMuscle-20, bMuscle-6, bMuscle-21）
        static func erectorSpinae(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: pt(0.3805, 0.4076, rect))
                p.addCurve(to: pt(0.3695, 0.3964, rect), control1: pt(0.3799, 0.4061, rect), control2: pt(0.3711, 0.3974, rect))
                p.addCurve(to: pt(0.3497, 0.3805, rect), control1: pt(0.3678, 0.3953, rect), control2: pt(0.3520, 0.3819, rect))
                p.addCurve(to: pt(0.3406, 0.3726, rect), control1: pt(0.3473, 0.3792, rect), control2: pt(0.3453, 0.3769, rect))
                p.addCurve(to: pt(0.3295, 0.3659, rect), control1: pt(0.3379, 0.3702, rect), control2: pt(0.3331, 0.3676, rect))
                p.addCurve(to: pt(0.3295, 0.3734, rect), control1: pt(0.3300, 0.3689, rect), control2: pt(0.3300, 0.3715, rect))
                p.addCurve(to: pt(0.3226, 0.4093, rect), control1: pt(0.3282, 0.3784, rect), control2: pt(0.3236, 0.4022, rect))
                p.addCurve(to: pt(0.3832, 0.4201, rect), control1: pt(0.3477, 0.4078, rect), control2: pt(0.3832, 0.4201, rect))
                p.addCurve(to: pt(0.3805, 0.4076, rect), control1: pt(0.3862, 0.4165, rect), control2: pt(0.3812, 0.4091, rect))
                p.closeSubpath()
                p.move(to: pt(0.6182, 0.4076, rect))
                p.addCurve(to: pt(0.6292, 0.3964, rect), control1: pt(0.6188, 0.4061, rect), control2: pt(0.6276, 0.3974, rect))
                p.addCurve(to: pt(0.6490, 0.3805, rect), control1: pt(0.6309, 0.3953, rect), control2: pt(0.6467, 0.3819, rect))
                p.addCurve(to: pt(0.6581, 0.3726, rect), control1: pt(0.6514, 0.3792, rect), control2: pt(0.6534, 0.3769, rect))
                p.addCurve(to: pt(0.6692, 0.3659, rect), control1: pt(0.6607, 0.3702, rect), control2: pt(0.6656, 0.3676, rect))
                p.addCurve(to: pt(0.6692, 0.3734, rect), control1: pt(0.6687, 0.3689, rect), control2: pt(0.6687, 0.3715, rect))
                p.addCurve(to: pt(0.6761, 0.4093, rect), control1: pt(0.6705, 0.3784, rect), control2: pt(0.6751, 0.4022, rect))
                p.addCurve(to: pt(0.6155, 0.4201, rect), control1: pt(0.6510, 0.4078, rect), control2: pt(0.6155, 0.4201, rect))
                p.addCurve(to: pt(0.6182, 0.4076, rect), control1: pt(0.6125, 0.4165, rect), control2: pt(0.6175, 0.4091, rect))
                p.closeSubpath()
                p.move(to: pt(0.3320, 0.4130, rect))
                p.addCurve(to: pt(0.3965, 0.4296, rect), control1: pt(0.3320, 0.4130, rect), control2: pt(0.3829, 0.4231, rect))
                p.addCurve(to: pt(0.3451, 0.4489, rect), control1: pt(0.3965, 0.4296, rect), control2: pt(0.3562, 0.4453, rect))
                p.addCurve(to: pt(0.3114, 0.4681, rect), control1: pt(0.3341, 0.4524, rect), control2: pt(0.3129, 0.4643, rect))
                p.addCurve(to: pt(0.3320, 0.4130, rect), control1: pt(0.3114, 0.4681, rect), control2: pt(0.3044, 0.4332, rect))
                p.closeSubpath()
                p.move(to: pt(0.6667, 0.4130, rect))
                p.addCurve(to: pt(0.6022, 0.4296, rect), control1: pt(0.6667, 0.4130, rect), control2: pt(0.6158, 0.4231, rect))
                p.addCurve(to: pt(0.6536, 0.4489, rect), control1: pt(0.6022, 0.4296, rect), control2: pt(0.6425, 0.4453, rect))
                p.addCurve(to: pt(0.6873, 0.4681, rect), control1: pt(0.6646, 0.4524, rect), control2: pt(0.6858, 0.4643, rect))
                p.addCurve(to: pt(0.6667, 0.4130, rect), control1: pt(0.6873, 0.4681, rect), control2: pt(0.6943, 0.4332, rect))
                p.closeSubpath()
            }
        }

        // 三角筋後部（2パーツ: bMuscle-3, bMuscle-19）
        static func deltoidPosterior(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: pt(0.2275, 0.2410, rect))
                p.addCurve(to: pt(0.2470, 0.2234, rect), control1: pt(0.2275, 0.2410, rect), control2: pt(0.2356, 0.2291, rect))
                p.addCurve(to: pt(0.3087, 0.2096, rect), control1: pt(0.2584, 0.2177, rect), control2: pt(0.2899, 0.2108, rect))
                p.addCurve(to: pt(0.3812, 0.1959, rect), control1: pt(0.3275, 0.2085, rect), control2: pt(0.3765, 0.1986, rect))
                p.addCurve(to: pt(0.3819, 0.2037, rect), control1: pt(0.3812, 0.1959, rect), control2: pt(0.3819, 0.2007, rect))
                p.addCurve(to: pt(0.3832, 0.2571, rect), control1: pt(0.3819, 0.2067, rect), control2: pt(0.3832, 0.2550, rect))
                p.addCurve(to: pt(0.3738, 0.2616, rect), control1: pt(0.3832, 0.2592, rect), control2: pt(0.3738, 0.2616, rect))
                p.addCurve(to: pt(0.3174, 0.2631, rect), control1: pt(0.3738, 0.2616, rect), control2: pt(0.3201, 0.2622, rect))
                p.addCurve(to: pt(0.2812, 0.2419, rect), control1: pt(0.3148, 0.2640, rect), control2: pt(0.2825, 0.2443, rect))
                p.addCurve(to: pt(0.2825, 0.2282, rect), control1: pt(0.2799, 0.2395, rect), control2: pt(0.2825, 0.2282, rect))
                p.addCurve(to: pt(0.2275, 0.2410, rect), control1: pt(0.2825, 0.2282, rect), control2: pt(0.2503, 0.2261, rect))
                p.closeSubpath()
                p.move(to: pt(0.7712, 0.2410, rect))
                p.addCurve(to: pt(0.7517, 0.2234, rect), control1: pt(0.7712, 0.2410, rect), control2: pt(0.7631, 0.2291, rect))
                p.addCurve(to: pt(0.6900, 0.2096, rect), control1: pt(0.7403, 0.2177, rect), control2: pt(0.7088, 0.2108, rect))
                p.addCurve(to: pt(0.6175, 0.1959, rect), control1: pt(0.6712, 0.2085, rect), control2: pt(0.6222, 0.1986, rect))
                p.addCurve(to: pt(0.6168, 0.2037, rect), control1: pt(0.6175, 0.1959, rect), control2: pt(0.6168, 0.2007, rect))
                p.addCurve(to: pt(0.6155, 0.2571, rect), control1: pt(0.6168, 0.2067, rect), control2: pt(0.6155, 0.2550, rect))
                p.addCurve(to: pt(0.6249, 0.2616, rect), control1: pt(0.6155, 0.2592, rect), control2: pt(0.6249, 0.2616, rect))
                p.addCurve(to: pt(0.6813, 0.2631, rect), control1: pt(0.6249, 0.2616, rect), control2: pt(0.6786, 0.2622, rect))
                p.addCurve(to: pt(0.7175, 0.2419, rect), control1: pt(0.6839, 0.2640, rect), control2: pt(0.7162, 0.2443, rect))
                p.addCurve(to: pt(0.7162, 0.2282, rect), control1: pt(0.7188, 0.2395, rect), control2: pt(0.7162, 0.2282, rect))
                p.addCurve(to: pt(0.7712, 0.2410, rect), control1: pt(0.7162, 0.2282, rect), control2: pt(0.7484, 0.2261, rect))
                p.closeSubpath()
            }
        }

        // 三角筋中部（2パーツ: bMuscle-15, bMuscle-28）
        static func deltoidLateral(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: pt(0.3128, 0.2661, rect))
                p.addCurve(to: pt(0.3126, 0.2663, rect), control1: pt(0.3128, 0.2661, rect), control2: pt(0.3127, 0.2662, rect))
                p.addCurve(to: pt(0.3094, 0.2646, rect), control1: pt(0.3118, 0.2649, rect), control2: pt(0.3094, 0.2646, rect))
                p.addCurve(to: pt(0.2795, 0.2467, rect), control1: pt(0.3094, 0.2646, rect), control2: pt(0.2836, 0.2485, rect))
                p.addCurve(to: pt(0.2742, 0.2401, rect), control1: pt(0.2755, 0.2449, rect), control2: pt(0.2742, 0.2401, rect))
                p.addLine(to: pt(0.2748, 0.2304, rect))
                p.addCurve(to: pt(0.2450, 0.2362, rect), control1: pt(0.2748, 0.2304, rect), control2: pt(0.2534, 0.2328, rect))
                p.addCurve(to: pt(0.2278, 0.2450, rect), control1: pt(0.2378, 0.2391, rect), control2: pt(0.2295, 0.2440, rect))
                p.addCurve(to: pt(0.2275, 0.2452, rect), control1: pt(0.2276, 0.2451, rect), control2: pt(0.2275, 0.2452, rect))
                p.addCurve(to: pt(0.2274, 0.2453, rect), control1: pt(0.2275, 0.2452, rect), control2: pt(0.2275, 0.2453, rect))
                p.addCurve(to: pt(0.2208, 0.2497, rect), control1: pt(0.2232, 0.2473, rect), control2: pt(0.2208, 0.2497, rect))
                p.addCurve(to: pt(0.2099, 0.2664, rect), control1: pt(0.2208, 0.2497, rect), control2: pt(0.2099, 0.2658, rect))
                p.addCurve(to: pt(0.2054, 0.2689, rect), control1: pt(0.2099, 0.2670, rect), control2: pt(0.2072, 0.2684, rect))
                p.addCurve(to: pt(0.2028, 0.2692, rect), control1: pt(0.2048, 0.2691, rect), control2: pt(0.2038, 0.2691, rect))
                p.addCurve(to: pt(0.2027, 0.2759, rect), control1: pt(0.2030, 0.2704, rect), control2: pt(0.2035, 0.2742, rect))
                p.addCurve(to: pt(0.1952, 0.3226, rect), control1: pt(0.2020, 0.2774, rect), control2: pt(0.1973, 0.3050, rect))
                p.addCurve(to: pt(0.2054, 0.3536, rect), control1: pt(0.1983, 0.3346, rect), control2: pt(0.2034, 0.3485, rect))
                p.addCurve(to: pt(0.2383, 0.3757, rect), control1: pt(0.2081, 0.3608, rect), control2: pt(0.2383, 0.3757, rect))
                p.addCurve(to: pt(0.2349, 0.3695, rect), control1: pt(0.2383, 0.3757, rect), control2: pt(0.2376, 0.3725, rect))
                p.addCurve(to: pt(0.2332, 0.3618, rect), control1: pt(0.2329, 0.3672, rect), control2: pt(0.2335, 0.3641, rect))
                p.addCurve(to: pt(0.2325, 0.3487, rect), control1: pt(0.2328, 0.3574, rect), control2: pt(0.2326, 0.3531, rect))
                p.addCurve(to: pt(0.2416, 0.3106, rect), control1: pt(0.2320, 0.3357, rect), control2: pt(0.2354, 0.3233, rect))
                p.addLine(to: pt(0.2443, 0.3085, rect))
                p.addCurve(to: pt(0.2597, 0.3079, rect), control1: pt(0.2524, 0.3025, rect), control2: pt(0.2597, 0.3079, rect))
                p.addLine(to: pt(0.2604, 0.3097, rect))
                p.addCurve(to: pt(0.2650, 0.3426, rect), control1: pt(0.2632, 0.3207, rect), control2: pt(0.2652, 0.3316, rect))
                p.addCurve(to: pt(0.2638, 0.3656, rect), control1: pt(0.2649, 0.3501, rect), control2: pt(0.2663, 0.3582, rect))
                p.addCurve(to: pt(0.2658, 0.3686, rect), control1: pt(0.2638, 0.3656, rect), control2: pt(0.2631, 0.3677, rect))
                p.addCurve(to: pt(0.2785, 0.3847, rect), control1: pt(0.2685, 0.3695, rect), control2: pt(0.2799, 0.3790, rect))
                p.addCurve(to: pt(0.2939, 0.3760, rect), control1: pt(0.2785, 0.3847, rect), control2: pt(0.2875, 0.3797, rect))
                p.addCurve(to: pt(0.2943, 0.3707, rect), control1: pt(0.2941, 0.3742, rect), control2: pt(0.2942, 0.3724, rect))
                p.addCurve(to: pt(0.2983, 0.3472, rect), control1: pt(0.2943, 0.3707, rect), control2: pt(0.2948, 0.3557, rect))
                p.addCurve(to: pt(0.3114, 0.3256, rect), control1: pt(0.3018, 0.3386, rect), control2: pt(0.3114, 0.3256, rect))
                p.addCurve(to: pt(0.3154, 0.3091, rect), control1: pt(0.3114, 0.3256, rect), control2: pt(0.3128, 0.3226, rect))
                p.addCurve(to: pt(0.3128, 0.2661, rect), control1: pt(0.3181, 0.2957, rect), control2: pt(0.3161, 0.2706, rect))
                p.closeSubpath()
                p.move(to: pt(0.6859, 0.2661, rect))
                p.addCurve(to: pt(0.6861, 0.2663, rect), control1: pt(0.6859, 0.2661, rect), control2: pt(0.6860, 0.2662, rect))
                p.addCurve(to: pt(0.6893, 0.2646, rect), control1: pt(0.6869, 0.2649, rect), control2: pt(0.6893, 0.2646, rect))
                p.addCurve(to: pt(0.7192, 0.2467, rect), control1: pt(0.6893, 0.2646, rect), control2: pt(0.7151, 0.2485, rect))
                p.addCurve(to: pt(0.7245, 0.2401, rect), control1: pt(0.7232, 0.2449, rect), control2: pt(0.7245, 0.2401, rect))
                p.addLine(to: pt(0.7239, 0.2304, rect))
                p.addCurve(to: pt(0.7537, 0.2362, rect), control1: pt(0.7239, 0.2304, rect), control2: pt(0.7453, 0.2328, rect))
                p.addCurve(to: pt(0.7709, 0.2450, rect), control1: pt(0.7609, 0.2391, rect), control2: pt(0.7692, 0.2440, rect))
                p.addCurve(to: pt(0.7712, 0.2452, rect), control1: pt(0.7711, 0.2451, rect), control2: pt(0.7712, 0.2452, rect))
                p.addCurve(to: pt(0.7713, 0.2453, rect), control1: pt(0.7712, 0.2452, rect), control2: pt(0.7712, 0.2453, rect))
                p.addCurve(to: pt(0.7779, 0.2497, rect), control1: pt(0.7755, 0.2473, rect), control2: pt(0.7779, 0.2497, rect))
                p.addCurve(to: pt(0.7888, 0.2664, rect), control1: pt(0.7779, 0.2497, rect), control2: pt(0.7888, 0.2658, rect))
                p.addCurve(to: pt(0.7933, 0.2689, rect), control1: pt(0.7888, 0.2670, rect), control2: pt(0.7915, 0.2684, rect))
                p.addCurve(to: pt(0.7959, 0.2692, rect), control1: pt(0.7939, 0.2691, rect), control2: pt(0.7949, 0.2691, rect))
                p.addCurve(to: pt(0.7960, 0.2759, rect), control1: pt(0.7957, 0.2704, rect), control2: pt(0.7952, 0.2742, rect))
                p.addCurve(to: pt(0.8035, 0.3226, rect), control1: pt(0.7967, 0.2774, rect), control2: pt(0.8014, 0.3050, rect))
                p.addCurve(to: pt(0.7933, 0.3536, rect), control1: pt(0.8004, 0.3346, rect), control2: pt(0.7953, 0.3485, rect))
                p.addCurve(to: pt(0.7604, 0.3757, rect), control1: pt(0.7906, 0.3608, rect), control2: pt(0.7604, 0.3757, rect))
                p.addCurve(to: pt(0.7638, 0.3695, rect), control1: pt(0.7604, 0.3757, rect), control2: pt(0.7611, 0.3725, rect))
                p.addCurve(to: pt(0.7655, 0.3618, rect), control1: pt(0.7658, 0.3672, rect), control2: pt(0.7652, 0.3641, rect))
                p.addCurve(to: pt(0.7662, 0.3487, rect), control1: pt(0.7659, 0.3574, rect), control2: pt(0.7661, 0.3531, rect))
                p.addCurve(to: pt(0.7571, 0.3106, rect), control1: pt(0.7667, 0.3357, rect), control2: pt(0.7633, 0.3233, rect))
                p.addLine(to: pt(0.7544, 0.3085, rect))
                p.addCurve(to: pt(0.7390, 0.3079, rect), control1: pt(0.7463, 0.3025, rect), control2: pt(0.7390, 0.3079, rect))
                p.addLine(to: pt(0.7383, 0.3097, rect))
                p.addCurve(to: pt(0.7337, 0.3426, rect), control1: pt(0.7355, 0.3207, rect), control2: pt(0.7335, 0.3316, rect))
                p.addCurve(to: pt(0.7349, 0.3656, rect), control1: pt(0.7338, 0.3501, rect), control2: pt(0.7324, 0.3582, rect))
                p.addCurve(to: pt(0.7329, 0.3686, rect), control1: pt(0.7349, 0.3656, rect), control2: pt(0.7356, 0.3677, rect))
                p.addCurve(to: pt(0.7202, 0.3847, rect), control1: pt(0.7302, 0.3695, rect), control2: pt(0.7188, 0.3790, rect))
                p.addCurve(to: pt(0.7048, 0.3760, rect), control1: pt(0.7202, 0.3847, rect), control2: pt(0.7112, 0.3797, rect))
                p.addCurve(to: pt(0.7044, 0.3707, rect), control1: pt(0.7046, 0.3742, rect), control2: pt(0.7045, 0.3724, rect))
                p.addCurve(to: pt(0.7004, 0.3472, rect), control1: pt(0.7044, 0.3707, rect), control2: pt(0.7039, 0.3557, rect))
                p.addCurve(to: pt(0.6873, 0.3256, rect), control1: pt(0.6969, 0.3386, rect), control2: pt(0.6873, 0.3256, rect))
                p.addCurve(to: pt(0.6833, 0.3091, rect), control1: pt(0.6873, 0.3256, rect), control2: pt(0.6859, 0.3226, rect))
                p.addCurve(to: pt(0.6859, 0.2661, rect), control1: pt(0.6806, 0.2957, rect), control2: pt(0.6826, 0.2706, rect))
                p.closeSubpath()
            }
        }

        // 上腕三頭筋（4パーツ: bMuscle-13, bMuscle-26, bMuscle-14, bMuscle-27）
        static func triceps(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: pt(0.1997, 0.3548, rect))
                p.addCurve(to: pt(0.1933, 0.3386, rect), control1: pt(0.1997, 0.3528, rect), control2: pt(0.1963, 0.3451, rect))
                p.addCurve(to: pt(0.1876, 0.3465, rect), control1: pt(0.1924, 0.3401, rect), control2: pt(0.1908, 0.3427, rect))
                p.addCurve(to: pt(0.1664, 0.3846, rect), control1: pt(0.1815, 0.3536, rect), control2: pt(0.1685, 0.3718, rect))
                p.addCurve(to: pt(0.1666, 0.4443, rect), control1: pt(0.1652, 0.3925, rect), control2: pt(0.1661, 0.4219, rect))
                p.addCurve(to: pt(0.1946, 0.3745, rect), control1: pt(0.1760, 0.4172, rect), control2: pt(0.1931, 0.3773, rect))
                p.addCurve(to: pt(0.1997, 0.3548, rect), control1: pt(0.1966, 0.3709, rect), control2: pt(0.1997, 0.3583, rect))
                p.closeSubpath()
                p.move(to: pt(0.7990, 0.3548, rect))
                p.addCurve(to: pt(0.8054, 0.3386, rect), control1: pt(0.7990, 0.3528, rect), control2: pt(0.8024, 0.3451, rect))
                p.addCurve(to: pt(0.8111, 0.3465, rect), control1: pt(0.8063, 0.3401, rect), control2: pt(0.8079, 0.3427, rect))
                p.addCurve(to: pt(0.8323, 0.3846, rect), control1: pt(0.8172, 0.3536, rect), control2: pt(0.8302, 0.3718, rect))
                p.addCurve(to: pt(0.8321, 0.4443, rect), control1: pt(0.8335, 0.3925, rect), control2: pt(0.8326, 0.4219, rect))
                p.addCurve(to: pt(0.8041, 0.3745, rect), control1: pt(0.8227, 0.4172, rect), control2: pt(0.8056, 0.3773, rect))
                p.addCurve(to: pt(0.7990, 0.3548, rect), control1: pt(0.8021, 0.3709, rect), control2: pt(0.7990, 0.3583, rect))
                p.closeSubpath()
                p.move(to: pt(0.2852, 0.4112, rect))
                p.addCurve(to: pt(0.2933, 0.3815, rect), control1: pt(0.2879, 0.4064, rect), control2: pt(0.2915, 0.3938, rect))
                p.addLine(to: pt(0.2797, 0.3870, rect))
                p.addLine(to: pt(0.2747, 0.3946, rect))
                p.addCurve(to: pt(0.2495, 0.3913, rect), control1: pt(0.2747, 0.3946, rect), control2: pt(0.2611, 0.3958, rect))
                p.addCurve(to: pt(0.2570, 0.4114, rect), control1: pt(0.2495, 0.3913, rect), control2: pt(0.2550, 0.4090, rect))
                p.addCurve(to: pt(0.2628, 0.4405, rect), control1: pt(0.2587, 0.4134, rect), control2: pt(0.2646, 0.4257, rect))
                p.addCurve(to: pt(0.2852, 0.4112, rect), control1: pt(0.2719, 0.4284, rect), control2: pt(0.2825, 0.4161, rect))
                p.closeSubpath()
                p.move(to: pt(0.7135, 0.4112, rect))
                p.addCurve(to: pt(0.7054, 0.3815, rect), control1: pt(0.7108, 0.4064, rect), control2: pt(0.7072, 0.3938, rect))
                p.addLine(to: pt(0.7190, 0.3870, rect))
                p.addLine(to: pt(0.7240, 0.3946, rect))
                p.addCurve(to: pt(0.7492, 0.3913, rect), control1: pt(0.7240, 0.3946, rect), control2: pt(0.7376, 0.3958, rect))
                p.addCurve(to: pt(0.7417, 0.4114, rect), control1: pt(0.7492, 0.3913, rect), control2: pt(0.7437, 0.4090, rect))
                p.addCurve(to: pt(0.7359, 0.4405, rect), control1: pt(0.7400, 0.4134, rect), control2: pt(0.7341, 0.4257, rect))
                p.addCurve(to: pt(0.7135, 0.4112, rect), control1: pt(0.7268, 0.4284, rect), control2: pt(0.7162, 0.4161, rect))
                p.closeSubpath()
            }
        }

        // 前腕筋群（2パーツ: bMuscle-16, bMuscle-29）
        static func forearms(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: pt(0.2535, 0.4135, rect))
                p.addCurve(to: pt(0.2389, 0.3785, rect), control1: pt(0.2455, 0.3984, rect), control2: pt(0.2389, 0.3785, rect))
                p.addCurve(to: pt(0.2037, 0.3590, rect), control1: pt(0.2389, 0.3785, rect), control2: pt(0.2092, 0.3660, rect))
                p.addCurve(to: pt(0.1997, 0.3736, rect), control1: pt(0.2025, 0.3639, rect), control2: pt(0.2017, 0.3687, rect))
                p.addCurve(to: pt(0.1837, 0.4128, rect), control1: pt(0.1942, 0.3866, rect), control2: pt(0.1891, 0.3997, rect))
                p.addCurve(to: pt(0.1787, 0.4242, rect), control1: pt(0.1821, 0.4166, rect), control2: pt(0.1805, 0.4204, rect))
                p.addCurve(to: pt(0.1736, 0.4345, rect), control1: pt(0.1771, 0.4276, rect), control2: pt(0.1754, 0.4311, rect))
                p.addCurve(to: pt(0.1702, 0.4407, rect), control1: pt(0.1725, 0.4366, rect), control2: pt(0.1714, 0.4387, rect))
                p.addCurve(to: pt(0.1666, 0.4466, rect), control1: pt(0.1692, 0.4425, rect), control2: pt(0.1666, 0.4448, rect))
                p.addCurve(to: pt(0.1664, 0.4708, rect), control1: pt(0.1669, 0.4591, rect), control2: pt(0.1670, 0.4690, rect))
                p.addCurve(to: pt(0.1632, 0.4862, rect), control1: pt(0.1654, 0.4743, rect), control2: pt(0.1643, 0.4816, rect))
                p.addCurve(to: pt(0.2133, 0.4903, rect), control1: pt(0.1687, 0.4879, rect), control2: pt(0.1818, 0.4902, rect))
                p.addLine(to: pt(0.2213, 0.4903, rect))
                p.addLine(to: pt(0.2383, 0.4901, rect))
                p.addCurve(to: pt(0.2555, 0.4506, rect), control1: pt(0.2399, 0.4851, rect), control2: pt(0.2471, 0.4635, rect))
                p.addCurve(to: pt(0.2556, 0.4506, rect), control1: pt(0.2555, 0.4506, rect), control2: pt(0.2556, 0.4506, rect))
                p.addCurve(to: pt(0.2535, 0.4135, rect), control1: pt(0.2570, 0.4442, rect), control2: pt(0.2601, 0.4257, rect))
                p.closeSubpath()
                p.move(to: pt(0.7452, 0.4135, rect))
                p.addCurve(to: pt(0.7598, 0.3785, rect), control1: pt(0.7532, 0.3984, rect), control2: pt(0.7598, 0.3785, rect))
                p.addCurve(to: pt(0.7950, 0.3590, rect), control1: pt(0.7598, 0.3785, rect), control2: pt(0.7895, 0.3660, rect))
                p.addCurve(to: pt(0.7990, 0.3736, rect), control1: pt(0.7962, 0.3639, rect), control2: pt(0.7970, 0.3687, rect))
                p.addCurve(to: pt(0.8150, 0.4128, rect), control1: pt(0.8045, 0.3866, rect), control2: pt(0.8096, 0.3997, rect))
                p.addCurve(to: pt(0.8200, 0.4242, rect), control1: pt(0.8166, 0.4166, rect), control2: pt(0.8182, 0.4204, rect))
                p.addCurve(to: pt(0.8251, 0.4345, rect), control1: pt(0.8216, 0.4276, rect), control2: pt(0.8233, 0.4311, rect))
                p.addCurve(to: pt(0.8285, 0.4407, rect), control1: pt(0.8262, 0.4366, rect), control2: pt(0.8273, 0.4387, rect))
                p.addCurve(to: pt(0.8321, 0.4466, rect), control1: pt(0.8295, 0.4425, rect), control2: pt(0.8321, 0.4448, rect))
                p.addCurve(to: pt(0.8323, 0.4708, rect), control1: pt(0.8318, 0.4591, rect), control2: pt(0.8317, 0.4690, rect))
                p.addCurve(to: pt(0.8355, 0.4862, rect), control1: pt(0.8333, 0.4743, rect), control2: pt(0.8344, 0.4816, rect))
                p.addCurve(to: pt(0.7854, 0.4903, rect), control1: pt(0.8300, 0.4879, rect), control2: pt(0.8169, 0.4902, rect))
                p.addLine(to: pt(0.7774, 0.4903, rect))
                p.addLine(to: pt(0.7604, 0.4901, rect))
                p.addCurve(to: pt(0.7432, 0.4506, rect), control1: pt(0.7588, 0.4851, rect), control2: pt(0.7516, 0.4635, rect))
                p.addCurve(to: pt(0.7431, 0.4506, rect), control1: pt(0.7432, 0.4506, rect), control2: pt(0.7431, 0.4506, rect))
                p.addCurve(to: pt(0.7452, 0.4135, rect), control1: pt(0.7417, 0.4442, rect), control2: pt(0.7386, 0.4257, rect))
                p.closeSubpath()
            }
        }

        // 臀筋群（2パーツ: bMuscle-7, bMuscle-22）
        static func glutes(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: pt(0.4035, 0.4309, rect))
                p.addCurve(to: pt(0.3471, 0.4520, rect), control1: pt(0.4035, 0.4309, rect), control2: pt(0.3617, 0.4475, rect))
                p.addCurve(to: pt(0.3134, 0.4748, rect), control1: pt(0.3471, 0.4520, rect), control2: pt(0.3215, 0.4634, rect))
                p.addCurve(to: pt(0.3195, 0.5035, rect), control1: pt(0.3134, 0.4748, rect), control2: pt(0.3134, 0.4928, rect))
                p.addCurve(to: pt(0.3763, 0.5293, rect), control1: pt(0.3228, 0.5095, rect), control2: pt(0.3431, 0.5264, rect))
                p.addCurve(to: pt(0.4740, 0.5170, rect), control1: pt(0.4126, 0.5325, rect), control2: pt(0.4464, 0.5281, rect))
                p.addCurve(to: pt(0.4940, 0.5044, rect), control1: pt(0.4819, 0.5138, rect), control2: pt(0.4906, 0.5090, rect))
                p.addCurve(to: pt(0.4997, 0.4943, rect), control1: pt(0.4964, 0.5012, rect), control2: pt(0.4992, 0.4977, rect))
                p.addCurve(to: pt(0.4883, 0.4658, rect), control1: pt(0.5010, 0.4845, rect), control2: pt(0.4962, 0.4751, rect))
                p.addCurve(to: pt(0.4654, 0.4491, rect), control1: pt(0.4837, 0.4604, rect), control2: pt(0.4757, 0.4528, rect))
                p.addCurve(to: pt(0.4035, 0.4309, rect), control1: pt(0.4654, 0.4491, rect), control2: pt(0.4393, 0.4394, rect))
                p.closeSubpath()
                p.move(to: pt(0.5952, 0.4309, rect))
                p.addCurve(to: pt(0.6516, 0.4520, rect), control1: pt(0.5952, 0.4309, rect), control2: pt(0.6370, 0.4475, rect))
                p.addCurve(to: pt(0.6853, 0.4748, rect), control1: pt(0.6516, 0.4520, rect), control2: pt(0.6772, 0.4634, rect))
                p.addCurve(to: pt(0.6792, 0.5035, rect), control1: pt(0.6853, 0.4748, rect), control2: pt(0.6853, 0.4928, rect))
                p.addCurve(to: pt(0.6224, 0.5293, rect), control1: pt(0.6759, 0.5095, rect), control2: pt(0.6556, 0.5264, rect))
                p.addCurve(to: pt(0.5247, 0.5170, rect), control1: pt(0.5861, 0.5325, rect), control2: pt(0.5523, 0.5281, rect))
                p.addCurve(to: pt(0.5047, 0.5044, rect), control1: pt(0.5168, 0.5138, rect), control2: pt(0.5081, 0.5090, rect))
                p.addCurve(to: pt(0.4990, 0.4943, rect), control1: pt(0.5023, 0.5012, rect), control2: pt(0.4995, 0.4977, rect))
                p.addCurve(to: pt(0.5104, 0.4658, rect), control1: pt(0.4977, 0.4845, rect), control2: pt(0.5025, 0.4751, rect))
                p.addCurve(to: pt(0.5333, 0.4491, rect), control1: pt(0.5150, 0.4604, rect), control2: pt(0.5230, 0.4528, rect))
                p.addCurve(to: pt(0.5952, 0.4309, rect), control1: pt(0.5333, 0.4491, rect), control2: pt(0.5595, 0.4394, rect))
                p.closeSubpath()
            }
        }

        // ハムストリングス（6パーツ: bMuscle-17, bMuscle-37, bMuscle-8, bMuscle-36, bMuscle-35, bMuscle-38）
        static func hamstrings(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: pt(0.4765, 0.6684, rect))
                p.addCurve(to: pt(0.4775, 0.6321, rect), control1: pt(0.4765, 0.6684, rect), control2: pt(0.4780, 0.6446, rect))
                p.addCurve(to: pt(0.4695, 0.5853, rect), control1: pt(0.4770, 0.6196, rect), control2: pt(0.4705, 0.5940, rect))
                p.addCurve(to: pt(0.4609, 0.5629, rect), control1: pt(0.4685, 0.5768, rect), control2: pt(0.4661, 0.5718, rect))
                p.addCurve(to: pt(0.4433, 0.5443, rect), control1: pt(0.4579, 0.5577, rect), control2: pt(0.4518, 0.5515, rect))
                p.addCurve(to: pt(0.4381, 0.5331, rect), control1: pt(0.4384, 0.5402, rect), control2: pt(0.4356, 0.5331, rect))
                p.addCurve(to: pt(0.4378, 0.5331, rect), control1: pt(0.4381, 0.5331, rect), control2: pt(0.4380, 0.5331, rect))
                p.addCurve(to: pt(0.3530, 0.5445, rect), control1: pt(0.4089, 0.5333, rect), control2: pt(0.3699, 0.5320, rect))
                p.addCurve(to: pt(0.3369, 0.6126, rect), control1: pt(0.3309, 0.5609, rect), control2: pt(0.3342, 0.6033, rect))
                p.addCurve(to: pt(0.3423, 0.6711, rect), control1: pt(0.3396, 0.6219, rect), control2: pt(0.3430, 0.6577, rect))
                p.addCurve(to: pt(0.3385, 0.6814, rect), control1: pt(0.3420, 0.6762, rect), control2: pt(0.3404, 0.6794, rect))
                p.addCurve(to: pt(0.3416, 0.6956, rect), control1: pt(0.3402, 0.6864, rect), control2: pt(0.3420, 0.6929, rect))
                p.addCurve(to: pt(0.3463, 0.7174, rect), control1: pt(0.3409, 0.7004, rect), control2: pt(0.3463, 0.7174, rect))
                p.addCurve(to: pt(0.3477, 0.7211, rect), control1: pt(0.3463, 0.7174, rect), control2: pt(0.3475, 0.7187, rect))
                p.addCurve(to: pt(0.3879, 0.6753, rect), control1: pt(0.3614, 0.7065, rect), control2: pt(0.3809, 0.6860, rect))
                p.addCurve(to: pt(0.4033, 0.6667, rect), control1: pt(0.3906, 0.6729, rect), control2: pt(0.3978, 0.6666, rect))
                p.addCurve(to: pt(0.4186, 0.6764, rect), control1: pt(0.4101, 0.6668, rect), control2: pt(0.4171, 0.6750, rect))
                p.addCurve(to: pt(0.4232, 0.6821, rect), control1: pt(0.4202, 0.6786, rect), control2: pt(0.4218, 0.6805, rect))
                p.addCurve(to: pt(0.4687, 0.7278, rect), control1: pt(0.4316, 0.6914, rect), control2: pt(0.4598, 0.7190, rect))
                p.addCurve(to: pt(0.4752, 0.6966, rect), control1: pt(0.4717, 0.7226, rect), control2: pt(0.4738, 0.7096, rect))
                p.addCurve(to: pt(0.4765, 0.6684, rect), control1: pt(0.4760, 0.6758, rect), control2: pt(0.4750, 0.6877, rect))
                p.closeSubpath()
                p.move(to: pt(0.5209, 0.6684, rect))
                p.addCurve(to: pt(0.5199, 0.6321, rect), control1: pt(0.5209, 0.6684, rect), control2: pt(0.5194, 0.6446, rect))
                p.addCurve(to: pt(0.5280, 0.5853, rect), control1: pt(0.5204, 0.6196, rect), control2: pt(0.5269, 0.5940, rect))
                p.addCurve(to: pt(0.5365, 0.5629, rect), control1: pt(0.5290, 0.5768, rect), control2: pt(0.5313, 0.5718, rect))
                p.addCurve(to: pt(0.5542, 0.5443, rect), control1: pt(0.5396, 0.5577, rect), control2: pt(0.5456, 0.5515, rect))
                p.addCurve(to: pt(0.5593, 0.5331, rect), control1: pt(0.5590, 0.5402, rect), control2: pt(0.5618, 0.5331, rect))
                p.addCurve(to: pt(0.5597, 0.5331, rect), control1: pt(0.5593, 0.5331, rect), control2: pt(0.5595, 0.5331, rect))
                p.addCurve(to: pt(0.6444, 0.5445, rect), control1: pt(0.5885, 0.5333, rect), control2: pt(0.6275, 0.5320, rect))
                p.addCurve(to: pt(0.6605, 0.6126, rect), control1: pt(0.6666, 0.5609, rect), control2: pt(0.6632, 0.6033, rect))
                p.addCurve(to: pt(0.6552, 0.6711, rect), control1: pt(0.6578, 0.6219, rect), control2: pt(0.6545, 0.6577, rect))
                p.addCurve(to: pt(0.6589, 0.6814, rect), control1: pt(0.6554, 0.6762, rect), control2: pt(0.6570, 0.6794, rect))
                p.addCurve(to: pt(0.6558, 0.6956, rect), control1: pt(0.6573, 0.6864, rect), control2: pt(0.6554, 0.6929, rect))
                p.addCurve(to: pt(0.6511, 0.7175, rect), control1: pt(0.6565, 0.7004, rect), control2: pt(0.6511, 0.7175, rect))
                p.addCurve(to: pt(0.6497, 0.7211, rect), control1: pt(0.6511, 0.7175, rect), control2: pt(0.6500, 0.7187, rect))
                p.addCurve(to: pt(0.6095, 0.6753, rect), control1: pt(0.6360, 0.7065, rect), control2: pt(0.6166, 0.6860, rect))
                p.addCurve(to: pt(0.5942, 0.6667, rect), control1: pt(0.6068, 0.6729, rect), control2: pt(0.5996, 0.6666, rect))
                p.addCurve(to: pt(0.5788, 0.6764, rect), control1: pt(0.5874, 0.6668, rect), control2: pt(0.5804, 0.6750, rect))
                p.addCurve(to: pt(0.5743, 0.6821, rect), control1: pt(0.5772, 0.6786, rect), control2: pt(0.5757, 0.6805, rect))
                p.addCurve(to: pt(0.5287, 0.7278, rect), control1: pt(0.5658, 0.6914, rect), control2: pt(0.5377, 0.7190, rect))
                p.addCurve(to: pt(0.5223, 0.6966, rect), control1: pt(0.5257, 0.7226, rect), control2: pt(0.5236, 0.7096, rect))
                p.addCurve(to: pt(0.5209, 0.6684, rect), control1: pt(0.5214, 0.6758, rect), control2: pt(0.5224, 0.6877, rect))
                p.closeSubpath()
                p.move(to: pt(0.3336, 0.5206, rect))
                p.addCurve(to: pt(0.3081, 0.4919, rect), control1: pt(0.3114, 0.5099, rect), control2: pt(0.3081, 0.4919, rect))
                p.addCurve(to: pt(0.2940, 0.5890, rect), control1: pt(0.2812, 0.5143, rect), control2: pt(0.2879, 0.5663, rect))
                p.addCurve(to: pt(0.3268, 0.6511, rect), control1: pt(0.3000, 0.6117, rect), control2: pt(0.3262, 0.6416, rect))
                p.addCurve(to: pt(0.3265, 0.6617, rect), control1: pt(0.3271, 0.6552, rect), control2: pt(0.3274, 0.6586, rect))
                p.addCurve(to: pt(0.3351, 0.6709, rect), control1: pt(0.3293, 0.6651, rect), control2: pt(0.3332, 0.6687, rect))
                p.addCurve(to: pt(0.3329, 0.6281, rect), control1: pt(0.3386, 0.6582, rect), control2: pt(0.3345, 0.6360, rect))
                p.addCurve(to: pt(0.3285, 0.5884, rect), control1: pt(0.3309, 0.6183, rect), control2: pt(0.3299, 0.6036, rect))
                p.addCurve(to: pt(0.3371, 0.5521, rect), control1: pt(0.3272, 0.5732, rect), control2: pt(0.3371, 0.5521, rect))
                p.addCurve(to: pt(0.3336, 0.5206, rect), control1: pt(0.3371, 0.5521, rect), control2: pt(0.3386, 0.5231, rect))
                p.closeSubpath()
                p.move(to: pt(0.6639, 0.5206, rect))
                p.addCurve(to: pt(0.6894, 0.4919, rect), control1: pt(0.6860, 0.5099, rect), control2: pt(0.6894, 0.4919, rect))
                p.addCurve(to: pt(0.7035, 0.5890, rect), control1: pt(0.7162, 0.5143, rect), control2: pt(0.7095, 0.5663, rect))
                p.addCurve(to: pt(0.6706, 0.6511, rect), control1: pt(0.6974, 0.6117, rect), control2: pt(0.6713, 0.6416, rect))
                p.addCurve(to: pt(0.6709, 0.6617, rect), control1: pt(0.6703, 0.6552, rect), control2: pt(0.6700, 0.6586, rect))
                p.addCurve(to: pt(0.6624, 0.6709, rect), control1: pt(0.6681, 0.6651, rect), control2: pt(0.6642, 0.6687, rect))
                p.addCurve(to: pt(0.6646, 0.6281, rect), control1: pt(0.6589, 0.6582, rect), control2: pt(0.6629, 0.6360, rect))
                p.addCurve(to: pt(0.6689, 0.5884, rect), control1: pt(0.6666, 0.6183, rect), control2: pt(0.6676, 0.6036, rect))
                p.addCurve(to: pt(0.6604, 0.5521, rect), control1: pt(0.6703, 0.5732, rect), control2: pt(0.6604, 0.5521, rect))
                p.addCurve(to: pt(0.6639, 0.5206, rect), control1: pt(0.6604, 0.5521, rect), control2: pt(0.6588, 0.5231, rect))
                p.closeSubpath()
                p.move(to: pt(0.4990, 0.5147, rect))
                p.addCurve(to: pt(0.4997, 0.5623, rect), control1: pt(0.4990, 0.5147, rect), control2: pt(0.5040, 0.5411, rect))
                p.addCurve(to: pt(0.4789, 0.6184, rect), control1: pt(0.4957, 0.5823, rect), control2: pt(0.4799, 0.6130, rect))
                p.addCurve(to: pt(0.4703, 0.5633, rect), control1: pt(0.4789, 0.6184, rect), control2: pt(0.4784, 0.5804, rect))
                p.addCurve(to: pt(0.4467, 0.5328, rect), control1: pt(0.4633, 0.5483, rect), control2: pt(0.4457, 0.5397, rect))
                p.addCurve(to: pt(0.4990, 0.5147, rect), control1: pt(0.4467, 0.5328, rect), control2: pt(0.4880, 0.5281, rect))
                p.closeSubpath()
                p.move(to: pt(0.4990, 0.5147, rect))
                p.addCurve(to: pt(0.4981, 0.5623, rect), control1: pt(0.4990, 0.5147, rect), control2: pt(0.4939, 0.5411, rect))
                p.addCurve(to: pt(0.5189, 0.6184, rect), control1: pt(0.5021, 0.5823, rect), control2: pt(0.5179, 0.6131, rect))
                p.addCurve(to: pt(0.5275, 0.5633, rect), control1: pt(0.5189, 0.6184, rect), control2: pt(0.5195, 0.5804, rect))
                p.addCurve(to: pt(0.5511, 0.5329, rect), control1: pt(0.5345, 0.5483, rect), control2: pt(0.5521, 0.5397, rect))
                p.addCurve(to: pt(0.4990, 0.5147, rect), control1: pt(0.5511, 0.5329, rect), control2: pt(0.5101, 0.5281, rect))
                p.closeSubpath()
            }
        }

        // 内転筋群（2パーツ: bMuscle-9, bMuscle-23）
        static func adductors(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: pt(0.4275, 0.7608, rect))
                p.addCurve(to: pt(0.4181, 0.7055, rect), control1: pt(0.4275, 0.7581, rect), control2: pt(0.4181, 0.7055, rect))
                p.addCurve(to: pt(0.3839, 0.6879, rect), control1: pt(0.4181, 0.7055, rect), control2: pt(0.3899, 0.6852, rect))
                p.addCurve(to: pt(0.3477, 0.7237, rect), control1: pt(0.3839, 0.6879, rect), control2: pt(0.3691, 0.7088, rect))
                p.addCurve(to: pt(0.3497, 0.7957, rect), control1: pt(0.3470, 0.7279, rect), control2: pt(0.3463, 0.7766, rect))
                p.addCurve(to: pt(0.3517, 0.8025, rect), control1: pt(0.3500, 0.7977, rect), control2: pt(0.3507, 0.8000, rect))
                p.addCurve(to: pt(0.3839, 0.8247, rect), control1: pt(0.3601, 0.8118, rect), control2: pt(0.3726, 0.8231, rect))
                p.addCurve(to: pt(0.4282, 0.8214, rect), control1: pt(0.4034, 0.8274, rect), control2: pt(0.4161, 0.8256, rect))
                p.addCurve(to: pt(0.4409, 0.7969, rect), control1: pt(0.4403, 0.8172, rect), control2: pt(0.4430, 0.8035, rect))
                p.addCurve(to: pt(0.4275, 0.7608, rect), control1: pt(0.4389, 0.7903, rect), control2: pt(0.4275, 0.7635, rect))
                p.closeSubpath()
                p.move(to: pt(0.5712, 0.7608, rect))
                p.addCurve(to: pt(0.5806, 0.7055, rect), control1: pt(0.5712, 0.7581, rect), control2: pt(0.5806, 0.7055, rect))
                p.addCurve(to: pt(0.6148, 0.6879, rect), control1: pt(0.5806, 0.7055, rect), control2: pt(0.6088, 0.6852, rect))
                p.addCurve(to: pt(0.6510, 0.7237, rect), control1: pt(0.6148, 0.6879, rect), control2: pt(0.6296, 0.7088, rect))
                p.addCurve(to: pt(0.6490, 0.7957, rect), control1: pt(0.6517, 0.7279, rect), control2: pt(0.6524, 0.7766, rect))
                p.addCurve(to: pt(0.6470, 0.8025, rect), control1: pt(0.6487, 0.7977, rect), control2: pt(0.6480, 0.8000, rect))
                p.addCurve(to: pt(0.6148, 0.8247, rect), control1: pt(0.6386, 0.8118, rect), control2: pt(0.6261, 0.8231, rect))
                p.addCurve(to: pt(0.5705, 0.8214, rect), control1: pt(0.5953, 0.8274, rect), control2: pt(0.5826, 0.8256, rect))
                p.addCurve(to: pt(0.5578, 0.7969, rect), control1: pt(0.5584, 0.8172, rect), control2: pt(0.5557, 0.8035, rect))
                p.addCurve(to: pt(0.5712, 0.7608, rect), control1: pt(0.5598, 0.7903, rect), control2: pt(0.5712, 0.7635, rect))
                p.closeSubpath()
            }
        }

        // 腓腹筋（2パーツ: bMuscle-11, bMuscle-30）
        static func gastrocnemius(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: pt(0.4471, 0.8990, rect))
                p.addCurve(to: pt(0.4449, 0.8950, rect), control1: pt(0.4464, 0.8977, rect), control2: pt(0.4455, 0.8962, rect))
                p.addCurve(to: pt(0.4393, 0.8839, rect), control1: pt(0.4431, 0.8913, rect), control2: pt(0.4413, 0.8876, rect))
                p.addCurve(to: pt(0.4281, 0.8644, rect), control1: pt(0.4359, 0.8774, rect), control2: pt(0.4323, 0.8709, rect))
                p.addCurve(to: pt(0.4105, 0.8417, rect), control1: pt(0.4232, 0.8567, rect), control2: pt(0.4179, 0.8490, rect))
                p.addCurve(to: pt(0.4050, 0.8368, rect), control1: pt(0.4088, 0.8401, rect), control2: pt(0.4069, 0.8385, rect))
                p.addCurve(to: pt(0.3782, 0.8257, rect), control1: pt(0.3992, 0.8317, rect), control2: pt(0.3877, 0.8293, rect))
                p.addCurve(to: pt(0.3658, 0.8195, rect), control1: pt(0.3734, 0.8239, rect), control2: pt(0.3694, 0.8217, rect))
                p.addCurve(to: pt(0.3565, 0.8127, rect), control1: pt(0.3628, 0.8177, rect), control2: pt(0.3576, 0.8150, rect))
                p.addCurve(to: pt(0.3696, 0.8347, rect), control1: pt(0.3601, 0.8197, rect), control2: pt(0.3648, 0.8273, rect))
                p.addCurve(to: pt(0.3804, 0.8391, rect), control1: pt(0.3737, 0.8362, rect), control2: pt(0.3775, 0.8377, rect))
                p.addCurve(to: pt(0.4156, 0.8702, rect), control1: pt(0.3904, 0.8438, rect), control2: pt(0.4111, 0.8655, rect))
                p.addCurve(to: pt(0.4201, 0.8753, rect), control1: pt(0.4172, 0.8719, rect), control2: pt(0.4186, 0.8736, rect))
                p.addCurve(to: pt(0.4272, 0.8837, rect), control1: pt(0.4225, 0.8781, rect), control2: pt(0.4248, 0.8809, rect))
                p.addCurve(to: pt(0.4352, 0.8934, rect), control1: pt(0.4299, 0.8869, rect), control2: pt(0.4325, 0.8902, rect))
                p.addCurve(to: pt(0.4423, 0.9020, rect), control1: pt(0.4376, 0.8963, rect), control2: pt(0.4400, 0.8991, rect))
                p.addCurve(to: pt(0.4469, 0.9075, rect), control1: pt(0.4439, 0.9039, rect), control2: pt(0.4454, 0.9057, rect))
                p.addCurve(to: pt(0.4505, 0.9065, rect), control1: pt(0.4481, 0.9090, rect), control2: pt(0.4515, 0.9086, rect))
                p.addCurve(to: pt(0.4471, 0.8990, rect), control1: pt(0.4493, 0.9037, rect), control2: pt(0.4486, 0.9017, rect))
                p.closeSubpath()
                p.move(to: pt(0.5503, 0.9003, rect))
                p.addCurve(to: pt(0.5525, 0.8964, rect), control1: pt(0.5511, 0.8991, rect), control2: pt(0.5519, 0.8976, rect))
                p.addCurve(to: pt(0.5581, 0.8853, rect), control1: pt(0.5543, 0.8927, rect), control2: pt(0.5561, 0.8890, rect))
                p.addCurve(to: pt(0.5693, 0.8657, rect), control1: pt(0.5615, 0.8787, rect), control2: pt(0.5651, 0.8722, rect))
                p.addCurve(to: pt(0.5869, 0.8431, rect), control1: pt(0.5742, 0.8581, rect), control2: pt(0.5796, 0.8504, rect))
                p.addCurve(to: pt(0.5924, 0.8382, rect), control1: pt(0.5886, 0.8414, rect), control2: pt(0.5905, 0.8398, rect))
                p.addCurve(to: pt(0.6192, 0.8270, rect), control1: pt(0.5982, 0.8330, rect), control2: pt(0.6098, 0.8306, rect))
                p.addCurve(to: pt(0.6316, 0.8208, rect), control1: pt(0.6240, 0.8252, rect), control2: pt(0.6280, 0.8231, rect))
                p.addCurve(to: pt(0.6410, 0.8141, rect), control1: pt(0.6346, 0.8190, rect), control2: pt(0.6398, 0.8163, rect))
                p.addCurve(to: pt(0.6278, 0.8360, rect), control1: pt(0.6373, 0.8210, rect), control2: pt(0.6326, 0.8287, rect))
                p.addCurve(to: pt(0.6170, 0.8404, rect), control1: pt(0.6238, 0.8376, rect), control2: pt(0.6199, 0.8391, rect))
                p.addCurve(to: pt(0.5818, 0.8716, rect), control1: pt(0.6070, 0.8451, rect), control2: pt(0.5863, 0.8669, rect))
                p.addCurve(to: pt(0.5774, 0.8766, rect), control1: pt(0.5802, 0.8732, rect), control2: pt(0.5788, 0.8749, rect))
                p.addCurve(to: pt(0.5702, 0.8851, rect), control1: pt(0.5749, 0.8794, rect), control2: pt(0.5726, 0.8823, rect))
                p.addCurve(to: pt(0.5622, 0.8947, rect), control1: pt(0.5675, 0.8883, rect), control2: pt(0.5649, 0.8915, rect))
                p.addCurve(to: pt(0.5551, 0.9034, rect), control1: pt(0.5598, 0.8976, rect), control2: pt(0.5574, 0.9005, rect))
                p.addCurve(to: pt(0.5505, 0.9089, rect), control1: pt(0.5536, 0.9052, rect), control2: pt(0.5520, 0.9070, rect))
                p.addCurve(to: pt(0.5469, 0.9079, rect), control1: pt(0.5493, 0.9104, rect), control2: pt(0.5459, 0.9100, rect))
                p.addCurve(to: pt(0.5503, 0.9003, rect), control1: pt(0.5481, 0.9050, rect), control2: pt(0.5488, 0.9030, rect))
                p.closeSubpath()
            }
        }

        // ヒラメ筋（2パーツ: bMuscle-12, bMuscle-31）
        static func soleus(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: pt(0.4186, 0.8839, rect))
                p.addCurve(to: pt(0.4121, 0.8666, rect), control1: pt(0.4168, 0.8796, rect), control2: pt(0.4141, 0.8722, rect))
                p.addCurve(to: pt(0.3804, 0.8391, rect), control1: pt(0.4044, 0.8587, rect), control2: pt(0.3888, 0.8430, rect))
                p.addCurve(to: pt(0.3696, 0.8347, rect), control1: pt(0.3775, 0.8377, rect), control2: pt(0.3737, 0.8362, rect))
                p.addCurve(to: pt(0.3690, 0.8337, rect), control1: pt(0.3694, 0.8344, rect), control2: pt(0.3692, 0.8340, rect))
                p.addCurve(to: pt(0.3919, 0.8680, rect), control1: pt(0.3790, 0.8491, rect), control2: pt(0.3895, 0.8635, rect))
                p.addCurve(to: pt(0.3960, 0.8775, rect), control1: pt(0.3928, 0.8696, rect), control2: pt(0.3943, 0.8731, rect))
                p.addCurve(to: pt(0.4040, 0.8870, rect), control1: pt(0.3995, 0.8809, rect), control2: pt(0.4025, 0.8844, rect))
                p.addCurve(to: pt(0.4279, 0.9135, rect), control1: pt(0.4093, 0.8961, rect), control2: pt(0.4190, 0.9050, rect))
                p.addCurve(to: pt(0.4370, 0.9215, rect), control1: pt(0.4308, 0.9162, rect), control2: pt(0.4339, 0.9188, rect))
                p.addCurve(to: pt(0.4398, 0.9193, rect), control1: pt(0.4403, 0.9234, rect), control2: pt(0.4409, 0.9215, rect))
                p.addCurve(to: pt(0.4302, 0.9048, rect), control1: pt(0.4374, 0.9146, rect), control2: pt(0.4337, 0.9095, rect))
                p.addCurve(to: pt(0.4214, 0.8899, rect), control1: pt(0.4265, 0.8999, rect), control2: pt(0.4238, 0.8950, rect))
                p.addCurve(to: pt(0.4186, 0.8839, rect), control1: pt(0.4204, 0.8879, rect), control2: pt(0.4195, 0.8859, rect))
                p.closeSubpath()
                p.move(to: pt(0.5788, 0.8852, rect))
                p.addCurve(to: pt(0.5853, 0.8679, rect), control1: pt(0.5806, 0.8809, rect), control2: pt(0.5833, 0.8735, rect))
                p.addCurve(to: pt(0.6170, 0.8404, rect), control1: pt(0.5930, 0.8601, rect), control2: pt(0.6087, 0.8444, rect))
                p.addCurve(to: pt(0.6278, 0.8360, rect), control1: pt(0.6199, 0.8391, rect), control2: pt(0.6238, 0.8376, rect))
                p.addCurve(to: pt(0.6284, 0.8351, rect), control1: pt(0.6280, 0.8357, rect), control2: pt(0.6282, 0.8354, rect))
                p.addCurve(to: pt(0.6055, 0.8693, rect), control1: pt(0.6185, 0.8505, rect), control2: pt(0.6079, 0.8648, rect))
                p.addCurve(to: pt(0.6014, 0.8788, rect), control1: pt(0.6046, 0.8710, rect), control2: pt(0.6031, 0.8744, rect))
                p.addCurve(to: pt(0.5934, 0.8884, rect), control1: pt(0.5980, 0.8822, rect), control2: pt(0.5949, 0.8858, rect))
                p.addCurve(to: pt(0.5695, 0.9148, rect), control1: pt(0.5881, 0.8974, rect), control2: pt(0.5784, 0.9064, rect))
                p.addCurve(to: pt(0.5604, 0.9228, rect), control1: pt(0.5666, 0.9175, rect), control2: pt(0.5635, 0.9202, rect))
                p.addCurve(to: pt(0.5577, 0.9206, rect), control1: pt(0.5571, 0.9247, rect), control2: pt(0.5565, 0.9228, rect))
                p.addCurve(to: pt(0.5672, 0.9061, rect), control1: pt(0.5600, 0.9159, rect), control2: pt(0.5637, 0.9109, rect))
                p.addCurve(to: pt(0.5760, 0.8913, rect), control1: pt(0.5709, 0.9012, rect), control2: pt(0.5736, 0.8963, rect))
                p.addCurve(to: pt(0.5788, 0.8852, rect), control1: pt(0.5770, 0.8893, rect), control2: pt(0.5779, 0.8873, rect))
                p.closeSubpath()
            }
        }

    }

    // MARK: - 人体シルエット

    static func bodyOutlineFront(in rect: CGRect) -> Path {
        Path { p in
            // 首上部（頭を削除し、首から始まる）
            // 自然な首の曲線で終端
            p.move(to: pt(0.44, 0.125, rect))
            p.addQuadCurve(to: pt(0.50, 0.118, rect), control: pt(0.47, 0.115, rect))
            p.addQuadCurve(to: pt(0.56, 0.125, rect), control: pt(0.53, 0.115, rect))
            p.addLine(to: pt(0.545, 0.148, rect))
            p.addLine(to: pt(0.455, 0.148, rect))
            p.closeSubpath()
            // 胴体
            p.move(to: pt(0.29, 0.185, rect))
            p.addQuadCurve(to: pt(0.50, 0.176, rect), control: pt(0.39, 0.170, rect))
            p.addQuadCurve(to: pt(0.71, 0.185, rect), control: pt(0.61, 0.170, rect))
            p.addLine(to: pt(0.62, 0.450, rect))
            p.addQuadCurve(to: pt(0.50, 0.460, rect), control: pt(0.56, 0.460, rect))
            p.addQuadCurve(to: pt(0.38, 0.450, rect), control: pt(0.44, 0.460, rect))
            p.closeSubpath()
            // 左腕
            p.move(to: pt(0.29, 0.190, rect))
            p.addQuadCurve(to: pt(0.23, 0.345, rect), control: pt(0.23, 0.265, rect))
            p.addLine(to: pt(0.21, 0.445, rect))
            p.addLine(to: pt(0.27, 0.445, rect))
            p.addQuadCurve(to: pt(0.34, 0.260, rect), control: pt(0.32, 0.345, rect))
            p.closeSubpath()
            // 右腕
            p.move(to: pt(0.71, 0.190, rect))
            p.addQuadCurve(to: pt(0.77, 0.345, rect), control: pt(0.77, 0.265, rect))
            p.addLine(to: pt(0.79, 0.445, rect))
            p.addLine(to: pt(0.73, 0.445, rect))
            p.addQuadCurve(to: pt(0.66, 0.260, rect), control: pt(0.68, 0.345, rect))
            p.closeSubpath()
            // 左脚（ふくらはぎ〜足首まで延長）
            p.move(to: pt(0.39, 0.455, rect))
            p.addLine(to: pt(0.50, 0.460, rect))
            p.addQuadCurve(to: pt(0.485, 0.730, rect), control: pt(0.492, 0.595, rect))
            p.addQuadCurve(to: pt(0.475, 0.870, rect), control: pt(0.490, 0.800, rect))
            p.addQuadCurve(to: pt(0.460, 0.955, rect), control: pt(0.470, 0.920, rect))
            p.addLine(to: pt(0.420, 0.955, rect))
            p.addQuadCurve(to: pt(0.395, 0.870, rect), control: pt(0.405, 0.920, rect))
            p.addQuadCurve(to: pt(0.385, 0.730, rect), control: pt(0.385, 0.800, rect))
            p.addQuadCurve(to: pt(0.39, 0.455, rect), control: pt(0.383, 0.595, rect))
            p.closeSubpath()
            // 右脚（ふくらはぎ〜足首まで延長）
            p.move(to: pt(0.61, 0.455, rect))
            p.addLine(to: pt(0.50, 0.460, rect))
            p.addQuadCurve(to: pt(0.515, 0.730, rect), control: pt(0.508, 0.595, rect))
            p.addQuadCurve(to: pt(0.525, 0.870, rect), control: pt(0.510, 0.800, rect))
            p.addQuadCurve(to: pt(0.540, 0.955, rect), control: pt(0.530, 0.920, rect))
            p.addLine(to: pt(0.580, 0.955, rect))
            p.addQuadCurve(to: pt(0.605, 0.870, rect), control: pt(0.595, 0.920, rect))
            p.addQuadCurve(to: pt(0.615, 0.730, rect), control: pt(0.615, 0.800, rect))
            p.addQuadCurve(to: pt(0.61, 0.455, rect), control: pt(0.617, 0.595, rect))
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

    /// フロントビューで表示する筋肉（11筋肉）
    static let frontMuscles: [(muscle: Muscle, path: (CGRect) -> Path)] = [
        (.chestUpper, Front.chestUpper),
        (.chestLower, Front.chestLower),
        (.deltoidAnterior, Front.deltoidAnterior),
        (.biceps, Front.biceps),
        (.forearms, Front.forearms),
        (.rectusAbdominis, Front.rectusAbdominis),
        (.obliques, Front.obliques),
        (.quadriceps, Front.quadriceps),
        (.hipFlexors, Front.hipFlexors),
        (.gastrocnemius, Front.gastrocnemius),
        (.soleus, Front.soleus),
    ]

    /// バックビューで表示する筋肉（13筋肉）
    static let backMuscles: [(muscle: Muscle, path: (CGRect) -> Path)] = [
        (.trapsUpper, Back.trapsUpper),
        (.trapsMiddleLower, Back.trapsMiddleLower),
        (.lats, Back.lats),
        (.erectorSpinae, Back.erectorSpinae),
        (.deltoidPosterior, Back.deltoidPosterior),
        (.deltoidLateral, Back.deltoidLateral),
        (.triceps, Back.triceps),
        (.forearms, Back.forearms),
        (.glutes, Back.glutes),
        (.hamstrings, Back.hamstrings),
        (.adductors, Back.adductors),
        (.gastrocnemius, Back.gastrocnemius),
        (.soleus, Back.soleus),
    ]
}
