#!/usr/bin/env python3
"""Generate the vector-search demo seed and scenario queries.

Embeds each article and each natural-language query with all-MiniLM-L6-v2
(384-dim) and writes:

  cql/04_seed_data.cql        -- INSERTs with the article embedding inlined
  cql/scenarios/01..0N.cql    -- ANN queries with the query embedding inlined

Run once (the emitted CQL is checked in, so cqlsh needs no model at runtime):

  pip install sentence-transformers
  python tools/gen_seed.py

The article corpus and the query set live here and are independent from the
FTS demo — the two demos share nothing.
"""

from __future__ import annotations

from pathlib import Path

from sentence_transformers import SentenceTransformer

MODEL_NAME = "sentence-transformers/all-MiniLM-L6-v2"

CQL_DIR = Path(__file__).resolve().parent.parent / "cql"

ARTICLES = [
    ("v0000000-0000-4000-8000-000000000001", "Photosynthesis",
     "Green plants, algae, and some bacteria feed themselves by capturing light with the pigment chlorophyll in their leaves. They take in carbon dioxide and water and build sugars that nourish the organism, releasing oxygen as a by-product."),
    ("v0000000-0000-4000-8000-000000000002", "Jupiter",
     "The largest planet in the Solar System is a swirling ball of hydrogen and helium with a centuries-old storm called the Great Red Spot and a large family of orbiting moons."),
    ("v0000000-0000-4000-8000-000000000003", "Saturn",
     "This ringed world is the second largest planet, a low-density gas giant encircled by bright bands of orbiting ice and rock that make it a favourite target for backyard telescopes."),
    ("v0000000-0000-4000-8000-000000000004", "Lion",
     "A large social cat of the African grasslands, it lives in prides and hunts antelope and zebra as a coordinated group, the males recognisable by their heavy manes."),
    ("v0000000-0000-4000-8000-000000000005", "African elephant",
     "The heaviest land animal roams the savanna and forests of Africa in matriarchal herds, using its trunk to gather food and water and its tusks to dig and strip bark."),
    ("v0000000-0000-4000-8000-000000000006", "Mount Everest",
     "Rising on the border of Nepal and Tibet, this is the highest mountain above sea level, its summit reaching into the jet stream and drawing climbers into a zone with too little oxygen to survive for long."),
    ("v0000000-0000-4000-8000-000000000007", "Pacific Ocean",
     "The largest and deepest body of water on the planet stretches from the Americas to Asia, holding more than half of the free water on Earth and the crushing depths of the Mariana Trench."),
    ("v0000000-0000-4000-8000-000000000008", "Coffee",
     "A brewed drink prepared from roasted beans of the coffea plant, prized for its caffeine and bitter aroma, it is one of the most heavily traded agricultural commodities in the world."),
    ("v0000000-0000-4000-8000-000000000009", "Electric car",
     "An automobile driven by electric motors and powered by a rechargeable battery pack, it produces no tailpipe emissions and is quieter and cheaper to run than a petrol vehicle."),
    ("v0000000-0000-4000-8000-000000000010", "Solar power",
     "Sunlight is turned into electricity by photovoltaic panels or concentrated to drive turbines, giving a clean and renewable source of energy that needs no fuel once installed."),
    ("v0000000-0000-4000-8000-000000000011", "Great Wall of China",
     "A series of fortifications built across the northern frontier of ancient China over many dynasties to guard against nomadic raids, its stone and earthen walls run for thousands of kilometres."),
    ("v0000000-0000-4000-8000-000000000012", "Ludwig van Beethoven",
     "A German composer and pianist who bridged the classical and romantic eras, he wrote nine symphonies and many sonatas, producing some of his greatest works after losing his hearing."),
    ("v0000000-0000-4000-8000-000000000013", "Vaccination",
     "Training the immune system with a harmless piece or weakened form of a pathogen teaches the body to fight the real disease later, a practice that has driven smallpox to extinction and controls measles and polio."),
    ("v0000000-0000-4000-8000-000000000014", "Honey bee",
     "A social insect that lives in large colonies and produces honey and beeswax, it pollinates a huge share of the world's flowering crops as it gathers nectar from flower to flower."),
    ("v0000000-0000-4000-8000-000000000015", "Volcano",
     "A rupture in a planet's crust where molten rock, ash, and gases escape from below, it can build mountains over time and reshape the land with rivers of glowing lava."),
]

QUERIES = [
    ("01_plants_and_sunlight", "how plants make their own food",
     "Semantic query with almost no lexical overlap with the target — expect the Photosynthesis article on top, ahead of Solar power and Coffee."),
    ("02_gas_giants", "giant planets made mostly of gas",
     "Expect the two gas giants (Jupiter, Saturn) ranked ahead of the rocky/earthly articles."),
    ("03_clean_energy", "renewable ways to generate electricity without fuel",
     "Expect Solar power and Electric car, which are semantically about clean energy, near the top."),
    ("04_african_wildlife", "large wild animals of the African plains",
     "Expect Lion and African elephant, even though the query shares few words with either article."),
]

TOP_K = 5


def format_vector(values) -> str:
    return "[" + ", ".join(f"{v:.6f}" for v in values) + "]"


def write_seed(model: SentenceTransformer) -> None:
    embeddings = model.encode([f"{t}. {body}" for _, t, body in ARTICLES])
    lines = [
        "-- ScyllaDB vector-search demo — seed data (15 articles, embeddings inlined).",
        "--",
        "-- GENERATED by tools/gen_seed.py — do not edit by hand.",
        "--",
        "-- Each row carries its all-MiniLM-L6-v2 embedding (384 floats) of the article",
        "-- text, so cqlsh needs no embedding model to seed. Apply after 01_keyspace,",
        "-- 02_tables, and 03_index_vector; the vector index picks these rows up via CDC.",
        "",
        "USE wikipedia;",
        "",
    ]
    for (article_id, title, body), embedding in zip(ARTICLES, embeddings):
        safe_title = title.replace("'", "''")
        safe_body = body.replace("'", "''")
        lines.append(
            f"INSERT INTO articles (article_id, title, article, embedding) VALUES "
            f"({article_id}, '{safe_title}', '{safe_body}', {format_vector(embedding)});"
        )
        lines.append("")
    (CQL_DIR / "04_seed_data.cql").write_text("\n".join(lines))


def write_scenarios(model: SentenceTransformer) -> None:
    scenarios_dir = CQL_DIR / "scenarios"
    scenarios_dir.mkdir(parents=True, exist_ok=True)
    embeddings = model.encode([text for _, text, _ in QUERIES])
    for (name, text, note), embedding in zip(QUERIES, embeddings):
        content = "\n".join([
            "-- ScyllaDB vector-search demo — semantic (ANN) query.",
            f"-- Query: \"{text}\"",
            f"-- {note}",
            "--",
            "-- GENERATED by tools/gen_seed.py — the vector below is the all-MiniLM-L6-v2",
            "-- embedding of the query text, precomputed and inlined.",
            "USE wikipedia;",
            "",
            f"SELECT article_id, title FROM articles ORDER BY embedding ANN OF {format_vector(embedding)} LIMIT {TOP_K};",
            "",
        ])
        (scenarios_dir / f"{name}.cql").write_text(content)


def main() -> None:
    model = SentenceTransformer(MODEL_NAME)
    write_seed(model)
    write_scenarios(model)
    print(f"Wrote {len(ARTICLES)} articles and {len(QUERIES)} scenario queries to {CQL_DIR}")


if __name__ == "__main__":
    main()
