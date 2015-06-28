{View} = require 'atom'

module.exports = class StatusView

    constructor: (serializedState) ->

        @element = document.createElement('div')

    serialize: ->

    destroy: ->
        @detach()

    update: (text) ->
        # Update the message
        @element.innerHTML = text

    getElement: ->
      @element
