az vm run-command invoke `
--resource-group rg-cas-prod-uks-core `
--name P5CASWINWEB001 `
--command-id RunPowerShellScript `
--scripts @(
  "Set-Location 'C:\_bits\commonforwebandapp\devopsagent'",
  "./config.cmd --unattended --environment --environmentname prod --agent 'P5CASWINWEB001' --runasservice --work '_work' --url 'https://dev.azure.com/' --projectname 'Cascade Underlying Platform' --auth PAT --token "enter your PAT token here" "
)

#  .\config.cmd remove --auth 'PAT' --token '<token>'