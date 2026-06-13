#!/usr/bin/env node
// SwiftUI MusclePathData.swift → SVG path JSON 変換スクリプト
const fs = require('fs');

const swiftFile = fs.readFileSync(
  '/Users/og3939397/MuscleMap/MuscleMap/Views/Home/MusclePathData.swift',
  'utf8'
);

const lines = swiftFile.split('\n');

// パース状態
let currentView = null; // 'front' | 'back'
let currentMuscle = null;
let pathCommands = [];
const result = {
  viewBox: "0 0 1 1",
  note: "Coordinates are normalized 0-1. Original source viewBox: 0 0 248.333 557.994",
  front: {},
  back: {}
};

// muscle名マッピング (Swift func名 → muscle ID)
const muscleIdMap = {
  chestUpper: 'chest_upper',
  chestLower: 'chest_lower',
  deltoidAnterior: 'deltoid_anterior',
  deltoidLateral: 'deltoid_lateral',
  deltoidPosterior: 'deltoid_posterior',
  biceps: 'biceps',
  triceps: 'triceps',
  forearms: 'forearms',
  rectusAbdominis: 'rectus_abdominis',
  obliques: 'obliques',
  quadriceps: 'quadriceps',
  hipFlexors: 'hip_flexors',
  gastrocnemius: 'gastrocnemius',
  soleus: 'soleus',
  trapsUpper: 'traps_upper',
  trapsMiddleLower: 'traps_middle_lower',
  lats: 'lats',
  erectorSpinae: 'erector_spinae',
  glutes: 'glutes',
  hamstrings: 'hamstrings',
  adductors: 'adductors',
};

function flushMuscle() {
  if (currentMuscle && currentView && pathCommands.length > 0) {
    const muscleId = muscleIdMap[currentMuscle] || currentMuscle;
    result[currentView][muscleId] = pathCommands.join(' ');
    pathCommands = [];
  }
}

// pt(x, y, rect) の数値を抽出
function extractPt(str) {
  const m = str.match(/pt\(\s*([\d.]+)\s*,\s*([\d.]+)/);
  if (!m) return null;
  return { x: parseFloat(m[1]), y: parseFloat(m[2]) };
}

function extractAllPts(str) {
  const pts = [];
  const re = /pt\(\s*([\d.]+)\s*,\s*([\d.]+)/g;
  let m;
  while ((m = re.exec(str)) !== null) {
    pts.push({ x: parseFloat(m[1]), y: parseFloat(m[2]) });
  }
  return pts;
}

// 4桁に丸め
function r(v) {
  return Math.round(v * 10000) / 10000;
}

for (let i = 0; i < lines.length; i++) {
  const line = lines[i].trim();

  // ビュー判定
  if (line === 'enum Front {') {
    currentView = 'front';
    continue;
  }
  if (line === 'enum Back {') {
    flushMuscle();
    currentView = 'back';
    continue;
  }

  // 筋肉関数開始
  const funcMatch = line.match(/static func (\w+)\(in rect:/);
  if (funcMatch) {
    flushMuscle();
    currentMuscle = funcMatch[1];
    continue;
  }

  // bodyOutline等はスキップ
  if (currentMuscle === 'bodyOutlineFront' || currentMuscle === 'bodyOutlineBack') {
    continue;
  }

  // パスコマンド解析
  if (line.includes('p.move(to:')) {
    const pt = extractPt(line);
    if (pt) pathCommands.push(`M ${r(pt.x)} ${r(pt.y)}`);
  } else if (line.includes('p.addLine(to:')) {
    const pt = extractPt(line);
    if (pt) pathCommands.push(`L ${r(pt.x)} ${r(pt.y)}`);
  } else if (line.includes('p.addCurve(to:')) {
    // SwiftUI: addCurve(to: dest, control1: c1, control2: c2)
    // SVG: C c1x c1y c2x c2y dx dy
    // But might span multiple lines - collect full statement
    let fullLine = line;
    while (!fullLine.includes('closeSubpath') && !fullLine.endsWith(')') && !fullLine.endsWith('))')) {
      i++;
      if (i >= lines.length) break;
      fullLine += ' ' + lines[i].trim();
    }

    const pts = extractAllPts(fullLine);
    if (pts.length >= 3) {
      // pts[0] = to (destination), pts[1] = control1, pts[2] = control2
      pathCommands.push(`C ${r(pts[1].x)} ${r(pts[1].y)} ${r(pts[2].x)} ${r(pts[2].y)} ${r(pts[0].x)} ${r(pts[0].y)}`);
    }
  } else if (line.includes('p.addQuadCurve(to:')) {
    const pts = extractAllPts(line);
    if (pts.length >= 2) {
      pathCommands.push(`Q ${r(pts[1].x)} ${r(pts[1].y)} ${r(pts[0].x)} ${r(pts[0].y)}`);
    }
  } else if (line.includes('closeSubpath')) {
    pathCommands.push('Z');
  }

  // セクション終了判定（bodyOutlineに到達したらflush）
  if (line.includes('static func bodyOutline')) {
    flushMuscle();
    currentMuscle = null;
    currentView = null;
  }
}

flushMuscle();

// 検証
const frontCount = Object.keys(result.front).length;
const backCount = Object.keys(result.back).length;
console.log(`Front muscles: ${frontCount} — ${Object.keys(result.front).join(', ')}`);
console.log(`Back muscles: ${backCount} — ${Object.keys(result.back).join(', ')}`);
console.log(`Total: ${frontCount + backCount}`);

const outputPath = '/Users/og3939397/Developer/MuscleMapContent/src/assets/muscle_paths.json';
fs.writeFileSync(outputPath, JSON.stringify(result, null, 2));
console.log(`\nWritten to: ${outputPath}`);
