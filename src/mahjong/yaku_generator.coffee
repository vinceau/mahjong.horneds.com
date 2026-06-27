sample = require 'lodash/sample'
sampleSize = require 'lodash/sampleSize'
shuffle = require 'lodash/shuffle'
random = require 'lodash/random'
without = require 'lodash/without'
flatten = require 'lodash/flatten'
orderBy = require 'lodash/orderBy'

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

tilePool = ->
    (new Tile(t) for t in shuffle TILES)

findSpecificMeld = (pool, meldStr) ->
    tileNames = meldStr.match /.{1,2}/g
    result = []
    poolCopy = [...pool]
    for name in tileNames
        idx = poolCopy.findIndex (t) -> t.tile == name
        return null if idx == -1
        result.push poolCopy[idx]
        poolCopy.splice(idx, 1)
    return result

findSetSimple = (tiles, pair = false, meldType = 'any') ->
    for t1, idx1 in tiles
        for t2, idx2 in tiles[(idx1 + 1)...]
            if pair
                continue unless t1.value == t2.value
                set = new TileSet(t1, t2)
                continue unless set.isValid()
                return { set, indices: [idx1, idx1 + 1 + idx2] }

            continue unless t1.isConnected t2

            if meldType == 'allPung' or meldType == 'allKan'
                continue unless t1.value == t2.value
            else if meldType == 'allChow'
                continue unless t1.suit == t2.suit and Math.abs(t1.value - t2.value) == 1

            for t3, idx3 in tiles[(idx1 + idx2 + 2)...]
                start3 = idx1 + idx2 + 2 + idx3
                if meldType == 'allChow'
                    set = new TileSet(t1, t2, t3)
                    if set.isValid()
                        return { set, indices: [idx1, idx1 + 1 + idx2, start3] }
                else if meldType == 'allPung'
                    continue unless t1.value == t3.value
                    set = new TileSet(t1, t2, t3)
                    if set.isValid()
                        return { set, indices: [idx1, idx1 + 1 + idx2, start3] }
                else
                    set = new TileSet(t1, t2, t3)
                    if set.isValid()
                        if meldType == 'allKan' and set.isPon
                            for t4, idx4 in tiles[(start3 + 1)...]
                                continue unless t4.tile == t1.tile
                                set.tiles.push(t4)
                                set.isValid()
                                return { set, indices: [idx1, idx1 + 1 + idx2, start3, start3 + 1 + idx4] }
                        return { set, indices: [idx1, idx1 + 1 + idx2, start3] }
    return null

findSetForKan = (tiles) ->
    for t1, idx1 in tiles
        same = (t for t in tiles when t.tile == t1.tile)
        if same.length >= 4
            set = new TileSet(same[0], same[1], same[2], same[3])
            set.isValid()
            indices = [
                tiles.indexOf(same[0])
                tiles.indexOf(same[1])
                tiles.indexOf(same[2])
                tiles.indexOf(same[3])
            ]
            return { set, indices }
    return null

removeIndices = (arr, indices) ->
    sorted = [...indices].sort (a, b) -> b - a
    for idx in sorted
        arr.splice(idx, 1)
    return arr

buildHandSimple = (filterFn, options = {}) ->
    { meldType, forceKanCount } = options
    meldType ?= 'any'
    forceKanCount ?= 0

    attempts = 0
    while attempts < 50
        attempts++
        pool = tilePool()
        pool = pool.filter(filterFn) if filterFn

        hand = new Hand()
        kanCount = 0
        success = true

        while hand.sets.length < 4
            result = null
            if forceKanCount > 0 and kanCount < forceKanCount
                result = findSetForKan(pool)
                if result
                    kanCount++

            unless result
                if forceKanCount > 0 and kanCount < forceKanCount
                    result = findSetForKan(pool)
                    if result
                        kanCount++
                    else
                        result = findSetSimple(pool, false, 'allPung')
                else
                    result = findSetSimple(pool, false, meldType)

            unless result
                success = false
                break

            removeIndices(pool, result.indices)
            hand.push(result.set)

        continue unless success

        pairResult = findSetSimple(pool, true)
        unless pairResult
            continue

        hand.push(pairResult.set)
        return hand

    return null

buildHandWithMelds = (forcedMeldStrings, options = {}) ->
    { filterFn, forcedPair } = options

    attempts = 0
    while attempts < 50
        attempts++
        pool = tilePool()
        pool = pool.filter(filterFn) if filterFn

        hand = new Hand()
        success = true

        for meldStr in forcedMeldStrings
            tiles = findSpecificMeld(pool, meldStr)
            unless tiles
                success = false
                break
            set = new TileSet(tiles...)
            set.isValid()
            for t in tiles
                idx = pool.indexOf(t)
                pool.splice(idx, 1)
            hand.push(set)

        continue unless success

        reservedPair = null
        if forcedPair
            reservedPair = findSpecificMeld(pool, forcedPair)
            unless reservedPair and reservedPair.length == 2
                continue
            for t in reservedPair
                idx = pool.indexOf(t)
                pool.splice(idx, 1)

        while hand.sets.length < 4
            result = findSetSimple(pool, false, 'any')
            unless result
                success = false
                break
            removeIndices(pool, result.indices)
            hand.push(result.set)

        continue unless success

        if forcedPair
            pair = new TileSet(reservedPair...)
            pair.isValid()
            hand.push(pair)
        else
            pairResult = findSetSimple(pool, true)
            unless pairResult
                continue
            hand.push(pairResult.set)

        return hand

    return null

constructForYaku = (target) ->
    switch target
        when 'tanyao'
            buildHandSimple ((t) -> not t.isHonor and not t.isTerminal), {}

        when 'honitsu'
            suit = sample ['m', 's', 'p']
            hand = buildHandSimple ((t) -> t.suit == suit or t.isHonor), {}
            if hand
                hand.isOpened = true
            return hand

        when 'chinitsu'
            suit = sample ['m', 's', 'p']
            buildHandSimple ((t) -> t.suit == suit), {}

        when 'honroutou'
            hand = buildHandSimple ((t) -> t.isHonor or t.isTerminal), {}
            if hand
                hand.isOpened = true
            return hand

        when 'tsuu iisou'
            hand = buildHandSimple ((t) -> t.isHonor), {}
            if hand
                hand.isOpened = true
            return hand

        when 'chinrouto'
            hand = buildHandSimple ((t) -> t.isTerminal), {}
            if hand
                hand.isOpened = true
            return hand

        when 'ryuu iisou'
            allowed = ['s2', 's3', 's4', 's6', 's8', 'dG']
            buildHandSimple ((t) -> t.tile in allowed), {}

        when 'toitoi'
            hand = buildHandSimple null, { meldType: 'allPung' }
            if hand
                hand.isOpened = true
            return hand

        when 'pinfu'
            suit = sample ['m', 's', 'p']
            melds = [
                "#{suit}1#{suit}2#{suit}3"
                "#{suit}2#{suit}3#{suit}4"
                "#{suit}6#{suit}7#{suit}8"
                "#{suit}7#{suit}8#{suit}9"
            ]
            hand = buildHandWithMelds melds, { filterFn: (t) -> not t.isHonor }
            if hand
                hand.isOpened = false
                hand.wait = hand.sets[0].tiles[1]
            return hand

        when 'sanankou'
            num1 = random(1, 9)
            num2 = random(1, 9)
            num3 = random(1, 9)
            chowNum = random(1, 7)
            chowSuit = sample ['m', 's', 'p']
            melds = [
                "m#{num1}m#{num1}m#{num1}"
                "s#{num2}s#{num2}s#{num2}"
                "p#{num3}p#{num3}p#{num3}"
                "#{chowSuit}#{chowNum}#{chowSuit}#{chowNum + 1}#{chowSuit}#{chowNum + 2}"
            ]
            hand = buildHandWithMelds melds
            if hand
                hand.wait = hand.sets[3].tiles[1]
            return hand

        when 'suu ankou'
            hand = buildHandSimple null, { meldType: 'allPung' }
            if hand
                hand.wait = hand.pair.tiles[0]
                hand.isOpened = false
            return hand

        when 'suu kan tsu'
            hand = buildHandSimple null, { forceKanCount: 4 }
            if hand
                hand.isOpened = true
            return hand

        when 'sankantsu'
            buildHandSimple null, { forceKanCount: 3, meldType: 'allChow' }

        when 'itsu'
            suit = sample ['m', 's', 'p']
            melds = [
                "#{suit}1#{suit}2#{suit}3"
                "#{suit}4#{suit}5#{suit}6"
                "#{suit}7#{suit}8#{suit}9"
            ]
            buildHandWithMelds melds

        when 'sanshoku'
            num = random(1, 7)
            melds = [
                "m#{num}m#{num + 1}m#{num + 2}"
                "s#{num}s#{num + 1}s#{num + 2}"
                "p#{num}p#{num + 1}p#{num + 2}"
            ]
            buildHandWithMelds melds

        when 'sanshoku dokou'
            num = random(1, 9)
            otherNum = random(1, 7)
            otherSuits = without ['m', 's', 'p'], sample ['m', 's', 'p']
            chowSuit = sample otherSuits
            melds = [
                "m#{num}m#{num}m#{num}"
                "s#{num}s#{num}s#{num}"
                "p#{num}p#{num}p#{num}"
                "#{chowSuit}#{otherNum}#{chowSuit}#{otherNum + 1}#{chowSuit}#{otherNum + 2}"
            ]
            buildHandWithMelds melds

        when 'iipeikou'
            suit = sample ['m', 's', 'p']
            num = random(1, 7)
            chow = "#{suit}#{num}#{suit}#{num + 1}#{suit}#{num + 2}"
            buildHandWithMelds [chow, chow]

        when 'ryanpeikou'
            suit = sample ['m', 's', 'p']
            num1 = random(1, 4)
            num2 = random(num1 + 3, 7)
            chow1 = "#{suit}#{num1}#{suit}#{num1 + 1}#{suit}#{num1 + 2}"
            chow2 = "#{suit}#{num2}#{suit}#{num2 + 1}#{suit}#{num2 + 2}"
            buildHandWithMelds [chow1, chow1, chow2, chow2]

        when 'shou sangen'
            dragons = sampleSize ['dR', 'dW', 'dG'], 3
            melds = [
                "#{dragons[0]}#{dragons[0]}#{dragons[0]}"
                "#{dragons[1]}#{dragons[1]}#{dragons[1]}"
            ]
            buildHandWithMelds melds, { forcedPair: "#{dragons[2]}#{dragons[2]}" }

        when 'dai sangen'
            suit = sample ['m', 's', 'p']
            num = random(1, 7)
            melds = ['dRdRdR', 'dWdWdW', 'dGdGdG', "#{suit}#{num}#{suit}#{num + 1}#{suit}#{num + 2}"]
            buildHandWithMelds melds

        when 'shou suushii'
            winds = sampleSize ['wE', 'wS', 'wW', 'wN'], 4
            suit = sample ['m', 's', 'p']
            num = random(1, 7)
            melds = [
                "#{winds[0]}#{winds[0]}#{winds[0]}"
                "#{winds[1]}#{winds[1]}#{winds[1]}"
                "#{winds[2]}#{winds[2]}#{winds[2]}"
                "#{suit}#{num}#{suit}#{num + 1}#{suit}#{num + 2}"
            ]
            buildHandWithMelds melds, { forcedPair: "#{winds[3]}#{winds[3]}" }

        when 'dai suushii'
            melds = ['wEwEwE', 'wSwSwS', 'wWwWwW', 'wNwNwN']
            suit = sample ['m', 's', 'p']
            num = random(1, 9)
            hand = buildHandWithMelds melds, { forcedPair: "#{suit}#{num}#{suit}#{num}" }
            if hand
                hand.isOpened = true
            return hand

        when 'chanta'
            suit = sample ['m', 's', 'p']
            direction = sample ['low', 'high']
            if direction == 'low'
                chow1 = "#{suit}1#{suit}2#{suit}3"
                chow2 = "#{suit}7#{suit}8#{suit}9"
                pairTile = "#{suit}9"
            else
                chow1 = "#{suit}7#{suit}8#{suit}9"
                chow2 = "#{suit}1#{suit}2#{suit}3"
                pairTile = "#{suit}1"
            otherSuits = without ['m', 's', 'p'], suit
            otherSuit = sample otherSuits
            honors = sampleSize ['wE', 'wS', 'wW', 'wN', 'dR', 'dW', 'dG'], 2
            melds = [
                chow1
                chow2
                "#{honors[0]}#{honors[0]}#{honors[0]}"
                "#{honors[1]}#{honors[1]}#{honors[1]}"
            ]
            buildHandWithMelds melds, { forcedPair: "#{pairTile}#{pairTile}" }

        when 'junchan'
            suit = sample ['m', 's', 'p']
            direction = sample ['low', 'high']
            otherSuits = without ['m', 's', 'p'], suit
            otherSuit1 = sample otherSuits
            otherSuit2 = without(otherSuits, otherSuit1)[0]

            if direction == 'low'
                chow1 = "#{suit}1#{suit}2#{suit}3"
                chow2 = "#{suit}7#{suit}8#{suit}9"
                pairTile = "#{suit}9"
            else
                chow1 = "#{suit}7#{suit}8#{suit}9"
                chow2 = "#{suit}1#{suit}2#{suit}3"
                pairTile = "#{suit}1"

            melds = [
                chow1
                chow2
                "#{otherSuit1}1#{otherSuit1}1#{otherSuit1}1"
                "#{otherSuit2}9#{otherSuit2}9#{otherSuit2}9"
            ]
            buildHandWithMelds melds, { forcedPair: "#{pairTile}#{pairTile}" }

        when 'yakuhai'
            honor = sample ['dR', 'dW', 'dG']
            melds = ["#{honor}#{honor}#{honor}"]
            buildHandWithMelds melds

        when 'chuuren pooto'
            suit = sample ['m', 's', 'p']
            set1 = TileSet.create("#{suit}1#{suit}1#{suit}1")
            set2 = TileSet.create("#{suit}2#{suit}3#{suit}4")
            pair = TileSet.create("#{suit}5#{suit}5")
            set3 = TileSet.create("#{suit}6#{suit}7#{suit}8")
            set4 = TileSet.create("#{suit}9#{suit}9#{suit}9")
            new Hand(set1, set2, pair, set3, set4)

        else
            buildHandSimple null, {}

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

    hand = null
    attempts = 0
    while not hand and attempts < 30
        hand = constructForYaku(target)
        attempts++
        unless hand
            target = selectTarget()

    unless hand
        pool = tilePool()
        wall = pool.splice(0, 14)
        tile.isClosed = true for tile in wall
        hand = new Hand()
        while hand.sets.length < 4
            result = findSetSimple(pool, false, 'any')
            return generateGameState() unless result
            removeIndices(pool, result.indices)
            hand.push result.set
        pairResult = findSetSimple(pool, true)
        return generateGameState() unless pairResult
        hand.push pairResult.set
        return { wall, hand, seatWind: sample(SUITS.w), prevalentWind: sample([SUITS.w[0], SUITS.w[1]]) }

    wall = buildWall(hand)
    seatWind = sample(SUITS.w)
    prevalentWind = sample([SUITS.w[0], SUITS.w[1]])

    game = { wall, hand, seatWind, prevalentWind }
    result = analyze(game)
    recordYaku(result.yaku)

    return { wall, hand: game.hand, seatWind, prevalentWind }

module.exports = { generateGameState, constructForYaku }
