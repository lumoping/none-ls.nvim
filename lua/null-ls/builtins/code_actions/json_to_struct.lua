local h = require("null-ls.helpers")
local methods = require("null-ls.methods")
local u = require("null-ls.utils")
local log = require("null-ls.logger")

local CODE_ACTION = methods.internal.CODE_ACTION

return h.make_builtin({
    name = "json_to_struct",
    meta = {
        url = "https://github.com/tmc/json-to-struct",
        description = "json-to-struct attempts to generate go struct definitions from json documents",
        notes = { "Requires installing the json-to-struct tool." },
    },
    method = CODE_ACTION,
    filetypes = { "go" },
    can_run = function()
        return u.is_executable("json-to-struct")
    end,
    generator_opts = {
        command = "json-to-struct",
        args = {},
    },
    factory = function(opts)
        return {
            fn = function(params)
                local bufnr = params.bufnr
                local lstart = params.range.row
                local lend = params.range.end_row
                local json2struct = function()
                    return {
                        title = "Generate struct",
                        action = function()
                            vim.ui.input({ prompt = "Enter interface name: " }, function(name)
                                if not name then
                                    return
                                end
                                if name == "" then
                                    log:error("name cannot be empty")
                                    return
                                end
                                local input = vim.fn.getline(lstart, lend)
                                if not input or input == "" then
                                    return
                                end
                                local inputStr = ""
                                local inputType = type(input)
                                if inputType == "string" then
                                    inputStr = input
                                elseif inputType == "table" then
                                    inputStr = table.concat(input, "\n")
                                end
                                local cmd = "echo '" .. inputStr .. "' | json-to-struct  -name " .. name
                                local output = vim.fn.system(cmd)
                                if not output or output == "" then
                                    return
                                end

                                local struct = vim.list_slice(vim.split(output, "\n"), 3)
                                vim.api.nvim_buf_set_lines(bufnr, lstart - 1, lend, false, struct)
                            end)
                        end,
                    }
                end
                local actions = {}
                table.insert(actions, json2struct())
                return actions
            end,
        }
    end,
})
