#!/usr/bin/env python3
"""Scoring engine: reads check JSON from stdin, prints integer score to stdout.

Formula (from SKILL.md Section 4):
  Critical=3pts, Important=2pts, NiceToHave=1pt
  PASS=full, WARNING=half(floor), FAIL=0, N/A+UNTESTABLE=excluded
  Score = (earned / possible) * 100, truncated to int. If possible==0: 100.
"""
import json, sys

WEIGHTS = {"critical": 3, "important": 2, "nice_to_have": 1}
RESULT_MULTIPLIERS = {"PASS": 1.0, "WARNING": 0.5, "FAIL": 0.0}


def score_checks(checks):
    earned = 0
    possible = 0
    for check in checks:
        if check["result"] in ("N/A", "UNTESTABLE"):
            continue
        weight = WEIGHTS[check["severity"]]
        possible += weight
        earned += int(weight * RESULT_MULTIPLIERS[check["result"]])
    return 100 if possible == 0 else int(earned / possible * 100)


if __name__ == "__main__":
    data = json.load(sys.stdin)
    print(score_checks(data.get("checks", [])))
