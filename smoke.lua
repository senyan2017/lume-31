--
-- smoke.lua -- minimal, dependency-free self-check for lume.lua
--
-- Exercises the core capability groups end to end (table helpers, string
-- helpers, serialization and chaining) so a single command can confirm the
-- library still behaves after a change, without needing the full test suite.
--
-- Run from anywhere:
--   lua smoke.lua            (e.g. lua5.3 / lua5.4 / luajit)
--
-- Exits with status 0 when every check passes, 1 otherwise.
--

-- Make `require "lume"` resolve relative to this script, not the caller's cwd.
local here = (arg and arg[0] or ""):match("^(.*[/\\])") or "./"
package.path = here .. "?.lua;" .. package.path

local lume = require "lume"

local passed, failed = 0, 0

-- Recursive value comparison: epsilon for numbers, structural for tables.
local function eq(a, b)
  if type(a) ~= type(b) then return false end
  if type(a) == "number" then
    -- Exact match first so infinities compare equal (inf - inf is nan);
    -- fall back to an epsilon for ordinary floating-point results.
    return a == b or math.abs(a - b) < 1e-9
  end
  if type(a) ~= "table" then return a == b end
  for k, v in pairs(a) do if not eq(b[k], v) then return false end end
  for k, v in pairs(b) do if not eq(a[k], v) then return false end end
  return true
end

local function check(name, got, expected)
  if eq(got, expected) then
    passed = passed + 1
  else
    failed = failed + 1
    print(string.format("  FAIL %s: expected %s, got %s",
      name, lume.serialize(expected), lume.serialize(got)))
  end
end

local function check_true(name, cond)
  check(name, not not cond, true)
end

-- 1. Table helpers ---------------------------------------------------
print("-- table helpers")
check("map", lume.map({1, 2, 3}, function(x) return x * 2 end), {2, 4, 6})
check("map (string iteratee)",
  lume.map({{id = 1}, {id = 2}}, "id"), {1, 2})
check("filter", lume.filter({1, 2, 3, 4}, function(x) return x % 2 == 0 end), {2, 4})
check("reject", lume.reject({1, 2, 3, 4}, function(x) return x % 2 == 0 end), {1, 3})
check("filter/reject partition",
  lume.concat(
    lume.filter({1, 2, 3, 4, 5}, function(x) return x % 2 == 0 end),
    lume.reject({1, 2, 3, 4, 5}, function(x) return x % 2 == 0 end)),
  {2, 4, 1, 3, 5})
check("reduce", lume.reduce({1, 2, 3, 4}, function(a, b) return a + b end), 10)
check("count (table iteratee)",
  lume.count({{n = 1}, {n = 2}, {n = 1}}, {n = 1}), 2)
check("find", lume.find({"a", "b", "c"}, "b"), 2)
check("slice", lume.slice({"a", "b", "c", "d", "e"}, 2, -2), {"b", "c", "d"})
do
  local sum = 0
  lume.each({10, 20, 30}, function(x) sum = sum + x end)
  check("each (side effect)", sum, 60)
  local k = lume.keys({a = 1, b = 2, c = 3})
  table.sort(k)
  check("keys", k, {"a", "b", "c"})
end

-- 2. String helpers --------------------------------------------------
print("-- string helpers")
check("split (whitespace)", lume.split("cat dog pig"), {"cat", "dog", "pig"})
check("split (separator)", lume.split("a,b,,c", ","), {"a", "b", "", "c"})
check("trim (whitespace)", lume.trim("  hello  "), "hello")
check("trim (chars)", lume.trim("--hi--", "-"), "hi")
check("wordwrap", lume.wordwrap("aaa bbb ccc", 5), "aaa \nbbb \nccc")
check("format (named)", lume.format("{b} hi {a}", {a = "mark", b = "Oh"}), "Oh hi mark")
check("format (indexed)", lume.format("Hello {1}!", {"world"}), "Hello world!")

-- 3. Serialization ---------------------------------------------------
print("-- serialization")
do
  local t = {1, 2, 3, true, false, "cat", {x = 1, y = {2, 3}}}
  check("serialize round-trip", lume.deserialize(lume.serialize(t)), t)
  check("serialize +inf", lume.deserialize(lume.serialize(math.huge)), math.huge)
  check("serialize -inf", lume.deserialize(lume.serialize(-math.huge)), -math.huge)
  local nan = lume.deserialize(lume.serialize(0 / 0))
  check_true("serialize nan", nan ~= nan)
  check_true("serialize circular errors",
    not pcall(function() local c = {}; c.self = c; lume.serialize(c) end))
end

-- 4. Chaining --------------------------------------------------------
print("-- chaining")
check("chain filter+map",
  lume.chain({1, 2, 3, 4})
    :filter(function(x) return x % 2 == 0 end)
    :map(function(x) return -x end)
    :result(),
  {-2, -4})
check("chain scalar passthrough", lume.chain(10):result(), 10)
check("module-call chain form",
  lume({1, 2, 3}):map(function(x) return x * 2 end):result(),
  {2, 4, 6})

-- Summary ------------------------------------------------------------
print(string.format("-- smoke: %d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
