import Daisho  from 'daisho/src'
import Promise from 'broken'
import numeral from 'numeral'
import { isRequired } from 'daisho/src/views/middleware'

import searchHtml from './templates/search.pug'
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

class HanzoSearch extends Daisho.Views.HanzoDynamicTable
  tag: 'hanzo-search'
  html: searchHtml
  css:  css

  name: 'Search'

  display: 1000

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

HanzoSearch.register()

export default class Search
  constructor: (daisho, ps, ms, cs)->
    tag = null
    opts = {}

    ps.register 'search',
      ->
        @el = el = document.createElement 'hanzo-search'

        tag = (daisho.mount el)[0]
        return el
      ->
        tag.refresh()
        return @el
      ->

    ms.register 'Search', ->
      ps.show 'search'
