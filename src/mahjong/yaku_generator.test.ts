import analyze from './analyze'
import { constructForYaku, generateGameState, NORMAL_YAKU, selectTarget, YAKUMAN } from './yaku_generator'

const ALL_YAKU = [...NORMAL_YAKU, ...YAKUMAN]


// three and four kans add one tile each to the usual fourteen
const KAN_TILE_COUNTS: Record<string, number> = {
    'sankantsu': 17,
    'suu kan tsu': 18,
}


test('generates a valid game state', () => {
    const game = generateGameState()

    expect(game.wall).toHaveLength(14)
    expect(game.hand).toBeTruthy()
    expect(game.seatWind).toBeTruthy()
    expect(game.prevalentWind).toBeTruthy()
    expect(game.hand.sets).toHaveLength(4)
    expect(game.hand.pair).toBeTruthy()

    const kans = game.hand.sets.filter((set) => set.isKan).length
    expect(game.hand.tiles()).toHaveLength(14 + kans)
})


test('builds a valid hand for every yaku', () => {
    for (const yaku of ALL_YAKU) {
        const { hand } = constructForYaku(yaku)

        expect(hand).toBeTruthy()
        expect(hand.sets).toHaveLength(4)
        expect(hand.pair).toBeTruthy()
        expect(hand.tiles()).toHaveLength(KAN_TILE_COUNTS[yaku] || 14)

        // the score screen shows called sets, so an open hand must mark them and
        // the winning tile must stay concealed
        expect(hand.isOpened).toEqual(hand.sets.some((set) => !!set.isOpened))
        if (hand.isOpened) expect(hand.wait!.set!.isOpened).toBeFalsy()
    }
})


test('every constructed hand is detected as its target yaku', () => {
    for (const yaku of ALL_YAKU) {
        const { hand } = constructForYaku(yaku)
        const result = analyze({ hand, wall: [], seatWind: 'wE', prevalentWind: 'wS' })

        expect(result.yaku.map((item) => item.name)).toContain(yaku)
    }
})


test('rejects an unknown target', () => {
    expect(() => constructForYaku('not a yaku')).toThrow()
})


test('generated hands always have a yaku', () => {
    const game = generateGameState()

    expect(analyze(game).yaku.length).toBeGreaterThan(0)
})


test('selects every yaku over a run', () => {
    // the target is drawn from the seeded random source, so this is stable
    const targets = new Set<string>()
    for (let idx = 0; idx < 2000; idx++) targets.add(selectTarget())

    for (const yaku of ALL_YAKU) expect(targets.has(yaku)).toBeTruthy()
})
