-- test_deep_path.lua
-- Minimal validation for lume.get / lume.set / lume.has / lume.del

local lume = require "lume"

local pass = 0
local fail = 0

local function check(name, got, expected)
  if got == expected then
    pass = pass + 1
  else
    fail = fail + 1
    io.write(("FAIL [%s]: expected %s, got %s\n"):format(
      name, tostring(expected), tostring(got)))
  end
end

local function check_table(name, got, expected)
  -- shallow comparison
  if type(got) ~= "table" or type(expected) ~= "table" then
    if got == expected then pass = pass + 1 else
      fail = fail + 1
      io.write(("FAIL [%s]: expected table, got %s\n"):format(name, tostring(got)))
    end
    return
  end
  for k, v in pairs(expected) do
    if got[k] ~= v then
      fail = fail + 1
      io.write(("FAIL [%s]: key %s expected %s, got %s\n"):format(
        name, tostring(k), tostring(v), tostring(got[k])))
      return
    end
  end
  for k in pairs(got) do
    if expected[k] == nil then
      fail = fail + 1
      io.write(("FAIL [%s]: unexpected key %s\n"):format(name, tostring(k)))
      return
    end
  end
  pass = pass + 1
end


-- ========== lume.get ==========

-- basic dot-path read
do
  local t = { a = { b = { c = 42 } } }
  check("get dot", lume.get(t, "a.b.c"), 42)
end

-- array-path read
do
  local t = { a = { b = { c = 42 } } }
  check("get array", lume.get(t, {"a", "b", "c"}), 42)
end

-- mixed: numeric key in array path for list index
do
  local t = { players = { { name = "alice" }, { name = "bob" } } }
  check("get nested array index", lume.get(t, {"players", 2, "name"}), "bob")
end

-- missing path returns nil
do
  local t = { a = { b = 1 } }
  check("get missing", lume.get(t, "a.x.y"), nil)
end

-- path through non-table returns nil
do
  local t = { a = 5 }
  check("get through non-table", lume.get(t, "a.b"), nil)
end

-- empty string path (0 keys) returns the table itself
do
  local t = { x = 1 }
  check_table("get empty path", lume.get(t, ""), t)
end


-- ========== lume.set ==========

-- basic set with dot-path, auto-creates intermediate tables
do
  local t = {}
  lume.set(t, "a.b.c", 42)
  check("set dot", lume.get(t, "a.b.c"), 42)
end

-- set with array path
do
  local t = {}
  lume.set(t, {"x", "y"}, 10)
  check("set array path", lume.get(t, "x.y"), 10)
end

-- set does not overwrite existing sibling data
do
  local t = { a = { keep = true } }
  lume.set(t, "a.new", 5)
  check("set preserves siblings (new)", lume.get(t, "a.new"), 5)
  check("set preserves siblings (keep)", lume.get(t, "a.keep"), true)
end

-- set through non-table raises error
do
  local t = { a = 5 }
  local ok = pcall(lume.set, t, "a.b", 1)
  check("set through non-table errors", ok, false)
end

-- set returns the table for chaining
do
  local t = {}
  local ret = lume.set(t, "x", 1)
  check("set returns t", ret == t, true)
end

-- set numeric index into array
do
  local t = { list = { "a", "b", "c" } }
  lume.set(t, {"list", 2}, "B")
  check("set numeric index", lume.get(t, {"list", 2}), "B")
end


-- ========== lume.has ==========

-- existing path
do
  local t = { a = { b = 1 } }
  check("has existing", lume.has(t, "a.b"), true)
end

-- missing path
do
  local t = { a = { b = 1 } }
  check("has missing", lume.has(t, "a.c"), false)
end

-- path through non-table
do
  local t = { a = 5 }
  check("has through non-table", lume.has(t, "a.b"), false)
end

-- has with array path
do
  local t = { a = { { v = 1 } } }
  check("has array path", lume.has(t, {"a", 1, "v"}), true)
  check("has array path missing", lume.has(t, {"a", 1, "x"}), false)
end

-- has with false value (still exists, false ~= nil)
do
  local t = { a = { b = false } }
  check("has false value", lume.has(t, "a.b"), true)
end


-- ========== lume.del ==========

-- basic delete
do
  local t = { a = { b = { c = 42, d = 99 } } }
  lume.del(t, "a.b.c")
  check("del basic", lume.get(t, "a.b.c"), nil)
  check("del preserves sibling", lume.get(t, "a.b.d"), 99)
end

-- delete missing path is no-op
do
  local t = { a = 1 }
  lume.del(t, "a.b.c")
  check("del missing no-op", lume.get(t, "a"), 1)
end

-- delete returns the table
do
  local t = { a = 1 }
  local ret = lume.del(t, "a")
  check("del returns t", ret == t, true)
end

-- delete with array path
do
  local t = { items = { { id = 1 }, { id = 2 } } }
  lume.del(t, {"items", 1, "id"})
  check("del array path", lume.get(t, {"items", 1, "id"}), nil)
  check("del array path sibling ok", lume.get(t, {"items", 2, "id"}), 2)
end

-- delete through non-table is safe no-op
do
  local t = { a = "string" }
  lume.del(t, "a.b.c")
  check("del through non-table no-op", t.a, "string")
end


-- ========== README examples validation ==========

-- README get example
do
  local t = { a = { b = { c = 42 } } }
  check("README get 1", lume.get(t, "a.b.c"), 42)
  check("README get 2", lume.get(t, {"a", "b", "c"}), 42)
  check("README get 3", lume.get(t, "a.x"), nil)
end

-- README set example
do
  local t = {}
  lume.set(t, "a.b.c", 42)
  check("README set", lume.get(t, "a.b.c"), 42)

  local t2 = { players = { { name = "alice" }, { name = "bob" } } }
  lume.set(t2, {"players", 2, "name"}, "carol")
  check("README set array", lume.get(t2, {"players", 2, "name"}), "carol")
end

-- README has example
do
  local t = { a = { b = 1 } }
  check("README has 1", lume.has(t, "a.b"), true)
  check("README has 2", lume.has(t, "a.x"), false)
end

-- README del example
do
  local t = { a = { b = { c = 42, d = 99 } } }
  lume.del(t, "a.b.c")
  check("README del", lume.get(t, "a.b.c"), nil)
  check("README del sibling", lume.get(t, "a.b.d"), 99)
end


-- ========== summary ==========
io.write(("\n=== %d passed, %d failed ===\n"):format(pass, fail))
if fail > 0 then os.exit(1) end
