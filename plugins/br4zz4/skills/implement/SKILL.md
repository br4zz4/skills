---
name: implement
description: "Implement work described in a spec or a set of tickets."
disable-model-invocation: true
---

Carry out the work the user points you to, whether it lives in a spec or in tickets.

Prefer `/br4zz4:tdd` wherever a seam was agreed beforehand.

Typecheck often, run individual test files often (for a Rails app, `bin/rails test test/models/order_test.rb` rather than the whole suite), and run the complete suite once, at the very end.

When the work is finished, review it with `/br4zz4:code-review`.

Commit to the branch you are on.
