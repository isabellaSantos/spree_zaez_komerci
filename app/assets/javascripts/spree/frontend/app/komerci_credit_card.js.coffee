#= require_self
class window.KomerciCreditCard

  afterConstructor: ->

  beforeConstructor: ->

  constructor: (@available_cc, defaultExecution = true) ->
    do @beforeConstructor
    do @defaultExecution if defaultExecution
    do @afterConstructor

  defaultExecution: ->
    $('.komerci-cc').on 'input', @setCreditCard

  # Verifica se o cartao que esta sendo digitado esta disponivel
  # para a loja
  setCreditCard: =>
    $('#komerci_unrecognized').hide()
    if $('.komerci-cc').val().length > 10
      type = $.payment.cardType($('.komerci-cc').val())
      if type == null or !@available_cc.hasOwnProperty(type)
        $('#komerci_unrecognized').show()
      else
        $('#komerci_cc_type').html("<img src='#{@available_cc[type]}' class='cc-icon pull-right' />")
        $('#komerci_unrecognized').hide()