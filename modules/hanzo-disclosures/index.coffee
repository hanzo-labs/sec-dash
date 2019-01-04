import Daisho  from 'daisho/src'
import Promise from 'broken'
import numeral from 'numeral'
import { isRequired } from 'daisho/src/views/middleware'

import disclosureHtml from './templates/disclosure.pug'
import disclosuresHtml from './templates/disclosures.pug'
import css  from './css/app.styl'
# import TractorBeam from 'tractor-beam'

class HanzoDisclosures extends Daisho.Views.HanzoDynamicTable
  tag: 'hanzo-disclosures'
  html: disclosuresHtml
  css:  css

  name: 'Disclosures'

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
      name: 'SENT ON'
    }
    {
      name: 'FILE'
    }
    {
      name: 'USER'
    }
    {
      name: 'TYPE'
    }
  ]

  openFilter: false

  init: ->
    super

  create: ()->
    # @services.page.show 'disclosure', ''

  list: (opts) ->
    return new Promise (resolve, reject)=>
      resolve [
          {
            createdOn: '10-10-2018'
            file: 'Prospectus-2018.pdf'
            user: 'David Tai'
            type: 'Prospectus'
          }
          {
            createdOn: '10-10-2018'
            file: 'Summary-2018-06-30.pdf'
            user: 'Zach Kelling'
            type: 'Summary'
          }
          {
            createdOn: '10-10-2018'
            file: 'Summary-2018-03-30.pdf'
            user: 'Phil Liu'
            type: 'Summary'
          }
          {
            createdOn: '10-10-2018'
            file: 'PersonalizedSummary-2018-06-30.pdf'
            user: 'Rayne Steinberg'
            type: 'Summary'
          }
        ]

HanzoDisclosures.register()

class HanzoDisclosure extends Daisho.Views.Dynamic
  tag: 'hanzo-disclosure'
  html: disclosureHtml
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

HanzoDisclosure.register()

export default class Disclosures
  constructor: (daisho, ps, ms, cs)->
    tag = null
    opts = {}

    ps.register 'disclosures',
      ->
        @el = el = document.createElement 'hanzo-disclosures'

        tag = (daisho.mount el)[0]
        return el
      ->
        tag.refresh()
        return @el
      ->

    ps.register 'disclosure',
      (ps, id)->
        opts.id = id if id?
        @el = el = document.createElement 'hanzo-disclosure'

        tag = (daisho.mount el)[0]
        tag.data.set 'id', opts.id
        return el
      (ps, id)->
        opts.id = id if id?
        tag.data.set 'id', opts.id
        tag.refresh()
        return @el
      ->

    ms.register 'Disclosures', ->
      ps.show 'disclosures'

