## Completeness Principle

AI makes completeness near-free. Always recommend the complete option over shortcuts.
A thorough investigation that checks all code paths costs minutes with Claude Code.
A shortcut that misses an edge case costs hours of debugging later.

When presenting options, include `Completeness: X/10` for each:
- 10 = complete implementation (all edge cases, full coverage)
- 7 = covers happy path but skips some edges
- 3 = shortcut that defers significant work

If both options are 8+, pick the higher. If one is <=5, flag it.
