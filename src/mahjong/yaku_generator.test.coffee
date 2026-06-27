{ generateGameState, constructForYaku } = require './yaku_generator'
analyze = require './analyze'

ALL_YAKU = [
    'chinitsu', 'ryanpeikou'
    'sanshoku dokou', 'sanankou', 'sankantsu', 'toitoi'
    'honitsu', 'shou sangen', 'honroutou', 'junchan'
    'pinfu', 'iipeikou', 'tanyao', 'sanshoku', 'itsu'
    'yakuhai', 'chanta'
    'chuuren pooto', 'suu ankou', 'suu kan tsu'
    'ryuu iisou', 'chinrouto', 'tsuu iisou'
    'dai sangen', 'shou suushii', 'dai suushii'
]

KAN_TILE_COUNTS =
    sankantsu: 17   # 3 kongs + 1 meld + pair = 3*4+3+2 = 17
    'suu kan tsu': 18  # 4 kongs + pair = 4*4+2 = 18

test 'generates valid game state shape', ->
    game = generateGameState()
    expect(game.wall).toBeTruthy()
    expect(game.wall.length).toBe 14
    expect(game.hand).toBeTruthy()
    expect(game.seatWind).toBeTruthy()
    expect(game.prevalentWind).toBeTruthy()
    expect(game.hand.sets.length).toBe 4
    expect(game.hand.pair).toBeTruthy()
    kanCount = (set for set in game.hand.sets when set.isKan).length
    expect(game.hand.tiles().length).toBe 14 + kanCount

test 'constructForYaku produces valid hand for every yaku', ->
    for yakuName in ALL_YAKU
        hand = constructForYaku(yakuName)
        unless hand
            console.log "FAIL: constructForYaku('#{yakuName}') returned null"
        expect(hand).toBeTruthy()
        if KAN_TILE_COUNTS[yakuName]
            expect(hand.tiles().length).toBe KAN_TILE_COUNTS[yakuName]
        else
            expect(hand.tiles().length).toBe 14
        expect(hand.sets.length).toBe 4
        expect(hand.pair).toBeTruthy()
    return

test 'each constructed hand is detected as its target yaku', ->
    for yakuName in ALL_YAKU
        hand = constructForYaku(yakuName)
        wall = []
        result = analyze { wall, hand, seatWind: 'wE', prevalentWind: 'wS' }
        detected = (y.name for y in result.yaku)
        unless yakuName in detected
            console.log "FAIL: #{yakuName} not detected, saw: #{detected.join(', ')}"
            console.log "  options: #{JSON.stringify(Object.keys(hand.options))}"
            console.log "  wait: #{hand.wait?.tile}"
            console.log "  isOpened: #{hand.isOpened}"
            console.log "  tsumo: #{hand.tsumo}"
        expect(detected).toContain(yakuName)
    return

test 'generateGameState produces hands with yaku', ->
    for i in [0...50]
        game = generateGameState()
        result = analyze(game)
        expect(result.yaku.length).toBeGreaterThan 0
    return
