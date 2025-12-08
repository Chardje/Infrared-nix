{
  config,
  lib,
  pkgs,
  ...
}:

let

  infraredPackage = pkgs.callPackage ./package.nix { };

  cfg = config.services.infrared;

  configFile = pkgs.writeText "config.yml" ''
    bind: ${cfg.listensIpPort}
    keepAliveTimeout: ${cfg.keepAliveTimeout}
    ${lib.optionalString cfg.proxyProtocol.enable ''
      proxyProtocol:
        receive: true
        trustedCIDRs:
        ${lib.concatStringsSep "\n" (map (cidr: "      - ${cidr}") cfg.proxyProtocol.trustedCIDRs)}
    ''}
    ${lib.optionalString cfg.filters.rateLimiter.enable ''
      filters:
        rateLimiter:
          requestLimit: ${toString cfg.filters.rateLimiter.requestLimit}
          windowLength: ${cfg.filters.rateLimiter.windowLength}
    ''}
  '';
  proxyFiles = lib.mapAttrs' (
    name: proxyCfg:
    lib.nameValuePair ("infrared/proxies/${name}.yml") {
      mode = "0644";
      text = ''
        domains:
        ${lib.concatStringsSep "\n" (map (d: "  - ${d}") proxyCfg.domains)}

        addresses:
        ${lib.concatStringsSep "\n" (map (a: "  - ${a}") proxyCfg.addresses)}

        ${lib.optionalString proxyCfg.sendProxyProtocol ''
          sendProxyProtocol: true
        ''}
      '';
    }
  ) (lib.filterAttrs (_: v: v.enable) cfg.proxies);
in
{
  options.services.infrared = {
    enable = lib.mkEnableOption "infrared";

    package = lib.mkOption {
      type = lib.types.package;
      default = infraredPackage;
      description = "A Minecraft Reverse Proxy";
    };

    listensIpPort = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0:25565";
      description = "Address that Infrared bind and listens to";
    };

    keepAliveTimeout = lib.mkOption {
      type = lib.types.str;
      default = "30s";
      description = "Maximum duration between packets before the client gets timed out.";
    };

    proxies = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Enable proxy ${name}.";
              };

              domains = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ "${name}.example.com" ];
                description = "Domain patterns served by this proxy.";
              };

              addresses = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ "127.0.0.1:25565" ];
                description = "Backend server addresses.";
              };

              sendProxyProtocol = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Enable sending PROXY protocol headers.";
              };
            };
          }
        )
      );
      default = { };
      description = "List of Infrared proxy configurations.";
    };

    proxyProtocol = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable receiving PROXY Protocol headers.";
          };

          trustedCIDRs = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ "127.0.0.1/32" ];
            description = "List of trusted CIDRs to receive PROXY Protocol headers from.";
          };
        };
      };
      default = { };
      description = "Configuration for receiving PROXY Protocol.";
    };

    filters = lib.mkOption {
      type = lib.types.submodule {
        options = {
          rateLimiter = lib.mkOption {
            type = lib.types.submodule {
              options = {
                enable = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                  description = "Enable IP rate limiting.";
                };

                requestLimit = lib.mkOption {
                  type = lib.types.int;
                  default = 10;
                  description = "Maximum number of requests per IP before blocking.";
                };

                windowLength = lib.mkOption {
                  type = lib.types.str;
                  default = "1s";
                  description = "Time frame for request limit (e.g., '1s', '10m').";
                };
              };
            };
            default = { };
            description = "Configuration for the rateLimiter filter.";
          };
        };
      };
      default = { };
      description = "Global filters configuration.";
    };

  };

  # Systemd Service
  config = lib.mkIf cfg.enable {

    environment.etc = (
      proxyFiles
      // {
        "infrared/config.yml".source = configFile;
      }
    );

    systemd.services.infrared = {
      description = "A service for Minecraft Reverse Proxy";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/infrared -c /etc/infrared/config.yml -p /etc/infrared/proxies";
        Restart = "always";
      };
    };
  };

}
