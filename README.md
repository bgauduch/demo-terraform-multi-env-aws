# Terraform Multi-Environment Demo (AWS)

Demonstration progressive de la gestion multi-environnement avec Terraform CE (Community Edition) sur AWS.

Contenu de support pour la "matinale tech" live Twitch.

> **Note** : ces demos et approches concernent Terraform CE. En mode CE, il faut construire et maintenir toute la "glue" CI/CD soi-meme (backend S3, locking DynamoDB, pipelines, gestion des credentials, policy as code, etc.). Pour un fonctionnement out-of-the-box, se diriger vers [HCP Terraform](https://www.hashicorp.com/products/terraform/pricing/) - le cout des licences couvre en grande partie les couts de build et run d'une stack CI/CD custom autour de TF CE.

## Ressources deployees

Topologie reseau simple (gratuite, rapide a creer/detruire) :

- **VPC** avec CIDR variable par environnement
- **2 subnets** : public + private (calcules via `cidrsubnet()`)
- **Tags** : Project, Environment, ManagedBy

## Structure

Chaque level est autonome et executable independamment.

```
level-0-single-env/        # Un root module, un seul environnement
level-1-workspaces/         # Un root module, des workspaces Terraform
level-2-root-per-env/       # Un root module par env + modules partages
level-3-specialization/     # Un root module + specialisation via -backend-config et -var-file
```

## Level 0 - Single Environment

Approche "monolithique" : un root module, un state, un environnement.

```bash
cd level-0-single-env
terraform init
terraform plan
terraform apply
terraform destroy
```

- (+) simple, rapide a mettre en place
- (-) impossible de gerer plusieurs environnements sans dupliquer le code

## Level 1 - Workspaces

Un root module avec `terraform.workspace` pour differencier les environnements. Le state est automatiquement separe par workspace.

```bash
cd level-1-workspaces
terraform init

terraform workspace new dev
terraform plan
terraform apply

terraform workspace new prod
terraform plan
terraform apply

# Nettoyage
terraform workspace select dev && terraform destroy
terraform workspace select prod && terraform destroy
```

- (+) state separe par workspace automatiquement, zero duplication de code
- (-) config env codee en dur dans les locals, risque d'apply sur le mauvais workspace, pas d'isolation reelle
- Approche deconseillee par la [doc officielle](https://developer.hashicorp.com/terraform/cli/workspaces#when-not-to-use-multiple-workspaces) pour la gestion multi-env

## Level 2 - Root Module par Environnement

Structure recommandee par la [doc officielle Terraform](https://developer.hashicorp.com/terraform/language/style) pour les utilisateurs hors HCP Terraform/TFE.

Un repertoire par env, chacun avec son propre state. Les modules sont partages.

```bash
# Dev
cd level-2-root-per-env/dev
terraform init
terraform plan
terraform apply

# Prod
cd ../prod
terraform init
terraform plan
terraform apply

# Nettoyage
cd ../dev && terraform destroy
cd ../prod && terraform destroy
```

- (+) isolation complete des states, pas de risque d'erreur d'env, modules reutilisables
- (-) duplication du code racine (providers, outputs) entre les envs

## Level 3 - Root Module + Specialisation

Un seul root module. L'environnement cible est selectionne a l'execution via :

- `terraform init -backend-config=env/<env>.backend.hcl` pour le state
- `terraform plan/apply -var-file=env/<env>.tfvars` pour la configuration

```bash
cd level-3-specialization

# Dev
terraform init -backend-config=env/dev.backend.hcl
terraform plan -var-file=env/dev.tfvars
terraform apply -var-file=env/dev.tfvars

# Prod (re-init necessaire pour changer de backend)
terraform init -reconfigure -backend-config=env/prod.backend.hcl
terraform plan -var-file=env/prod.tfvars
terraform apply -var-file=env/prod.tfvars

# Nettoyage
terraform init -reconfigure -backend-config=env/dev.backend.hcl
terraform destroy -var-file=env/dev.tfvars
terraform init -reconfigure -backend-config=env/prod.backend.hcl
terraform destroy -var-file=env/prod.tfvars
```

- (+) zero duplication de code, ajout d'un env = 2 fichiers (`.tfvars` + `.backend.hcl`)
- (-) necessite un `init -reconfigure` pour changer d'env en local (transparent en CI/CD)

## Pour aller plus loin

- **Terragrunt** : wrapper autour de Terraform qui pousse le DRY encore plus loin (gestion backend, inputs, dependencies entre modules). Attention : mode wrapper uniquement, pas de retour arriere simple une fois implemente - choix structurant pour l'equipe.
- **Terraform Stacks** : feature recente HCP Terraform pour orchestrer plusieurs root modules comme un ensemble (deployments, deferred changes).

## Pre-requis

- Terraform >= 1.5.0
- AWS CLI configure avec des credentials valides
- Region par defaut : `eu-west-1` (Paris)

## Points techniques demontres

- `cidrsubnet()` pour le calcul dynamique de CIDR
- Data source `aws_availability_zones` pour la selection dynamique d'AZ
- `merge()` pour la composition de tags
- `lookup()` avec fallback (level 1)
- Separation backend / variables d'env (level 3)
- Provider-defined functions (v1.8+) : `provider::aws::arn_parse()`, `provider::aws::arn_build()`
