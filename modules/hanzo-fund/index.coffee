import Daisho  from 'daisho/src'
import { isRequired } from 'daisho/src/views/middleware'

import fundHtml from './templates/fund.pug'
import css  from './css/app.styl'

class HanzoFund extends Daisho.Views.Dynamic
  tag: 'hanzo-fund'
  html: fundHtml
  css:  css
  _dataStaleField:  'id'

  showResetModal: false
  showSaveModal: false
  showMessageModal: false

  loading: false

  # message modal's message
  message: ''

  configs:
    'fullName': [isRequired]

  _refresh: ->
    org = @daisho.akasha.get('orgs')[@daisho.akasha.get('activeOrg')]

    # @loading = true
    # return @client.organization.get(org.id).then (res) =>
    #   @cancelModals()
    #   @loading = false
    #   @data.set res
    #   @scheduleUpdate()
    # .catch (err)=>
    #   @loading = false

  reset: ->
    @_refresh().then =>
      @showMessage 'Reset!'

  save: ->
    test = @submit()
    test.then (val) =>
      if !val?
        if $('.input .error')[0]?
          @cancelModals()
          @showMessage 'Some things were missing or incorrect.  Try again.'
          @scheduleUpdate()
    .catch (err)=>
      @showMessage err

  _submit: ->
    data = @data.get()

    @loading = true
    # @client.organization.update(data).then (res) =>
    #   @cancelModals()
    #   @loading = false
    #   @data.set res
    #   @showMessage 'Success!'
    #   @scheduleUpdate()
    # .catch (err) =>
    #   @loading = false
    #   @showMessage err

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

    @messageTimeoutId = setTimeout =>
      @cancelModals()
      @scheduleUpdate()
    , 5000

  # show the save modal
  showSave: ->
    @cancelModals()
    @showSaveModal = true
    @scheduleUpdate()

  # show the reset modal
  showReset: ->
    @cancelModals()
    @showResetModal = true
    @scheduleUpdate()

  # close all modals
  cancelModals: ->
    clearTimeout @messageTimeoutId
    @showSaveModal = false
    @showMessageModal = false
    @scheduleUpdate()

HanzoFund.register()

class HanzoDailies extends Daisho.Views.HanzoStaticTable
  tag: 'hanzo-dailies'

  display: 100

  name: 'Daily Fund Statistics'

  # count field name
  countField: 'dailies.count'

  # results field name
  resultsField: 'dailies.results'

  # table header configuration
  headers: [
    # {
    #   name: 'Image'
    #   field: 'Slug'
    # },
    {
      name: 'Date'
    },
    {
      name: 'Total Supply'
    },
    {
      name: 'Total Value'
    },
    {
      name: 'NAV'
    },
  ]

  init: ->
    super(arguments...)

  doLoad: ->
    return true

  list: ->
    return new Promise (resolve, reject)=>
      resolve [
          {
            date: '10-11-2018 16:58Z'
            supply: 1e11 + 54309
            nav: 100
          }
          {
            date: '10-10-2018 17:02Z'
            supply: 1e11 + 59359
            nav: 102
          }
          {
            date: '10-9-2018 17:01Z'
            supply: 1e11 + 32412
            nav: 100
          }
          {
            date: '10-8-2018 16:59Z'
            supply: 1e11 + 3432
            nav: 100
          }
          {
            date: '10-7-2018 17:01Z'
            supply: 1e11 + 21
            nav: 100
          }

          {
            date: '10-6-2018 17:00'
            supply: 1e11 - 843
            nav: 99
          }
        ]

HanzoDailies.register()

export default class Fund
  constructor: (daisho, ps, ms, cs)->
    ps.register 'fund',
      ->
        @el = el = document.createElement 'hanzo-fund'

        @tag = (daisho.mount el)[0]
        return el
      ->
        @tag.refresh()
        return @el
      ->
        return @el

    ms.register 'Fund', ->
      ps.show 'fund'


