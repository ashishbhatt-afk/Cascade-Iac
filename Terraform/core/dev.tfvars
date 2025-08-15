environment               = "dev"
vnet_address_space        = ["10.10.0.0/20"]          # 4096 IPs total
snet_iis_address_prefix   = ["10.10.0.0/23"]         # IIS
snet_sql_address_prefix   = ["10.10.2.0/23"]         # SQL
snet_app_address_prefix   = ["10.10.4.0/23"]         # App
snet_sqlmi_address_prefix = ["10.10.6.0/23"]         # SQL-MI
snet_rbq_address_prefix   = ["10.10.8.0/23"]         # RBQ
snet_mgmt_address_prefix  = ["10.10.10.0/23"]        # Mgmt

# spare /23s for future use
# 10.10.12.0/23
# 10.10.14.0/23
# /23 → 512−5=507 usable addresses


