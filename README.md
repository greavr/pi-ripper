# pi-ripper

## Install TF
Source
`https://learn.hashicorp.com/tutorials/terraform/install-cli`

```
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform
terraform -install-autocomplete
```

## Run TF
```
cd tf/
terraform plan
terraform apply -auto-approve
```

Then to destroy
```
terraform destroy -auto-approve`
```

CF Permissions:
```
roles/secretmanager.secretAccessor
```

```
export GCP_PROJECT='rgreaves-sandbox'
```