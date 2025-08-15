connect-azAccount -UseDeviceAuthentication
$imgbuider_sp = "<YOUR-PACKER_SP>"
$subName = "<YOUR-SUBSCRIPTION>"
$sub = Get-AzSubscription -SubscriptionName $subName

$sp = New-AzADServicePrincipal -DisplayName $imgbuider_sp -role Contributor -scope /subscriptions/$($sub.Id)
$plainPassword = (New-AzADSpCredential -ObjectId $sp.Id).SecretText

$plainPassword
$sp.AppId


