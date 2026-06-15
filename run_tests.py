#!/usr/bin/env python3
"""Run smoke_test.lua via lupa (Python-Lua bridge)."""
import sys
import lupa

try:
    lua = lupa.LuaRuntime()
except Exception:
    lua = lupa.LuaRuntime(unpack_return_values=True)

# Load and execute lume.lua, then smoke_test.lua
try:
    with open("lume.lua", "r") as f:
        lume_code = f.read()
    with open("smoke_test.lua", "r") as f:
        test_code = f.read()

    # Override os.exit to capture exit code
    lua.execute("""
        _exit_code = 0
        os.exit = function(code) _exit_code = code or 0 end
    """)

    # Execute lume code to populate require-able module
    lua.execute(lume_code)
    # Make require("lume") work by storing the global
    lua.execute('package.loaded["lume"] = lume')

    # Now run the test
    lua.execute(test_code)

    exit_code = lua.eval("_exit_code")
    sys.exit(int(exit_code) if exit_code else 0)

except lupa.LuaError as e:
    print(f"Lua error: {e}", file=sys.stderr)
    sys.exit(2)
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(2)
