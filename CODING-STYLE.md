Below is a **MiniScript Coding Style Guide** distilled directly from what we learned while designing, debugging, documenting, and testing `Dice.ms`. This is meant to be a **living reference**: practical, opinionated, and grounded in real MiniScript behavior rather than abstract ideals.

---

# MiniScript Coding Style Guide

## 1. File Structure

### 1.1 File Header
Every file should begin with a clear header explaining **what the file provides**.

```miniscript
// Dice.ms
// -----------------------------------------------------------------------------
// Provides a Dice utility for parsing, rolling, and formatting dice expressions
// such as "2d6+1". Supports constants, bounds calculation, and unit testing.
// -----------------------------------------------------------------------------
```

**Guidelines**
- Use line comments only (`//`)
- Include:
  - Filename
  - High-level purpose
- Decorative separators are encouraged for readability

---

## 2. Comments & Documentation

### 2.1 No Block Comments
MiniScript supports only line comments.  
Block comment notation (`/* */`) is meaningless and should not be used.

✅ Correct:
```miniscript
// Parses a dice expression like "2d6+1".
```

❌ Incorrect:
```miniscript
/* Parses a dice expression */
```

---

### 2.2 JSDoc-Style Documentation (Line-Based)

Use **JSDoc-style conventions**, adapted to line comments.

```miniscript
// Parses a dice expression (e.g. "2d6+1", "5").
//
// @param {string} text Dice expression.
// @returns Dice
Dice.parse = function(text)
```

**Rules**
- One blank comment line between description and tags
- Always include:
  - `@param` with type and description
  - `@returns` with type
- Types are informational (MiniScript does not enforce them)

---

### 2.3 Properties Should Be Documented

Document public properties just like functions.

```miniscript
// @property {int} numDice Number of dice to roll.
Dice.numDice = 1
```

---

## 3. Naming Rules

### 3.1 Do NOT Shadow Built‑Ins
Never name variables after built-in functions or intrinsics.

❌ Bad:
```miniscript
sign = text[modIndex]
```

✅ Good:
```miniscript
sgn = text[modIndex]
```

**Common built-ins to avoid**
- `sign`
- `range`
- `min`
- `max`
- `val`
- `rnd`

---

### 3.2 Prefer Explicit, Short Names
MiniScript favors clarity over cleverness.

✅ Good:
```miniscript
numDice
numSides
modifier
modIndex
```

❌ Avoid:
```miniscript
n
x
tmp
```
(except for trivial loop indices)

---

## 4. Language Constraints to Remember

### 4.1 No Ternary Operator
MiniScript does **not** support ternary expressions.

❌ Invalid:
```miniscript
sgn = (c == "-" ? -1 : 1)
```

✅ Correct:
```miniscript
if c == "-" then
	sgn = -1
else
	sgn = 1
end if
```

---

### 4.2 Function Call Parentheses Matter
- **If a return value is expected**, parentheses are required.
- **If no return value is expected**, parentheses are optional.

```miniscript
x = foo()     // required
print foo    // allowed
```

---

### 4.3 `range(n)` Is Inclusive
This is critical and easy to forget.

```miniscript
range(5)   // → 0,1,2,3,4,5  (6 iterations!)
```

✅ Correct pattern:
```miniscript
for i in range(count - 1)
```

---

## 5. Numeric Parsing Rules

### 5.1 `val` Is Strict
`val` fails silently and returns `0` if the string is malformed.

```miniscript
val("+ 1")   // → 0
val(" 1")    // → 1
```

**Guideline**
- Strip operators yourself
- Trim before calling `val`

✅ Recommended pattern:
```miniscript
sgn = text[i]
modText = text[i+1:].trim
modifier = val(modText) * sgn
```

---

## 6. Parsing Strategy

### 6.1 Parse Structure Before Meaning
Always parse **structure first**, then values.

Recommended order:
1. Normalize text (`lower`, `trim`)
2. Extract modifier
3. Parse dice (`NdM`)
4. Fall back to constant

Avoid approaches like:
- `contains("+")` without knowing context
- Splitting before identifying structure

---

## 7. Object Design Patterns

### 7.1 Constants as Zero-Dice Objects
Represent constants as:

```miniscript
numDice = 0
numSides = 0
modifier = value
```

This allows:
- Unified `roll`, `min`, `max`
- Cleaner API
- Fewer special cases

---

### 7.2 Prefer Constructor Helpers
Use factory functions instead of raw table manipulation.

✅ Good:
```miniscript
Dice.make(2, 6, 1)
Dice.const(5)
```

❌ Avoid:
```miniscript
d = {}
d.numDice = 2
```

---

## 8. Randomness & Bounds

### 8.1 Roll Logic Must Match Bounds
`roll`, `min`, and `max` must agree mathematically.

If:
```miniscript
min = numDice + modifier
max = numDice * numSides + modifier
```

Then:
- Roll exactly `numDice` times
- Never exceed bounds (unit tests should verify this)

---

## 9. Unit Testing Practices

### 9.1 Tests Live With the Module
Embedding tests in the same file is acceptable and encouraged.

```miniscript
if globals == locals then runUnitTests
```

---

### 9.2 Test Behavior, Not Implementation
Good tests:
- Validate bounds, not exact random values
- Catch off-by-one errors
- Catch whitespace and casing issues

Example:
```miniscript
assertTrue r >= d.min and r <= d.max
```

---

## 10. Formatting & Readability

### 10.1 Vertical Spacing Matters
- Separate logical sections with comment dividers
- Leave space between functions
- Group related logic tightly

### 10.2 Be Explicit, Not Clever
MiniScript rewards straightforward code.  
If something looks “clever,” it’s probably wrong—or fragile.

---

## Final Note (Opinion)

Everything in this guide exists because **we hit real bugs**:
- Off-by-one errors from `range`
- Silent failures from `val`
- Missing language features (ternary)
- Shadowing built-ins
- Whitespace-sensitive parsing

If you follow this guide, you’ll avoid entire *classes* of MiniScript bugs before they happen.
