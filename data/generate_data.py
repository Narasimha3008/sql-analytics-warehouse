#!/usr/bin/env python3
"""Generate synthetic retail data for the SQL analytics warehouse.

Deterministic (seeded) so results are reproducible. Writes CSVs to data/
and, if run with --build-db, loads everything into retail.db.

    python3 generate_data.py            # CSVs only
    python3 generate_data.py --build-db # CSVs + sqlite database

No real customer data — every name, email, and address is fabricated.
"""

import argparse
import csv
import random
import sqlite3
from datetime import date, timedelta
from pathlib import Path

SEED = 42
DATA_DIR = Path(__file__).resolve().parent

FIRST = ["Aarav", "Maya", "Liam", "Sofia", "Noah", "Aisha", "Ethan", "Priya",
         "Lucas", "Emma", "Arjun", "Olivia", "Mateo", "Ava", "Kabir", "Mia",
         "James", "Zara", "Daniel", "Nina", "Ravi", "Chloe", "Omar", "Ella",
         "Vikram", "Grace", "Diego", "Lena", "Kiran", "Ruby"]

LAST = ["Sharma", "Patel", "Garcia", "Kim", "Nguyen", "Singh", "Johnson",
        "Brown", "Davis", "Miller", "Khan", "Reddy", "Lopez", "Hernandez",
        "Gonzalez", "Wilson", "Anderson", "Thomas", "Moore", "Martin",
        "Lee", "Walker", "Hall", "Young", "King", "Wright", "Scott", "Green"]

CITIES = [("New York", "NY", "Northeast"), ("Boston", "MA", "Northeast"),
          ("Chicago", "IL", "Midwest"), ("Minneapolis", "MN", "Midwest"),
          ("Dallas", "TX", "South"), ("Atlanta", "GA", "South"),
          ("Miami", "FL", "South"), ("Denver", "CO", "West"),
          ("Seattle", "WA", "West"), ("San Francisco", "CA", "West"),
          ("Los Angeles", "CA", "West"), ("Phoenix", "AZ", "West")]

PRODUCTS = [
    # (name, category, subcategory, unit_cost, unit_price)
    ("Wireless Headphones", "Electronics", "Audio", 45, 129),
    ("4K Smart TV 55in", "Electronics", "TV & Video", 320, 699),
    ("Laptop Stand Pro", "Electronics", "Accessories", 18, 59),
    ("Mechanical Keyboard", "Electronics", "Accessories", 35, 99),
    ("Smart Watch", "Electronics", "Wearables", 90, 249),
    ("Bluetooth Speaker", "Electronics", "Audio", 28, 79),
    ("Denim Jacket", "Apparel", "Outerwear", 30, 89),
    ("Running Shoes", "Apparel", "Footwear", 40, 120),
    ("Cotton T-Shirt", "Apparel", "Tops", 8, 25),
    ("Wool Sweater", "Apparel", "Tops", 25, 75),
    ("Yoga Pants", "Apparel", "Bottoms", 15, 45),
    ("Leather Wallet", "Apparel", "Accessories", 12, 40),
    ("Coffee Maker", "Home", "Kitchen", 55, 149),
    ("Air Fryer", "Home", "Kitchen", 48, 129),
    ("Robot Vacuum", "Home", "Cleaning", 150, 399),
    ("Desk Lamp", "Home", "Lighting", 14, 39),
    ("Throw Pillow Set", "Home", "Decor", 16, 49),
    ("Cast Iron Skillet", "Home", "Kitchen", 20, 55),
    ("Tennis Racket", "Sports", "Racquet Sports", 60, 159),
    ("Yoga Mat", "Sports", "Fitness", 12, 35),
    ("Dumbbell Set", "Sports", "Fitness", 70, 179),
    ("Camping Tent", "Sports", "Outdoor", 80, 219),
    ("Basketball", "Sports", "Team Sports", 10, 30),
    ("Hiking Backpack", "Sports", "Outdoor", 45, 120),
]

START = date(2024, 1, 1)
END = date(2026, 8, 31)


def rand_date(rng, lo=START, hi=END):
    return lo + timedelta(days=rng.randint(0, (hi - lo).days))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--build-db", action="store_true")
    ap.add_argument("--customers", type=int, default=2000)
    ap.add_argument("--orders", type=int, default=15000)
    args = ap.parse_args()

    rng = random.Random(SEED)
    DATA_DIR.mkdir(parents=True, exist_ok=True)

    # ---- customers ------------------------------------------------------
    customers = []
    for i in range(1, args.customers + 1):
        fn, ln = rng.choice(FIRST), rng.choice(LAST)
        city, state, region = rng.choice(CITIES)
        signup = rand_date(rng, START, date(2026, 5, 31))
        customers.append({
            "customer_id": i,
            "first_name": fn,
            "last_name": ln,
            "email": f"{fn.lower()}.{ln.lower()}{i}@example.com",
            "city": city, "state": state, "region": region,
            "signup_date": signup.isoformat(),
        })

    # ---- products -------------------------------------------------------
    products = [
        {"product_id": i + 1, "product_name": n, "category": c,
         "subcategory": s, "unit_cost": cost, "unit_price": price}
        for i, (n, c, s, cost, price) in enumerate(PRODUCTS)
    ]

    # ---- orders + order_items -------------------------------------------
    # Higher-value customers order more often; orders skew toward recent dates.
    weights = [rng.uniform(0.2, 1.0) for _ in customers]
    cust_ids = rng.choices([c["customer_id"] for c in customers],
                           weights=weights, k=args.orders)

    orders, items = [], []
    order_id, item_id = 1, 1
    for cid in cust_ids:
        # Recency skew: square the uniform draw so recent dates dominate.
        day_offset = int((END - START).days * (rng.random() ** 0.6))
        odate = START + timedelta(days=day_offset)
        status = rng.choices(["completed", "cancelled", "returned"],
                             weights=[0.9, 0.06, 0.04])[0]
        orders.append({
            "order_id": order_id, "customer_id": cid,
            "order_date": odate.isoformat(), "order_status": status,
            "shipping_mode": rng.choices(["standard", "express", "same-day"],
                                         weights=[0.7, 0.22, 0.08])[0],
        })
        for _ in range(rng.randint(1, 4)):
            p = rng.choice(products)
            qty = rng.randint(1, 3)
            disc = rng.choice([0, 0, 0, 0.1, 0.15, 0.2])
            items.append({
                "order_item_id": item_id, "order_id": order_id,
                "product_id": p["product_id"], "quantity": qty,
                "discount_pct": disc,
            })
            item_id += 1
        order_id += 1

    datasets = {"customers": customers, "products": products,
                "orders": orders, "order_items": items}
    for name, rows in datasets.items():
        with open(DATA_DIR / f"{name}.csv", "w", newline="") as f:
            w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
            w.writeheader()
            w.writerows(rows)
        print(f"{name}.csv: {len(rows):,} rows")

    if args.build_db:
        db_path = DATA_DIR / "retail.db"
        if db_path.exists():
            db_path.unlink()
        con = sqlite3.connect(db_path)
        con.executescript(
            (DATA_DIR.parent / "schema" / "01_schema.sql").read_text())
        for name, rows in datasets.items():
            cols = list(rows[0].keys())
            con.executemany(
                f"INSERT INTO {name} ({','.join(cols)}) "
                f"VALUES ({','.join('?' * len(cols))})",
                [tuple(r[c] for c in cols) for r in rows])
        con.commit()
        print(f"retail.db: {sum(con.execute('SELECT COUNT(*) FROM ' + t).fetchone()[0] for t in datasets):,} rows total")
        con.close()


if __name__ == "__main__":
    main()
