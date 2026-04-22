# nixpkg-destructive-command-guard

Thin Nix packaging repo for [`Dicklesworthstone/destructive_command_guard`](https://github.com/Dicklesworthstone/destructive_command_guard).

## Upstream

- Repo: `Dicklesworthstone/destructive_command_guard`
- Upstream crate version: `0.4.3`
- Pinned commit: `b86e95d97f1f74db7420e58f334d8535d27f25c7`

## Usage

```bash
nix build
nix run
```

The package fetches the pinned upstream source directly from GitHub, stages only the crate inputs needed for packaging, and installs the `dcg` binary.
