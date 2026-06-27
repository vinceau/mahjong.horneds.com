sample = require 'lodash/sample'
sampleSize = require 'lodash/sampleSize'
shuffle = require 'lodash/shuffle'
random = require 'lodash/random'

{ Tile, TileSet, Hand } = require './tiles'
{ TILES, SUITS } = require './resources'
analyze = require './analyze'

class Pool
    constructor: ->
        @counts = {}
        for tile in TILES
            @counts[tile] = (@counts[tile] or 0) + 1

    take: (tile) ->
        if @counts[tile] <= 0
            throw new Error "No #{tile} remaining (max 4)"
        @counts[tile]--
        new Tile(tile)

NORMAL_YAKU = [
    'chinitsu', 'ryanpeikou'
    'sanshoku dokou', 'sanankou', 'sankantsu', 'toitoi'
    'honitsu', 'shou sangen', 'honroutou', 'junchan'
    'pinfu', 'iipeikou', 'tanyao', 'sanshoku', 'itsu'
    'yakuhai', 'chanta'
]

YAKUMAN = [
    'chuuren pooto', 'suu ankou', 'suu kan tsu'
    'ryuu iisou', 'chinrouto', 'tsuu iisou'
    'dai sangen', 'shou suushii', 'dai suushii'
]

unseenNormal = new Set(NORMAL_YAKU)
unseenYakuman = new Set(YAKUMAN)

chow = (pool, suit, start) ->
    tiles = (pool.take("#{suit}#{start + i}") for i in [0..2])
    ts = new TileSet(tiles...)
    ts.isValid()
    ts

pung = (pool, suit, val) ->
    tiles = (pool.take("#{suit}#{val}") for _ in [0..2])
    ts = new TileSet(tiles...)
    ts.isValid()
    ts

kan = (pool, suit, val) ->
    tiles = (pool.take("#{suit}#{val}") for _ in [0..3])
    ts = new TileSet(tiles...)
    ts.isValid()
    ts

pair = (pool, suit, val) ->
    tiles = (pool.take("#{suit}#{val}") for _ in [0..1])
    ts = new TileSet(tiles...)
    ts.isValid()
    ts

honorPung = (pool, name) ->
    tiles = (pool.take(name) for _ in [0..2])
    ts = new TileSet(tiles...)
    ts.isValid()
    ts

honorPair = (pool, name) ->
    tiles = (pool.take(name) for _ in [0..1])
    ts = new TileSet(tiles...)
    ts.isValid()
    ts

selectTarget = ->
    if unseenYakuman.size > 0 and random(100) <= 10
        return sample([...unseenYakuman])
    if unseenNormal.size == 0
        unseenNormal = new Set(NORMAL_YAKU)
    return sample([...unseenNormal])

recordYaku = (yakuList) ->
    for y in yakuList
        unseenNormal.delete(y.name)
        unseenYakuman.delete(y.name)
    if unseenYakuman.size == 0
        unseenYakuman = new Set(YAKUMAN)
    if unseenNormal.size == 0
        unseenNormal = new Set(NORMAL_YAKU)

constructForYaku = (target) ->
    pool = new Pool()
    hand = switch target
        when 'tanyao'
            suit = sample ['m', 's', 'p']
            new Hand(
                chow(pool, suit, 2), chow(pool, suit, 3), chow(pool, suit, 5), chow(pool, suit, 6),
                pair(pool, suit, 8)
            )

        when 'honitsu'
            suit = sample ['m', 's', 'p']
            honor = sample ['wE', 'wS', 'wW', 'wN', 'dR', 'dW', 'dG']
            hand = new Hand(
                chow(pool, suit, 1), chow(pool, suit, 4), chow(pool, suit, 7), honorPung(pool, honor),
                pair(pool, suit, 5)
            )
            hand.isOpened = true
            hand

        when 'chinitsu'
            suit = sample ['m', 's', 'p']
            new Hand(
                chow(pool, suit, 1), chow(pool, suit, 4), chow(pool, suit, 7), pung(pool, suit, 5),
                pair(pool, suit, 1)
            )

        when 'honroutou'
            honors = sampleSize ['wE', 'wS', 'wW', 'wN', 'dR', 'dW', 'dG'], 3
            suit = sample ['m', 's', 'p']
            pairSuit = sample (s for s in ['m', 's', 'p'] when s != suit)
            hand = new Hand(
                honorPung(pool, honors[0]), honorPung(pool, honors[1]),
                pung(pool, suit, 1), pung(pool, suit, 9),
                pair(pool, pairSuit, 1)
            )
            hand.isOpened = true
            hand

        when 'tsuu iisou'
            honors = sampleSize ['wE', 'wS', 'wW', 'wN', 'dR', 'dW', 'dG'], 5
            hand = new Hand(
                honorPung(pool, honors[0]), honorPung(pool, honors[1]),
                honorPung(pool, honors[2]), honorPung(pool, honors[3]),
                honorPair(pool, honors[4])
            )
            hand.isOpened = true
            hand

        when 'chinrouto'
            suits = sampleSize ['m', 's', 'p'], 3
            hand = new Hand(
                pung(pool, suits[0], 1), pung(pool, suits[1], 9), pung(pool, suits[2], 1),
                pung(pool, suits[0], 9),
                pair(pool, suits[1], 1)
            )
            hand.isOpened = true
            hand

        when 'ryuu iisou'
            new Hand(
                chow(pool, 's', 2), pung(pool, 's', 6), pung(pool, 's', 8), pung(pool, 's', 4),
                honorPair(pool, 'dG')
            )

        when 'toitoi'
            hand = new Hand(
                pung(pool, 'm', 1), pung(pool, 's', 5), pung(pool, 'p', 9), pung(pool, 'm', 3),
                pair(pool, 's', 7)
            )
            hand.isOpened = true
            hand

        when 'pinfu'
            suit = sample ['m', 's', 'p']
            hand = new Hand(
                chow(pool, suit, 1), chow(pool, suit, 2), chow(pool, suit, 6), chow(pool, suit, 7),
                pair(pool, suit, 5)
            )
            hand.wait = hand.sets[0].tiles[1]
            hand

        when 'sanankou'
            hand = new Hand(
                pung(pool, 'm', 5), pung(pool, 's', 3), pung(pool, 'p', 7),
                chow(pool, 'm', 1),
                pair(pool, 'm', 9)
            )
            hand.wait = hand.sets[3].tiles[1]
            hand

        when 'suu ankou'
            hand = new Hand(
                pung(pool, 'm', 1), pung(pool, 's', 3), pung(pool, 'p', 5), pung(pool, 'm', 7),
                pair(pool, 's', 9)
            )
            hand.wait = hand.pair.tiles[0]
            hand

        when 'suu kan tsu'
            hand = new Hand(
                kan(pool, 'm', 1), kan(pool, 's', 3), kan(pool, 'p', 5), kan(pool, 'm', 7),
                pair(pool, 's', 9)
            )
            hand.isOpened = true
            hand

        when 'sankantsu'
            new Hand(
                kan(pool, 'm', 1), kan(pool, 's', 3), kan(pool, 'p', 5),
                chow(pool, 'm', 2),
                pair(pool, 'm', 8)
            )

        when 'itsu'
            suit = sample ['m', 's', 'p']
            new Hand(
                chow(pool, suit, 1), chow(pool, suit, 4), chow(pool, suit, 7),
                chow(pool, suit, 2),
                pair(pool, suit, 5)
            )

        when 'sanshoku'
            num = random(1, 7)
            new Hand(
                chow(pool, 'm', num), chow(pool, 's', num), chow(pool, 'p', num),
                chow(pool, 'm', 2),
                pair(pool, 'm', 5)
            )

        when 'sanshoku dokou'
            num = random(1, 9)
            pairVal = if num != 5 then 5 else 7
            chowSuit = sample ['m', 's', 'p']
            new Hand(
                pung(pool, 'm', num), pung(pool, 's', num), pung(pool, 'p', num),
                chow(pool, chowSuit, 2),
                pair(pool, 's', pairVal)
            )

        when 'iipeikou'
            suit = sample ['m', 's', 'p']
            new Hand(
                chow(pool, suit, 2), chow(pool, suit, 2),
                chow(pool, suit, 6), chow(pool, suit, 7),
                pair(pool, suit, 5)
            )

        when 'ryanpeikou'
            suit = sample ['m', 's', 'p']
            num1 = random(1, 4)
            num2 = random(num1 + 3, 7)
            new Hand(
                chow(pool, suit, num1), chow(pool, suit, num1),
                chow(pool, suit, num2), chow(pool, suit, num2),
                pair(pool, suit, 8)
            )

        when 'shou sangen'
            dragons = sampleSize ['dR', 'dW', 'dG'], 3
            suit = sample ['m', 's', 'p']
            new Hand(
                honorPung(pool, dragons[0]), honorPung(pool, dragons[1]),
                chow(pool, suit, 2), chow(pool, suit, 5),
                honorPair(pool, dragons[2])
            )

        when 'dai sangen'
            suit = sample ['m', 's', 'p']
            num = random(1, 7)
            new Hand(
                honorPung(pool, 'dR'), honorPung(pool, 'dW'), honorPung(pool, 'dG'),
                chow(pool, suit, num),
                pair(pool, suit, 1)
            )

        when 'shou suushii'
            winds = sampleSize ['wE', 'wS', 'wW', 'wN'], 4
            suit = sample ['m', 's', 'p']
            num = random(1, 7)
            new Hand(
                honorPung(pool, winds[0]), honorPung(pool, winds[1]), honorPung(pool, winds[2]),
                chow(pool, suit, num),
                honorPair(pool, winds[3])
            )

        when 'dai suushii'
            winds = sampleSize ['wE', 'wS', 'wW', 'wN'], 4
            suit = sample ['m', 's', 'p']
            num = random(1, 9)
            hand = new Hand(
                honorPung(pool, winds[0]), honorPung(pool, winds[1]),
                honorPung(pool, winds[2]), honorPung(pool, winds[3]),
                pair(pool, suit, num)
            )
            hand.isOpened = true
            hand

        when 'chanta'
            suit = sample ['m', 's', 'p']
            direction = sample ['low', 'high']
            [chow1, chow2, pairTile] = if direction == 'low'
                [chow(pool, suit, 1), chow(pool, suit, 7), pair(pool, suit, 9)]
            else
                [chow(pool, suit, 7), chow(pool, suit, 1), pair(pool, suit, 1)]
            honors = sampleSize ['wE', 'wS', 'wW', 'wN', 'dR', 'dW', 'dG'], 2
            hand = new Hand(
                chow1, chow2,
                honorPung(pool, honors[0]), honorPung(pool, honors[1]),
                pairTile
            )
            hand.isOpened = true
            hand

        when 'junchan'
            suit = sample ['m', 's', 'p']
            direction = sample ['low', 'high']
            otherSuits = (s for s in ['m', 's', 'p'] when s != suit)
            otherSuit1 = sample otherSuits
            otherSuit2 = (s for s in otherSuits when s != otherSuit1)[0]
            [chow1, chow2, pairTile] = if direction == 'low'
                [chow(pool, suit, 1), chow(pool, suit, 7), pair(pool, suit, 9)]
            else
                [chow(pool, suit, 7), chow(pool, suit, 1), pair(pool, suit, 1)]
            hand = new Hand(
                chow1, chow2,
                pung(pool, otherSuit1, 1), pung(pool, otherSuit2, 9),
                pairTile
            )
            hand.isOpened = true
            hand

        when 'yakuhai'
            honor = sample ['dR', 'dW', 'dG']
            suit = sample ['m', 's', 'p']
            new Hand(
                honorPung(pool, honor),
                chow(pool, suit, 2), chow(pool, suit, 5), chow(pool, suit, 6),
                pair(pool, suit, 8)
            )

        when 'chuuren pooto'
            suit = sample ['m', 's', 'p']
            new Hand(
                pung(pool, suit, 1),
                chow(pool, suit, 2),
                pair(pool, suit, 5),
                chow(pool, suit, 6),
                pung(pool, suit, 9)
            )

        else
            suit = sample ['m', 's', 'p']
            new Hand(
                chow(pool, suit, 1), chow(pool, suit, 2), chow(pool, suit, 4), chow(pool, suit, 5),
                pair(pool, suit, 7)
            )
    { hand, pool }

buildWall = (pool, hand) ->
    remaining = []
    for tile, count of pool.counts
        remaining.push(new Tile(tile)) for _ in [0...count]
    remaining = shuffle(remaining)
    wall = remaining.splice(0, 14)
    tile.isClosed = true for tile in wall

    indicators = 1 + (set for set in hand.sets when set.isKan).length
    indicators += 1 while random(100) > 75 and indicators < 5
    for idx in [0...indicators]
        wall[2 + idx]?.isClosed = wall[9 + idx]?.isClosed = false

    wall

generateGameState = ->
    target = selectTarget()

    { hand, pool } = constructForYaku(target)

    wall = buildWall(pool, hand)
    seatWind = sample(SUITS.w)
    prevalentWind = sample([SUITS.w[0], SUITS.w[1]])

    result = analyze({ wall, hand, seatWind, prevalentWind })
    detected = (y.name for y in result.yaku)
    unless target in detected
        throw new Error "Sanity check: target yaku '#{target}' not found in analysis (found: #{detected.join(', ')})"
    recordYaku(result.yaku)

    { wall, hand, seatWind, prevalentWind }

module.exports = { generateGameState, constructForYaku }
