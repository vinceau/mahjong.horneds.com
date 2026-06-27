analyze = require './analyze'

scores = require './analyze/scores'
{ generateGameState } = require './yaku_generator'


module.exports = ->
    game = generateGameState()
    game = analyze game
    game = scores game

    return game
