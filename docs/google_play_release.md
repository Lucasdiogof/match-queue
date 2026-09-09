# Google Play — checklist sequencial de release

Baseado no AAB real já gerado (`build/app/outputs/bundle/release/
app-release.aab`, auditado em 2026-09-09 — ver seção "Auditoria do AAB"
abaixo). Nada aqui foi inventado: texto/arte que não existem ficam como
`MISSING`, decisões do dono do produto como `NEEDS USER INPUT`,
formulários que só existem dentro do painel como `NEEDS PLAY CONSOLE`.

## Auditoria do AAB gerado

Inspecionado o `.aab` diretamente (zip + manifest binário do módulo
base, sem `bundletool` disponível neste ambiente — leitura direta do
protobuf via extração de strings ASCII, suficiente pra confirmar cada
item):

| Item | Valor confirmado no artefato | Status |
| --- | --- | --- |
| `applicationId`/package | `com.lucasdiogof.fifaqueue` | READY |
| `versionName` | `0.1.0` | READY (mas é a v1 — subir a cada release seguinte) |
| Assinatura | `META-INF/FIFAQUEU.RSA` presente, `Built-By: Signflinger` (ferramenta real de assinatura do Android Gradle Plugin) — **assinado com a release key real**, não debug | READY |
| Permissões no manifest final | `INTERNET`, `WAKE_LOCK`, `ACCESS_NETWORK_STATE`, `VIBRATE`, `POST_NOTIFICATIONS`, permissões internas do FCM (`c2dm.permission.RECEIVE/SEND`) | READY — todas esperadas, nenhuma permissão sensível (câmera/localização/contatos) presente |
| Firebase (Messaging, Crashlytics, Core) | Registrado no manifest, `ComponentDiscoveryService` com os registrars corretos | READY |
| Flag `debuggable`/`testOnly` | Ausente do manifest | READY (confirma que não é uma build de debug disfarçada) |
| Tamanho | ~65 MB | Dentro do esperado pra um app Flutter + Firebase; Play Store aceita bem acima disso via AAB (limite de 200 MB pro download inicial) |
| `minSdk`/`targetSdk` | Herdados do Flutter SDK instalado (não hardcoded no projeto) | READY — confirmar o valor exato exportado pela versão do Flutter usada no Mac/CI de release, caso mude entre máquinas |

## Checklist sequencial

### 1. Conta Play Console
| Item | Status |
| --- | --- |
| Conta de desenvolvedor Google Play (taxa única, verificação de identidade) | **NEEDS USER INPUT** |

### 2. Criar o app no Console
| Item | Status |
| --- | --- |
| Nome interno do app no Console | **NEEDS USER INPUT** |
| Idioma padrão | **NEEDS USER INPUT** (provavelmente PT-BR, decisão do dono) |
| Categoria (app ou jogo) | **NEEDS USER INPUT** — "Ferramentas" ou "Esportes" fazem sentido, decisão de produto |

### 3. Store Listing
| Item | Status |
| --- | --- |
| Nome do app (30 caracteres) | **MISSING** |
| Short description (80 caracteres) | **MISSING** |
| Full description (4000 caracteres) | **MISSING** |
| Ícone da loja (512×512 PNG) | **READY** — exportável do ícone adaptativo já existente (`launcher_icon`, ver `docs/release_checklist_android.md`) |
| Feature graphic (1024×500) | **MISSING** |
| Screenshots (telefone, mínimo 2) | **MISSING — NEEDS PHYSICAL DEVICE** |
| Screenshots (tablet, opcional) | **MISSING — NEEDS PHYSICAL DEVICE** |
| Categoria de tags | **NEEDS USER INPUT** |

### 4. Privacy Policy
| Item | Status |
| --- | --- |
| URL pública da Política de Privacidade | **MISSING — NEEDS WEBSITE**. O app já tem a tela `privacy_policy_page.dart` com o texto real, mas a Play Store exige uma **URL hospedada**, não uma tela dentro do app. Domínio já existe (`lucksrei.com`, ver `env/production.json`) — falta publicar o conteúdo lá. |

### 5. Data Safety
Ver `docs/google_play_data_safety.md` para o detalhe campo a campo — aqui
só o resumo: **NEEDS PLAY CONSOLE** (formulário oficial preenchido
manualmente), mas todo o levantamento do que o app de fato coleta já
está pronto nesse documento, então preencher é mecânico.

### 6. Content Rating
| Item | Status |
| --- | --- |
| Questionário IARC | **NEEDS PLAY CONSOLE** — preenchido dentro do Console; o app não tem conteúdo violento/adulto/apostas, deve classificar como livre ou baixa faixa etária, mas a classificação oficial só existe depois do questionário |

### 7. App Access
| Item | Status |
| --- | --- |
| Instruções de acesso pro revisor (se alguma parte exigir login) | **NEEDS USER INPUT** — recomenda-se criar uma conta de revisor dedicada, já com um time e um squad configurados, e informar e-mail/senha no formulário |

### 8. Ads
| Item | Status |
| --- | --- |
| Declaração "contém anúncios" | **READY — declarar que NÃO contém.** Nenhum SDK de ads no `pubspec.yaml` |

### 9. Target Audience e conteúdo
| Item | Status |
| --- | --- |
| Faixa de idade / público-alvo | **NEEDS USER INPUT** |
| App voltado a crianças (Families Policy) | **NEEDS USER INPUT** — provavelmente não se aplica, mas é uma declaração formal |

### 10. Account Deletion
| Item | Status |
| --- | --- |
| Fluxo de exclusão de conta | **READY** — já implementado dentro do app (Fase A), a Play Store aceita declarar o fluxo in-app sem precisar de URL separada |

### 11. App content — declarações adicionais
| Item | Status |
| --- | --- |
| Declaração de notícias/COVID/etc. (não aplicável) | **READY (N/A)** |
| Government app (não aplicável) | **READY (N/A)** |

### 12. Testing interno
| Item | Status |
| --- | --- |
| Faixa de teste interno criada | **NEEDS PLAY CONSOLE** |
| Lista de testers (e-mails) | **NEEDS USER INPUT** |
| Upload do AAB pra faixa interna | **READY PARA FAZER** — o AAB já existe e está assinado corretamente; só falta o upload manual no Console |

### 13. Release notes
| Item | Status |
| --- | --- |
| Texto de "novidades desta versão" | **MISSING** — pode reaproveitar o `CHANGELOG.md`/`.pt.md`/`.es.md` já escrito (Etapa 18) como base, adaptado pro tamanho que a Play Store aceita |

### 14. Pre-launch report
| Item | Status |
| --- | --- |
| Relatório automático da Play Console (roda o app em devices reais deles) | **NEEDS PLAY CONSOLE** — dispara automaticamente depois do primeiro upload numa faixa de teste; não precisa de ação manual além de revisar o resultado |

### 15. Rollout de produção
| Item | Status |
| --- | --- |
| Promoção da faixa interna/fechada pra produção | **NEEDS USER INPUT** — decisão de quando, depois de testing interno + Device QA (ver `docs/android_device_qa.md`) |
| Percentual de rollout gradual | **NEEDS USER INPUT** — recomenda-se começar em 10-20%, não 100% direto |

## Estimativa de completude

**~40%** (subiu de ~35% na Etapa 20 porque o AAB assinado real agora
existe e pode ser enviado pra uma faixa de teste hoje mesmo — o que
falta é 100% texto/arte/decisão humana/formulário do Console, nada de
código ou configuração de projeto).
