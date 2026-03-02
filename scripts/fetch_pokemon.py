#!/usr/bin/env python3
"""
Fetches all 1025 Pokemon from PokeAPI and writes pokemon_data.json
to TeamBuilder/Resources/. Uses only stdlib — no pip required.

Run from the repo root:
    python3 scripts/fetch_pokemon.py

Estimated runtime: ~40–60 seconds (20 parallel workers).
"""

import json
import urllib.request
import urllib.error
from concurrent.futures import ThreadPoolExecutor, as_completed
import time
import sys
import os

BASE_URL = "https://pokeapi.co/api/v2"
TOTAL = 1025
OUTPUT_PATH = os.path.join(os.path.dirname(__file__), "..", "TeamBuilder", "Resources", "pokemon_data.json")


def fetch_json(url: str, retries: int = 3) -> dict:
    """Fetch URL and return parsed JSON, with simple retry logic."""
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "TeamBuilder/1.0 (Pokemon team builder app)"})
            with urllib.request.urlopen(req, timeout=30) as resp:
                return json.loads(resp.read())
        except Exception as e:
            if attempt == retries - 1:
                raise
            time.sleep(1)


def generation_number(name: str) -> int:
    """Convert 'generation-iv' → 4."""
    roman = {"i": 1, "ii": 2, "iii": 3, "iv": 4, "v": 5,
             "vi": 6, "vii": 7, "viii": 8, "ix": 9}
    suffix = name.replace("generation-", "")
    return roman.get(suffix, 0)


def extract_chain_ids(chain_link: dict) -> list[int]:
    """Recursively extract all Pokemon IDs from an evolution chain link."""
    ids = []
    species_url = chain_link["species"]["url"]
    parts = species_url.rstrip("/").split("/")
    if parts[-1].isdigit():
        ids.append(int(parts[-1]))
    for next_link in chain_link.get("evolves_to", []):
        ids.extend(extract_chain_ids(next_link))
    return ids


def fetch_one(pokemon_id: int):
    """Fetch /pokemon/{id} and /pokemon-species/{id}, return merged entry."""
    try:
        poke = fetch_json(f"{BASE_URL}/pokemon/{pokemon_id}")
        species = fetch_json(f"{BASE_URL}/pokemon-species/{pokemon_id}")
    except Exception as e:
        print(f"  ERROR id={pokemon_id}: {e}", file=sys.stderr)
        return None

    # Types (ordered by slot)
    types = [t["type"]["name"] for t in sorted(poke["types"], key=lambda x: x["slot"])]

    # Stats
    stats = {s["stat"]["name"]: s["base_stat"] for s in poke["stats"]}

    # Abilities (ordered by slot)
    abilities = [a["ability"]["name"] for a in sorted(poke["abilities"], key=lambda x: x["slot"])]

    # Generation
    gen = generation_number(species["generation"]["name"])

    # Evolution chain URL — we'll resolve these in a second pass
    evo_chain_url = (species.get("evolution_chain") or {}).get("url", "")

    return {
        "id": pokemon_id,
        "name": poke["name"],
        "types": types,
        "hp": stats.get("hp", 0),
        "attack": stats.get("attack", 0),
        "defense": stats.get("defense", 0),
        "specialAttack": stats.get("special-attack", 0),
        "specialDefense": stats.get("special-defense", 0),
        "speed": stats.get("speed", 0),
        "abilities": abilities,
        "generation": gen,
        "isLegendary": species.get("is_legendary", False),
        "isMythical": species.get("is_mythical", False),
        "_evoChainURL": evo_chain_url,   # temporary — resolved below
        "evolutionChainIDs": [],
    }


def resolve_evo_chains(entries):
    """Fetch unique evolution chains and populate evolutionChainIDs on each entry."""
    # Collect unique chain URLs
    chain_urls = {e["_evoChainURL"] for e in entries if e.get("_evoChainURL")}
    print(f"Fetching {len(chain_urls)} unique evolution chains…")

    chain_map = {}
    def fetch_chain(url):
        try:
            data = fetch_json(url)
            ids = extract_chain_ids(data["chain"])
            return url, ids
        except Exception as e:
            print(f"  Chain ERROR {url}: {e}", file=sys.stderr)
            return url, []

    with ThreadPoolExecutor(max_workers=20) as ex:
        futures = {ex.submit(fetch_chain, url): url for url in chain_urls}
        done = 0
        for future in as_completed(futures):
            url, ids = future.result()
            chain_map[url] = ids
            done += 1
            if done % 50 == 0 or done == len(chain_urls):
                print(f"  {done}/{len(chain_urls)} chains done")

    # Populate entries
    for entry in entries:
        url = entry.pop("_evoChainURL", "")
        entry["evolutionChainIDs"] = chain_map.get(url, [])

    return entries


def main():
    start = time.time()
    print(f"Fetching {TOTAL} Pokemon from PokeAPI…")

    results: list[dict | None] = [None] * (TOTAL + 1)  # index by ID

    with ThreadPoolExecutor(max_workers=20) as ex:
        futures = {ex.submit(fetch_one, i): i for i in range(1, TOTAL + 1)}
        done = 0
        for future in as_completed(futures):
            pokemon_id = futures[future]
            entry = future.result()
            results[pokemon_id] = entry
            done += 1
            if done % 100 == 0 or done == TOTAL:
                elapsed = time.time() - start
                print(f"  {done}/{TOTAL} Pokemon fetched ({elapsed:.0f}s)")

    # Filter None, sort by ID
    entries = [r for r in results if r is not None]
    entries.sort(key=lambda x: x["id"])
    print(f"Successfully fetched {len(entries)}/{TOTAL} Pokemon")

    # Resolve evolution chains
    entries = resolve_evo_chains(entries)

    # Write output
    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
    with open(OUTPUT_PATH, "w") as f:
        json.dump(entries, f, separators=(",", ":"))

    size_kb = os.path.getsize(OUTPUT_PATH) / 1024
    elapsed = time.time() - start
    print(f"\nDone! Wrote {len(entries)} entries to:")
    print(f"  {OUTPUT_PATH}")
    print(f"  Size: {size_kb:.0f} KB")
    print(f"  Time: {elapsed:.0f}s")


if __name__ == "__main__":
    main()
