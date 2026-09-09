import 'package:fifa_queue/features/legal/domain/legal_document.dart';

const String kSupportEmailPlaceholder = '[EMAIL_DE_SUPORTE]';
const String kResponsiblePartyPlaceholder =
    '[NOME/RAZÃO SOCIAL DO RESPONSÁVEL PELO APP]';

const String _nonAffiliationPt =
    'O FIFA Queue é um aplicativo independente, feito por fã, e não é '
    'afiliado, endossado ou patrocinado pela EA SPORTS, Electronic Arts, '
    'FIFA ou qualquer uma de suas afiliadas. Todas as marcas, nomes e '
    'imagens de terceiros mencionados pertencem aos seus respectivos '
    'donos e são usados apenas para identificar do que o aplicativo trata.';

const LegalDocument kPrivacyPolicyPt = LegalDocument(
  updatedAt: '2026-09-08',
  nonAffiliationDisclaimer: _nonAffiliationPt,
  sections: <LegalSection>[
    LegalSection(
      title: '1. Responsável pelo aplicativo',
      body:
          'O FIFA Queue é operado por $kResponsiblePartyPlaceholder. '
          'Dúvidas sobre esta Política podem ser enviadas para '
          '$kSupportEmailPlaceholder.',
    ),
    LegalSection(
      title: '2. Quais dados coletamos',
      body:
          'Coletamos apenas o necessário para o app funcionar:\n\n'
          '• Dados de conta: e-mail e senha (armazenada de forma segura '
          'pelo provedor de autenticação, nunca em texto simples).\n'
          '• Perfil: nome de exibição e, se você escolher enviar uma, foto '
          'de avatar.\n'
          '• Identificadores internos: um ID único gerado para sua conta e '
          'para cada Time/Elenco que você cria ou participa.\n'
          '• Elencos (Contas EA FC): nomes que você dá aos seus elencos, '
          'divisão de Rivals e registro de Weekend League que você mesmo '
          'informar.\n'
          '• Times: nome, tag e histórico de atividade dos times dos quais '
          'você participa.\n'
          '• Dados de partidas: buscas de partida, filas, resultados e '
          'estatísticas (gols, assistências) que você ou seu time '
          'registrarem.\n'
          '• Token de notificação push (Firebase Cloud Messaging), se você '
          'permitir notificações.\n'
          '• Perfil público: somente se você ativar essa opção nas '
          'configurações, um link público mostra seu nome, escalação '
          'principal e estatísticas resumidas.',
    ),
    LegalSection(
      title: '3. Provedores que usamos',
      body:
          'Usamos o Supabase (banco de dados, autenticação e hospedagem de '
          'API) e o Firebase (notificações push e relatório de falhas). '
          'Esses provedores processam dados em nosso nome, seguindo suas '
          'próprias políticas de segurança, e não têm permissão para usar '
          'seus dados para fins próprios.',
    ),
    LegalSection(
      title: '4. Para que usamos seus dados',
      body:
          'Usamos os dados coletados exclusivamente para: autenticar sua '
          'conta; organizar a fila de busca de partida do seu time; '
          'exibir seu histórico e estatísticas; enviar notificações sobre '
          'sua vez na fila ou eventos do time (se você permitir); e, caso '
          'você ative o perfil público, exibi-lo no link que você '
          'compartilhar. Não vendemos seus dados nem os usamos para '
          'publicidade.',
    ),
    LegalSection(
      title: '5. Armazenamento e segurança',
      body:
          'Os dados ficam armazenados em servidores do Supabase, protegidos '
          'por controle de acesso em nível de linha (Row Level Security): '
          'cada usuário só consegue ler/editar o que é seu ou o que seu '
          'time compartilha com você. Senhas nunca são armazenadas em '
          'texto simples. Comunicação entre o app e o servidor é feita '
          'sempre por HTTPS.',
    ),
    LegalSection(
      title: '6. Retenção',
      body:
          'Mantemos seus dados enquanto sua conta existir. Histórico de '
          'partidas do seu time é mantido mesmo após você excluir sua '
          'conta, mas de forma anônima (sem seu nome associado) para não '
          'apagar o histórico compartilhado dos demais membros do time.',
    ),
    LegalSection(
      title: '7. Exclusão de conta',
      body:
          'Você pode excluir sua conta a qualquer momento em Perfil → '
          'Excluir minha conta. A exclusão remove seu perfil, elencos, '
          'escalações, participação em times, dispositivos registrados, '
          'preferências de notificação e perfil público. Se você for o '
          'único integrante de um time que criou, o time inteiro é '
          'removido; se houver outros integrantes, a exclusão só é '
          'permitida depois que você deixar de ser o único dono (ex.: '
          'promovendo/removendo outros membros pelas ferramentas '
          'disponíveis). Essa ação é permanente e não pode ser desfeita.',
    ),
    LegalSection(
      title: '8. Compartilhamento de dados',
      body:
          'Não compartilhamos seus dados com terceiros para fins de '
          'marketing. Compartilhamos dados apenas com os provedores de '
          'infraestrutura citados na seção 3, na medida necessária para o '
          'app funcionar, e quando exigido por lei.',
    ),
    LegalSection(
      title: '9. Seus direitos',
      body:
          'Você pode, a qualquer momento: acessar e editar seu nome de '
          'exibição e avatar pelo próprio app; ativar ou desativar seu '
          'perfil público; e excluir sua conta e os dados associados a '
          'ela. Para qualquer outra solicitação sobre seus dados, entre em '
          'contato pelo $kSupportEmailPlaceholder.',
    ),
    LegalSection(
      title: '10. Menores de idade',
      body:
          'O FIFA Queue não é direcionado a menores de 13 anos e não '
          'coleta intencionalmente dados de crianças. Se você é '
          'responsável por um menor e acredita que ele nos forneceu dados '
          'pessoais, entre em contato para que possamos removê-los.',
    ),
    LegalSection(
      title: '11. Mudanças nesta política',
      body:
          'Podemos atualizar esta Política de tempos em tempos. Mudanças '
          'relevantes serão comunicadas dentro do app. A data no topo '
          'desta página sempre indica a versão mais recente.',
    ),
    LegalSection(title: '12. Marca e afiliação', body: _nonAffiliationPt),
  ],
);

const LegalDocument kTermsOfUsePt = LegalDocument(
  updatedAt: '2026-09-08',
  nonAffiliationDisclaimer: _nonAffiliationPt,
  sections: <LegalSection>[
    LegalSection(
      title: '1. Aceitação dos termos',
      body:
          'Ao criar uma conta ou usar o FIFA Queue, você concorda com estes '
          'Termos de Uso e com a nossa Política de Privacidade. Se você não '
          'concordar, não utilize o aplicativo.',
    ),
    LegalSection(
      title: '2. Sobre o app',
      body:
          'O FIFA Queue ajuda grupos de jogadores de EA SPORTS FC / Clubs a '
          'organizar quem busca partida em cada momento, além de registrar '
          'resultados, elencos e estatísticas do time.',
    ),
    LegalSection(
      title: '3. Sua conta',
      body:
          'Você é responsável por manter a confidencialidade da sua senha '
          'e por todas as atividades realizadas na sua conta. Você deve '
          'fornecer informações verdadeiras ao se cadastrar.',
    ),
    LegalSection(
      title: '4. Conduta do usuário',
      body:
          'Você concorda em não usar o app para assediar outros usuários, '
          'enviar conteúdo ofensivo, tentar acessar contas de terceiros, '
          'ou interferir no funcionamento normal do serviço.',
    ),
    LegalSection(
      title: '5. Matchmaking e fila',
      body:
          'A fila de busca de partida é organizada automaticamente pelo '
          'app com base na ordem de chegada. O FIFA Queue não participa, '
          'não interfere e não se responsabiliza pelo resultado das '
          'partidas jogadas fora do aplicativo.',
    ),
    LegalSection(
      title: '6. Conteúdo que você insere',
      body:
          'Você é responsável pelos nomes de elenco, resultados e demais '
          'informações que inserir no app. Reservamo-nos o direito de '
          'remover conteúdo claramente ofensivo ou que viole estes Termos.',
    ),
    LegalSection(
      title: '7. Conteúdo de terceiros',
      body:
          'Nomes de jogadores, clubes, ligas e outras referências ao '
          'EA SPORTS FC exibidos no app são usados apenas para fins '
          'informativos/organizacionais e pertencem aos seus respectivos '
          'donos, conforme detalhado na seção de marca abaixo.',
    ),
    LegalSection(
      title: '8. Disponibilidade do serviço',
      body:
          'Fazemos o possível para manter o app disponível, mas não '
          'garantimos operação ininterrupta ou livre de erros. '
          'Manutenções, atualizações ou falhas de terceiros (Supabase, '
          'Firebase, lojas de aplicativo) podem causar indisponibilidade '
          'temporária.',
    ),
    LegalSection(
      title: '9. Suspensão e encerramento',
      body:
          'Podemos suspender ou encerrar o acesso de uma conta que viole '
          'estes Termos. Você pode encerrar sua conta a qualquer momento '
          'pela função de exclusão de conta descrita na Política de '
          'Privacidade.',
    ),
    LegalSection(
      title: '10. Propriedade intelectual',
      body:
          'O código, design e marca "FIFA Queue" pertencem ao '
          'desenvolvedor do app. Marcas de terceiros (EA SPORTS, FIFA, '
          'Ultimate Team e afins) pertencem aos seus respectivos donos, '
          'conforme a seção de marca abaixo.',
    ),
    LegalSection(
      title: '11. Limitação de responsabilidade',
      body:
          'O app é fornecido "como está". Na máxima extensão permitida por '
          'lei, não nos responsabilizamos por danos indiretos decorrentes '
          'do uso ou da impossibilidade de uso do aplicativo.',
    ),
    LegalSection(
      title: '12. Alterações nestes Termos',
      body:
          'Podemos atualizar estes Termos periodicamente. O uso continuado '
          'do app após uma atualização significa que você aceita os novos '
          'Termos.',
    ),
    LegalSection(
      title: '13. Contato',
      body: 'Dúvidas sobre estes Termos: $kSupportEmailPlaceholder.',
    ),
    LegalSection(title: '14. Marca e afiliação', body: _nonAffiliationPt),
  ],
);
