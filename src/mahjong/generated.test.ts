import generate from './index'
import { Tile } from './tiles'
import { NORMAL_YAKU, YAKUMAN } from './yaku_generator'

const GAMES = 3000


const countDoras = (tiles: Tile[], indicators: Tile[]): number => {
    let total = 0
    for (const indicator of indicators) {
        if (indicator.isClosed) continue
        const dora = indicator.next()
        total += tiles.filter((tile) => tile.tile === dora).length
    }

    return total
}


test('generated hands are scored consistently', () => {
    let opened = 0
    const seen: Record<string, boolean> = {}

    for (let i = 0; i < GAMES; i++) {
        const game = generate()
        const { hand } = game
        for (const item of game.yaku) seen[item.name] = true

        // The winning tile must point at the set it belongs to, otherwise
        // yaku/fu that depend on the wait (pinfu, sanankou, tanki fu) go wrong.
        const holders = [hand.pair!, ...hand.sets].filter((set) => set.tiles.some((t) => t.id === hand.wait!.id))
        expect(holders.length).toEqual(1)
        expect(hand.wait!.set!.id).toEqual(holders[0].id)

        // An opened hand is declared by its called sets and its wait stays concealed.
        expect(hand.isOpened).toEqual(hand.sets.some((set) => set.isOpened))
        expect(hand.wait!.set!.isOpened).toBeFalsy()
        if (hand.isOpened) opened += 1

        // A hand without yaku cannot be declared riichi when it is opened.
        expect(game.yaku.length).toBeGreaterThan(0)

        // Generator may open up to 5 indicators, all of them count.
        expect(game.dora).toEqual(countDoras(hand.tiles(), game.wall.slice(2, 7)))
        expect(game.uraDora).toEqual(countDoras(hand.tiles(), game.wall.slice(9, 14)))
    }

    expect(opened).toBeGreaterThan(0)

    // the generator aims at a yaku every hand, so the whole list shows up
    for (const yaku of [...NORMAL_YAKU, ...YAKUMAN]) expect(seen[yaku]).toBeTruthy()
})
