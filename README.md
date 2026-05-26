# PoliVisitas

Sistema para gestao de visitas tecnicas, propriedades/feirantes, diagnosticos, encaminhamentos, usuarios e relatorios do projeto integrador.

O repositorio esta dividido em duas partes:

| Pasta | Nome tecnico | Descricao |
| --- | --- | --- |
| `projeto-integrador/` | `polivisitas-api` | Backend REST em Spring Boot |
| `mobile_app/` | `polivisitas_mobile` | Aplicativo Flutter do PoliVisitas |

## Backend

O backend fica em `projeto-integrador/` e expoe a API REST usada pelo aplicativo.

Principais tecnologias e bibliotecas:

| Biblioteca | Uso |
| --- | --- |
| Java 21 | Versao usada na compilacao do projeto |
| Spring Boot 4.0.5 | Base da aplicacao backend |
| Spring Web | Controllers REST e endpoints HTTP |
| Spring Validation | Validacao dos DTOs recebidos pela API |
| Spring Data JPA | Persistencia com entidades e repositories |
| Spring Security | Autenticacao e autorizacao |
| JJWT 0.12.6 | Geracao e validacao dos tokens JWT |
| PostgreSQL Driver | Conexao com o banco PostgreSQL |
| Flyway | Controle de migrations do banco |
| Spring Cache | Cache local simples da aplicacao |
| AWS SDK S3 | Integracao com MinIO/S3 para imagens |
| Springdoc OpenAPI | Swagger e documentacao da API |
| Lombok | Reducao de codigo repetitivo em entidades/DTOs |
| JUnit/Spring Security Test | Testes automatizados |

Comandos principais no Windows:

```powershell
cd projeto-integrador
docker compose up -d
.\mvnw.cmd spring-boot:run
```

Comandos principais no Linux/macOS:

```bash
cd projeto-integrador
docker compose up -d
./mvnw spring-boot:run
```

Testes do backend:

```powershell
cd projeto-integrador
.\mvnw.cmd clean test
```

URLs locais do backend:

| Recurso | URL |
| --- | --- |
| API | `http://localhost:8080` |
| Swagger UI | `http://localhost:8080/swagger-ui/index.html` |
| OpenAPI JSON | `http://localhost:8080/v3/api-docs` |

Principais grupos de endpoints:

| Endpoint base | Funcao |
| --- | --- |
| `/api/auth` | Login, refresh token e logout |
| `/api/dashboard` | Resumo da tela inicial |
| `/api/propriedades` | Cadastro e consulta de propriedades/feirantes |
| `/api/visitas` | Agendamento, listagem, detalhes e finalizacao de visitas |
| `/api/encaminhamentos` | Listagem, conclusao e exclusao de encaminhamentos |
| `/api/imagens` | Upload de imagens de perfil e visitas |
| `/api/usuarios` | Cadastro e gerenciamento de usuarios |
| `/api/audit` | Consulta de auditoria |

## Frontend / Mobile

O aplicativo fica em `mobile_app/` e consome a API do backend com token JWT.

Principais tecnologias e bibliotecas:

| Biblioteca | Uso |
| --- | --- |
| Flutter / Dart | Base do aplicativo mobile |
| Dio | Cliente HTTP para consumir a API |
| Flutter Secure Storage | Armazenamento seguro de tokens |
| Flutter Dotenv | Leitura de variaveis do arquivo `.env` |
| Go Router | Rotas e navegacao |
| Table Calendar | Calendario de visitas |
| Google Maps Flutter | Integracao com Google Maps |
| Flutter Map | Mapa alternativo baseado em tiles |
| LatLong2 | Modelagem de coordenadas |
| Image Picker | Selecao/captura de imagens |
| Flutter Lints | Padrao de analise estatica |

Crie o arquivo `mobile_app/.env` para apontar o app para a API:

```env
API_BASE_URL=http://10.0.2.2:8080
MAPS_API_KEY=sua_chave_google_maps_aqui
```

Use `10.0.2.2` quando estiver rodando no emulador Android, porque esse endereco aponta para o `localhost` da maquina. Em celular fisico, troque pelo IP local do computador, por exemplo:

```env
API_BASE_URL=http://192.168.1.107:8080
MAPS_API_KEY=sua_chave_google_maps_aqui
```

Comandos principais:

```powershell
cd mobile_app
flutter pub get
flutter run
```

Analise estatica do app:

```powershell
cd mobile_app
flutter analyze
```

Se rodar o app como web, a porta nao e fixa por padrao. Para definir uma porta:

```powershell
cd mobile_app
flutter run -d chrome --web-port 5173
```

## Docker Compose

O arquivo `projeto-integrador/docker-compose.yml` sobe os servicos locais necessarios para desenvolvimento.

| Servico | Container | Porta local | Porta interna | Uso |
| --- | --- | --- | --- | --- |
| `postgres` | `polivisitas-postgres` | `5435` | `5432` | Banco PostgreSQL |
| `pgadmin` | `polivisitas-pgadmin` | `5050` | `80` | Interface web para o PostgreSQL |
| `minio` | `polivisitas-minio` | `9000` | `9000` | API S3 local para arquivos |
| `minio` | `polivisitas-minio` | `9001` | `9001` | Console web do MinIO |
| `minio-setup` | `polivisitas-minio-setup` | sem porta | sem porta | Cria o bucket `polivisitas-imagens` automaticamente |

URLs dos servicos:

| Recurso | URL |
| --- | --- |
| PostgreSQL | `localhost:5435` |
| pgAdmin | `http://localhost:5050` |
| MinIO API | `http://localhost:9000` |
| MinIO Console | `http://localhost:9001` |

## Portas da aplicacao

| Parte | Porta | Observacao |
| --- | --- | --- |
| Backend Spring Boot | `8080` | Definida em `server.port=8080` |
| App Android emulator | sem porta propria | Consome a API em `http://10.0.2.2:8080` |
| App em celular fisico | sem porta propria | Consome a API pelo IP local da maquina |
| App Flutter Web | variavel | Pode ser fixada com `--web-port 5173` |
| PostgreSQL | `5435` | Porta local mapeada pelo Docker |
| pgAdmin | `5050` | Interface web |
| MinIO API | `9000` | Upload/download de imagens |
| MinIO Console | `9001` | Administracao do MinIO |

## Fluxo recomendado para desenvolvimento

1. Subir os servicos Docker em `projeto-integrador/`.
2. Rodar o backend na porta `8080`.
3. Configurar `mobile_app/.env` com a URL correta da API.
4. Rodar o app Flutter.
5. Usar o Swagger para conferir endpoints quando precisar testar a API direto pelo navegador.

## Verificacao antes de commit

```powershell
cd mobile_app
flutter analyze

cd ..\projeto-integrador
.\mvnw.cmd clean test
```
