"""Fill the Linux desktop build with ~3 weeks of maintain-goal demo data.

Usage (close the desktop app first):
    python3 -I tool/seed_maintain_demo.py            # seed
    python3 -I tool/seed_maintain_demo.py --restore  # put the backup back

Touches only the desktop data:
    ~/Documents/fitness_plan.sqlite
    ~/.local/share/com.fitnessplan.fitness_plan/shared_preferences.json
The first seed copies both to *.demo-backup; --restore copies them back.
"""

import datetime as dt
import json
import shutil
import sqlite3
import sys
import time
from pathlib import Path

DB = Path.home() / 'Documents/fitness_plan.sqlite'
PREFS = (
    Path.home()
    / '.local/share/com.fitnessplan.fitness_plan/shared_preferences.json'
)
DEMO_FOOD = '[演示] 家常饭'

# Daily intake minus TDEE (kcal), oldest first; the last one is today.
# |net| ≤ max(150, 10%·TDEE) counts as a balanced day.
NETS = [
    120, -80, -450, 60, 180, -150, 0, -60, -520, 40, 250,
    -110, 90, -300, 30, -40, 600, -90, 150, -20, -380, 70,
]
CHEAT_INDEX = 6  # 放纵日：使用用户填写的盈余
CHEAT_KCAL = 1200
MEAL_SPLIT = [('breakfast', 0.25), ('lunch', 0.40), ('dinner', 0.35)]


def backup_paths():
    return [(p, p.with_name(p.name + '.demo-backup')) for p in (DB, PREFS)]


def restore():
    for path, bak in backup_paths():
        if not bak.exists():
            sys.exit(f'没有备份：{bak}')
        shutil.copy2(bak, path)
        bak.unlink()
        print(f'已还原 {path}')


def local_midnight_epoch(day: dt.date) -> int:
    return int(time.mktime(day.timetuple()))


def seed():
    for path, bak in backup_paths():
        if not path.exists():
            sys.exit(f'找不到 {path}：先运行一次 flutter run -d linux 并建档')
        if not bak.exists():
            shutil.copy2(path, bak)
            print(f'已备份 {path} → {bak.name}')

    prefs = json.loads(PREFS.read_text())
    profile = json.loads(prefs['flutter.user_profile'])
    if profile.get('goal') != 'maintain':
        sys.exit('当前档案目标不是「维持」，先在 App 里切到维持再灌数据')
    tdee = float(profile['tdee'])
    targets = profile['targets']

    today = dt.date.today()
    days = [today - dt.timedelta(days=len(NETS) - 1 - i) for i in range(len(NETS))]
    now = int(time.time())

    con = sqlite3.connect(DB)
    cur = con.cursor()
    food_id = cur.execute('select id from food_items order by id limit 1').fetchone()[0]
    cur.execute('delete from meal_entries where food_name = ?', (DEMO_FOOD,))

    for i, (day, net) in enumerate(zip(days, NETS)):
        key = day.isoformat()
        cur.execute(
            'insert or ignore into daily_nutrition_targets '
            '(date, calories, protein_g, carb_g, fat_g, estimated_tdee, source, status, updated_at) '
            "values (?, ?, ?, ?, ?, ?, 'profile', 'confirmed', ?)",
            (key, targets['calories'], targets['proteinG'], targets['carbG'],
             targets['fatG'], tdee, local_midnight_epoch(day)),
        )
        intake = tdee + (300 if i == CHEAT_INDEX else net)
        for meal, share in MEAL_SPLIT:
            kcal = round(intake * share, 1)
            cur.execute(
                'insert into meal_entries (date, meal_type, food_id, food_name, grams, '
                'calories, protein_g, carb_g, fat_g) values (?, ?, ?, ?, ?, ?, ?, ?, ?)',
                (local_midnight_epoch(day), meal, food_id, DEMO_FOOD,
                 round(kcal / 1.5), kcal, round(kcal * 0.25 / 4, 1),
                 round(kcal * 0.5 / 4, 1), round(kcal * 0.25 / 9, 1)),
            )

    cheat_day = days[CHEAT_INDEX]
    cur.execute(
        'insert or replace into day_markers (date, type, updated_at, pause_carb_cycle, '
        'cheat_penalty_enabled, cheat_penalty_kcal, include_steps, include_diet, '
        'exclude_contributions) values (?, ?, ?, 0, 1, ?, 1, 0, 0)',
        (cheat_day.isoformat(), 'cheatMeal',
         local_midnight_epoch(cheat_day) + 20 * 3600, CHEAT_KCAL),
    )
    con.commit()
    con.close()

    prefs['flutter.maintain_cultivation_state'] = json.dumps({
        'frozenBalancedDays': 0,
        'segments': [{'start': days[0].isoformat(), 'end': None}],
    })
    PREFS.write_text(json.dumps(prefs))

    threshold = max(150.0, tdee * 0.1)
    nets = [CHEAT_KCAL if i == CHEAT_INDEX else n for i, n in enumerate(NETS)]
    left = sum(-n for n in nets if n < 0)
    right = sum(n for n in nets if n > 0)
    balanced = sum(
        1 for i, n in enumerate(NETS) if i != CHEAT_INDEX and abs(n) <= threshold
    )
    print(f'已写入 {days[0]} ~ {today}，共 {len(days)} 天（{cheat_day} 为放纵日 +{CHEAT_KCAL}）')
    print(f'预期：左盘 −{left:.0f}、右盘 +{right:.0f}、净 {right - left:+.0f} kcal，平衡日 {balanced} 天')
    print('步数也会计入亏空；桌面版一般没有步数，数字应与上面一致。')


if __name__ == '__main__':
    restore() if '--restore' in sys.argv else seed()
