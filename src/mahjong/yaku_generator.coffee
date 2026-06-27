sample = require 'lodash/sample'
sampleSize = require 'lodash/sampleSize'
shuffle = require 'lodash/shuffle'
random = require 'lodash/random'

{ Tile, TileSet, Hand } = require './tiles'
{ TILES, SUITS } = require './resources'
analyze = require './analyze'

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

chow = (suit, start) ->
    TileSet.create "#{suit}#{start}#{suit}#{start + 1}#{suit}#{start + 2}"

pung = (suit, val) ->
    TileSet.create "#{suit}#{val}#{suit}#{val}#{suit}#{val}"

kan = (suit, val) ->
    TileSet.create "#{suit}#{val}#{suit}#{val}#{suit}#{val}#{suit}#{val}"

pair = (suit, val) ->
    TileSet.create "#{suit}#{val}#{suit}#{val}"

honorPung = (name) ->
    TileSet.create "#{name}#{name}#{name}"

honorPair = (name) ->
    TileSet.create "#{name}#{name}"

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
    switch target
        when 'tanyao'
            suit = sample ['m', 's', 'p']
            new Hand(
                chow(suit, 2), chow(suit, 3), chow(suit, 5), chow(suit, 6),
                pair(suit, 8)
            )

        when 'honitsu'
            suit = sample ['m', 's', 'p']
            honor = sample ['wE', 'wS', 'wW', 'wN', 'dR', 'dW', 'dG']
            hand = new Hand(
                chow(suit, 1), chow(suit, 4), chow(suit, 7), honorPung(honor),
                pair(suit, 5)
            )
            hand.isOpened = true
            hand

        when 'chinitsu'
            suit = sample ['m', 's', 'p']
            new Hand(
                chow(suit, 1), chow(suit, 4), chow(suit, 7), pung(suit, 5),
                pair(suit, 5)
            )

        when 'honroutou'
            honors = sampleSize ['wE', 'wS', 'wW', 'wN', 'dR', 'dW', 'dG'], 3
            suit = sample ['m', 's', 'p']
            hand = new Hand(
                honorPung(honors[0]), honorPung(honors[1]),
                pung(suit, 1), pung(suit, 9),
                pair(suit, 1)
            )
            hand.isOpened = true
            hand

        when 'tsuu iisou'
            honors = sampleSize ['wE', 'wS', 'wW', 'wN', 'dR', 'dW', 'dG'], 5
            hand = new Hand(
                honorPung(honors[0]), honorPung(honors[1]),
                honorPung(honors[2]), honorPung(honors[3]),
                honorPair(honors[4])
            )
            hand.isOpened = true
            hand

        when 'chinrouto'
            suits = sampleSize ['m', 's', 'p'], 3
            hand = new Hand(
                pung(suits[0], 1), pung(suits[1], 9), pung(suits[2], 1), pung('m', 9),
                pair('s', 9)
            )
            hand.isOpened = true
            hand

        when 'ryuu iisou'
            new Hand(
                chow('s', 2), pung('s', 6), pung('s', 8), honorPung('dG'),
                honorPair('dG')
            )

        when 'toitoi'
            hand = new Hand(
                pung('m', 1), pung('s', 5), pung('p', 9), pung('m', 3),
                pair('s', 7)
            )
            hand.isOpened = true
            hand

        when 'pinfu'
            suit = sample ['m', 's', 'p']
            hand = new Hand(
                chow(suit, 1), chow(suit, 2), chow(suit, 6), chow(suit, 7),
                pair(suit, 5)
            )
            hand.wait = hand.sets[0].tiles[1]
            hand

        when 'sanankou'
            hand = new Hand(
                pung('m', 5), pung('s', 3), pung('p', 7),
                chow('m', 1),
                pair('m', 5)
            )
            hand.wait = hand.sets[3].tiles[1]
            hand

        when 'suu ankou'
            hand = new Hand(
                pung('m', 1), pung('s', 3), pung('p', 5), pung('m', 7),
                pair('s', 9)
            )
            hand.wait = hand.pair.tiles[0]
            hand

        when 'suu kan tsu'
            hand = new Hand(
                kan('m', 1), kan('s', 3), kan('p', 5), kan('m', 7),
                pair('s', 9)
            )
            hand.isOpened = true
            hand

        when 'sankantsu'
            new Hand(
                kan('m', 1), kan('s', 3), kan('p', 5),
                chow('m', 2),
                pair('m', 8)
            )

        when 'itsu'
            suit = sample ['m', 's', 'p']
            new Hand(
                chow(suit, 1), chow(suit, 4), chow(suit, 7),
                chow(suit, 2),
                pair(suit, 5)
            )

        when 'sanshoku'
            num = random(1, 7)
            new Hand(
                chow('m', num), chow('s', num), chow('p', num),
                chow('m', 2),
                pair('m', 5)
            )

        when 'sanshoku dokou'
            num = random(1, 9)
            chowSuit = sample ['m', 's', 'p']
            new Hand(
                pung('m', num), pung('s', num), pung('p', num),
                chow(chowSuit, 2),
                pair('m', 5)
            )

        when 'iipeikou'
            suit = sample ['m', 's', 'p']
            new Hand(
                chow(suit, 2), chow(suit, 2),
                chow(suit, 6), chow(suit, 7),
                pair(suit, 5)
            )

        when 'ryanpeikou'
            suit = sample ['m', 's', 'p']
            num1 = random(1, 4)
            num2 = random(num1 + 3, 7)
            new Hand(
                chow(suit, num1), chow(suit, num1),
                chow(suit, num2), chow(suit, num2),
                pair(suit, 8)
            )

        when 'shou sangen'
            dragons = sampleSize ['dR', 'dW', 'dG'], 3
            suit = sample ['m', 's', 'p']
            new Hand(
                honorPung(dragons[0]), honorPung(dragons[1]),
                chow(suit, 2), chow(suit, 5),
                honorPair(dragons[2])
            )

        when 'dai sangen'
            suit = sample ['m', 's', 'p']
            num = random(1, 7)
            new Hand(
                honorPung('dR'), honorPung('dW'), honorPung('dG'),
                chow(suit, num),
                pair(suit, 1)
            )

        when 'shou suushii'
            winds = sampleSize ['wE', 'wS', 'wW', 'wN'], 4
            suit = sample ['m', 's', 'p']
            num = random(1, 7)
            new Hand(
                honorPung(winds[0]), honorPung(winds[1]), honorPung(winds[2]),
                chow(suit, num),
                honorPair(winds[3])
            )

        when 'dai suushii'
            winds = sampleSize ['wE', 'wS', 'wW', 'wN'], 4
            suit = sample ['m', 's', 'p']
            num = random(1, 9)
            hand = new Hand(
                honorPung(winds[0]), honorPung(winds[1]),
                honorPung(winds[2]), honorPung(winds[3]),
                pair(suit, num)
            )
            hand.isOpened = true
            hand

        when 'chanta'
            suit = sample ['m', 's', 'p']
            direction = sample ['low', 'high']
            [chow1, chow2, pairTile] = if direction == 'low'
                [chow(suit, 1), chow(suit, 7), pair(suit, 9)]
            else
                [chow(suit, 7), chow(suit, 1), pair(suit, 1)]
            honors = sampleSize ['wE', 'wS', 'wW', 'wN', 'dR', 'dW', 'dG'], 2
            hand = new Hand(
                chow1, chow2,
                honorPung(honors[0]), honorPung(honors[1]),
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
                [chow(suit, 1), chow(suit, 7), pair(suit, 9)]
            else
                [chow(suit, 7), chow(suit, 1), pair(suit, 1)]
            hand = new Hand(
                chow1, chow2,
                pung(otherSuit1, 1), pung(otherSuit2, 9),
                pairTile
            )
            hand.isOpened = true
            hand

        when 'yakuhai'
            honor = sample ['dR', 'dW', 'dG']
            suit = sample ['m', 's', 'p']
            new Hand(
                honorPung(honor),
                chow(suit, 2), chow(suit, 5), chow(suit, 6),
                pair(suit, 8)
            )

        when 'chuuren pooto'
            suit = sample ['m', 's', 'p']
            set1 = TileSet.create("#{suit}1#{suit}1#{suit}1")
            set2 = TileSet.create("#{suit}2#{suit}3#{suit}4")
            p = TileSet.create("#{suit}5#{suit}5")
            set3 = TileSet.create("#{suit}6#{suit}7#{suit}8")
            set4 = TileSet.create("#{suit}9#{suit}9#{suit}9")
            new Hand(set1, set2, p, set3, set4)

        else
            suit = sample ['m', 's', 'p']
            new Hand(
                chow(suit, 1), chow(suit, 2), chow(suit, 4), chow(suit, 5),
                pair(suit, 7)
            )

tilePool = ->
    (new Tile(t) for t in shuffle TILES)

buildWall = (hand) ->
    allTiles = tilePool()
    handTiles = hand.tiles()

    handCounts = {}
    for t in handTiles
        handCounts[t.tile] = (handCounts[t.tile] or 0) + 1

    remaining = []
    for tileObj in allTiles
        if handCounts[tileObj.tile] and handCounts[tileObj.tile] > 0
            handCounts[tileObj.tile]--
        else
            remaining.push(tileObj)

    wall = remaining.splice(0, 14)
    tile.isClosed = true for tile in wall

    indicators = 1 + (set for set in hand.sets when set.isKan).length
    indicators += 1 while random(100) > 75 and indicators < 5
    for idx in [0...indicators]
        wall[2 + idx]?.isClosed = wall[9 + idx]?.isClosed = false

    return wall

generateGameState = ->
    target = selectTarget()

    hand = constructForYaku(target)

    wall = buildWall(hand)
    seatWind = sample(SUITS.w)
    prevalentWind = sample([SUITS.w[0], SUITS.w[1]])

    result = analyze({ wall, hand, seatWind, prevalentWind })
    recordYaku(result.yaku)

    { wall, hand, seatWind, prevalentWind }

module.exports = { generateGameState, constructForYaku }
