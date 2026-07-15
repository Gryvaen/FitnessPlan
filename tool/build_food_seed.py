#!/usr/bin/env python3
"""Build assets/food_seed.json from China food composition CSV + Open Food Facts.

Sources:
  - tool/data2026.csv (cn-food-mcp / China food composition style, MIT)
  - Open Food Facts (ODbL) — Chinese-language or China/HK/TW products with per-100g macros

Usage:
  python3 tool/build_food_seed.py              # refresh OFF cache then merge
  python3 tool/build_food_seed.py --offline    # CSV + existing cache only
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

# Shared with convert_cn_food_csv.py — first match wins.
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
    ("蔬菜", ["菜", "白菜", "青菜", "菠菜", "芹菜", "韭菜", "葱", "蒜", "姜", "洋葱", "番茄", "西红柿", "黄瓜", "茄子", "辣椒", "青椒", "萝卜", "胡萝卜", "冬瓜", "南瓜", "丝瓜", "苦瓜", "西葫芦", "莴笋", "生菜", "油麦菜", "空心菜", "西兰花", "花菜", "菜花", "包菜", "甘蓝", "芦笋", "竹笋", "莲藕", "茭白", "豆角", "四季豆", "豇豆", "玉米笋", "金针", "芥菜", "苋菜", "茼蒿", "蒜苗", "蒜薹", "香菜", "芫荽", "茎", "叶", "瓜", "椒", "笋"]),
    ("谷类", ["米", "饭", "粥", "面", "粉", "馒头", "包子", "饺子", "馄饨", "面条", "挂面", "通心粉", "意面", "燕麦", "小麦", "大麦", "荞麦", "小米", "玉米", "高粱", "糙米", "糯米", "黑米", "紫米", "藜麦", "薏米", "面包", "烙饼", "烧饼", "油条", "花卷", "窝头", "年糕", "粽子", "方便面", "河粉", "米粉", "凉皮", "谷", "麦"]),
]

HAN_RE = re.compile(r"[\u4e00-\u9fff]")
UA = "FitnessPlanFoodImporter/1.0 (local; github.com/FitnessPlan)"
OFF_FIELDS = ",".join(
    [
        "code",
        "product_name",
        "product_name_zh",
        "brands",
        "categories_tags",
        "energy-kcal_100g",
        "energy_100g",
        "proteins_100g",
        "carbohydrates_100g",
        "fat_100g",
    ]
)

# Search queries: Chinese language OR China / Hong Kong / Taiwan markets.
OFF_QUERIES: list[list[tuple[str, str]]] = [
    [("tagtype_0", "languages"), ("tag_contains_0", "contains"), ("tag_0", "zh")],
    [("tagtype_0", "countries"), ("tag_contains_0", "contains"), ("tag_0", "en:china")],
    [("tagtype_0", "countries"), ("tag_contains_0", "contains"), ("tag_0", "en:hong-kong")],
    [("tagtype_0", "countries"), ("tag_contains_0", "contains"), ("tag_0", "en:taiwan")],
]


def parse_num(raw: object | None) -> float | None:
    if raw is None:
        return None
    if isinstance(raw, (int, float)):
        if raw != raw:  # NaN
            return None
        return float(raw)
    s = str(raw).strip()
    if not s or s.lower() in {"tr", "trace", "-", "—", "－", "na", "n/a"}:
        return None
    s = s.replace(",", "")
    m = re.match(r"^-?\d+(\.\d+)?", s)
    if not m:
        return None
    try:
        return float(m.group(0))
    except ValueError:
        return None


def classify(name: str, *, default: str = "其他") -> str:
    for category, keywords in CATEGORY_RULES:
        for kw in keywords:
            if kw in name:
                return category
    return default


def nutrient_score(item: dict) -> float:
    return abs(item["kcal"]) + abs(item["protein"]) + abs(item["carb"]) + abs(item["fat"])


def load_cfct(csv_path: Path) -> dict[str, dict]:
    with csv_path.open(newline="", encoding="utf-8-sig") as f:
        rows = list(csv.reader(f))
    if not rows:
        raise SystemExit(f"empty CSV: {csv_path}")
    header = [h.replace("\n", "").strip() for h in rows[0]]

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
        kcal = parse_num(row[i_kcal]) or 0.0
        protein = parse_num(row[i_protein]) or 0.0
        carb = parse_num(row[i_carb]) or 0.0
        fat = parse_num(row[i_fat]) or 0.0
        item = {
            "name": name,
            "category": classify(name),
            "kcal": round(kcal, 1),
            "protein": round(protein, 1),
            "carb": round(carb, 1),
            "fat": round(fat, 1),
            "_src": "cfct",
        }
        prev = by_name.get(name)
        if prev is None or nutrient_score(item) > nutrient_score(prev):
            by_name[name] = item
    return by_name


OFF_DUMP_URL = (
    "https://static.openfoodfacts.org/data/en.openfoodfacts.org.products.csv.gz"
)
OFF_DUMP_PATH = ROOT / "tool" / "off_products.csv.gz"


def _download_file(url: str, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    tmp = dest.with_suffix(dest.suffix + ".part")
    print(f"downloading {url}")
    print(f"  → {dest}")
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=600) as resp, tmp.open("wb") as out:
        total = resp.headers.get("Content-Length")
        total_n = int(total) if total and total.isdigit() else None
        done = 0
        last_pct = -1
        while True:
            chunk = resp.read(1024 * 1024)
            if not chunk:
                break
            out.write(chunk)
            done += len(chunk)
            if total_n:
                pct = int(done * 100 / total_n)
                if pct != last_pct and pct % 5 == 0:
                    print(f"  {pct}% ({done // (1024 * 1024)} MB)")
                    last_pct = pct
    tmp.replace(dest)
    print(f"download complete ({dest.stat().st_size // (1024 * 1024)} MB)")


def _csv_row_relevant(row: dict[str, str]) -> bool:
    countries = (row.get("countries_tags") or "").lower()
    langs = (row.get("languages_tags") or "").lower()
    name_zh = row.get("product_name:zh") or ""
    if any(
        tag in countries
        for tag in ("en:china", "en:hong-kong", "en:taiwan", "en:macau")
    ):
        return True
    if "en:zh" in langs or ",zh" in langs or langs.startswith("zh"):
        return True
    return bool(HAN_RE.search(name_zh))


def _csv_row_to_product(row: dict[str, str]) -> dict:
    return {
        "code": (row.get("code") or "").strip(),
        "product_name": (row.get("product_name") or "").strip(),
        "product_name_zh": (row.get("product_name:zh") or "").strip(),
        "brands": (row.get("brands") or "").strip(),
        "energy-kcal_100g": row.get("energy-kcal_100g") or None,
        "energy_100g": row.get("energy_100g") or None,
        "proteins_100g": row.get("proteins_100g") or None,
        "carbohydrates_100g": row.get("carbohydrates_100g") or None,
        "fat_100g": row.get("fat_100g") or None,
    }


def refresh_off_cache_from_dump(
    cache_path: Path,
    dump_path: Path = OFF_DUMP_PATH,
    *,
    force_download: bool = False,
) -> int:
    import gzip

    if force_download or not dump_path.exists():
        _download_file(OFF_DUMP_URL, dump_path)
    else:
        print(f"using existing dump {dump_path}")

    by_code: dict[str, dict] = {}
    scanned = 0
    kept = 0
    print("streaming dump for Chinese-related products …")
    with gzip.open(dump_path, "rt", encoding="utf-8", errors="replace") as f:
        reader = csv.DictReader(f, delimiter="\t")
        for row in reader:
            scanned += 1
            if scanned % 200_000 == 0:
                print(f"  scanned {scanned:,}, kept {kept:,}")
            if not _csv_row_relevant(row):
                continue
            product = _csv_row_to_product(row)
            code = product["code"]
            if not code:
                continue
            by_code[code] = product
            kept = len(by_code)

    _write_cache(cache_path, by_code)
    print(f"dump filter done: scanned {scanned:,}, cache {len(by_code):,} → {cache_path}")
    return len(by_code)


def _http_get_json(url: str, retries: int = 12) -> dict:
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "application/json"})
    delay = 2.0
    last_err: Exception | None = None
    for attempt in range(retries):
        try:
            with urllib.request.urlopen(req, timeout=90) as resp:
                return json.loads(resp.read().decode("utf-8"))
        except urllib.error.HTTPError as e:
            last_err = e
            if e.code in {429, 500, 502, 503, 504} and attempt + 1 < retries:
                print(f"    retry {attempt + 1}/{retries} after HTTP {e.code}, sleep {delay:.1f}s")
                time.sleep(delay)
                delay = min(delay * 1.6, 45)
                continue
            raise
        except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as e:
            last_err = e
            if attempt + 1 < retries:
                print(f"    retry {attempt + 1}/{retries} after {type(e).__name__}, sleep {delay:.1f}s")
                time.sleep(delay)
                delay = min(delay * 1.6, 45)
                continue
            raise
    raise RuntimeError(f"GET failed: {url}") from last_err


def fetch_off_query(
    tag_params: list[tuple[str, str]],
    *,
    by_code: dict[str, dict],
    cache_path: Path,
    page_size: int = 100,
) -> None:
    page = 1
    total_pages = 1
    page_fail_streak = 0
    while page <= total_pages:
        params = {
            "action": "process",
            "json": "1",
            "page_size": str(page_size),
            "page": str(page),
            "fields": OFF_FIELDS,
            **dict(tag_params),
        }
        url = "https://world.openfoodfacts.org/cgi/search.pl?" + urllib.parse.urlencode(params)
        try:
            data = _http_get_json(url)
            page_fail_streak = 0
        except Exception as e:  # noqa: BLE001
            page_fail_streak += 1
            print(f"  WARN page {page} failed ({e}); streak={page_fail_streak}")
            if page_fail_streak >= 5:
                print(f"  giving up query after {page_fail_streak} consecutive page failures")
                break
            time.sleep(20)
            continue
        total_pages = int(data.get("page_count") or 1)
        batch = data.get("products") or []
        for p in batch:
            code = str(p.get("code") or "").strip()
            if code:
                by_code[code] = p
        _write_cache(cache_path, by_code)
        print(
            f"  OFF page {page}/{total_pages} (+{len(batch)}, "
            f"unique cache {len(by_code)})"
        )
        if not batch:
            break
        page += 1
        time.sleep(0.55)


def _write_cache(cache_path: Path, by_code: dict[str, dict]) -> None:
    cache_path.parent.mkdir(parents=True, exist_ok=True)
    tmp = cache_path.with_suffix(".tmp")
    with tmp.open("w", encoding="utf-8") as out:
        for p in by_code.values():
            out.write(json.dumps(p, ensure_ascii=False) + "\n")
    tmp.replace(cache_path)


def refresh_off_cache_via_api(cache_path: Path) -> int:
    by_code: dict[str, dict] = {}
    for p in load_off_cache(cache_path):
        code = str(p.get("code") or "").strip()
        if code:
            by_code[code] = p
    if by_code:
        print(f"resumed OFF cache with {len(by_code)} products")

    for tag_params in OFF_QUERIES:
        label = dict(tag_params).get("tag_0", "?")
        print(f"fetch OFF query {label} …")
        fetch_off_query(tag_params, by_code=by_code, cache_path=cache_path)
        time.sleep(1.0)

    _write_cache(cache_path, by_code)
    print(f"wrote OFF cache {len(by_code)} products → {cache_path}")
    return len(by_code)


def load_off_cache(cache_path: Path) -> list[dict]:
    if not cache_path.exists():
        return []
    items: list[dict] = []
    with cache_path.open(encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            items.append(json.loads(line))
    return items


def pick_chinese_name(product: dict) -> str | None:
    candidates = [
        product.get("product_name_zh"),
        product.get("product_name"),
    ]
    for raw in candidates:
        if not raw or not isinstance(raw, str):
            continue
        name = " ".join(raw.split()).strip()
        if name and HAN_RE.search(name):
            return name
    return None


def first_brand(brands: object | None) -> str:
    if not brands or not isinstance(brands, str):
        return ""
    # OFF brands are comma-separated.
    part = brands.split(",")[0].strip()
    return part[:40]


def off_macros(product: dict) -> tuple[float, float, float, float] | None:
    nutriments = product.get("nutriments") or {}
    # When using fields=..., macros may be top-level OR under nutriments depending on API.
    def get(*keys: str) -> float | None:
        for k in keys:
            if k in product and product[k] is not None:
                v = parse_num(product[k])
                if v is not None:
                    return v
            if isinstance(nutriments, dict) and k in nutriments:
                v = parse_num(nutriments[k])
                if v is not None:
                    return v
        return None

    kcal = get("energy-kcal_100g", "energy-kcal_value")
    if kcal is None:
        kj = get("energy_100g", "energy-kj_100g")
        if kj is not None:
            kcal = kj / 4.184
    protein = get("proteins_100g")
    carb = get("carbohydrates_100g")
    fat = get("fat_100g")
    if None in (kcal, protein, carb, fat):
        return None
    assert kcal is not None and protein is not None and carb is not None and fat is not None
    # Sanity: reject absurd rows
    if kcal < 0 or kcal > 1200:
        return None
    if min(protein, carb, fat) < 0 or max(protein, carb, fat) > 120:
        return None
    return (round(kcal, 1), round(protein, 1), round(carb, 1), round(fat, 1))


def off_to_items(products: list[dict]) -> dict[str, dict]:
    by_name: dict[str, dict] = {}
    for p in products:
        base = pick_chinese_name(p)
        if not base:
            continue
        macros = off_macros(p)
        if macros is None:
            continue
        kcal, protein, carb, fat = macros
        brand = first_brand(p.get("brands"))
        # Prefer branded display name when brand adds signal and isn't already in name.
        if brand and brand not in base and HAN_RE.search(brand):
            name = f"{brand} {base}"
        else:
            name = base
        name = name[:80].strip()
        if not name:
            continue
        cat = classify(name, default="包装食品")
        if cat == "其他":
            cat = "包装食品"
        item = {
            "name": name,
            "category": cat,
            "kcal": kcal,
            "protein": protein,
            "carb": carb,
            "fat": fat,
            "_src": "off",
        }
        prev = by_name.get(name)
        if prev is None or nutrient_score(item) > nutrient_score(prev):
            by_name[name] = item
    return by_name


def merge(cfct: dict[str, dict], off: dict[str, dict]) -> list[dict]:
    # CFCT wins on name conflict.
    merged = dict(off)
    merged.update(cfct)
    foods: list[dict] = []
    for item in merged.values():
        foods.append(
            {
                "name": item["name"],
                "category": item["category"],
                "kcal": item["kcal"],
                "protein": item["protein"],
                "carb": item["carb"],
                "fat": item["fat"],
            }
        )
    foods.sort(key=lambda x: (x["category"], x["name"]))
    return foods


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--csv", type=Path, default=ROOT / "tool" / "data2026.csv")
    parser.add_argument("--cache", type=Path, default=ROOT / "tool" / "off_zh_cache.jsonl")
    parser.add_argument("--dump", type=Path, default=OFF_DUMP_PATH)
    parser.add_argument("--output", type=Path, default=ROOT / "assets" / "food_seed.json")
    parser.add_argument(
        "--offline",
        action="store_true",
        help="Do not download; use existing OFF cache only",
    )
    parser.add_argument(
        "--source",
        choices=("dump", "api"),
        default="dump",
        help="How to refresh OFF cache (default: official CSV dump)",
    )
    parser.add_argument(
        "--force-download",
        action="store_true",
        help="Re-download OFF CSV dump even if present",
    )
    args = parser.parse_args()

    if not args.csv.exists():
        raise SystemExit(f"missing CSV: {args.csv}")

    if not args.offline:
        if args.source == "dump":
            refresh_off_cache_from_dump(
                args.cache,
                args.dump,
                force_download=args.force_download,
            )
        else:
            refresh_off_cache_via_api(args.cache)
    elif not args.cache.exists():
        raise SystemExit(f"--offline but missing cache: {args.cache}")

    cfct = load_cfct(args.csv)
    print(f"CFCT foods: {len(cfct)}")
    off_raw = load_off_cache(args.cache)
    off = off_to_items(off_raw)
    print(f"OFF eligible (Chinese + macros): {len(off)}")
    foods = merge(cfct, off)
    packaged = sum(1 for f in foods if f["category"] == "包装食品")
    print(f"merged unique: {len(foods)} (包装食品={packaged})")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="utf-8") as out:
        json.dump(foods, out, ensure_ascii=False, indent=2)
        out.write("\n")
    print(f"wrote {len(foods)} foods → {args.output}")


if __name__ == "__main__":
    main()
