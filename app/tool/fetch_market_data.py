#!/usr/bin/env python3
"""Regenerates assets/data/market_returns.json from Yahoo Finance.

Run from app/:  python3 tool/fetch_market_data.py

Same endpoint and shape the app's own monthly refresh uses
(lib/data/market_data.dart), so whatever this script writes, the app can
also produce for itself. Monthly adjusted closes (dividends included) —
the projections are ratios over this series, so the quote unit (dollars,
rupees, pence) never matters.
"""

import json
import time
import urllib.request
from datetime import date, datetime

# (id, display name, Yahoo ticker, quote currency)
# Indices first per market, then the household-name stocks. The app
# defaults to an index; a single stock always takes a deliberate tap.
FUNDS = [
    # US
    ("sp500", "S&P 500", "SPY", "USD"),
    ("nasdaq", "NASDAQ-100", "QQQ", "USD"),
    # Global
    ("world", "MSCI World", "IWDA.AS", "EUR"),
    # India
    ("nifty", "Nifty 50", "NIFTYBEES.NS", "INR"),
    # UK
    ("ftse", "FTSE 100", "ISF.L", "GBP"),
    # Germany / eurozone
    ("dax", "DAX", "EXS1.DE", "EUR"),
    # US household names
    ("aapl", "Apple", "AAPL", "USD"),
    ("msft", "Microsoft", "MSFT", "USD"),
    ("googl", "Google", "GOOGL", "USD"),
    ("amzn", "Amazon", "AMZN", "USD"),
    ("nvda", "Nvidia", "NVDA", "USD"),
    ("tsla", "Tesla", "TSLA", "USD"),
    # Indian household names
    ("reliance", "Reliance", "RELIANCE.NS", "INR"),
    ("tcs", "TCS", "TCS.NS", "INR"),
]

URL = (
    "https://query1.finance.yahoo.com/v8/finance/chart/{ticker}"
    "?range=35y&interval=1mo"
)


def fetch(ticker):
    req = urllib.request.Request(
        URL.format(ticker=ticker), headers={"User-Agent": "BurnMyDesire/1.0"}
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.load(resp)


def parse(raw):
    """Mirrors _parseChart in market_data.dart: carry gaps forward,
    require at least 24 months."""
    result = raw["chart"]["result"][0]
    timestamps = result["timestamp"]
    adjclose = result["indicators"]["adjclose"][0]["adjclose"]
    series, first, last, prev = [], None, None, None
    for ts, value in zip(timestamps, adjclose):
        if value is None:
            value = prev
        if value is None:
            continue
        prev = value
        day = datetime.utcfromtimestamp(ts).date()
        if first is None:
            first = day
        last = day
        series.append(round(value, 4))
    if len(series) < 24:
        raise ValueError(f"only {len(series)} months")
    return series, first, last


def main():
    funds = []
    for fund_id, name, ticker, currency in FUNDS:
        raw = fetch(ticker)
        series, first, last, = parse(raw)
        funds.append(
            {
                "id": fund_id,
                "name": name,
                "ticker": ticker,
                "currency": currency,
                "start": f"{first.year}-{first.month:02d}",
                "end": f"{last.year}-{last.month:02d}",
                "monthly": series,
            }
        )
        years = (len(series) - 1) // 12
        print(f"{fund_id:9} {ticker:12} {currency} {first} → {last} ({years}y)")
        time.sleep(1)  # be polite to a free endpoint

    out = {"generated": date.today().isoformat(), "funds": funds}
    with open("assets/data/market_returns.json", "w") as f:
        json.dump(out, f, separators=(",", ":"))
    print(f"wrote {len(funds)} funds")


if __name__ == "__main__":
    main()
