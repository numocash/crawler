# Swap Library [![Foundry][foundry-badge]][foundry] [![License: MIT][license-badge]][license]

[gha]: https://github.com/numo-hq/swap-library/actions
[gha-badge]: https://github.com/numo-hq/swap-library/actions/workflows/ci.yml/badge.svg
[foundry]: https://getfoundry.sh/
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg
[license]: https://opensource.org/licenses/MIT
[license-badge]: https://img.shields.io/badge/License-MIT-blue.svg

Helper functions for swapping with Numo.

## Examples

- **SwapRouter.sol:** Facilitates swapping on PowerMaker
- **Arbitrage.sol:** Allows for arbitrage between a Uniswap V2 or V3 style exchange and PowerMaker

## Development

### Build

Build the contracts:

```sh
$ forge build
```

### Clean

Delete the build artifacts and cache directories:

```sh
$ forge clean
```

### Compile

Compile the contracts:

```sh
$ forge build
```

### Format

Format the contracts:

```sh
$ forge fmt
```

### Gas Usage

Get a gas report:

```sh
$ forge test --gas-report
```

### Lint

Lint the contracts:

```sh
$ pnpm lint
```

### Test

Run the tests:

```sh
$ forge test
```

## Notes

1. Foundry uses [git submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules) to manage dependencies. For
   detailed instructions on working with dependencies, please refer to the
   [guide](https://book.getfoundry.sh/projects/dependencies.html) in the book
2. You don't have to create a `.env` file, but filling in the environment variables may be useful when debugging and
   testing against a fork.

## License

[MIT](./LICENSE.md) © Numo
