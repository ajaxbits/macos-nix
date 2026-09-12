# Firefox remains a Homebrew cask so its native updater can manage application updates.
{ lib, ... }:
let
  profilePath = "Library/Application Support/Firefox/Profiles/ffeb7rvx.default-release-2";
  autoUpdatingExtensions = [
    "{c607c8df-14a7-4f28-894f-29e8722976af}" # Temporary Containers
    "shortcut-forwarding-tool@gdh1995.cn"
    "search@kagi.com"
    "@contain-facebook"
    "vimium-c@gdh1995.cn"
    "gdpr@cavi.au.dk"
    "maksimovic@outlook.com"
    "{61a05c39-ad45-4086-946f-32adb0a40a9d}" # linkding
    "@testpilot-containers"
    "sponsorBlocker@ajay.app"
    "firefox@betterttv.net"
    "deArrow@ajay.app"
    "{3c078156-979c-498b-8990-85f7987dd929}" # Sidebery
    "{446900e4-71c2-419f-a6a7-df9c091e268b}" # Bitwarden
    "uBlock0@raymondhill.net"
    "{f0bda7ce-0cda-42dc-9ea8-126b20fed280}" # Hister
  ];
  workOnlyExtensions = [
    "{315f61e5-f0ce-4d6e-a521-70e8da512405}" # Glean
    "plugin@okta.com" # Okta Browser Plugin
  ];
  autoUpdatingExtensionSettings = lib.genAttrs autoUpdatingExtensions (_: {
    installation_mode = "normal_installed";
    updates_disabled = false;
  });
in
{
  flake.modules.homeManager.firefox-personal = {
    programs.firefox = {
      enable = true;
      # The application is installed by Homebrew rather than the Nix store.
      package = null;
      # Keep the existing profile registry intact while managing the active profile.
      profileVersion = 2;
      profiles.default-release = {
        id = 0;
        path = "xhcuxhl1.default-release";
        isDefault = false;
      };
      profiles.default = {
        id = 1;
        path = "n8dckb2h.default";
        isDefault = true;
      };
      profiles.default-release-1 = {
        id = 2;
        path = "0ygchr04.default-release-1";
        isDefault = false;
      };
      profiles."default-release-2" = {
        id = 3;
        path = "ffeb7rvx.default-release-2";
        storeId = "cb8ad46c";
        userChrome = ./firefox/userChrome.css;
        settings = {
          "browser.ai.control.default" = "blocked";
          "browser.ai.control.linkPreviewKeyPoints" = "blocked";
          "browser.ai.control.pdfjsAltText" = "blocked";
          "browser.ai.control.sidebarChatbot" = "blocked";
          "browser.ai.control.smartTabGroups" = "blocked";
          "browser.ai.control.translations" = "blocked";
          "browser.ctrlTab.sortByRecentlyUsed" = true;
          "browser.download.autohideButton" = false;
          "browser.ipProtection.enabled" = true;
          "browser.startup.homepage" = "about:blank";
          "browser.startup.page" = 3;
          "browser.tabs.inTitlebar" = 1;
          "browser.tabs.loadInBackground" = false;
          "browser.tabs.warnOnClose" = true;
          "browser.toolbars.bookmarks.showOtherBookmarks" = false;
          "browser.toolbars.bookmarks.visibility" = "never";
          "browser.urlbar.suggest.quicksuggest.sponsored" = false;
          "devtools.cache.disabled" = true;
          "devtools.netmonitor.persistlog" = true;
          "devtools.responsive.touchSimulation.enabled" = true;
          "devtools.responsive.userAgent" = "Mozilla/5.0 (Linux; Android 11; SAMSUNG SM-G973U) AppleWebKit/537.36 (KHTML, like Gecko) SamsungBrowser/14.2 Chrome/87.0.4280.141 Mobile Safari/537.36";
          "devtools.responsive.viewport.height" = 883;
          "devtools.responsive.viewport.pixelRatio" = 3;
          "devtools.responsive.viewport.width" = 412;
          "doh-rollout.mode" = 0;
          "doh-rollout.self-enabled" = true;
          "doh-rollout.uri" = "https://mozilla.cloudflare-dns.com/dns-query";
          "dom.security.https_only_mode" = true;
          "extensions.formautofill.creditCards.enabled" = false;
          "extensions.ml.enabled" = false;
          "findbar.highlightAll" = true;
          "image.jxl.enabled" = true;
          "network.dns.disablePrefetch" = true;
          "network.http.speculative-parallel-limit" = 0;
          "network.prefetch-next" = false;
          "network.security.ports.banned.override" = "6666";
          "network.trr.custom_uri" = "https://dns.nextdns.io/b698e3";
          "pdfjs.enableAltText" = false;
          "privacy.clearOnShutdown_v2.formdata" = true;
          "reader.font_size" = 7;
          "signon.rememberSignons" = false;
        };
      };
      profiles.dev-edition-default = {
        id = 4;
        path = "7bi16hgq.dev-edition-default";
        isDefault = false;
      };
    };

    home.file = {
      "${profilePath}/chrome/chrome/hide_tabs_toolbar_v2.css".source = ./firefox/chrome/hide_tabs_toolbar_v2.css;
      "${profilePath}/chrome/chrome/window_control_placeholder_support.css".source = ./firefox/chrome/window_control_placeholder_support.css;
    };

    targets.darwin.defaults."org.mozilla.firefox" = {
      EnterprisePoliciesEnabled = true;
      ExtensionSettings = autoUpdatingExtensionSettings // lib.genAttrs workOnlyExtensions (_: {
        installation_mode = "blocked";
      });
    };
  };

  flake.modules.homeManager.firefox-work = {
    targets.darwin.defaults."org.mozilla.firefox" = {
      EnterprisePoliciesEnabled = true;
      ExtensionSettings = lib.genAttrs workOnlyExtensions (_: {
        installation_mode = "normal_installed";
        updates_disabled = false;
      });
    };
  };
}
