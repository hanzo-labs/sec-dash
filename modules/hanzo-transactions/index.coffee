import Daisho  from 'daisho/src'
import Promise from 'broken'
import numeral from 'numeral'
import { isRequired } from 'daisho/src/views/middleware'

import transactionHtml from './templates/transaction.pug'
import transactionsHtml from './templates/transactions.pug'
import css  from './css/app.styl'
# import TractorBeam from 'tractor-beam'

class Hanzotransactions extends Daisho.Views.HanzoDynamicTable
  tag: 'hanzo-transactions'
  html: transactionsHtml
  css:  css

  name: 'Transactions'

  configs:
    'filter': []

  initialized: false
  loading: false

  # table header configuration
  headers: [
    # {
    #   name: 'Image'
    #   field: 'Slug'
    # },
    {
      name: 'Created On'
    },
    {
      name: 'Hash'
    },
    {
      name: 'Protocol'
    },
    {
      name: 'From'
    },
    {
      name: 'To'
    }
    {
      name: 'Amount'
    }
    {
      name: 'Fees'
    }
  ]

  openFilter: false

  init: ->
    super

  create: ->
    # @services.page.show 'transaction', ''

  trimToElipsis: (str)->
    return str.substr(0,16) + '...'

  list: (opts) ->
    return @client.tokentransaction.list opts

  export: ->
    window.open '/export.csv', '_blank'

Hanzotransactions.register()

class Hanzotransaction extends Daisho.Views.Dynamic
  tag: 'hanzo-transaction'
  html: transactionHtml
  css:  css

  _dataStaleField:  'id'
  showResetModal: false
  showSaveModal: false
  showMessageModal: false

  loading: false

  # message modal's message
  message: ''

  configs:
    file:   [isRequired]

  init: ->
    super

    # @one 'updated', ()=>
    #   beam = new TractorBeam '.tractor-beam'
    #   beam.on 'dropped', (files) ->
    #     for filepath in files
    #       console.log 'Uploading...', filepath

  default: ()->
    # pull the org information from localstorage
    org = @daisho.akasha.get('orgs')[@daisho.akasha.get('activeOrg')]
    model =
      currency: org.currency

    return model

  # load things
  _refresh: ()->
    id = @data.get('id')
    if !id
      @data.clear()
      @data.set @default()
      @scheduleUpdate()
      return true

    # @loading = true
    # return @client.user.get(id: id).then (res) =>
    #   @cancelModals()
    #   @loading = false
    #   @data.set res
    #   @scheduleUpdate()
    # .catch (err)=>
    #   @loading = false

  # load things but slightly differently
  reset: ()->
    @_refresh(true).then ()=>
      @showMessage 'Reset!'

  # save by using submit to validate inputs
  save: ()->
    test = @submit()
    test.then (val)=>
      if !val?
        if $('.input .error')[0]?
          @cancelModals()
          @showMessage 'Some things were missing or incorrect.  Try again.'
          @scheduleUpdate()
    .catch (err)=>
      @showMessage err

  # show the message modal
  showMessage: (msg)->
    if !msg?
      msg = 'There was an error.'
    else
      msg = msg.message ? msg

    @cancelModals()
    @message = msg
    @showMessageModal = true
    @scheduleUpdate()

    @messageTimeoutId = setTimeout ()=>
      @cancelModals()
      @scheduleUpdate()
    , 5000

  # show the reset modal
  showReset: ()->
    @cancelModals()
    @showResetModal = true
    @scheduleUpdate()

  # show the save modal
  showSave: ()->
    @cancelModals()
    @showSaveModal = true
    @scheduleUpdate()

  # close all modals
  cancelModals: ()->
    clearTimeout @messageTimeoutId
    @showResetModal = false
    @showResetPasswordModal = false
    @showSaveModal = false
    @showMessageModal = false
    @scheduleUpdate()

  # submit the form
  _submit: ()->
    # data = Object.assign {},  @data.get()
    # delete data.balances
    # delete data.referrers
    # delete data.referrals

    # # presence of id determines method used
    # api = 'create'
    # if data.id?
    #   api = 'update'

    # @loading = true
    # @client.user[api](data).then (res)=>
    #   @cancelModals()
    #   @loading = false
    #   @data.set res
    #   @showMessage 'Success!'
    #   @scheduleUpdate()
    # .catch (err)=>
    #   @loading = false
    #   @showMessage err

Hanzotransaction.register()

export default class transactions
  constructor: (daisho, ps, ms, cs)->
    tag = null
    opts = {}

    ps.register 'transactions',
      ->
        @el = el = document.createElement 'hanzo-transactions'

        tag = (daisho.mount el)[0]
        return el
      ->
        tag.refresh()
        return @el
      ->

    ps.register 'transaction',
      (ps, id)->
        opts.id = id if id?
        @el = el = document.createElement 'hanzo-transaction'

        tag = (daisho.mount el)[0]
        tag.data.set 'id', opts.id
        return el
      (ps, id)->
        opts.id = id if id?
        tag.data.set 'id', opts.id
        tag.refresh()
        return @el
      ->

    ms.register 'Transactions', ->
      ps.show 'transactions'

