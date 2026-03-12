#!/usr/bin/env python3
"""Scoring engine: reads check JSON from stdin, prints score(s) to stdout.

Supports two input modes:

1. Single-category (backward compatible):
   {"checks": [...]}  →  prints integer score

2. Multi-category:
   {"categories": {"aeo": {"checks": [...]}, ...}}
   →  prints JSON with per-category scores, overall score, and letter grade

Formula (from SKILL.md Section 4):
  Critical=3pts, Important=2pts, NiceToHave=1pt
  PASS=full, WARNING=half(floor), FAIL=0, N/A+UNTESTABLE=excluded
  Score = (earned / possible) * 100, truncated to int. If possible==0: 100.

Overall grade (weighted):
  AEO: 25%, GEO: 25%, SEO Technical: 20%, SEO On-Page: 15%, Structured Data: 15%
  If only some categories are present, weights are redistributed proportionally.

Letter grade: A+ (95+), A (90+), A- (85+), B+ (80+), B (75+), B- (70+),
              C+ (65+), C (60+), C- (55+), D (50+), F (<50)
"""
import json, sys

WEIGHTS = {"critical": 3, "important": 2, "nice_to_have": 1}
RESULT_MULTIPLIERS = {"PASS": 1.0, "WARNING": 0.5, "FAIL": 0.0}

CATEGORY_WEIGHTS = {
    "aeo": 25,
    "geo": 25,
    "seo_technical": 20,
    "seo_on_page": 15,
    "structured_data": 15,
}

GRADE_THRESHOLDS = [
    (95, "A+"),
    (90, "A"),
    (85, "A-"),
    (80, "B+"),
    (75, "B"),
    (70, "B-"),
    (65, "C+"),
    (60, "C"),
    (55, "C-"),
    (50, "D"),
    (0,  "F"),
]


def score_checks(checks):
    """Score a list of checks. Returns integer 0-100."""
    earned = 0
    possible = 0
    for check in checks:
        if check["result"] in ("N/A", "UNTESTABLE"):
            continue
        weight = WEIGHTS[check["severity"]]
        possible += weight
        earned += int(weight * RESULT_MULTIPLIERS[check["result"]])
    return 100 if possible == 0 else int(earned / possible * 100)


def letter_grade(score):
    """Map an integer score to a letter grade."""
    for threshold, grade in GRADE_THRESHOLDS:
        if score >= threshold:
            return grade
    return "F"


def score_categories(categories):
    """Score multiple categories and compute weighted overall grade.

    Args:
        categories: dict of {category_name: {"checks": [...]}}

    Returns:
        dict with per-category scores, overall score, and letter grade.
    """
    results = {}
    total_weight = 0
    weighted_sum = 0

    for name, data in categories.items():
        cat_score = score_checks(data.get("checks", []))
        weight = CATEGORY_WEIGHTS.get(name, 0)
        results[name] = {"score": cat_score, "weight": weight}
        if weight > 0:
            total_weight += weight
            weighted_sum += cat_score * weight

    # Redistribute weights proportionally if not all categories present
    if total_weight > 0:
        overall = int(weighted_sum / total_weight)
    else:
        overall = 100

    return {
        "categories": results,
        "overall": overall,
        "grade": letter_grade(overall),
    }


if __name__ == "__main__":
    data = json.load(sys.stdin)

    if "categories" in data:
        # Multi-category mode
        result = score_categories(data["categories"])
        print(json.dumps(result))
    else:
        # Single-category mode (backward compatible)
        print(score_checks(data.get("checks", [])))
