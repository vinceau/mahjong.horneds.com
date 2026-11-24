Riichi Mahjong Scores Trainer
=============================

Source files for https://mahjong.horneds.com

## Changes in this fork

The only functional change is a yaku-aware hand generator. Everything else
(opened hands, seeded links, keyboard controls and mobile layout) comes from
upstream. The Pages workflow is upstream's, except that the fork deploys to
`https://vinceau.github.io/mahjong.horneds.com/`.

### How our yaku generator works

The upstream generator shuffles the wall and tries to draw four sets and a pair
from it. The fork's generator works the other way around and builds the hand for
one chosen yaku:

1. Pick a target yaku.
2. Take tiles from a pool that starts with four copies of every tile, so a
   construction can never use a fifth copy.
3. Build the exact sets and pair that the target needs. The recipes are fixed
   patterns parameterised by suit, number or honour; for example pinfu is
   `123 234 678 789 55` and ryanpeikou is two copies of two different chows.
4. Fill the 14-tile wall from the unused pool and reveal the dora indicators.
5. Run the normal analyzer over the hand. If the analyzer does not find the
   target yaku, generation throws instead of showing an unscoreable hand.

The hand is still drawn from the seeded random source, so the upstream
`#<seed>` link keeps showing the same hand. There is no session-wide "unseen
yaku" queue: target selection has to be a pure function of the seed, otherwise
a shared link would depend on how many hands the sender had already seen.

### Yaku that are generated

Normal yaku (17):

`chinitsu`, `ryanpeikou`, `sanshoku dokou`, `sanankou`, `sankantsu`, `toitoi`,
`honitsu`, `shou sangen`, `honroutou`, `junchan`, `pinfu`, `iipeikou`,
`tanyao`, `sanshoku`, `itsu`, `yakuhai`, `chanta`

Yakuman (9):

`chuuren pooto`, `suu ankou`, `suu kan tsu`, `ryuu iisou`, `chinrouto`,
`tsuu iisou`, `dai sangen`, `shou suushii`, `dai suushii`

### Random chances

`random(100)` has 101 outcomes (0 through 100), so the exact fractions are
slightly above the round percentages below.

- **Target yaku:** `random(100) <= 10` asks for a yakuman, so **11/101
  (~10.9%)** of hands target a yakuman and the other **90/101 (~89.1%)** target
  a normal yaku.
- **Individual target:** every entry in each list is equally likely.
  - each normal yaku: `90/101 * 1/17` = **~5.2%** of all hands
  - each yakuman: `11/101 * 1/9` = **~1.2%** of all hands
- **Opened hands:** there is no independent open roll; it follows the target.
  Five normal targets (`honitsu`, `honroutou`, `toitoi`, `chanta`, `junchan`)
  and four yakuman (`tsuu iisou`, `chinroutou`, `suu kan tsu`, `dai suushii`)
  are built open. That is
  `90/101 * 5/17 + 11/101 * 4/9` = **~31%** of hands. An open target marks one
  set as called (all four kans for `suu kan tsu`) and keeps the winning tile in
  a concealed set.
- **Kans:** target-driven rather than random. `sankantsu` always has three
  kans and `suu kan tsu` always has four; no other target uses a kan.
- **Dora indicators:** one, plus one per kan, then each additional indicator
  has a **~25%** chance up to the five-indicator maximum
  (`random(100) > 75`). The upstream generator uses the same rule.
- **Winds:** the seat wind is uniformly one of East/South/West/North; the
  prevalent wind is uniformly East or South.
- **Tsumo and riichi:** these come from the analyzer, not the generator:
  **~40%** of hands are won by tsumo, and a concealed hand gets riichi with
  **~21%** probability. Opened hands never get riichi.

### How all yaku are covered

- Every yaku in the two lists above has its own constructor, so none can be
  unreachable.
- `selectTarget` only ever returns names from those lists.
- `src/mahjong/yaku_generator.test.ts` builds every target and asserts that the
  analyzer detects that exact yaku. It also draws 2000 targets and asserts that
  all 26 names appear.
- `src/mahjong/generated.test.ts` generates 3000 scored hands and asserts that
  every yaku name appears in the results, alongside the existing score, wait,
  dora and open-hand checks.

Coverage is therefore statistical rather than a guaranteed no-repeat queue: no
yaku is privileged and every yaku appears quickly, but the same yaku can return
before the full list has been seen. That is the trade-off for keeping shared
seed links reproducible.

### Differences from the upstream generator

| | upstream | this fork |
| --- | --- | --- |
| hand building | shuffle the wall and draw sets with weighted rejection | build a hand backwards from a target yaku |
| target | none, so plain hands are common | one of 17 normal yaku or 9 yakuman every hand |
| honour/terminal bias | honours ~70%, terminals ~80% | set by the target recipe |
| opened hands | ~15% chance, then 1-2 called sets | ~31%, determined by the target |
| kans | ~1% chance to upgrade a pon | fixed by the target |
| yaku guarantee | analyzer may find none, then the app draws again | target yaku is always present, checked after analysis |
| coverage | whatever the random draw gives | every yaku has a target and is exercised by tests |

## Build instructions

You need Node.js 18 or newer and Yarn 1.x. The Makefile sets the OpenSSL legacy
provider that webpack 4 needs on modern Node versions.

| What | Command | Notes |
| --- | --- | --- |
| Install dependencies | `make node_modules` | runs `yarn` |
| Development server | `make dev` | http://localhost:5000, hot reload, opens a browser |
| Production bundle | `make production` | writes static files to `build/` |
| Type check | `make check` | `tsc --noEmit` |
| Run the tests | `make test` | Jest, same as `make t` |
| Tests with coverage | `make coverage` | enforces the coverage thresholds |
| Bump the version | `make version` | bumps `src/package.json` |
| Build the Docker image | `make docker` | |
| Run the Docker image | `make docker-run` | serves on http://localhost:8000 |

Without Make, the same steps are:

```sh
yarn install
NODE_OPTIONS=--openssl-legacy-provider NODE_ENV=production \
  ./node_modules/.bin/webpack --config src/webpack.config.js
./node_modules/.bin/jest
```

### Deployment

Pushing to `main` (or running the **Deploy to GitHub Pages** workflow manually)
runs type checks, coverage, the production build and publishes `build/` to
GitHub Pages.

The fork lives at `https://vinceau.github.io/mahjong.horneds.com/`.

