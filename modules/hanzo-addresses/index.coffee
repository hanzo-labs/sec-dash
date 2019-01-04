import Daisho  from 'daisho/src'
import Promise from 'broken'
import numeral from 'numeral'
import { isRequired } from 'daisho/src/views/middleware'

import addressHtml from './templates/address.pug'
import addressesHtml from './templates/addresses.pug'
import css  from './css/app.styl'
# import TractorBeam from 'tractor-beam'

class Hanzoaddresses extends Daisho.Views.HanzoDynamicTable
  tag: 'hanzo-addresses'
  html: addressesHtml
  css:  css

  name: 'Addresses'

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
      name: 'File'
      field: 'File'
    },
    {
      name: 'Email List'
      field: 'Email List'
    },
    {
      name: 'Issued On'
      field: 'CreatedAt'
    },
    {
      name: 'Last Updated'
      field: 'UpdatedAt'
    }
  ]

  openFilter: false

  init: ->
    super

  create: ()->
    # @services.page.show 'address', ''

  list: (opts) ->

Hanzoaddresses.register()

class Hanzoaddress extends Daisho.Views.Dynamic
  tag: 'hanzo-address'
  html: addressHtml
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

Hanzoaddress.register()

export default class addresses
  constructor: (daisho, ps, ms, cs)->
    tag = null
    opts = {}

    ps.register 'addresses',
      ->
        @el = el = document.createElement 'hanzo-addresses'

        tag = (daisho.mount el)[0]
        return el
      ->
        tag.refresh()
        return @el
      ->

    ps.register 'address',
      (ps, id)->
        opts.id = id if id?
        @el = el = document.createElement 'hanzo-address'

        tag = (daisho.mount el)[0]
        tag.data.set 'id', opts.id
        return el
      (ps, id)->
        opts.id = id if id?
        tag.data.set 'id', opts.id
        tag.refresh()
        return @el
      ->

    ms.register 'Addresses', ->
      ps.show 'addresses'

