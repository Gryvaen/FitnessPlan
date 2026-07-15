#!/usr/bin/env python3
"""Convert cn-food-mcp data2026.csv → assets/food_seed.json.

Source: https://github.com/ruffood/cn-food-mcp (MIT) data2026.csv
Usage:
  python3 tool/convert_cn_food_csv.py
  python3 tool/convert_cn_food_csv.py --input tool/data2026.csv --output assets/food_seed.json
"""

from __future__ import annotations

import argparse
import csv
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

# (category, keywords) — first match wins; order matters.
CATEGORY_RULES: list[tuple[str, list[str]]] = [
    ("禽肉", ["鸡", "鸭", "鹅", "鸽", "鹌鹑", "火鸡", "禽"]),
    ("畜肉", ["猪", "牛", "羊", "兔", "马", "驴", "鹿", "骆驼", "狗肉", "肉松", "火腿", "香肠", "腊肉", "培根", "蹄膀", "肘子", "排骨", "里脊", "五花", "瘦肉", "肥肉", "腱子", "腰花", "肝", "心", "肺", "肾", "肚", "肠", "血豆腐", "肉"]),
    ("水产", ["鱼", "虾", "蟹", "贝", "鱿鱼", "墨鱼", "章鱼", "海参", "鲍", "蛤", "蚝", "牡蛎", "扇贝", "贻贝", "螺", "鳝", "鳖", "龟", "海带", "紫菜", "海蜇", "龙虾", "对虾", "河虾", "螃蟹", "鲤", "草鱼", "鲫", "鲈", "带鱼", "黄鱼", "鳕", "鲑", "三文鱼", "金枪鱼", "鲇", "鳗", "泥鳅", "田螺"]),
    ("蛋类", ["蛋", "蛋黄", "蛋清", "皮蛋", "咸蛋", "松花蛋"]),
    ("乳类", ["奶", "乳", "酸奶", "奶酪", "干酪", "乳清", "炼乳", "奶粉", "奶油", "黄油"]),
    ("豆类", ["豆腐", "豆浆", "豆干", "豆皮", "腐竹", "腐乳", "豆豉", "黄豆", "黑豆", "绿豆", "红豆", "赤豆", "芸豆", "蚕豆", "豌豆", "扁豆", "刀豆", "毛豆", "豆芽", "豆沙", "豆粉", "豆"]),
    ("坚果", ["核桃", "杏仁", "花生", "腰果", "开心果", "榛子", "松子", "瓜子", "芝麻", "栗", "夏威夷果", "碧根果", "巴旦木", "白果", "莲子", "芡实"]),
    ("油脂", ["油", "猪油", "牛油", "羊油", "黄油", "酥油", "色拉油", "橄榄油", "香油", "麻油", "棕榈油"]),
    ("调味品", ["盐", "酱油", "醋", "酱", "味精", "鸡精", "花椒", "八角", "桂皮", "香料", "料酒", "蚝油", "豆瓣", "酱汁", "咖喱", "胡椒", "芥末", "番茄酱", "沙拉酱", "调料"]),
    ("糖蜜饯", ["糖", "蜜饯", "果脯", "话梅", "杏脯", "山楂片", "麦芽糖", "蜂蜜", "红糖", "白糖", "冰糖", "砂糖"]),
    ("饮料", ["饮料", "果汁", "可乐", "汽水", "茶", "咖啡", "豆浆", "啤酒", "酒", "白酒", "红酒", "黄酒", "米酒", "葡萄酒", "香槟", "鸡尾酒", "矿泉水", "纯净水", "酸奶饮"]),
    ("小吃", ["饼干", "蛋糕", "面包", "糕点", "月饼", "点心", "薯片", "薯条", "糖果", "巧克力", "冰淇淋", "雪糕", "蛋挞", "泡芙", "威化", "派", "曲奇"]),
    ("菌藻", ["蘑菇", "香菇", "平菇", "金针菇", "杏鲍菇", "口蘑", "木耳", "银耳", "猴头", "茶树菇", "草菇", "海带", "紫菜", "裙带菜", "藻"]),
    ("水果", ["苹果", "梨", "桃", "杏", "李", "枣", "葡萄", "香蕉", "橙", "桔", "橘", "柑", "柚", "柠檬", "西瓜", "哈密瓜", "甜瓜", "草莓", "蓝莓", "樱桃", "猕猴桃", "芒果", "菠萝", "荔枝", "龙眼", "桂圆", "枇杷", "柿", "石榴", "火龙果", "椰子", "榴莲", "山楂", "桑葚", "杨梅", "木瓜", "番石榴", "果干", "葡萄干", "果酱"]),
    ("薯类", ["土豆", "马铃薯", "红薯", "甘薯", "地瓜", "山药", "芋", "芋头", "木薯", "粉丝", "粉条", "淀粉", "藕粉", "凉粉"]),
    ("蔬菜", ["菜", "白菜", "青菜", "菠菜", "芹菜", "韭菜", "葱", "蒜", "姜", "洋葱", "番茄", "西红柿", "黄瓜", "茄子", "辣椒", "青椒", "萝卜", "胡萝卜", "冬瓜", "南瓜", "丝瓜", "苦瓜", "西葫芦", "莴笋", "生菜", "油麦菜", "空心菜", "西兰花", "花菜", "菜花", "包菜", "甘蓝", "西兰花", "芦笋", "竹笋", "莲藕", "茭白", "豆角", "四季豆", "豇豆", "玉米笋", "金针", "芥菜", "苋菜", "茼蒿", "蒜苗", "蒜薹", "香菜", "芫荽", "茎", "叶", "瓜", "椒", "笋"]),
    ("谷类", ["米", "饭", "粥", "面", "粉", "馒头", "包子", "饺子", "馄饨", "面条", "挂面", "通心粉", "意面", "燕麦", "小麦", "大麦", "荞麦", "小米", "玉米", "高粱", "糙米", "糯米", "黑米", "紫米", "藜麦", "薏米", "面包", "烙饼", "烧饼", "油条", "包子", "花卷", "窝头", "年糕", "粽子", "方便面", "粉丝", "河粉", "米粉", "凉皮", "谷", "麦"]),
]


def parse_num(raw: str | None) -> float:
    if raw is None:
        return 0.0
    s = str(raw).strip()
    if not s or s.lower() in {"tr", "trace", "-", "—", "－", "na", "n/a"}:
        return 0.0
    s = s.replace(",", "")
    m = re.match(r"^-?\d+(\.\d+)?", s)
    if not m:
        return 0.0
    try:
        return float(m.group(0))
    except ValueError:
        return 0.0


def classify(name: str) -> str:
    for category, keywords in CATEGORY_RULES:
        for kw in keywords:
            if kw in name:
                return category
    return "其他"


def nutrient_score(item: dict) -> float:
    return abs(item["kcal"]) + abs(item["protein"]) + abs(item["carb"]) + abs(item["fat"])


def convert(input_path: Path, output_path: Path) -> int:
    with input_path.open(newline="", encoding="utf-8-sig") as f:
        reader = csv.reader(f)
        # Multi-line header: first 4 rows are header fragments in this CSV.
        # DictReader works once we join — csv module already parses quoted newlines.
        rows = list(reader)

    if not rows:
        raise SystemExit("empty CSV")

    header = rows[0]
    # Normalize header cells (may contain newlines)
    header = [h.replace("\n", "").strip() for h in header]

    # Find column indices by substring
    def col(*needles: str) -> int:
        for i, h in enumerate(header):
            for n in needles:
                if n in h:
                    return i
        raise KeyError(f"column not found: {needles} in {header}")

    i_name = col("食物")
    i_kcal = col("能量")
    i_protein = col("蛋白质")
    i_carb = col("糖类", "碳水")
    i_fat = col("脂肪")

    by_name: dict[str, dict] = {}
    for row in rows[1:]:
        if len(row) <= max(i_name, i_kcal, i_protein, i_carb, i_fat):
            continue
        name = row[i_name].strip()
        if not name:
            continue
        item = {
            "name": name,
            "category": classify(name),
            "kcal": round(parse_num(row[i_kcal]), 1),
            "protein": round(parse_num(row[i_protein]), 1),
            "carb": round(parse_num(row[i_carb]), 1),
            "fat": round(parse_num(row[i_fat]), 1),
        }
        prev = by_name.get(name)
        if prev is None or nutrient_score(item) > nutrient_score(prev):
            by_name[name] = item

    foods = sorted(by_name.values(), key=lambda x: (x["category"], x["name"]))
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", encoding="utf-8") as out:
        json.dump(foods, out, ensure_ascii=False, indent=2)
        out.write("\n")
    return len(foods)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--input",
        type=Path,
        default=ROOT / "tool" / "data2026.csv",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=ROOT / "assets" / "food_seed.json",
    )
    args = parser.parse_args()
    if not args.input.exists():
        raise SystemExit(f"missing input: {args.input}")
    n = convert(args.input, args.output)
    print(f"wrote {n} foods → {args.output}")


if __name__ == "__main__":
    main()
