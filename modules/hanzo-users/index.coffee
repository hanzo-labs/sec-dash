import Daisho  from 'daisho/src'
import Promise from 'broken'
import numeral from 'numeral'
import { isRequired } from 'daisho/src/views/middleware'

import usersHtml from './templates/users.pug'
import userHtml from './templates/user.pug'
import css from './css/app.styl'
# import TractorBeam from 'tractor-beam'
#
import ShippingAddressState from 'shop.js/src/controls/checkout/shippingaddress-state'
import ShippingAddressCountry from 'shop.js/src/controls/checkout/shippingaddress-country'

statusOpts =
  approved:  'Approved'
  denied:    'Denied'
  pending:   'Pending'
  initiated: 'Initiated'

class HanzoUsers extends Daisho.Views.HanzoDynamicTable
  tag: 'hanzo-users'
  html: usersHtml
  css:  css

  name: 'Users'

  display: 100

  configs:
    'filter': []

  initialized: false
  loading: false

  # a map of all the range facets that should use currency instead of numeric
  facetCurrency:
    price: true
    listPrice: true
    inventoryCost: true

  statusOpts: statusOpts

  # table header configuration
  headers: [
    {
      checkbox: true
    },
    {
      name: 'DATE TIME'
      field: 'CreatedAt'
    },
    {
      name: 'EMAIL'
      field: 'Email'
    },
    {
      name: 'NAME'
      field: 'FirstName'
    },
    {
      name: 'FLAGGED'
      field: 'KYCFlagged'
    },
    {
      name: 'FROZEN'
      field: 'KYCFrozen'
    },
    {
      name: 'STATUS'
      field: 'KYCStatus'
    },
    {
      name: 'JURISDICTION'
      field: 'KYCAddressStateCode'
    },
  ]

  openFilter: false

  init: ->
    super

  create: ()->
    @services.page.show 'user', ''

  search: (e)->
    qs = []

    search = @data.get 'filters.search'

    if search
      qs.push '"' + search + '"'

    firstName = @data.get 'filters.firstName'

    if firstName
      qs.push "FirstName = '" + firstName + "'"

    lastName = @data.get 'filters.lastName'

    if lastName
      qs.push "LastName = '" + lastName + "'"

    email = @data.get 'filters.email'

    if email
      qs.push "Email = '" + email + "'"

    taxId = @data.get 'filters.taxId'

    if taxId
      qs.push "KYCTaxId = '" + taxId + "'"

    status = @data.get 'filters.status'

    if status
      qs.push "KYCStatus = '" + status + "'"

    country = @data.get 'filters.country'

    if country
      qs.push "KYCCountryCode = '" + country + "'"

    state = @data.get 'filters.state'

    if state
      qs.push "KYCStateCode = '" + state + "'"

    @data.set 'facets.query', qs.join ' AND '

    p = @onsearch(e, @data.get()) if @onsearch?
    if p? && p.then?
      @loading = true
      p.then =>
        @loading = false
        @scheduleUpdate()
      if p.catch?
        p.catch =>
          @loading = false
          @scheduleUpdate()

      @scheduleUpdate()

  list: (opts) ->
    return @client.user.list opts

  getJurisdiction: (state, country)->
      if !state || !country
        return 'Unknown'
      return state + ', ' + country

  export: ->
    window.open '/export.csv', '_blank'

HanzoUsers.register()

class HanzoUser extends Daisho.Views.Dynamic
  tag: 'hanzo-user'
  html: userHtml
  css:  css
  _dataStaleField:  'id'
  showResetModal: false
  showResetPasswordModal: false
  showSaveModal: false
  showMessageModal: false
  password: 'New Password Appears Here'

  loading: false

  # message modal's message
  message: ''

  genderOpts:
    M: 'Male'
    F: 'Female'
    Other:       'Other'
    Unspecified: 'Unspecified'

  # spatial units
  dimensionsUnits:
    cm: 'cm'
    m:  'm'
    in: 'in'
    ft: 'ft'

  # mass units
  weightUnits:
    g:  'g'
    kg: 'kg'
    oz: 'oz'
    lb: 'lb'

  statusOpts: statusOpts

  configs:
    firstName:   [isRequired]
    email:       [isRequired]
    enabled:     [isRequired]

  init: ->
    super arguments...

    # @one 'updated', ()=>
    #   beam = new TractorBeam '.tractor-beam'
    #   beam.on 'dropped', (files) ->
    #     for filepath in files
    #       console.log 'Uploading...', filepath

  getGender: ->
    gender = @genderOpts[@data.get("kyc.gender")]
    return gender ? "Unspecified"

  getBillingAddress: ->
    return [
      @data.get('billingAddress.line1')
      @data.get('billingAddress.line2')
      @data.get('billingAddress.city')
      @data.get('billingAddress.state')
      @data.get('billingAddress.postalCode')
      @data.get('billingAddress.country')
    ].join ' '

  default: ()->
    # pull the org information from localstorage
    org = @daisho.akasha.get('orgs')[@daisho.akasha.get('activeOrg')]
    model =
      currency: org.currency

    return model

  isDateApproved: ->
    @data.get('kyc.dateApproved') != '0001-01-01T00:00:00Z'

  export: ->
    window.open '/export.csv', '_blank'

  # load things
  _refresh: ()->
    id = @data.get('id')
    if !id
      @data.clear()
      @data.set @default()
      @scheduleUpdate()
      return true

    @loading = true
    return @client.user.get(id: id).then (res) =>
      @cancelModals()
      @loading = false
      @data.set res
      @scheduleUpdate()
    .catch (err)=>
      @loading = false

  # load things but slightly differently
  reset: ()->
    @_refresh(true).then ()=>
      @showMessage 'Reset!'

  resetPassword: ->
    @loading = true
    @scheduleUpdate()

    @client.user.resetPassword(@data.get('id')).then (res) =>
      @cancelModals()
      @password = res.password
      @loading = false
      @scheduleUpdate()
    .catch (err)=>
      @loading = false
      @showMessage err

  getResetPassword: ->
    return @password ? ''

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

  # show the reset password
  showResetPassword: ()->
    @cancelModals()
    @showResetPasswordModal = true
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
    data = Object.assign {},  @data.get()
    delete data.balances
    delete data.referrers
    delete data.referrals

    # presence of id determines method used
    api = 'create'
    if data.id?
      api = 'update'

    @loading = true
    @client.user[api](data).then (res)=>
      @cancelModals()
      @loading = false
      @data.set res
      @showMessage 'Success!'
      @scheduleUpdate()
    .catch (err)=>
      @loading = false
      @showMessage err

  getAddress1: ->
    address = []

    line1 = @data.get 'kyc.address.line1'
    line2 = @data.get 'kyc.address.line2'

    if line1
      address.push line1

    if line2
      address.push line2

    return address.join ' '

  getAddress2: ->
    address = ''

    city = @data.get('kyc.address.city')
    state = @data.get('kyc.address.state')
    postalCode = @data.get('kyc.address.postalCode')

    if city && state
      address = city + ', ' + state
    else
      if city
        address += city
      if state
        address += state

    if postalCode
      address += postalCode

    return address

  hasImage: ->
    return !!@data.get("kyc.documents.1")

  getImage: ->
    image = @data.get("kyc.documents.1")
    if image
      return @data.get("kyc.documents.1")

    return '/img/blue-camera-svg'

HanzoUser.register()

class HanzoUserDisclosures extends Daisho.Views.HanzoStaticTable
  tag: 'hanzo-user-disclosures'

  display: 100

  name: 'Disclosures'

  # count field name
  countField: 'disclosures.count'

  # results field name
  resultsField: 'disclosures.results'

  # table header configuration
  headers: [
    # {
    #   name: 'Image'
    #   field: 'Slug'
    # },
    {
      name: 'Issued On'
    },
    {
      name: 'File'
    },
    {
      name: 'User List'
    },
  ]

  init: ->
    super(arguments...)

  doLoad: ->
    return !!@data.get('id')

  list: ->
    return new Promise (resolve, reject)=>
      resolve [
          {
            createdOn: '10-10-2018'
            file: 'Summary-2018-09-30.pdf'
            users: 'all'
          }
          {
            createdOn: '10-10-2018'
            file: 'Summary-2018-06-30.pdf'
            users: 'all'
          }
          {
            createdOn: '10-10-2018'
            file: 'Summary-2018-03-30.pdf'
            users: 'all'
          }
          {
            createdOn: '10-10-2018'
            file: 'PersonalizedSummary-2018-06-30.pdf'
            users: 'David Tai, Zach Kelling'
          }
        ]

#     return @client.user.transactions(@data.get('id')).then (res) =>
#       vs = []
#       for k, v of res.data
#         v.currency = k
#         vs.push v
#       return vs

  openImage: ->
    return =>
      window.open '/id.jpeg', '_blank'

HanzoUserDisclosures.register()

class HanzoUserDocuments extends Daisho.Views.HanzoStaticTable
  tag: 'hanzo-user-documents'

  display: 100

  name: 'Documents'

  # count field name
  countField: 'documents.count'

  # results field name
  resultsField: 'documents.results'

  # table header configuration
  headers: [
    # {
    #   name: 'Image'
    #   field: 'Slug'
    # },
    {
      name: 'Name'
    },
    {
      name: 'View Link'
    },
    {
      name: 'Download Link'
    },
  ]

  init: ->
    super(arguments...)

    @data.on 'set', (k)=>
      if k == 'kyc'
        @_refresh true

  doLoad: ->
    return !!@data.get('id')

  list: ->
    return @data.get 'kyc.documents'

  openImage: (k)->
    return =>
      img = new Image()
      img.src = @data.get('kyc.documents.' + k)
      w = window.open "", '_blank'
      w.document.write(img.outerHTML)

  getName: (k)->
    return switch k
      when 0 then 'Face'
      when 1 then 'ID Front'
      when 2 then 'ID Back'

HanzoUserDocuments.register()

class HanzoUserAddresses extends Daisho.Views.HanzoStaticTable
  tag: 'hanzo-user-addresses'

  display: 100

  name: 'Addresses'

  # count field name
  countField: 'addresses.count'

  # results field name
  resultsField: 'addresses.results'

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
      name: 'Address'
    },
    {
      name: 'Blockchain'
    },
    {
      name: 'Amount'
    },
  ]

  init: ->
    super(arguments...)

  doLoad: ->
    return !!@data.get('id')

  list: ->
    return new Promise (resolve, reject)=>
      resolve [
          {
            address:'0xF2FcCC0198fc6b39246Bd91272769D46d2F9D43b', blockchain: 'Ethereum Ropsten Testnet'
            amount: '2000'
            createdOn: '10-10-2018'
          }
          {
            address:'EOS5acgkXtdpGF4LNVMK6LryrYNmAyh9yvwppThNkHEMZa4Z6kzPn', blockchain: 'EOS Testnet'
            createdOn: '10-10-2018'
            amount: '100'
          }
        ]

#     return @client.user.transactions(@data.get('id')).then (res) =>
#       vs = []
#       for k, v of res.data
#         v.currency = k
#         vs.push v
#       return vs

HanzoUserAddresses.register()

class HanzoUserTransactions extends Daisho.Views.HanzoStaticTable
  tag: 'hanzo-user-transactions'

  display: 100

  name: 'Transactions'

  # count field name
  countField: 'trx.count'

  # results field name
  resultsField: 'trx.results'

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
    super(arguments...)

  doLoad: ->
    return !!@data.get('id')

  list: ->
    return new Promise (resolve, reject)=>
      resolve [
          {
            hash:'0xc0d914...'
            blockchain: 'Ethereum Ropsten Testnet',
            from:
              id: '12345',
              name: 'David Tai'
              address: '0xa39b0ff4c3413db472d62a12a7a474544b58bc25'
              state: 'CA'
              country: 'US'
            to:
              id: '23451',
              name: 'Zach Kelling'
              address: '0xdCEb51B0D8B4c6FBFD1917551371d3D0455BC5e1'
              state: 'CA'
              country: 'US'
            amount: 24332
            fee: 0.0001
            symbol: 'UST'
            createdOn: '10-10-2018',
          }
          {
            hash:'0xaa8809...'
            blockchain: 'Ethereum Ropsten Testnet',
            from:
              id: '54321',
              name: 'Phil Liu'
              address: '0x5c7efdf24D93BFFF255a6f3EE50B6d0Ed2856055'
              state: 'CA'
              country: 'US'
            to:
              id: '23451',
              name: 'Zach Kelling'
              address: '0x4FED1fC4144c223aE3C1553be203cDFcbD38C581'
              state: 'CA'
              country: 'US'
            amount: 1000
            fee: 0.0001
            symbol: 'UST'
            createdOn: '9-31-2018',
          }
          {
            hash:'0xe765d5...'
            blockchain: 'Ethereum Ropsten Testnet',
            from:
              id: '1A2b3',
              name: 'Tim Messer'
              address: '0x5c7efdf24D93BFFF255a6f3EE50B6d0Ed2856055'
              state: 'CA'
              country: 'US'
            to:
              id: 'ZsR3Yi',
              name: 'David Tai'
              address: '0x4FED1fC4144c223aE3C1553be203cDFcbD38C581'
              state: 'CA'
              country: 'US'
            amount: 100
            fee: 0.0001
            symbol: 'UST'
            createdOn: '9-30-2018',
          }
        ]

#     return @client.user.transactions(@data.get('id')).then (res) =>
#       vs = []
#       for k, v of res.data
#         v.currency = k
#         vs.push v
#       return vs

  showTransaction: ->
    window.open 'https://ropsten.etherscan.io/tx/0xc0d91472350dac6722f4fdb19e3081a62265b94a11681f7128ff01be3ed397e1', '_blank'

HanzoUserTransactions.register()

export default class Users
  constructor: (daisho, ps, ms, cs)->
    tag = null
    opts = {}

    ps.register 'users',
      ->
        @el = el = document.createElement 'hanzo-users'

        tag = (daisho.mount el)[0]
        return el
      ->
        tag.refresh()
        return @el
      ->

    ps.register 'user',
      (ps, id)->
        opts.id = id if id?
        @el = el = document.createElement 'hanzo-user'

        tag = (daisho.mount el)[0]
        tag.data.set 'id', opts.id
        return el
      (ps, id)->
        opts.id = id if id?
        tag.data.set 'id', opts.id
        tag.refresh()
        return @el
      ->

    ps.register 'user-transactions',
      (ps, options)->
        opts = options if options?
        @el = el = document.createElement 'hanzo-user-transactions'

        tag = (daisho.mount el)[0]
        tag.data.set 'id', opts.id
        tag.data.set 'currency', opts.currency
        return el
      (ps, options)->
        opts = options if options?
        tag.data.set 'id', opts.id
        tag.data.set 'currency', opts.currency
        tag.refresh()
        return @el
      ->

    ms.register 'Users', ->
      ps.show 'users'
