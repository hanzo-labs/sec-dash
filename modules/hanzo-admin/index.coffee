import Daisho  from 'daisho/src'
import { isRequired } from 'daisho/src/views/middleware'

import adminHtml from './templates/admin.pug'
import css  from './css/app.styl'

class HanzoAdmin extends Daisho.Views.Dynamic
  tag: 'hanzo-admin'
  html: adminHtml
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

HanzoAdmin.register()

class HanzoAccountFlagging extends Daisho.Views.HanzoStaticTable
  tag: 'hanzo-account-flagging'

  display: 100

  name: 'Flagging'

  # count field name
  countField: 'flagging.count'

  # results field name
  resultsField: 'flagging.results'

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
      name: 'Name'
    },
    {
      name: 'IP'
    },
    {
      name: 'Amount'
    },
    {
      name: 'Country'
    },
    {
      name: 'State'
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
            createdOn: '10-10-2018'
            name: 'ANY'
            ip: 'ANY'
            amount: 'ANY'
            country: "Democratic People's Republic of Korea"
            state: 'ANY'
          }
          {
            createdOn: '10-10-2018'
            name: 'ANY'
            ip: 'ANY'
            amount: 'ANY'
            country: 'Islamic Republic of Iran'
            state: 'ANY'
          }
          {
            createdOn: '10-10-2018'
            name: 'ANY'
            ip: 'ANY'
            amount: '$1,000,000,000.01'
            country: 'ANY'
            state: 'ANY'
          }
        ]

HanzoAccountFlagging.register()

class HanzoDisclosureScheduling extends Daisho.Views.HanzoStaticTable
  tag: 'hanzo-disclosure-scheduling'

  display: 100

  name: 'Disclosure Scheduling'

  # count field name
  countField: 'disclosureScheduling.count'

  # results field name
  resultsField: 'disclosureScheduling.results'

  # table header configuration
  headers: [
    # {
    #   name: 'Image'
    #   field: 'Slug'
    # },
    {
      name: 'Created On'
    }
    {
      name: 'NAME'
    }
    {
      name: 'EVENT'
    }
  ]

  init: ->
    super(arguments...)

  doLoad: ->
    return true

  list: ->
    return new Promise (resolve, reject)=>
      resolve [
          {
            createdOn: '10-10-2018'
            name:  'Prospectus'
            event: 'registration-confirmed'
          }
          {
            createdOn: '10-10-2018'
            name: 'Account Statement'
            event: 'end-of-quarter'
          }
          {
            createdOn: '10-10-2018'
            name: 'Transaction Confirmation'
            event: 'transaction-confirmed'
          }
          {
            createdOn: '10-10-2018'
            name: 'Privacy Notice'
            event: 'start-of-year'
          }
          {
            createdOn: '10-10-2018'
            name: 'Proxy Notice'
            event: 'before-annual-meeting'
          }
        ]

HanzoDisclosureScheduling.register()

export default class Admin
  constructor: (daisho, ps, ms, cs)->
    ps.register 'admin',
      ->
        @el = el = document.createElement 'hanzo-admin'

        @tag = (daisho.mount el)[0]
        return el
      ->
        @tag.refresh()
        return @el
      ->
        return @el

    ms.register 'Admin', ->
      ps.show 'admin'


