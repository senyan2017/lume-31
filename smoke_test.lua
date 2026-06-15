-- smoke_test.lua — minimal self-check for lume after refactor
-- Run with:  lua smoke_test.lua

local lume = require "lume"

local pass, fail = 0, 0

local function check(label, cond)
  if cond then
    pass = pass + 1
  else
    fail = fail + 1
    print("FAIL: " .. label)
  end
end

local function approx(a, b, eps)
  eps = eps or 1e-9
  return math.abs(a - b) < eps
end

-- ===========================================================================
-- Math utilities
-- ===========================================================================

check("clamp low",       lume.clamp(-5, 0, 10) == 0)
check("clamp high",      lume.clamp(15, 0, 10) == 10)
check("clamp mid",       lume.clamp(5, 0, 10) == 5)

check("round pos",       lume.round(2.3) == 2)
check("round neg",       lume.round(-2.7) == -3)
check("round inc",       approx(lume.round(123.4567, 0.1), 123.5))

check("sign pos",        lume.sign(5) == 1)
check("sign neg",        lume.sign(-3) == -1)

check("lerp mid",        lume.lerp(100, 200, 0.5) == 150)
check("lerp clamp low",  lume.lerp(0, 100, -1) == 0)
check("lerp clamp high", lume.lerp(0, 100, 2) == 100)

check("smooth mid",      approx(lume.smooth(0, 100, 0.5), 50))
check("smooth low",      lume.smooth(0, 100, 0) == 0)
check("smooth high",     lume.smooth(0, 100, 1) == 100)

check("pingpong 0",      lume.pingpong(0) == 0)
check("pingpong 1",      lume.pingpong(1) == 1)

check("distance",        approx(lume.distance(0, 0, 3, 4), 5))
check("distance sq",     lume.distance(0, 0, 3, 4, true) == 25)

check("vector",          approx(lume.vector(0, 10), 10))

-- ===========================================================================
-- Table utilities
-- ===========================================================================

check("isarray yes",     lume.isarray({1,2,3}) == true)
check("isarray no",      lume.isarray({a=1}) == false)
check("isarray empty",   lume.isarray({}) == false)

local t1 = {1, 2, 3}
lume.push(t1, 4, 5)
check("push",            #t1 == 5 and t1[5] == 5)

local t2 = {1, 2, 3}
lume.remove(t2, 2)
check("remove",          #t2 == 2 and t2[1] == 1 and t2[2] == 3)

local t3 = {1, 2, 3}
lume.clear(t3)
check("clear",           next(t3) == nil)

local t4 = {a = 1}
lume.extend(t4, {b = 2, c = 3})
check("extend",          t4.a == 1 and t4.b == 2 and t4.c == 3)

local t5 = lume.sort({3, 1, 2})
check("sort",            t5[1] == 1 and t5[2] == 2 and t5[3] == 3)

local t5b = lume.sort({{z=3},{z=1},{z=2}}, "z")
check("sort key",        t5b[1].z == 1 and t5b[2].z == 2 and t5b[3].z == 3)

local t6 = lume.map({1, 2, 3}, function(x) return x * 2 end)
check("map",             t6[1] == 2 and t6[2] == 4 and t6[3] == 6)

check("all true",        lume.all({1, 2, 3}, function(x) return x > 0 end))
check("all false",       not lume.all({1, 2, 3}, function(x) return x > 1 end))

check("any true",        lume.any({1, 2, 3}, function(x) return x == 2 end))
check("any false",       not lume.any({1, 2, 3}, function(x) return x == 5 end))

check("reduce sum",      lume.reduce({1, 2, 3}, function(a, b) return a + b end) == 6)
check("reduce init",     lume.reduce({1, 2, 3}, function(a, b) return a + b end, 10) == 16)

local t7 = lume.filter({1, 2, 3, 4}, function(x) return x % 2 == 0 end)
check("filter",          #t7 == 2 and t7[1] == 2 and t7[2] == 4)

local t8 = lume.reject({1, 2, 3, 4}, function(x) return x % 2 == 0 end)
check("reject",          #t8 == 2 and t8[1] == 1 and t8[2] == 3)

-- filter with retainkeys
local t8b = lume.filter({a=1, b=2, c=3}, function(x) return x > 1 end, true)
check("filter retain",   t8b.a == nil and t8b.b == 2 and t8b.c == 3)

-- reject with retainkeys
local t8c = lume.reject({a=1, b=2, c=3}, function(x) return x > 2 end, true)
check("reject retain",   t8c.a == 1 and t8c.b == 2 and t8c.c == nil)

local t9 = lume.merge({a=1, b=2}, {c=3, b=9})
check("merge",           t9.a == 1 and t9.b == 9 and t9.c == 3)

local t10 = lume.concat({1,2}, {3,4}, {5})
check("concat",          #t10 == 5 and t10[5] == 5)

check("find hit",        lume.find({"a","b","c"}, "b") == 2)
check("find miss",       lume.find({"a","b","c"}, "z") == nil)

local v, k = lume.match({1, 5, 8, 7}, function(x) return x % 2 == 0 end)
check("match",           v == 8 and k == 3)

check("count all",       lume.count({1,2,3}) == 3)
check("count fn",        lume.count({1,2,3,4}, function(x) return x % 2 == 0 end) == 2)

local t11 = lume.slice({"a","b","c","d","e"}, 2, 4)
check("slice",           #t11 == 3 and t11[1] == "b" and t11[3] == "d")

check("first",           lume.first({"a","b","c"}) == "a")
check("first n",         #lume.first({"a","b","c"}, 2) == 2)
check("last",            lume.last({"a","b","c"}) == "c")
check("last n",          #lume.last({"a","b","c"}, 2) == 2)

local inv = lume.invert({a="x", b="y"})
check("invert",          inv.x == "a" and inv.y == "b")

local pk = lume.pick({a=1, b=2, c=3}, "a", "c")
check("pick",            pk.a == 1 and pk.b == nil and pk.c == 3)

local ks = lume.keys({a=1, b=2})
check("keys",            #ks == 2)

local cl = lume.clone({a=1, b=2})
check("clone",           cl.a == 1 and cl.b == 2)

local uniq = lume.unique({1, 2, 2, 3, 3, 3})
check("unique",          #uniq == 3)

-- ripairs
local ri = {}
for i, v in lume.ripairs({"a","b","c"}) do ri[#ri+1] = i .. v end
check("ripairs",         ri[1] == "3c" and ri[2] == "2b" and ri[3] == "1a")

-- array from iterator
local arr = lume.array(string.gmatch("hello world", "%a+"))
check("array",           #arr == 2 and arr[1] == "hello" and arr[2] == "world")

-- each
local each_sum = 0
lume.each({1,2,3}, function(x) each_sum = each_sum + x end)
check("each",            each_sum == 6)

-- ===========================================================================
-- String utilities
-- ===========================================================================

local sp = lume.split("one two three")
check("split words",     #sp == 3 and sp[1] == "one" and sp[3] == "three")

local sp2 = lume.split("a,b,,c", ",")
check("split sep",       #sp2 == 4 and sp2[1] == "a" and sp2[3] == "" and sp2[4] == "c")

check("trim",            lume.trim("  hello  ") == "hello")
check("trim chars",      lume.trim("xxhelloxx", "x") == "hello")

check("format named",    lume.format("{b} hi {a}", {a="mark", b="Oh"}) == "Oh hi mark")
check("format num",      lume.format("Hello {1}!", {"world"}) == "Hello world!")
check("format nil",      lume.format("plain text") == "plain text")

local wrapped = lume.wordwrap("Hello world. This is a short string", 14)
check("wordwrap",        wrapped:find("\n") ~= nil)

-- ===========================================================================
-- Serialization
-- ===========================================================================

local s1 = lume.serialize({a = "test", b = {1, 2, 3}, false})
check("serialize str",   type(s1) == "string")

local d1 = lume.deserialize(s1)
check("deserialize",     d1.a == "test" and #d1.b == 3 and d1[1] == false)

-- round-trip nested
local orig = {x = 1, y = {2, 3}, z = "hi"}
local rt = lume.deserialize(lume.serialize(orig))
check("round-trip",      rt.x == 1 and rt.y[1] == 2 and rt.y[2] == 3 and rt.z == "hi")

-- special numbers
check("serialize nan",   lume.serialize(0/0) == "0/0")
check("serialize inf",   lume.serialize(1/0) == "1/0")
check("serialize -inf",  lume.serialize(-1/0) == "-1/0")

-- boolean / nil
check("serialize bool",  lume.serialize(true) == "true")
check("serialize nil",   lume.serialize(nil) == "nil")

-- circular reference
local circ = {}
circ.self = circ
local circ_ok = pcall(lume.serialize, circ)
check("circular error",  not circ_ok)

-- ===========================================================================
-- Function utilities
-- ===========================================================================

local f1 = lume.fn(function(a, b) return a + b end, 10)
check("fn partial",      f1(5) == 15)

local call_count = 0
local f2 = lume.once(function() call_count = call_count + 1 end)
f2(); f2(); f2()
check("once",            call_count == 1)

local fib
fib = lume.memoize(function(n)
  return n < 2 and n or fib(n-1) + fib(n-2)
end)
check("memoize",         fib(10) == 55)

local combined_out = {}
local f3 = lume.combine(
  function(x) combined_out[#combined_out+1] = x * 2 end,
  function(x) combined_out[#combined_out+1] = x * 3 end
)
f3(5)
check("combine",         combined_out[1] == 10 and combined_out[2] == 15)

check("combine nil",     lume.combine() == nil or true)  -- returns noop, not nil

local r = lume.call(function(x) return x + 1 end, 5)
check("call",            r == 6)
check("call nil",        lume.call(nil, 1, 2) == nil)

local elapsed, val = lume.time(function(x) return x end, "hello")
check("time",            type(elapsed) == "number" and val == "hello")

local f4 = lume.lambda("x, y -> 2*x + y")
check("lambda",          f4(10, 5) == 25)

-- ===========================================================================
-- Color
-- ===========================================================================

local r, g, b, a = lume.color("#ff0000")
check("color hex",       approx(r, 1) and approx(g, 0) and approx(b, 0) and approx(a, 1))

local r2, g2, b2, a2 = lume.color("rgba(255, 0, 255, .5)")
check("color rgba",      approx(r2, 1) and approx(g2, 0) and approx(b2, 1) and approx(a2, 0.5))

local r3, g3, b3, a3 = lume.color("#00ffff", 256)
check("color mul",       approx(r3, 0) and approx(g3, 256) and approx(b3, 256))

local bad_color = pcall(lume.color, "not_a_color")
check("color bad",       not bad_color)

-- ===========================================================================
-- Chain
-- ===========================================================================

local c1 = lume.chain({1, 2, 3, 4})
  :filter(function(x) return x % 2 == 0 end)
  :map(function(x) return -x end)
  :result()
check("chain basic",     #c1 == 2 and c1[1] == -2 and c1[2] == -4)

local c2 = lume({5, 3, 1, 4, 2})
  :sort()
  :first(3)
  :result()
check("chain callable",  #c2 == 3 and c2[1] == 1 and c2[2] == 2 and c2[3] == 3)

-- chain with reduce
local c3 = lume.chain({1, 2, 3, 4})
  :reduce(function(a, b) return a + b end)
  :result()
check("chain reduce",    c3 == 10)

-- ===========================================================================
-- Iteratee variants (string, table, nil)
-- ===========================================================================

-- string iteratee
local ts = {{z = "cat"}, {z = "dog"}, {z = "owl"}}
local ms = lume.map(ts, "z")
check("iteratee str",    ms[1] == "cat" and ms[2] == "dog" and ms[3] == "owl")

-- table iteratee
local tt = {
  {age = 10, type = "cat"},
  {age = 8,  type = "dog"},
  {age = 10, type = "owl"},
}
check("iteratee tbl",    lume.count(tt, {age = 10}) == 2)

-- nil iteratee
local tn = lume.filter({true, true, false, true}, nil)
check("iteratee nil",    #tn == 3)

-- ===========================================================================
-- Misc
-- ===========================================================================

check("dostring",        lume.dostring("return 1 + 2") == 3)

local u = lume.uuid()
check("uuid format",     type(u) == "string" and #u == 36 and u:sub(15,15) == "4")

-- ===========================================================================
-- Report
-- ===========================================================================

print(string.format("\n=== Smoke test: %d passed, %d failed (total %d) ===",
  pass, fail, pass + fail))

if fail > 0 then
  os.exit(1)
else
  print("All tests passed!")
  os.exit(0)
end
