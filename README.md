# Infrared-nix
The Reverse Proxy for Minecraft

## Original project

https://github.com/haveachin/infrared/tree/main
https://infrared.dev/

## Description
An ultra lightweight Minecraft reverse proxy and status placeholder: Ever wanted to have only one exposed port on your server for multiple Minecraft servers? Then Infrared is the tool you need! Infrared works as a reverse proxy using a sub-/domains to connect clients to a specific Minecraft server.
## Features

- [X] Reverse Proxy
  - [X] Wildcards Support
  - [X] Multi-Domain Support
- [X] Status Response Caching
- [X] Proxy Protocol Support
- [X] Ratelimiter

## Installation via Flakes
Add it to your system configuration:
```
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  
    infrared.url = "github:Chardje/Infrared-nix";
    infrared.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, nixpkgs, infrared }: {
    nixosConfigurations.<nameofconfig> = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux"; 
      modules = [
        # your modules
        infrared.nixosModules.infrared
      ];
    };
  };
}
```
And to `configuration.nix` 
```
{ config, pkgs, ... }:
{
  services.infrared = {
    enable = true;
    listensIpPort = "0.0.0.0:25565"
    keepAliveTimeout = "30s";
    proxies.<nameofproxy> = {
      enable = true;
      domains = ["example.com"];
      addresses = ["127.0.0.1:25565"];
    };
  };
}
```
## Options
### `services.infrared.enable`

Enables or disables the Infrared Minecraft reverse proxy service.

### `services.infrared.package`

The package that provides the `infrared` binary.  
Defaults to the bundled package defined in `package.nix`.

### `services.infrared.listensIpPort`

IP address and port that Infrared binds to and listens on.  
Example: `"0.0.0.0:25565"`.

### `services.infrared.keepAliveTimeout`

Maximum time allowed between packets before disconnecting a client.
Examples: `"10s"`, `"30s"`, `"1m"`.

### `services.infrared.proxies.<name>.enable`

Enables or disables an individual proxy entry.

### `services.infrared.proxies.<name>.domains`

List of domain patterns served by this proxy.  
Supports `*` and `?` wildcards.

### `services.infrared.proxies.<name>.addresses`

List of backend server addresses that Infrared forwards to.  
Example: `"127.0.0.1:25565"`.

### `services.infrared.proxies.<name>.sendProxyProtocol`

Sends PROXY Protocol v2 headers to backend servers.  
Useful for forwarding the real player IP address.

### `services.infrared.proxyProtocol.enable`

Enables receiving PROXY Protocol v2 headers.

### `services.infrared.proxyProtocol.trustedCIDRs`

List of CIDR ranges allowed to send PROXY Protocol headers.  
Only connections from these ranges may include PROXY headers.

### `services.infrared.filters.rateLimiter.enable`

Enables IP-based rate limiting.

### `services.infrared.filters.rateLimiter.requestLimit`

Maximum number of allowed connection attempts per IP within the time window.

### `services.infrared.filters.rateLimiter.windowLength`

The time window for the rate limiter.  
Examples: `"1s"`, `"10s"`, `"1m"`.

