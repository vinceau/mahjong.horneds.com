import * as riot from 'riot'

import { Hand, TileSet } from 'mahjong/tiles'
import { desc } from 'utils/tiles'

import './index'


const mountHand = (mask: string | Hand): any => {
    const element = document.createElement('div')
    document.body.appendChild(element)

    const hand = typeof mask === 'string' ? Hand.create(mask) : mask
    return riot.mount(element, 'hand', { hand, number: 1 })[0]
}

const kanHand = (opened: boolean): Hand => {
    const hand = new Hand(
        TileSet.create('m5m5m5m5'),
        TileSet.create('p1p2p3'),
        TileSet.create('s1s2s3'),
        TileSet.create('m7m8m9'),
        TileSet.create('wEwE'),
    )
    hand.sets[0].isOpened = opened
    hand.isOpened = opened
    hand.wait = hand.pair!.tiles[0]
    return hand
}

const renderedTiles = (root: Element): Element[] =>
    [...root.children].filter((item) => item.tagName === 'TILE')

const meldBlocks = (root: Element): Element[] =>
    [...root.querySelectorAll('.mj-hand__called')]

const tileBacks = (block: Element): boolean[] =>
    [...block.querySelectorAll('.c-tile__img')]
        .map((img) => img.classList.contains('c-tile__img--back'))

const sidewaysTiles = (block: Element): boolean[] =>
    [...block.querySelectorAll('.c-tile')]
        .map((tile) => tile.classList.contains('c-tile--open'))


test('labels every tile with its name', () => {
    const tag = mountHand('m1m2m3 p1p2p3 s1s2s3 m7m8m9 wSwS')

    const labels = [...tag.root.querySelectorAll('.c-tile')].map((tile: Element) => tile.getAttribute('aria-label'))
    const hand = tag.opts.hand as Hand

    // the winning tile is rendered apart from the rest of the hand
    const tiles = hand.tiles()
    const expected = [...tiles.filter((tile) => tile.id !== hand.wait!.id), hand.wait!]

    expect(labels).toHaveLength(14)
    expect(labels).toEqual(expected.map((tile) => desc[tile.tile]))

    expect(labels).toContain('1 man')
    expect(labels).toContain('1 pin')
    expect(labels).toContain('1 sou')
    expect(labels).toContain('South Wind')

    tag.unmount()
})


test('shows a called set apart from the concealed part', () => {
    const hand = Hand.create('m1m2m3 p4p5p6 s1s2s3 wNwNwN m5m5')
    hand.tsumo = true
    hand.sets[0].isOpened = true
    hand.isOpened = true
    // the winning tile is rendered apart, keep it out of the called set
    hand.wait = hand.pair!.tiles[0]

    const tag = mountHand(hand)

    const called = tag.root.querySelectorAll('.mj-hand__called')
    expect(called).toHaveLength(1)
    expect(called[0].querySelectorAll('.c-tile')).toHaveLength(3)
    expect(called[0].querySelectorAll('.c-tile--open')).toHaveLength(1)

    // the concealed part holds the other sets, the pair and the winning tile
    const concealed = tag.root.querySelector('.u-flex--wrap')!
    const tiles = [...concealed.children].filter((item) => item.tagName === 'TILE')
    expect(tiles).toHaveLength(10)
    expect(concealed.lastElementChild!.className).toContain('mj-hand__called')
    expect(tag.root.textContent).toContain('TSUMO')

    tag.unmount()
})


test('keeps a closed hand straight', () => {
    const hand = Hand.create('m1m2m3 p4p5p6 s1s2s3 wNwNwN m5m5')
    hand.tsumo = true
    hand.wait = hand.pair!.tiles[0]

    const tag = mountHand(hand)

    expect(tag.root.querySelectorAll('.c-tile--open')).toHaveLength(0)

    tag.unmount()
})


test('lays a closed kan out on the right as back-face-face-back', () => {
    const tag = mountHand(kanHand(false))

    // the kan is not part of the concealed hand (10 tiles: the kan draws an extra)
    const concealed = tag.root.querySelector('.u-flex--wrap')!
    expect(renderedTiles(concealed)).toHaveLength(10)
    expect(concealed.lastElementChild!.className).toContain('mj-hand__called')

    const [kan] = meldBlocks(tag.root)
    expect(kan.querySelectorAll('.c-tile')).toHaveLength(4)
    expect(tileBacks(kan)).toEqual([true, false, false, true])
    // a closed kan is never turned sideways
    expect(sidewaysTiles(kan)).toEqual([false, false, false, false])

    tag.unmount()
})


test('lays an open kan out on the right with a sideways called tile', () => {
    const tag = mountHand(kanHand(true))

    const concealed = tag.root.querySelector('.u-flex--wrap')!
    expect(renderedTiles(concealed)).toHaveLength(10)

    const [kan] = meldBlocks(tag.root)
    expect(kan.querySelectorAll('.c-tile')).toHaveLength(4)
    expect(sidewaysTiles(kan)).toEqual([false, false, false, true])
    expect(tileBacks(kan)).toEqual([false, false, false, false])

    tag.unmount()
})


test('keeps a called set and a closed kan together at the right, in hand order', () => {
    const hand = new Hand(
        TileSet.create('m5m5m5m5'),
        TileSet.create('p1p2p3'),
        TileSet.create('s1s2s3'),
        TileSet.create('m7m8m9'),
        TileSet.create('wEwE'),
    )
    hand.sets[1].isOpened = true
    hand.isOpened = true
    hand.wait = hand.pair!.tiles[0]

    const tag = mountHand(hand)

    const concealed = tag.root.querySelector('.u-flex--wrap')!
    expect(renderedTiles(concealed)).toHaveLength(7)

    const [kan, called] = meldBlocks(tag.root)
    expect(tileBacks(kan)).toEqual([true, false, false, true])
    expect(sidewaysTiles(kan)).toEqual([false, false, false, false])
    expect(tileBacks(called)).toEqual([false, false, false])
    expect(sidewaysTiles(called)).toEqual([false, false, true])

    tag.unmount()
})
