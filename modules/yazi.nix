# Lightweight, navigation-first file management with Yazi.
{
  flake.modules.homeManager.yazi =
    { pkgs, ... }:
    let
      gruvboxDark = pkgs.fetchFromGitHub {
        owner = "bennyyip";
        repo = "gruvbox-dark.yazi";
        rev = "619fdc5844db0c04f6115a62cf218e707de2821e";
        hash = "sha256-Y/i+eS04T2+Sg/Z7/CGbuQHo5jxewXIgORTQm25uQb4=";
      };
    in
    {
      programs.yazi = {
        enable = true;
        enableFishIntegration = true;
        enableBashIntegration = true;
        enableZshIntegration = true;
        shellWrapperName = "y";

        # Keep Yazi's useful integrations, but omit image/video/PDF/font tools.
        # `file` remains in Yazi's required runtime dependencies for metadata
        # fallback and the wrapper's optional dependencies stay deliberately small.
        package = pkgs.yazi.override {
          optionalDeps = with pkgs; [
            fd
            ripgrep
            fzf
            zoxide
            jq
            _7zz
          ];
        };

        plugins = {
          inherit (pkgs.yaziPlugins) jump-to-char mime-ext;
        };

        flavors = {
          gruvbox-dark = gruvboxDark;
        };

        initLua = ''
          require("zoxide"):setup { update_db = true }
          require("mime-ext.local"):setup { fallback_file1 = true }
        '';

        keymap = {
          mgr.prepend_keymap = [
            {
              on = "/";
              run = "filter --smart";
              desc = "Filter names (Enter to finish, then navigate)";
            }
            {
              on = "F";
              run = "plugin jump-to-char";
              desc = "Jump to character";
            }
            {
              on = "z";
              run = "plugin zoxide";
              desc = "Jump via zoxide history";
            }
            {
              on = "Z";
              run = "plugin fzf";
              desc = "Find beneath the current directory";
            }
            {
              on = [
                "g"
                "p"
              ];
              run = "cd ~/code";
              desc = "Go to ~/code";
            }
          ];
          input.prepend_keymap = [
            {
              on = "<Esc>";
              run = "close";
              desc = "Cancel input";
            }
          ];
        };

        settings = {
          mgr = {
            sort_by = "alphabetical";
            sort_dir_first = true;
          };

          opener = {
            edit = [
              {
                run = "\${EDITOR:-vi} %s";
                desc = "$EDITOR";
                for = "unix";
                block = true;
              }
            ];
            open = [
              {
                run = "open %s";
                desc = "Open";
                for = "macos";
              }
            ];
            reveal = [
              {
                run = "open -R %s1";
                desc = "Reveal";
                for = "macos";
              }
            ];
            extract = [
              {
                run = "ya pub extract --list %s";
                desc = "Extract here";
              }
            ];
            trash = [
              {
                run = "ya pub trash-restore --list %S";
                desc = "Restore selected files";
              }
              {
                run = "ya pub trash-empty --list %S";
                desc = "Empty trash bin";
              }
            ];
          };

          open.rules = [
            {
              mime = "folder/*";
              use = [
                "edit"
                "open"
                "reveal"
              ];
            }
            {
              mime = "text/*";
              use = [
                "edit"
                "reveal"
              ];
            }
            {
              mime = "application/{json,ndjson,javascript,wine-extension-ini}";
              use = [
                "edit"
                "reveal"
              ];
            }
            {
              mime = "application/{zip,rar,7z*,tar,gzip,xz,zstd,bzip*,lzma,compress,archive,cpio,arj,xar,ms-cab*}";
              use = [
                "extract"
                "reveal"
              ];
            }
            {
              mime = "inode/empty";
              use = [
                "edit"
                "reveal"
              ];
            }
            {
              mime = "vfs/{absent,stale}";
              use = "download";
            }
            {
              mime = "trash/**";
              use = [
                "open"
                "trash"
              ];
            }
            {
              url = "*";
              use = [
                "open"
                "reveal"
              ];
            }
          ];

          plugin = {
            fetchers = [
              {
                url = "*/";
                run = "mime.dir";
                prio = "high";
                group = "mime";
              }
              {
                url = "local://*";
                run = "mime-ext.local";
                prio = "high";
                group = "mime";
              }
              {
                url = "trash://*";
                run = "mime.trash";
                prio = "high";
                group = "mime";
              }
              {
                url = "remote://*";
                run = "mime.remote";
                prio = "high";
                group = "mime";
              }
            ];
            spotters = [
              {
                mime = "multi/*";
                run = "multi";
              }
              {
                mime = "folder/*";
                run = "folder";
              }
              {
                mime = "text/*";
                run = "code";
              }
              {
                mime = "application/{mbox,javascript,wine-extension-ini}";
                run = "code";
              }
              {
                mime = "vfs/*";
                run = "vfs";
              }
              {
                mime = "trash/**";
                run = "trash";
              }
              {
                mime = "null/*";
                run = "null";
              }
              {
                url = "*";
                run = "file";
              }
              {
                url = "*/";
                run = "file";
              }
            ];
            preloaders = [
              {
                mime = "trash/**";
                run = "trash";
              }
            ];
            previewers = [
              {
                mime = "folder/*";
                run = "folder";
              }
              {
                mime = "text/*";
                run = "code";
              }
              {
                mime = "application/{mbox,javascript,wine-extension-ini}";
                run = "code";
              }
              {
                mime = "application/{json,ndjson}";
                run = "json";
              }
              {
                mime = "application/{zip,rar,7z*,tar,gzip,xz,zstd,bzip*,lzma,compress,archive,cpio,arj,xar,ms-cab*}";
                run = "archive";
              }
              {
                mime = "application/{debian*-package,redhat-package-manager,rpm,android.package-archive}";
                run = "archive";
              }
              {
                url = "*.{AppImage,appimage}";
                run = "archive";
              }
              {
                mime = "application/{iso9660-image,qemu-disk,ms-wim,apple-diskimage}";
                run = "archive";
              }
              {
                mime = "application/virtualbox-{vhd,vhdx}";
                run = "archive";
              }
              {
                url = "*.{img,fat,ext,ext2,ext3,ext4,squashfs,ntfs,hfs,hfsx}";
                run = "archive";
              }
              {
                mime = "inode/empty";
                run = "empty";
              }
              {
                mime = "vfs/*";
                run = "vfs";
              }
              {
                mime = "trash/**";
                run = "trash";
              }
              {
                mime = "null/*";
                run = "null";
              }
              {
                url = "*";
                run = "file";
              }
            ];
          };
        };

        theme = {
          flavor = {
            dark = "gruvbox-dark";
            light = "gruvbox-dark";
          };
          # The built-in devicons have their own colors and require a Nerd Font.
          # Clear every lookup table, including the metadata-based fallbacks.
          icon = {
            globs = [ ];
            dirs = [ ];
            files = [ ];
            exts = [ ];
            conds = [ ];
          };
          cmp = {
            icon_file = "";
            icon_folder = "";
            icon_command = "";
          };
          mgr = {
            border_symbol = "│";
            border_style = {
              fg = "#665c54";
            };
          };
          tabs = {
            sep_inner = {
              open = "";
              close = "";
            };
            sep_outer = {
              open = "";
              close = "";
            };
          };
          indicator.padding = {
            open = "";
            close = "";
          };
          status = {
            sep_left = {
              open = "";
              close = "";
            };
            sep_right = {
              open = "";
              close = "";
            };
          };
          which.separator = "  ";
          notify = {
            icon_info = "[i]";
            icon_warn = "[!]";
            icon_error = "[x]";
          };
        };
      };
    };
}
