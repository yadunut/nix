{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nut.neovim;
  inherit (lib) mkEnableOption mkIf mkOption;
in
{
  options.nut.neovim = {
    enable = mkEnableOption "Neovim";
    nix.enable = mkOption {
      default = true;
      description = "Enable nix related vim packages";
      type = lib.types.bool;
    };
    performance.enable = mkOption {
      default = false;
      description = "Enable performance options";
      type = lib.types.bool;
    };
  };

  config = mkIf cfg.enable {
    home.sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    programs.nixvim = {
      enable = true;

      performance = mkIf cfg.performance.enable {
        combinePlugins.enable = true;
        byteCompileLua = {
          enable = true;
          nvimRuntime = true;
          plugins = true;
        };
      };

      defaultEditor = true;
      colorschemes.gruvbox.enable = true;
      plugins = {
        flash.enable = true;
        oil.enable = true;
        neogit.enable = true;
        image = {
          enable = true;
          settings = {
            backend = "kitty";
          };
        };
        lsp = {
          enable = true;
          servers = {
            # gleam.enable = true;
            ts_ls.enable = true; # TS/JS
            biome.enable = true; # TS/JS
            pyright.enable = true; # Python
            ruff.enable = true; # python
            nixd = mkIf cfg.nix.enable {
              enable = true;
              extraOptions.settings.nixd = {
                formatting.command = "nixfmt";
              };
            };
            cssls.enable = true;
            jsonls.enable = true;
            html.enable = true;
            tinymist.enable = true;
            gopls.enable = true;
            texlab = {
              enable = true;
              settings = {
                texlab.build = {
                  executable = "tectonic";
                  args = [
                    "-X"
                    "compile"
                    "%f"
                    "--synctex"
                    "--keep-logs"
                    "--keep-intermediates"
                  ];
                };
              };
            };
          };
          keymaps.lspBuf = {
            gd = {
              action = "definition";
              desc = "Goto Definition";
            };
            gr = {
              action = "references";
              desc = "Goto References";
            };
            gD = {
              action = "declaration";
              desc = "Goto Declaration";
            };
            gI = {
              action = "implementation";
              desc = "Goto Implementation";
            };
            gT = {
              action = "type_definition";
              desc = "Type Definition";
            };
            K = {
              action = "hover";
              desc = "Hover";
            };
            "<leader>rn" = {
              action = "rename";
              desc = "Rename";
            };
          };
          keymaps.extra = [
            {
              action.__raw = "vim.lsp.buf.code_action";
              key = "<leader>la";
            }
            {
              action.__raw = "function() vim.lsp.buf.format { async = true } end";
              key = "<leader>lf";
            }
          ];
          keymaps.diagnostic = {
            "<leader>cd" = {
              action = "open_float";
              desc = "Line Diagnostics";
            };
            "[d" = {
              action = "goto_next";
              desc = "Next Diagnostic";
            };
            "]d" = {
              action = "goto_prev";
              desc = "Previous Diagnostic";
            };
          };
        };

        trouble.enable = true;
        cmp = {
          enable = true;
          autoEnableSources = true;
          settings = {
            sources = [
              { name = "nvim_lsp"; }
              { name = "nvim_lua"; }
              # {name = "emoji";}
              {
                name = "buffer";
                option.get_bufnrs.__raw = "vim.api.nvim_list_bufs";
                keywordLength = 3;
              }
              {
                name = "path";
                keywordLength = 3;
              }
              {
                name = "luasnip";
                keywordLength = 3;
              }
            ];
            window = {
              # completion = { border = "solid"; };
              # documentation = { border = "solid"; };
            };
            mapping = {
              "<C-n>" = "cmp.mapping.select_next_item()";
              "<C-p>" = "cmp.mapping.select_prev_item()";
              "<C-e>" = "cmp.mapping.abort()";
              "<C-b>" = "cmp.mapping.scroll_docs(-4)";
              "<C-f>" = "cmp.mapping.scroll_docs(4)";
              "<C-Space>" = "cmp.mapping.complete()";
              "<CR>" = "cmp.mapping.confirm({ select = true })";
              "<S-CR>" = "cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true })";
            };
          };
        };
        cmp-nvim-lsp.enable = true;
        cmp-nvim-lua.enable = true;
        cmp-buffer.enable = true;
        cmp-path.enable = true;
        cmp_luasnip.enable = true;
        cmp-cmdline.enable = true;
        nvim-tree = {
          enable = true;
          settings = {
            view.side = "right";
            update_focused_file.enable = true;
          };
        };

        friendly-snippets.enable = true;

        luasnip = {
          enable = true;
          settings = {
            enable_autosnippets = true;
            store_selection_keys = "<Tab>";
          };
          fromVscode = [
            {
              lazyLoad = true;
              paths = "${pkgs.vimPlugins.friendly-snippets}";
            }
          ];
        };

        bufferline.enable = true;

        treesitter = {
          enable = true;
          folding = true;
          grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
            bash
            json
            lua
            make
            markdown
            nix
            regex
            toml
            vim
            vimdoc
            xml
            yaml
            javascript
            go
            typescript
          ];
          settings = {
            highlight.enable = true;
            indent.enable = true;
          };
        };
        treesitter-context.enable = true;
        treesitter-textobjects = {
          enable = true;
          settings.move = {
            enable = true;
            gotoNextStart = {
              "]m" = {
                query = "@function.outer";
              };
              "]]" = {
                query = "@class.outer";
                desc = "Next class start";
              };
              "]o" = {
                query = "@loop.*";
              };
              "]s" = {
                query = "@scope";
                queryGroup = "locals";
                desc = "Next scope";
              };
              "]z" = {
                query = "@fold";
                queryGroup = "folds";
                desc = "Next fold";
              };
            };
            gotoNextEnd = {
              "]M" = {
                query = "@function.outer";
              };
              "][" = {
                query = "@class.outer";
              };
            };
            gotoPreviousStart = {
              "[m" = {
                query = "@function.outer";
              };
              "[[" = {
                query = "@class.outer";
              };
            };
            gotoPreviousEnd = {
              "[M" = {
                query = "@function.outer";
              };
              "[]" = {
                query = "@class.outer";
              };
            };
            gotoNext = {
              "]d" = {
                query = "@conditional.outer";
              };
            };
            gotoPrevious = {
              "[d" = {
                query = "@conditional.outer";
              };
            };
          };
        };
        ts-autotag.enable = true;

        which-key.enable = true;
        telescope = {
          enable = true;
          extensions.fzf-native.enable = true;
          settings = {
            defaults = {
              mappings = {
                i = {
                  "<C-t>".__raw = "require('trouble.sources.telescope').open";
                };
                n = {
                  "<C-t>".__raw = "require('trouble.sources.telescope').open";
                };
              };
            };
          };
        };

        web-devicons.enable = true;

        overseer = {
          enable = true;
        };
      };

      opts = {
        number = true;
        relativenumber = true;
        signcolumn = "yes";
        updatetime = 250;
        undofile = true;
        ignorecase = true;
        smartcase = true;
        swapfile = false;
        foldlevel = 9;
        smartindent = true;
        tabstop = 2;
        shiftwidth = 2;
        softtabstop = 0;
        expandtab = true;
        smarttab = true;
        scrolloff = 5;
        termguicolors = true;
        foldmethod = lib.mkForce "expr";
        foldexpr = lib.mkForce "v:lua.vim.treesitter.foldexpr()";
      };

      globals = {
        mapleader = " ";
        maplocalleader = " ";
      };
      keymaps = [
        {
          action = ":";
          key = ";";
          mode = [ "n" ];
        }
        # { action = "gj"; key = "j"; mode = [ "n" ]; }
        # { action = "gk"; key = "k"; mode = [ "n" ]; }
        {
          action = "<Esc>";
          key = "jk";
          mode = [ "i" ];
        }

        {
          action = "<cmd>Telescope find_files<CR>";
          key = "<leader><leader>";
          options.desc = "Find Files";
        }
        {
          action.__raw = "function() require('telescope.builtin').lsp_document_symbols({symbols='method'}) end";
          key = "<leader>fm";
          options.desc = "Find Methods";
        }
        {
          action = "<cmd>Telescope live_grep<CR>";
          key = "<leader>fg";
          options.desc = "Grep";
        }
        {
          action = "<cmd>Telescope buffers<CR>";
          key = "<leader>fb";
          options.desc = "Find Buffers";
        }
        {
          action = "<cmd>Telescope buffers<CR>";
          key = "<leader>fb";
          options.desc = "Find Buffers";
        }
        {
          action = "<cmd>Telescope projects<CR>";
          key = "<leader>pp";
          options.desc = "Switch Projects";
        }

        {
          action = "<cmd>Trouble diagnostics toggle<CR>";
          key = "<leader>tr";
        }
        {
          action = "<cmd>Neogit<CR>";
          key = "<leader>gg";
          options.desc = "Open Git";
        }
        {
          action = "<cmd>NvimTreeToggle<CR>";
          key = "<leader>tt";
          options.desc = "Tree View";
        }

        {
          action.__raw = "function() require('flash').jump() end";
          key = "s";
          mode = [
            "n"
            "x"
            "o"
          ];
          options.desc = "Flash";
        }
        {
          action.__raw = "function() require('flash').treesitter() end";
          key = "S";
          mode = [
            "n"
            "x"
            "o"
          ];
          options.desc = "Flash Treesitter";
        }
        {
          action.__raw = "function() require('flash').remote() end";
          key = "r";
          mode = [ "o" ];
          options.desc = "Remote Flash";
        }
        {
          action.__raw = "function() require('flash').treesitter_search() end";
          key = "R";
          mode = [ "o" ];
          options.desc = "Treesitter Search";
        }
        {
          action.__raw = "function() require('flash').toggle() end";
          key = "<c-s>";
          mode = [ "c" ];
          options.desc = "Toggle Flash";
        }
      ];
    };
  };
}
