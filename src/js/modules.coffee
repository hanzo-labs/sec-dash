import Users        from '../../modules/hanzo-users'
import Disclosures  from '../../modules/hanzo-disclosures'
import Addresses    from '../../modules/hanzo-addresses'
import Transactions from '../../modules/hanzo-transactions'
import Admin        from '../../modules/hanzo-admin'
import Fund         from '../../modules/hanzo-fund'
import Search       from '../../modules/hanzo-search'

export default modules =
  Users:        Users
  # Addresses:    Addresses
  Transactions: Transactions
  Disclosures:  Disclosures
  Admin:  Admin
  Fund: Fund
  Search: Search

