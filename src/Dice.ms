// Dice.ms
// -----------------------------------------------------------------------------
// Provides a Dice utility for parsing, rolling, and formatting dice expressions
// such as "2d6+1". Supports constants, bounds calculation, and unit testing.
// -----------------------------------------------------------------------------

if globals == locals then
    import "qa"
    import "mathUtil"
    import "stringUtil"
end if

// -----------------------------------------------------------------------------
// Dice prototype table.
// -----------------------------------------------------------------------------

// Dice object prototype.
// Represents either a dice roll (NdM+K) or a constant value.
Dice = {}

// @property {int} numDice Number of dice to roll.
Dice.numDice = 1

// @property {int} numSides Number of sides per die.
Dice.numSides = 6

// @property {int} modifier Flat modifier added to the roll.
Dice.modifier = 0

// -----------------------------------------------------------------------------
// Construction helpers.
// -----------------------------------------------------------------------------

// Creates a new Dice instance.
//
// @param numDice {int} Number of dice.
// @param numSides {int} Number of sides per die.
// @param modifier {int} Flat modifier (default 0).
// @returns Dice
Dice.make = function(numDice, numSides, modifier = 0)
    d = new Dice
    d.numDice = numDice
    d.numSides = numSides
    d.modifier = modifier
    return d
end function

// Returns a zero-value Dice (always rolls to 0).
//
// @returns Dice
Dice.zero = function
    return Dice.make(0, 0)
end function

// Returns a constant Dice value.
//
// @param {int} value Constant value
// @returns Dice
Dice.const = function(value)
    return Dice.make(0, 0, value)
end function

// -----------------------------------------------------------------------------
// Parsing.
// -----------------------------------------------------------------------------

// Parses a dice expression (e.g. "2d6+1", "5", "3D8 - 2").
//
// @param {string} text Dice expression.
// @returns Dice
Dice.parse = function(text)
    qa.assert text != null, "Text is empty."
    text = str(text).lower.trim
    qa.assert len(text) > 0, "Text is empty."

    numDice = 0
    numSides = 0
    modifier = 0

    // Locate modifier sign (only one, only after dice).
    modIndex = -1
    if text.contains("+") then
        modIndex = text.indexOf("+")
    else if text.contains("-") then
        modIndex = text.indexOf("-")
    end if

    // Parse modifier with whitespace tolerance.
    if modIndex >= 0 then
        sgn = text[modIndex]
        if sgn == "-" then sgn = -1 else sgn = 1
        modText = text[modIndex + 1:].trim
        modifier = val(modText) * sgn
        text = text[0:modIndex].trim
    end if

    // Dice or constant.
    if text.contains("d") then
        parts = text.split("d")
        qa.assert len(parts) == 2, "Invalid dice format."
        qa.assert len(parts[0]) > 0, "Missing number of dice."
        qa.assert len(parts[1]) > 0, "Missing number of sides."

        numDice = parts[0].val
        numSides = parts[1].val

        qa.assert numDice > 0 and numSides > 0, "Dice and sides must be positive."
    else
        // Constant value.
        numDice = 0
        numSides = 0
        modifier += text.val
    end if

    if numDice == 0 and modifier == 0 then
        return Dice.zero
    end if

    if numDice == 0 then
        return Dice.const(modifier)
    end if

    return Dice.make(numDice, numSides, modifier)
end function

// -----------------------------------------------------------------------------
// Rolling.
// -----------------------------------------------------------------------------

// Rolls the dice and returns the result.
//
// @returns {number}
Dice.roll = function
    if self.numDice == 0 then
        return self.modifier
    end if

    sum = 0
    for n in range(self.numDice - 1)
        sum += floor(rnd * self.numSides) + 1
    end for

    return sum + self.modifier
end function

// -----------------------------------------------------------------------------
// Formatting.
// -----------------------------------------------------------------------------

// Returns a string representation.
// 
// @param {boolean} useDiceNotation If true, returns NdM+K; otherwise returns min-max.
// @returns {string}
Dice.str = function(useDiceNotation = true)
    if useDiceNotation then
        if self.modifier >= 0 then
            return self.numDice + "d" + self.numSides + "+" + self.modifier
        else
            return self.numDice + "d" + self.numSides + self.modifier
        end if
    else
        return self.min + "-" + self.max
    end if
end function

// -----------------------------------------------------------------------------
// Bounds.
// -----------------------------------------------------------------------------

// Minimum possible roll.
//
// @returns {int}
Dice.min = function
    return self.numDice + self.modifier
end function

// Maximum possible roll.
//
// @returns {number}
Dice.max = function
    return self.numDice * self.numSides + self.modifier
end function

// -----------------------------------------------------------------------------
// Unit tests.
// -----------------------------------------------------------------------------

// Runs Dice unit tests.
runUnitTests = function
    print "Unit testing: Dice"

    errorCount = 0

    assertEqual = function(actual, expected, note = "")
        if actual != expected then
            print "Unit test failure (" + testing + "): expected " + expected + ", got " + actual
            if note != "" then print "  Note: " + note
            outer.errorCount = errorCount + 1
        end if
    end function

    assertTrue = function(value, note = "")
        if not value then
            print "Unit test failure (" + testing + "): expected true"
            if note != "" then print "  Note: " + note
            outer.errorCount = errorCount + 1
        end if
    end function

    // Construction
    testing = "make"
    d = Dice.make(2, 6, 3)
    assertEqual d.numDice, 2
    assertEqual d.numSides, 6
    assertEqual d.modifier, 3

    testing = "zero"
    d = Dice.zero
    assertEqual d.numDice, 0
    assertEqual d.numSides, 0
    assertEqual d.modifier, 0

    testing = "const"
    d = Dice.const(5)
    assertEqual d.numDice, 0
    assertEqual d.numSides, 0
    assertEqual d.modifier, 5

    // Parsing
    testing = "parse constant"
    d = Dice.parse("5")
    assertEqual d.numDice, 0
    assertEqual d.modifier, 5

    testing = "parse simple dice"
    d = Dice.parse("1d6")
    assertEqual d.numDice, 1
    assertEqual d.numSides, 6
    assertEqual d.modifier, 0

    testing = "parse dice with modifiers"
    d = Dice.parse("2d8+3")
    assertEqual d.modifier, 3
    d = Dice.parse("4d10-2")
    assertEqual d.modifier, -2

    testing = "parse whitespace and casing"
    d = Dice.parse("  3D6 + 1 ")
    assertEqual d.numDice, 3
    assertEqual d.numSides, 6
    assertEqual d.modifier, 1

    // Bounds
    testing = "min/max"
    d = Dice.make(2, 6, -1)
    assertEqual d.min, 1
    assertEqual d.max, 11

    // Rolling
    testing = "roll bounds"
    d = Dice.make(3, 6, 2)
    for i in range(100)
        r = d.roll
        assertTrue r >= d.min and r <= d.max, "roll out of bounds"
    end for

    testing = "roll constant"
    assertEqual Dice.const(4).roll, 4

    // Formatting
    testing = "str"
    assertEqual Dice.make(2, 6, 3).str, "2d6+3"
    assertEqual Dice.make(2, 6, -1).str, "2d6-1"
    assertEqual Dice.make(1, 8, 0).str(false), "1-8"

    if errorCount == 0 then
        print "All tests passed.  Yay!"
    else
        print errorCount + " error" + "s" * (errorCount != 1) + " found."
    end if
end function

if globals == locals then runUnitTests

return Dice