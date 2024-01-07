local M = {}

M.static = {}

local expert = function(filetype)
  return "I want you to act as a senior "
    .. filetype
    .. " developer. I will give you specific code examples and ask you questions. I want you to advise me with explanations and code examples."
end

local send_code = function(context)
  local text = require("codecompanion.helpers.code").get_code(context.start_line, context.end_line)

  return "I have the following code:\n\n```" .. context.filetype .. "\n" .. text .. "\n```\n\n"
end

M.static.actions = {
  {
    name = "Chat",
    strategy = "chat",
    description = "Open a chat buffer to converse with OpenAI",
    modes = { "n", "v" },
    prompts = {
      n = function()
        return require("codecompanion").chat()
      end,
      v = {
        {
          role = "system",
          content = function(context)
            return "I want you to act as a senior "
              .. context.filetype
              .. " developer. I will give you specific code examples and ask you questions. I want you to advise me with explanations and code examples."
          end,
        },
        {
          role = "user",
          contains_code = true,
          content = function(context)
            return send_code(context)
          end,
        },
      },
    },
  },
  {
    name = "Chat as ...",
    strategy = "chat",
    description = "Open a chat buffer, acting as a specific persona",
    modes = { "n" },
    picker = {
      prompt = "Select a persona",
      items = {
        {
          name = "JavaScript",
          strategy = "chat",
          description = "Chat as a senior JavaScript developer",
          prompts = {
            {
              role = "system",
              content = expert("JavaScript"),
            },
            {
              role = "user",
              contains_code = true,
              condition = function(context)
                return context.is_visual
              end,
              content = function(context)
                return send_code(context)
              end,
            },
            {
              role = "user",
              condition = function(context)
                return not context.is_visual
              end,
              content = "",
            },
          },
        },
        {
          name = "Lua",
          strategy = "chat",
          description = "Chat as a senior Lua developer",
          prompts = {
            {
              role = "system",
              content = expert("Lua"),
            },
            {
              role = "user",
              contains_code = true,
              condition = function(context)
                return context.is_visual
              end,
              content = function(context)
                return send_code(context)
              end,
            },
            {
              role = "user",
              condition = function(context)
                return not context.is_visual
              end,
              content = "",
            },
          },
        },
        {
          name = "PHP",
          strategy = "chat",
          description = "Chat as a senior PHP developer",
          prompts = {
            {
              role = "system",
              content = expert("PHP"),
            },
            {
              role = "user",
              contains_code = true,
              condition = function(context)
                return context.is_visual
              end,
              content = function(context)
                return send_code(context)
              end,
            },
            {
              role = "user",
              condition = function(context)
                return not context.is_visual
              end,
              content = "",
            },
          },
        },
        {
          name = "Python",
          strategy = "chat",
          description = "Chat as a senior Python developer",
          prompts = {
            {
              role = "system",
              content = expert("Python"),
            },
            {
              role = "user",
              contains_code = true,
              condition = function(context)
                return context.is_visual
              end,
              content = function(context)
                return send_code(context)
              end,
            },
            {
              role = "user",
              condition = function(context)
                return not context.is_visual
              end,
              content = "",
            },
          },
        },
        {
          name = "Ruby",
          strategy = "chat",
          description = "Chat as a senior Ruby developer",
          prompts = {
            {
              role = "system",
              content = expert("Ruby"),
            },
            {
              role = "user",
              contains_code = true,
              condition = function(context)
                return context.is_visual
              end,
              content = function(context)
                return send_code(context)
              end,
            },
            {
              role = "user",
              condition = function(context)
                return not context.is_visual
              end,
              content = "",
            },
          },
        },
      },
    },
  },
  {
    name = "Code author",
    strategy = "author",
    description = "Get OpenAI to write/refactor code for you",
    opts = {
      model = "gpt-4-1106-preview",
      modes = { "n", "v" },
      user_input = true,
      send_visual_selection = true,
    },
    prompts = {
      {
        role = "system",
        content = function(context)
          return "I want you to act as a senior "
            .. context.filetype
            .. " developer. I will ask you specific questions and I want you to return raw code only (no codeblocks and no explanations). If you can't respond with code, just say \"Error - I don't know\"."
        end,
      },
    },
  },
  {
    name = "Code advisor",
    strategy = "advisor",
    description = "Get advice on the code you've selected",
    opts = {
      model = "gpt-4-1106-preview",
      modes = { "v" },
      user_input = true,
      send_visual_selection = true,
    },
    prompts = {
      {
        role = "system",
        content = function(context)
          return "I want you to act as a senior "
            .. context.filetype
            .. " developer. I will ask you specific questions and I want you to advise me with explanations and code examples. If you can't respond, just say \"Error - I don't know\""
        end,
      },
    },
  },
  {
    name = "LSP assistant",
    strategy = "advisor",
    description = "Get help from OpenAI to fix LSP diagnostics",
    opts = {
      model = "gpt-4-1106-preview",
      modes = { "v" },
      user_input = false, -- Prompt the user for their own input
      send_visual_selection = false, -- No need to send the visual selection as we do this in prompt 3
    },
    prompts = {
      {
        role = "system",
        content = [[You are an expert coder and helpful assistant who can help debug code diagnostics, such as warning and error messages. When appropriate, give solutions with code snippets as fenced codeblocks with a language identifier to enable syntax highlighting. If you can't respond with an answer, just say "Error - I don't know".]],
      },
      {
        role = "user",
        content = function(context)
          local diagnostics = require("codecompanion.helpers.lsp").get_diagnostics(
            context.start_line,
            context.end_line,
            context.bufnr
          )

          local concatenated_diagnostics = ""
          for i, diagnostic in ipairs(diagnostics) do
            concatenated_diagnostics = concatenated_diagnostics
              .. i
              .. ". Issue "
              .. i
              .. "\n  - Location: Line "
              .. diagnostic.line_number
              .. "\n  - Severity: "
              .. diagnostic.severity
              .. "\n  - Message: "
              .. diagnostic.message
              .. "\n"
          end

          return "The programming language is "
            .. context.filetype
            .. ". This is a list of the diagnostic messages:\n\n"
            .. concatenated_diagnostics
        end,
      },
      {
        role = "user",
        contains_code = true,
        content = function(context)
          return "This is the code, for context:\n\n"
            .. "```"
            .. context.filetype
            .. "\n"
            .. require("codecompanion.helpers.code").get_code(
              context.start_line,
              context.end_line,
              { show_line_numbers = true }
            )
            .. "\n```\n\n"
        end,
      },
    },
  },
  {
    name = "Load conversations",
    strategy = "conversations",
    description = "Load your previous Chat conversations",
    picker = {
      prompt = "Conversations",
      columns = {
        "tokens",
        "filename",
        "dir",
      },
      items = require("codecompanion.strategy.conversation"):list(),
    },
  },
}

return M
