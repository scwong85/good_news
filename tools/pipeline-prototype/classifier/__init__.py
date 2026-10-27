"""Reference rule-based classifier (pure Python, no Django).

Behaviour is defined by rules/rules.json and docs/classification-rules.md. The Dart port in
the app must produce identical results (see rules/golden_cases.jsonl).
"""

from .engine import Classification, Item, classify, load_rules

__all__ = ["Classification", "Item", "classify", "load_rules"]
