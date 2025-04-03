-- Global objects
globals = {
    "vim",
}

-- Rerun tests only if their modification time changed
cache = true

-- Don't report unused self arguments of methods
self = false

-- Glorious list of warnings:
-- https://luacheck.readthedocs.io/en/stable/warnings.html

ignore = {
    "212", -- Unused argument
    "631", -- Line is too long
    "212/_.*", -- Unused argument starting with _
}
