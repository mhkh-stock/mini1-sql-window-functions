"""Rebuild demo.db and re-verify all 10 Mini #1 queries.

Run:  python3 run_queries.py
Does: rebuilds data/demo.db from data/schema.sql + data/seed.sql,
      runs every file in sql/ (stdlib sqlite3 only, no dependencies),
      and asserts every number the README claims.
Does NOT rewrite outputs/*.txt — those are the sqlite3
`-header -column` record of the same queries, verified byte-identical
against a fresh run on 2026-11-07.

Exits 1 on any failure. Requires Python 3 + SQLite 3.25+
(window functions). Verified on SQLite 3.45.1.
"""

import sqlite3
import sys
from pathlib import Path

BASE = Path(__file__).resolve().parent

fails = []
passed = 0


def check(name, cond, detail=""):
    global passed
    print(f"{'PASS' if cond else 'FAIL'}: {name} {detail}")
    if cond:
        passed += 1
    else:
        fails.append(name)


def main():
    db = BASE / "data" / "demo.db"
    if db.exists():
        db.unlink()
    con = sqlite3.connect(db)
    con.executescript((BASE / "data" / "schema.sql").read_text())
    con.executescript((BASE / "data" / "seed.sql").read_text())
    con.commit()

    counts = dict(zip(
        ["customers", "products", "orders", "lines"],
        [con.execute(f"SELECT COUNT(*) FROM {t}").fetchone()[0]
         for t in ["customers", "products", "orders", "order_items"]]))
    check("base data counts", counts == {"customers": 10, "products": 8,
                                         "orders": 32, "lines": 52},
          str(counts))

    total = con.execute(
        "SELECT SUM(quantity * unit_price_at_sale) FROM order_items"
    ).fetchone()[0]
    check("total revenue = 346,800", total == 346800, f"got {total}")

    monthly = con.execute(
        "SELECT SUM(oi.quantity * oi.unit_price_at_sale) FROM orders o "
        "JOIN order_items oi ON oi.order_id = o.order_id "
        "GROUP BY strftime('%Y-%m', o.order_date)").fetchall()
    check("monthly sum = 346,800", sum(r[0] for r in monthly) == 346800)

    cust_sum = con.execute(
        "SELECT SUM(t) FROM (SELECT SUM(oi.quantity * oi.unit_price_at_sale) t "
        "FROM orders o JOIN order_items oi ON oi.order_id = o.order_id "
        "GROUP BY o.customer_id)").fetchone()[0]
    check("customer sum = 346,800", cust_sum == 346800)

    check("no orders without lines",
          con.execute("SELECT COUNT(*) FROM orders o WHERE NOT EXISTS "
                      "(SELECT 1 FROM order_items oi "
                      "WHERE oi.order_id = o.order_id)").fetchone()[0] == 0)
    check("no orphan order lines",
          con.execute("SELECT COUNT(*) FROM order_items oi WHERE NOT EXISTS "
                      "(SELECT 1 FROM orders o WHERE o.order_id = oi.order_id) "
                      "OR NOT EXISTS (SELECT 1 FROM products p "
                      "WHERE p.product_id = oi.product_id)").fetchone()[0] == 0)

    results = {}
    for path in sorted((BASE / "sql").glob("*.sql")):
        cur = con.execute(path.read_text())
        cols = [d[0] for d in cur.description]
        rows = cur.fetchall()
        results[path.stem[:2]] = (cols, rows)
        print(f"ran {path.name}: {len(rows)} rows")

    # Q01 — top products per category
    q01 = results["01"][1]
    check("Q01: 8 rows", len(q01) == 8, str(len(q01)))
    tops = {(r[0], r[1]): r[2] for r in q01}
    check("Q01: category tops",
          tops.get(("Furniture", "Office Chair")) == 72000
          and tops.get(("Kitchen", "Dinner Set 24pc")) == 58000
          and tops.get(("Electronics", "Mechanical Keyboard")) == 51000,
          str(tops))

    # Q02 — latest order per customer
    check("Q02: 10 rows, one per customer", len(results["02"][1]) == 10)

    # Q03 — running total
    q03 = results["03"][1]
    check("Q03: 6 months", len(q03) == 6)
    check("Q03: Jan 37,100, Jun running total 346,800",
          q03[0][1] == 37100 and q03[-1][3] == 346800,
          f"Jan={q03[0][1]} Jun running={q03[-1][3]}")

    # Q04 — days between repeat orders
    q04 = results["04"][1]
    null_gaps = sum(1 for r in q04 if r[4] is None)
    check("Q04: 32 rows", len(q04) == 32)
    check("Q04: 10 NULL gaps (one first order per customer)",
          null_gaps == 10, f"got {null_gaps}")

    # Q05 — three-month moving average
    q05 = results["05"][1]
    check("Q05: 6 months", len(q05) == 6)
    check("Q05: Jun moving average 76,400 vs Jun revenue 94,200",
          q05[-1][1] == 94200 and q05[-1][2] == 76400.0,
          f"Jun revenue={q05[-1][1]} MA={q05[-1][2]}")

    # Q06 — customer ranking
    q06 = results["06"][1]
    check("Q06: 10 rows", len(q06) == 10)
    check("Q06: #1 Ayesha Khan PKR 56,700 (4 orders)",
          q06[0][0] == "Ayesha Khan" and q06[0][2] == 4
          and q06[0][3] == 56700 and q06[0][4] == 1, str(q06[0]))

    # Q07 — correct totals, must agree with Q06
    q07 = results["07"][1]
    q06_map = {r[0]: (r[2], r[3]) for r in q06}
    q07_map = {r[0]: (r[1], r[2]) for r in q07}
    check("Q07: 10 rows", len(q07) == 10)
    check("Q07: totals match Q06 on every customer", q07_map == q06_map)
    check("Q07: sum 346,800", sum(r[2] for r in q07) == 346800)

    # Q08 — share of category revenue
    q08 = results["08"][1]
    check("Q08: 8 rows", len(q08) == 8)
    shares = {}
    for r in q08:
        shares.setdefault(r[0], 0.0)
        shares[r[0]] += r[3]
    check("Q08: shares sum to 100% within each category",
          all(abs(v - 100.0) < 0.05 for v in shares.values()), str(shares))

    # Q09 — spend quartiles
    q09 = results["09"][1]
    check("Q09: 10 rows", len(q09) == 10)
    q1 = [r[0] for r in q09 if r[2] == 1]
    sizes = [sum(1 for r in q09 if r[2] == k) for k in (1, 2, 3, 4)]
    check("Q09: quartile 1 = Ayesha Khan, Bilal Ahmed, Fatima Noor",
          q1 == ["Ayesha Khan", "Bilal Ahmed", "Fatima Noor"], str(q1))
    check("Q09: quartile sizes 3, 3, 2, 2", sizes == [3, 3, 2, 2],
          str(sizes))

    # Q10 — first and last order value
    q10 = results["10"][1]
    check("Q10: 10 rows", len(q10) == 10)
    ayesha = [r for r in q10 if r[0] == "Ayesha Khan"][0]
    check("Q10: Ayesha Khan 11,800 -> 12,000",
          ayesha[1] == 11800 and ayesha[2] == 12000, str(ayesha))

    print(f"\n{passed} checks passed, {len(fails)} failed.")
    if fails:
        print("FAILED:", ", ".join(fails))
        sys.exit(1)
    print("All checks green.")


if __name__ == "__main__":
    main()
