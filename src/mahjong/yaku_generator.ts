import analyze from './analyze'
import { random, sample, shuffle } from './random'
import { SUITS, Suit, TILES } from './resources'
import { Hand, Tile, TileSet } from './tiles'
import { GeneratedGame } from './types'

// The hand is built for one yaku at a time, so every yaku (not just the easy
// ones) is generated often enough to practise its scoring.

export const NORMAL_YAKU = [
    'chinitsu', 'ryanpeikou',
    'sanshoku dokou', 'sanankou', 'sankantsu', 'toitoi',
    'honitsu', 'shou sangen', 'honroutou', 'junchan',
    'pinfu', 'iipeikou', 'tanyao', 'sanshoku', 'itsu',
    'yakuhai', 'chanta',
]

export const YAKUMAN = [
    'chuuren pooto', 'suu ankou', 'suu kan tsu',
    'ryuu iisou', 'chinrouto', 'tsuu iisou',
    'dai sangen', 'shou suushii', 'dai suushii',
]

// yakuman stay rare, but are still a lot more common than in a plain random hand
const YAKUMAN_PERCENT = 10

const SUIT_NAMES: Suit[] = ['m', 's', 'p']
const HONORS = [...SUITS.w, ...SUITS.d]

export const selectTarget = (): string =>
    random(100) <= YAKUMAN_PERCENT ? sample(YAKUMAN) : sample(NORMAL_YAKU)


// A tile can never be used more than four times across the hand and the wall
class Pool {

    counts: Record<string, number>

    constructor() {
        this.counts = {}
        for (const tile of TILES) this.counts[tile] = (this.counts[tile] || 0) + 1
    }

    take(tile: string): Tile {
        if (this.counts[tile] <= 0) throw new Error(`No ${tile} remaining (max 4)`)
        this.counts[tile] -= 1
        return new Tile(tile)
    }
}


const sampleSize = <T>(items: T[], count: number): T[] => shuffle(items).slice(0, count)

const row = (pool: Pool, suit: Suit, start: number): TileSet => {
    const tiles: Tile[] = []
    for (let idx = 0; idx < 3; idx++) tiles.push(pool.take(`${suit}${start + idx}`))
    const set = new TileSet(...tiles)
    set.isValid()
    return set
}

const pung = (pool: Pool, suit: Suit, value: number): TileSet => {
    const tiles: Tile[] = []
    for (let idx = 0; idx < 3; idx++) tiles.push(pool.take(`${suit}${value}`))
    const set = new TileSet(...tiles)
    set.isValid()
    return set
}

const kan = (pool: Pool, suit: Suit, value: number): TileSet => {
    const tiles: Tile[] = []
    for (let idx = 0; idx < 4; idx++) tiles.push(pool.take(`${suit}${value}`))
    const set = new TileSet(...tiles)
    set.isValid()
    return set
}

const pairOf = (pool: Pool, suit: Suit, value: number): TileSet => {
    const tiles: Tile[] = []
    for (let idx = 0; idx < 2; idx++) tiles.push(pool.take(`${suit}${value}`))
    const set = new TileSet(...tiles)
    set.isValid()
    return set
}

const honorPung = (pool: Pool, name: string): TileSet => {
    const tiles: Tile[] = []
    for (let idx = 0; idx < 3; idx++) tiles.push(pool.take(name))
    const set = new TileSet(...tiles)
    set.isValid()
    return set
}

const honorPair = (pool: Pool, name: string): TileSet => {
    const tiles: Tile[] = []
    for (let idx = 0; idx < 2; idx++) tiles.push(pool.take(name))
    const set = new TileSet(...tiles)
    set.isValid()
    return set
}


// The upstream score screen reads the called sets, so an open hand has to mark
// them. The winning tile always stays in a concealed set.
const openHand = (hand: Hand, count = 1): Hand => {
    for (const set of hand.sets.filter((item) => !item.isKan).slice(0, count))
        set.isOpened = true

    hand.isOpened = hand.sets.some((set) => !!set.isOpened)
    if (hand.isOpened) {
        const concealed = hand.tiles().filter((tile) => !tile.set!.isOpened && !tile.set!.isKan)
        hand.wait = sample(concealed)
    }

    return hand
}

const openKans = (hand: Hand): Hand => {
    for (const set of hand.sets) set.isOpened = true
    hand.isOpened = true
    hand.wait = sample(hand.pair!.tiles)
    return hand
}


export const constructForYaku = (target: string): { hand: Hand, pool: Pool } => {
    const pool = new Pool()

    const hand = ((): Hand => {
        switch (target) {
            case 'tanyao': {
                const suit = sample(SUIT_NAMES)
                return new Hand(
                    row(pool, suit, 2), row(pool, suit, 3), row(pool, suit, 5), row(pool, suit, 6),
                    pairOf(pool, suit, 8),
                )
            }

            case 'honitsu': {
                const suit = sample(SUIT_NAMES)
                const honor = sample(HONORS)
                return openHand(new Hand(
                    row(pool, suit, 1), row(pool, suit, 4), row(pool, suit, 7), honorPung(pool, honor),
                    pairOf(pool, suit, 5),
                ))
            }

            case 'chinitsu': {
                const suit = sample(SUIT_NAMES)
                return new Hand(
                    row(pool, suit, 1), row(pool, suit, 4), row(pool, suit, 7), pung(pool, suit, 5),
                    pairOf(pool, suit, 1),
                )
            }

            case 'honroutou': {
                const honors = sampleSize(HONORS, 3)
                const suit = sample(SUIT_NAMES)
                const pairSuit = sample(SUIT_NAMES.filter((item) => item !== suit))
                return openHand(new Hand(
                    honorPung(pool, honors[0]), honorPung(pool, honors[1]),
                    pung(pool, suit, 1), pung(pool, suit, 9),
                    pairOf(pool, pairSuit, 1),
                ))
            }

            case 'tsuu iisou': {
                const honors = sampleSize(HONORS, 5)
                return openHand(new Hand(
                    honorPung(pool, honors[0]), honorPung(pool, honors[1]),
                    honorPung(pool, honors[2]), honorPung(pool, honors[3]),
                    honorPair(pool, honors[4]),
                ))
            }

            case 'chinrouto': {
                const suits = sampleSize(SUIT_NAMES, 3)
                return openHand(new Hand(
                    pung(pool, suits[0], 1), pung(pool, suits[1], 9), pung(pool, suits[2], 1),
                    pung(pool, suits[0], 9),
                    pairOf(pool, suits[1], 1),
                ))
            }

            case 'ryuu iisou':
                return new Hand(
                    row(pool, 's', 2), pung(pool, 's', 6), pung(pool, 's', 8), pung(pool, 's', 4),
                    honorPair(pool, 'dG'),
                )

            case 'toitoi':
                return openHand(new Hand(
                    pung(pool, 'm', 1), pung(pool, 's', 5), pung(pool, 'p', 9), pung(pool, 'm', 3),
                    pairOf(pool, 's', 7),
                ))

            case 'pinfu': {
                const suit = sample(SUIT_NAMES)
                const hand = new Hand(
                    row(pool, suit, 1), row(pool, suit, 2), row(pool, suit, 6), row(pool, suit, 7),
                    pairOf(pool, suit, 5),
                )
                hand.wait = hand.sets[0].tiles[1]
                return hand
            }

            case 'sanankou': {
                const hand = new Hand(
                    pung(pool, 'm', 5), pung(pool, 's', 3), pung(pool, 'p', 7),
                    row(pool, 'm', 1),
                    pairOf(pool, 'm', 9),
                )
                hand.wait = hand.sets[3].tiles[1]
                return hand
            }

            case 'suu ankou': {
                const hand = new Hand(
                    pung(pool, 'm', 1), pung(pool, 's', 3), pung(pool, 'p', 5), pung(pool, 'm', 7),
                    pairOf(pool, 's', 9),
                )
                hand.wait = hand.pair!.tiles[0]
                return hand
            }

            case 'suu kan tsu':
                return openKans(new Hand(
                    kan(pool, 'm', 1), kan(pool, 's', 3), kan(pool, 'p', 5), kan(pool, 'm', 7),
                    pairOf(pool, 's', 9),
                ))

            case 'sankantsu':
                return new Hand(
                    kan(pool, 'm', 1), kan(pool, 's', 3), kan(pool, 'p', 5),
                    row(pool, 'm', 2),
                    pairOf(pool, 'm', 8),
                )

            case 'itsu': {
                const suit = sample(SUIT_NAMES)
                return new Hand(
                    row(pool, suit, 1), row(pool, suit, 4), row(pool, suit, 7),
                    row(pool, suit, 2),
                    pairOf(pool, suit, 5),
                )
            }

            case 'sanshoku': {
                const value = random(1, 7)
                return new Hand(
                    row(pool, 'm', value), row(pool, 's', value), row(pool, 'p', value),
                    row(pool, 'm', 2),
                    pairOf(pool, 'm', 5),
                )
            }

            case 'sanshoku dokou': {
                const value = random(1, 9)
                const pairValue = value !== 5 ? 5 : 7
                const chowSuit = sample(SUIT_NAMES)
                return new Hand(
                    pung(pool, 'm', value), pung(pool, 's', value), pung(pool, 'p', value),
                    row(pool, chowSuit, 2),
                    pairOf(pool, 's', pairValue),
                )
            }

            case 'iipeikou': {
                const suit = sample(SUIT_NAMES)
                return new Hand(
                    row(pool, suit, 2), row(pool, suit, 2),
                    row(pool, suit, 6), row(pool, suit, 7),
                    pairOf(pool, suit, 5),
                )
            }

            case 'ryanpeikou': {
                const suit = sample(SUIT_NAMES)
                const first = random(1, 4)
                const second = random(first + 3, 7)
                return new Hand(
                    row(pool, suit, first), row(pool, suit, first),
                    row(pool, suit, second), row(pool, suit, second),
                    pairOf(pool, suit, 8),
                )
            }

            case 'shou sangen': {
                const dragons = sampleSize(['dR', 'dW', 'dG'], 3)
                const suit = sample(SUIT_NAMES)
                return new Hand(
                    honorPung(pool, dragons[0]), honorPung(pool, dragons[1]),
                    row(pool, suit, 2), row(pool, suit, 5),
                    honorPair(pool, dragons[2]),
                )
            }

            case 'dai sangen': {
                const suit = sample(SUIT_NAMES)
                const value = random(1, 7)
                return new Hand(
                    honorPung(pool, 'dR'), honorPung(pool, 'dW'), honorPung(pool, 'dG'),
                    row(pool, suit, value),
                    pairOf(pool, suit, 1),
                )
            }

            case 'shou suushii': {
                const winds = sampleSize(['wE', 'wS', 'wW', 'wN'], 4)
                const suit = sample(SUIT_NAMES)
                const value = random(1, 7)
                return new Hand(
                    honorPung(pool, winds[0]), honorPung(pool, winds[1]), honorPung(pool, winds[2]),
                    row(pool, suit, value),
                    honorPair(pool, winds[3]),
                )
            }

            case 'dai suushii': {
                const winds = sampleSize(['wE', 'wS', 'wW', 'wN'], 4)
                const suit = sample(SUIT_NAMES)
                const value = random(1, 9)
                return openHand(new Hand(
                    honorPung(pool, winds[0]), honorPung(pool, winds[1]),
                    honorPung(pool, winds[2]), honorPung(pool, winds[3]),
                    pairOf(pool, suit, value),
                ))
            }

            case 'chanta': {
                const suit = sample(SUIT_NAMES)
                const direction = sample(['low', 'high'])
                const chows = direction === 'low'
                    ? [row(pool, suit, 1), row(pool, suit, 7)]
                    : [row(pool, suit, 7), row(pool, suit, 1)]
                const pair = direction === 'low' ? pairOf(pool, suit, 9) : pairOf(pool, suit, 1)
                const honors = sampleSize(HONORS, 2)
                return openHand(new Hand(
                    chows[0], chows[1],
                    honorPung(pool, honors[0]), honorPung(pool, honors[1]),
                    pair,
                ))
            }

            case 'junchan': {
                const suit = sample(SUIT_NAMES)
                const direction = sample(['low', 'high'])
                const otherSuits = SUIT_NAMES.filter((item) => item !== suit)
                const first = sample(otherSuits)
                const second = otherSuits.find((item) => item !== first)!
                const chows = direction === 'low'
                    ? [row(pool, suit, 1), row(pool, suit, 7)]
                    : [row(pool, suit, 7), row(pool, suit, 1)]
                const pair = direction === 'low' ? pairOf(pool, suit, 9) : pairOf(pool, suit, 1)
                return openHand(new Hand(
                    chows[0], chows[1],
                    pung(pool, first, 1), pung(pool, second, 9),
                    pair,
                ))
            }

            case 'yakuhai': {
                const honor = sample(['dR', 'dW', 'dG'])
                const suit = sample(SUIT_NAMES)
                return new Hand(
                    honorPung(pool, honor),
                    row(pool, suit, 2), row(pool, suit, 5), row(pool, suit, 6),
                    pairOf(pool, suit, 8),
                )
            }

            case 'chuuren pooto': {
                const suit = sample(SUIT_NAMES)
                return new Hand(
                    pung(pool, suit, 1),
                    row(pool, suit, 2),
                    pairOf(pool, suit, 5),
                    row(pool, suit, 6),
                    pung(pool, suit, 9),
                )
            }

            default:
                throw new Error(`Unknown yaku '${target}'`)
        }
    })()

    return { hand, pool }
}


const buildWall = (pool: Pool, hand: Hand): Tile[] => {
    const remaining: Tile[] = []
    for (const name of Object.keys(pool.counts)) {
        for (let idx = 0; idx < pool.counts[name]; idx++) remaining.push(new Tile(name))
    }

    const wall = shuffle(remaining).splice(0, 14)
    for (const tile of wall) tile.isClosed = true

    // one indicator per kan, sometimes a few more
    let indicators = 1 + hand.sets.filter((set) => set.isKan).length
    while (random(100) > 75 && indicators < 5) indicators += 1
    for (let idx = 0; idx < indicators; idx++) {
        wall[2 + idx].isClosed = false
        wall[9 + idx].isClosed = false
    }

    return wall
}


export const generateGameState = (): GeneratedGame => {
    const target = selectTarget()
    const { hand, pool } = constructForYaku(target)

    const wall = buildWall(pool, hand)
    const seatWind = sample(SUITS.w)
    const prevalentWind = sample([SUITS.w[0], SUITS.w[1]])

    const game = { wall, hand, seatWind, prevalentWind }
    const detected = analyze(game).yaku.map((item) => item.name)
    if (!detected.includes(target))
        throw new Error(`Target yaku '${target}' is missing from the analysis: ${detected.join(', ')}`)

    return game
}
