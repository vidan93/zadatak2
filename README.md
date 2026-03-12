# Terraform ECS Modul

## Struktura repozitorijuma

```text
terraform/
├── main.tf              # Poziv child modula i prosledjivanje konfiguracije
├── variables.tf         # Deklaracija root input varijabli
├── terraform.tfvars     # Konkretne vrednosti varijabli i definicija servisa
├── outputs.tf           # Outputi koji vracaju ime klastera i listu servisa
├── provider.tf          # Mock AWS provajder konfiguracija za lokalni plan
├── versions.tf          # Terraform requirementi (~>1.14.6 za root)
├── .gitignore           # Ignorisanje sistemskih i osetljivih fajlova (Izuzetak tfvar za potrebe zadatka)
├── README.md            # Dokumentacija projekta
└── ecs_module/          # Child modul direktorijum
    ├── main.tf          # Resursi (Cluster, Service, Task Def, IAM, CloudWatch)
    ├── variables.tf     # Deklaracija modula, validacije i opcioni parametri
    ├── outputs.tf       # Autputi samog modula
    └── versions.tf      # Minimalni Terraform requirementi (>= 1.14.0 za ecs modul)
```

## Kako pokrenuti
Za pokretanje, pozicionirajte se u root direktorijum (`terraform/`) i izvrsiti sledece komande:

1. cd terraform
2. terraform init
3. terraform plan

---

## Arhitektura i Dizajn

### 1. Organizacija koda
* **`provider.tf`**: Izdvojen blok za konfiguraciju AWS provajdera.
* **`versions.tf`**: Izdvojene su definicije za zahtevane verzije Terraforma i AWS provajdera.

### 2. Mrezna Arhitektura
* **HA i Subnet varijable:** U `terraform.tfvars` mockovana su **dva subneta** kako bi se simulirali High Availability kroz Multi-AZ deployment. Ovi subneti se prosleđuju kao varijable (obicno kao output iz VPC modula), zbog cega su u ovom modulu definisani kao lista stringova.
* **Privatna mreza i Load Balancer:** Fargate taskovima je na nivou koda eksplicitno zabranjeno dodeljivanje javnih IP adresa (`assign_public_ip = false`). To znaci da subnetovi koji se prosledjuju modulu **treba da budu iskljucivo privatni**. U realnom produkcionom okruzenju za web aplikacije, ovaj modul bi se kombinovao sa Application Load Balancer-om (ALB) koji bi bio smesten u **public subnetovima** i sluzio bi kao jedina ulazna tacka za rutiranje saobracaja ka ECS kontejnerima.

### 3. Modularnost
Umesto hardkodovanja modula da kreira samo jedan fiksni Task i Service, konfiguracija je apstrahovana u mapu objekata (`var.services`). Ovo omogucava da modul moze da podigne vise razlicitih mikroservisa unutar istog klastera jednostavnim dodavanjem novog bloka u `terraform.tfvars`, bez ikakvog menjanja logike unutar samog modula.

### 4. Validacije
Kako bi se izbegle greske u runtime-u (tokom `terraform apply` faze kada se gađa AWS API), modul koristi:
* **`validation` blokove:** Dodate su validacije za `task_cpu`, `task_memory`, `desired_count` i `log_retention_days`. Na primer, modul ce prijaviti gresku vec u fazi plana ukoliko korisnik unese CPU/Memory kombinaciju koju AWS Fargate ne podrzava.
* **`optional()` parametre:** Parametar `log_retention_days` su deklarisani kao opcioni sa default vrednostima (7 dana).

### 5. IAM
Umesto jedne univerzalne role, IAM politike su razdvojene za svaki servis:
* **Task Execution Role:** Koristi je ECS agent za sistemske operacije (u ovom slucaju za upisivanje logova). Kreira se jedinstvena rola za svaki servis.
* **Task Role:** Kreirana je i zakacena prazna IAM rola namenjena samoj aplikaciji unutar kontejnera, nije implementirano dodavanje polisa prema potrebama konkretnog zadatka.

### 6. Tagovanje Resursa
Shodno zahtevu zadatka, svaki AWS resurs mora nositi tag `SRE_TASK = Ime_Prezime`. Da bi modul bio fleksibilniji, iskorišćena je funkcija `merge()`. Ona spaja obavezni `SRE_TASK` tag sa mapom opcionih tagova (`var.additional_tags`), omogucavajuci dodavanje drugih tagova bez menjanja modula.

### 7. Region
AWS region nije hardkodovan, modul koristi `data "aws_region" "current" {}` kako bi automatski procitao region iz root provajdera.

---

