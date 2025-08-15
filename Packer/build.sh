# if [ -z "$PKR_VAR_product" ]; then
#   export PKR_VAR_product="commonforwebandapp"  # Default value, can be 'rdsserver' or 'commonforwebandapp'
#   echo "Using default product: $PKR_VAR_product"
# else
#   echo "Using provided product: $PKR_VAR_product"
# fi

# packer build -var-file="secrets.pkrvars.hcl" -var="product=$PKR_VAR_product" . 

# export PKR_VAR_product_postfix="DEMO002"

packer build -var-file="secrets.pkrvars.hcl" . | tee packer-output.log
