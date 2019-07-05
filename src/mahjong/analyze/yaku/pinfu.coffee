# PINFU
# -----
# Concealed all chows hand with a valueless pair. I.e. a concealed hand with four
# chows and a pair that is neither dragons, nor seat wind, nor prevalent wind.
# The winning tile is required to finish a chow with a two-sided wait. The hand
# is by definition worth no minipoints, only the base 30 on a discard or 20 on
# self-draw.
#
module.exports =
    name: 'pinfu'
    exclude: ['yakuhai', 'toitoi', 'chitoitsu', 'sanankou', 'sanshoku dokou', 'honroutou', 'sankantsu', 'shou sangen']
    test: ({ hand, seatWind, prevalentWind }) ->
        return if hand.isOpened
        for set in hand.sets
            return if set.isPon

        waitSet = hand.wait.set
        return if waitSet.isPon

        if waitSet.isPair
            connected = false
            for set in hand.sets
                continue unless set.isRow
                connected = connected or hand.wait.tile in [ set.tiles[0].tile, set.tiles[2].tile]

        else
            return unless hand.wait.id in [waitSet.tiles[0].id, waitSet.tiles[2].id]

        return if hand.pair.suit == 'd'
        return if hand.pair.value in [seatWind, prevalentWind]

        return 1
