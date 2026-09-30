import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gerado/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('pt')];

  /// No description provided for @appNome.
  ///
  /// In pt, this message translates to:
  /// **'Meu Drive'**
  String get appNome;

  /// No description provided for @inicialTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Minhas pastas'**
  String get inicialTitulo;

  /// No description provided for @verificandoMotor.
  ///
  /// In pt, this message translates to:
  /// **'Preparando o sincronizador...'**
  String get verificandoMotor;

  /// No description provided for @iniciandoMotor.
  ///
  /// In pt, this message translates to:
  /// **'Iniciando o sincronizador...'**
  String get iniciandoMotor;

  /// No description provided for @nenhumaPasta.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma pasta sincronizada ainda.'**
  String get nenhumaPasta;

  /// No description provided for @explorarCelular.
  ///
  /// In pt, this message translates to:
  /// **'Explorar o celular'**
  String get explorarCelular;

  /// No description provided for @permissaoTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Acesso aos arquivos'**
  String get permissaoTitulo;

  /// No description provided for @permissaoTexto.
  ///
  /// In pt, this message translates to:
  /// **'Para sincronizar e navegar pelas pastas do celular, conceda acesso a todos os arquivos.'**
  String get permissaoTexto;

  /// No description provided for @concederPermissao.
  ///
  /// In pt, this message translates to:
  /// **'Conceder acesso'**
  String get concederPermissao;

  /// No description provided for @configuracao.
  ///
  /// In pt, this message translates to:
  /// **'Configuração'**
  String get configuracao;

  /// No description provided for @diagnostico.
  ///
  /// In pt, this message translates to:
  /// **'Diagnóstico'**
  String get diagnostico;

  /// No description provided for @atualizar.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar'**
  String get atualizar;

  /// No description provided for @erroTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Algo deu errado'**
  String get erroTitulo;

  /// No description provided for @tentarNovamente.
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get tentarNovamente;

  /// No description provided for @recarregar.
  ///
  /// In pt, this message translates to:
  /// **'Recarregar pastas'**
  String get recarregar;

  /// No description provided for @rescan.
  ///
  /// In pt, this message translates to:
  /// **'Verificar mudanças agora'**
  String get rescan;

  /// No description provided for @pausada.
  ///
  /// In pt, this message translates to:
  /// **'Pausada'**
  String get pausada;

  /// No description provided for @sincronizando.
  ///
  /// In pt, this message translates to:
  /// **'Sincronizando'**
  String get sincronizando;

  /// No description provided for @sincronizado.
  ///
  /// In pt, this message translates to:
  /// **'Sincronizado'**
  String get sincronizado;

  /// No description provided for @erroPasta.
  ///
  /// In pt, this message translates to:
  /// **'Erro'**
  String get erroPasta;

  /// No description provided for @estadoDesconhecido.
  ///
  /// In pt, this message translates to:
  /// **'Desconhecido'**
  String get estadoDesconhecido;

  /// No description provided for @atualizadoEm.
  ///
  /// In pt, this message translates to:
  /// **'Atualizado em'**
  String get atualizadoEm;

  /// No description provided for @ok.
  ///
  /// In pt, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @portaGui.
  ///
  /// In pt, this message translates to:
  /// **'Endereço do motor'**
  String get portaGui;

  /// No description provided for @portaInvalida.
  ///
  /// In pt, this message translates to:
  /// **'Porta inválida.'**
  String get portaInvalida;

  /// No description provided for @salvar.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get salvar;

  /// No description provided for @cancelar.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get cancelar;

  /// No description provided for @logDiagnostico.
  ///
  /// In pt, this message translates to:
  /// **'Registro do diagnóstico'**
  String get logDiagnostico;

  /// No description provided for @copiarLog.
  ///
  /// In pt, this message translates to:
  /// **'Copiar registro'**
  String get copiarLog;

  /// No description provided for @logCopiado.
  ///
  /// In pt, this message translates to:
  /// **'Registro copiado.'**
  String get logCopiado;

  /// No description provided for @arquivoNaoAbrir.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir o arquivo.'**
  String get arquivoNaoAbrir;

  /// No description provided for @vazio.
  ///
  /// In pt, this message translates to:
  /// **'Vazio'**
  String get vazio;

  /// No description provided for @statusTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Status do motor'**
  String get statusTitulo;

  /// No description provided for @conectado.
  ///
  /// In pt, this message translates to:
  /// **'Conectado'**
  String get conectado;

  /// No description provided for @desconectado.
  ///
  /// In pt, this message translates to:
  /// **'Desconectado'**
  String get desconectado;

  /// No description provided for @permissaoArquivos.
  ///
  /// In pt, this message translates to:
  /// **'Perfil de acesso'**
  String get permissaoArquivos;

  /// No description provided for @concedido.
  ///
  /// In pt, this message translates to:
  /// **'Concedido'**
  String get concedido;

  /// No description provided for @naoConcedido.
  ///
  /// In pt, this message translates to:
  /// **'Não concedido'**
  String get naoConcedido;

  /// No description provided for @acordarMotor.
  ///
  /// In pt, this message translates to:
  /// **'Acordar motor'**
  String get acordarMotor;

  /// No description provided for @pararMotor.
  ///
  /// In pt, this message translates to:
  /// **'Parar motor'**
  String get pararMotor;

  /// No description provided for @recarregarTudo.
  ///
  /// In pt, this message translates to:
  /// **'Reiniciar motor'**
  String get recarregarTudo;

  /// No description provided for @testarConexao.
  ///
  /// In pt, this message translates to:
  /// **'Testar conexão'**
  String get testarConexao;

  /// No description provided for @logMotor.
  ///
  /// In pt, this message translates to:
  /// **'Log do motor'**
  String get logMotor;

  /// No description provided for @importarConfig.
  ///
  /// In pt, this message translates to:
  /// **'Importar do Syncthing-Fork'**
  String get importarConfig;

  /// No description provided for @importarConfigTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Importar configuração'**
  String get importarConfigTitulo;

  /// No description provided for @importarConfigMensagem.
  ///
  /// In pt, this message translates to:
  /// **'Isso substitui a configuração atual do motor pela exportada do Syncthing-Fork (mesmo device ID e pastas). Continue?'**
  String get importarConfigMensagem;

  /// No description provided for @motorParadoTexto.
  ///
  /// In pt, this message translates to:
  /// **'O motor está parado. Toque em acordar para retomar a sincronização.'**
  String get motorParadoTexto;

  /// No description provided for @gerenciar.
  ///
  /// In pt, this message translates to:
  /// **'Gerenciar'**
  String get gerenciar;

  /// No description provided for @pastasCompartilhadas.
  ///
  /// In pt, this message translates to:
  /// **'Pastas compartilhadas'**
  String get pastasCompartilhadas;

  /// No description provided for @esteAparelho.
  ///
  /// In pt, this message translates to:
  /// **'Este aparelho'**
  String get esteAparelho;

  /// No description provided for @tudoSincronizado.
  ///
  /// In pt, this message translates to:
  /// **'Tudo sincronizado'**
  String get tudoSincronizado;

  /// No description provided for @sincronizandoAgora.
  ///
  /// In pt, this message translates to:
  /// **'Sincronizando...'**
  String get sincronizandoAgora;

  /// No description provided for @sincronizacaoPausada.
  ///
  /// In pt, this message translates to:
  /// **'Sincronização pausada'**
  String get sincronizacaoPausada;

  /// No description provided for @itens.
  ///
  /// In pt, this message translates to:
  /// **'itens'**
  String get itens;

  /// No description provided for @nPastas.
  ///
  /// In pt, this message translates to:
  /// **'pastas'**
  String get nPastas;

  /// No description provided for @nArquivos.
  ///
  /// In pt, this message translates to:
  /// **'arquivos'**
  String get nArquivos;

  /// No description provided for @geral.
  ///
  /// In pt, this message translates to:
  /// **'Geral'**
  String get geral;

  /// No description provided for @tema.
  ///
  /// In pt, this message translates to:
  /// **'Tema'**
  String get tema;

  /// No description provided for @temaSistema.
  ///
  /// In pt, this message translates to:
  /// **'Sistema'**
  String get temaSistema;

  /// No description provided for @temaClaro.
  ///
  /// In pt, this message translates to:
  /// **'Claro'**
  String get temaClaro;

  /// No description provided for @temaEscuro.
  ///
  /// In pt, this message translates to:
  /// **'Escuro'**
  String get temaEscuro;

  /// No description provided for @nomeDesteAparelho.
  ///
  /// In pt, this message translates to:
  /// **'Nome deste aparelho'**
  String get nomeDesteAparelho;

  /// No description provided for @sincronizacao.
  ///
  /// In pt, this message translates to:
  /// **'Sincronização'**
  String get sincronizacao;

  /// No description provided for @pausarSincronizacao.
  ///
  /// In pt, this message translates to:
  /// **'Pausar sincronização'**
  String get pausarSincronizacao;

  /// No description provided for @manterSincronizado.
  ///
  /// In pt, this message translates to:
  /// **'Manter sincronizado'**
  String get manterSincronizado;

  /// No description provided for @detectarMudancas.
  ///
  /// In pt, this message translates to:
  /// **'Detectar mudanças automaticamente'**
  String get detectarMudancas;

  /// No description provided for @verificarACada.
  ///
  /// In pt, this message translates to:
  /// **'Verificar a cada'**
  String get verificarACada;

  /// No description provided for @ajuda.
  ///
  /// In pt, this message translates to:
  /// **'Ajuda'**
  String get ajuda;

  /// No description provided for @ajudaManterSincronizado.
  ///
  /// In pt, this message translates to:
  /// **'Ligado: o Meu Drive mantém o motor de sincronização rodando e ativo em segundo plano (aparece uma notificação de que está sincronizando). Desligado: a sincronização é pausada — nada é enviado nem recebido —, mas os arquivos continuam no aparelho e nada é apagado.'**
  String get ajudaManterSincronizado;

  /// No description provided for @ajudaDetectarMudancas.
  ///
  /// In pt, this message translates to:
  /// **'Ligado: o motor observa as pastas em tempo real e sincroniza assim que um arquivo é criado, alterado ou apagado (sincronização quase instantânea). Desligado: economiza um pouco de bateria, e as mudanças passam a ser encontradas apenas na verificação periódica (opção \"Verificar a cada\").'**
  String get ajudaDetectarMudancas;

  /// No description provided for @ajudaVerificarACada.
  ///
  /// In pt, this message translates to:
  /// **'De quanto em quanto tempo o motor faz uma varredura completa nas pastas para procurar mudanças. Serve de reforço quando a detecção em tempo real está desligada ou deixa passar algum evento. Em \"Desativado\", o motor só verifica quando você tocar em \"Verificar mudanças agora\".'**
  String get ajudaVerificarACada;

  /// No description provided for @verComo.
  ///
  /// In pt, this message translates to:
  /// **'Ver como'**
  String get verComo;

  /// No description provided for @modoLista.
  ///
  /// In pt, this message translates to:
  /// **'Lista'**
  String get modoLista;

  /// No description provided for @modoGrade.
  ///
  /// In pt, this message translates to:
  /// **'Grade'**
  String get modoGrade;

  /// No description provided for @ordenarPor.
  ///
  /// In pt, this message translates to:
  /// **'Ordenar por'**
  String get ordenarPor;

  /// No description provided for @ordenarNome.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get ordenarNome;

  /// No description provided for @ordenarData.
  ///
  /// In pt, this message translates to:
  /// **'Data de modificação'**
  String get ordenarData;

  /// No description provided for @ordenarTamanho.
  ///
  /// In pt, this message translates to:
  /// **'Tamanho'**
  String get ordenarTamanho;

  /// No description provided for @ordemCrescente.
  ///
  /// In pt, this message translates to:
  /// **'Crescente'**
  String get ordemCrescente;

  /// No description provided for @ordemDecrescente.
  ///
  /// In pt, this message translates to:
  /// **'Decrescente'**
  String get ordemDecrescente;

  /// No description provided for @tamanhoMiniaturas.
  ///
  /// In pt, this message translates to:
  /// **'Tamanho das miniaturas'**
  String get tamanhoMiniaturas;

  /// No description provided for @miniaturaPequena.
  ///
  /// In pt, this message translates to:
  /// **'Pequenas'**
  String get miniaturaPequena;

  /// No description provided for @miniaturaMedia.
  ///
  /// In pt, this message translates to:
  /// **'Médias'**
  String get miniaturaMedia;

  /// No description provided for @miniaturaGrande.
  ///
  /// In pt, this message translates to:
  /// **'Grandes'**
  String get miniaturaGrande;

  /// No description provided for @abrirCom.
  ///
  /// In pt, this message translates to:
  /// **'Abrir com outro app'**
  String get abrirCom;

  /// No description provided for @ampliada.
  ///
  /// In pt, this message translates to:
  /// **'Ampliada'**
  String get ampliada;

  /// No description provided for @toqueParaAmpliar.
  ///
  /// In pt, this message translates to:
  /// **'Toque duas vezes para ampliar'**
  String get toqueParaAmpliar;

  /// No description provided for @maisOpcoes.
  ///
  /// In pt, this message translates to:
  /// **'Mais opções'**
  String get maisOpcoes;

  /// No description provided for @mostrarOcultos.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar arquivos ocultos'**
  String get mostrarOcultos;

  /// No description provided for @ocultarOcultos.
  ///
  /// In pt, this message translates to:
  /// **'Ocultar arquivos ocultos'**
  String get ocultarOcultos;

  /// No description provided for @armazenamento.
  ///
  /// In pt, this message translates to:
  /// **'Armazenamento'**
  String get armazenamento;

  /// No description provided for @armazenamentoAparelho.
  ///
  /// In pt, this message translates to:
  /// **'Armazenamento do aparelho'**
  String get armazenamentoAparelho;

  /// No description provided for @compartilhado.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhado'**
  String get compartilhado;

  /// No description provided for @livres.
  ///
  /// In pt, this message translates to:
  /// **'livres'**
  String get livres;

  /// No description provided for @emUso.
  ///
  /// In pt, this message translates to:
  /// **'em uso'**
  String get emUso;

  /// No description provided for @backup.
  ///
  /// In pt, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @novaVersao.
  ///
  /// In pt, this message translates to:
  /// **'Nova versão disponível:'**
  String get novaVersao;

  /// No description provided for @atualizarApp.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar agora'**
  String get atualizarApp;

  /// No description provided for @baixandoAtualizacao.
  ///
  /// In pt, this message translates to:
  /// **'Baixando...'**
  String get baixandoAtualizacao;

  /// No description provided for @permitirInstalar.
  ///
  /// In pt, this message translates to:
  /// **'Permita \"instalar apps desconhecidos\" para o Meu Drive e toque de novo.'**
  String get permitirInstalar;

  /// No description provided for @verificarAtualizacoes.
  ///
  /// In pt, this message translates to:
  /// **'Verificar atualizações'**
  String get verificarAtualizacoes;

  /// No description provided for @tudoAtualizado.
  ///
  /// In pt, this message translates to:
  /// **'Você está na versão mais recente.'**
  String get tudoAtualizado;

  /// No description provided for @erroAtualizacao.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível verificar atualizações.'**
  String get erroAtualizacao;

  /// No description provided for @exportarConfig.
  ///
  /// In pt, this message translates to:
  /// **'Exportar configurações'**
  String get exportarConfig;

  /// No description provided for @exportarConfigFeito.
  ///
  /// In pt, this message translates to:
  /// **'Configurações exportadas para backups/syncthing/config.zip'**
  String get exportarConfigFeito;

  /// No description provided for @exportarConfigFalhou.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível exportar as configurações.'**
  String get exportarConfigFalhou;

  /// No description provided for @exportarConfigOk.
  ///
  /// In pt, this message translates to:
  /// **'Configurações exportadas.'**
  String get exportarConfigOk;

  /// No description provided for @desativado.
  ///
  /// In pt, this message translates to:
  /// **'Desativado'**
  String get desativado;

  /// No description provided for @hora.
  ///
  /// In pt, this message translates to:
  /// **'hora'**
  String get hora;

  /// No description provided for @horas.
  ///
  /// In pt, this message translates to:
  /// **'horas'**
  String get horas;

  /// No description provided for @avancado.
  ///
  /// In pt, this message translates to:
  /// **'Avançado'**
  String get avancado;

  /// No description provided for @compartilhamento.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhamento'**
  String get compartilhamento;

  /// No description provided for @pastaRecebidos.
  ///
  /// In pt, this message translates to:
  /// **'Pasta dos arquivos recebidos'**
  String get pastaRecebidos;

  /// No description provided for @pastaRecebidosAjuda.
  ///
  /// In pt, this message translates to:
  /// **'Quando você toca em \"Compartilhar\" em outro app e escolhe o Meu Drive, o arquivo é salvo nesta pasta. Escolha uma pasta (ou subpasta) dentro de uma pasta compartilhada para que o arquivo também seja sincronizado com os outros dispositivos.'**
  String get pastaRecebidosAjuda;

  /// No description provided for @pastaRecebidosNaoDefinida.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma pasta definida'**
  String get pastaRecebidosNaoDefinida;

  /// No description provided for @escolherPastaCompartilhada.
  ///
  /// In pt, this message translates to:
  /// **'Escolha a pasta compartilhada'**
  String get escolherPastaCompartilhada;

  /// No description provided for @pastaRecebidosSemPastas.
  ///
  /// In pt, this message translates to:
  /// **'Você ainda não tem pastas compartilhadas. Adicione uma pasta em Gerenciar para poder escolher onde salvar os arquivos recebidos.'**
  String get pastaRecebidosSemPastas;

  /// No description provided for @pastaRecebidosDefinida.
  ///
  /// In pt, this message translates to:
  /// **'Pasta de destino definida.'**
  String get pastaRecebidosDefinida;

  /// No description provided for @pastaRecebidosRemovida.
  ///
  /// In pt, this message translates to:
  /// **'Pasta de destino removida.'**
  String get pastaRecebidosRemovida;

  /// No description provided for @removerPastaRecebidos.
  ///
  /// In pt, this message translates to:
  /// **'Remover pasta de destino'**
  String get removerPastaRecebidos;

  /// No description provided for @abaPastas.
  ///
  /// In pt, this message translates to:
  /// **'Pastas'**
  String get abaPastas;

  /// No description provided for @abaComputadores.
  ///
  /// In pt, this message translates to:
  /// **'Computadores'**
  String get abaComputadores;

  /// No description provided for @adicionarPasta.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar pasta'**
  String get adicionarPasta;

  /// No description provided for @nomeDaPasta.
  ///
  /// In pt, this message translates to:
  /// **'Nome da pasta'**
  String get nomeDaPasta;

  /// No description provided for @escolherPasta.
  ///
  /// In pt, this message translates to:
  /// **'Escolher pasta'**
  String get escolherPasta;

  /// No description provided for @usarEstaPasta.
  ///
  /// In pt, this message translates to:
  /// **'Usar esta pasta'**
  String get usarEstaPasta;

  /// No description provided for @caminhoDaPasta.
  ///
  /// In pt, this message translates to:
  /// **'Caminho'**
  String get caminhoDaPasta;

  /// No description provided for @tipoPasta.
  ///
  /// In pt, this message translates to:
  /// **'Tipo'**
  String get tipoPasta;

  /// No description provided for @tipoEnviarReceber.
  ///
  /// In pt, this message translates to:
  /// **'Enviar e receber'**
  String get tipoEnviarReceber;

  /// No description provided for @tipoSomenteEnviar.
  ///
  /// In pt, this message translates to:
  /// **'Somente enviar'**
  String get tipoSomenteEnviar;

  /// No description provided for @tipoSomenteReceber.
  ///
  /// In pt, this message translates to:
  /// **'Somente receber'**
  String get tipoSomenteReceber;

  /// No description provided for @pausarPasta.
  ///
  /// In pt, this message translates to:
  /// **'Pausar'**
  String get pausarPasta;

  /// No description provided for @compartilharCom.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar com'**
  String get compartilharCom;

  /// No description provided for @compartilhadaCom.
  ///
  /// In pt, this message translates to:
  /// **'dispositivo(s)'**
  String get compartilhadaCom;

  /// No description provided for @excluir.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get excluir;

  /// No description provided for @excluirPastaTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Excluir pasta'**
  String get excluirPastaTitulo;

  /// No description provided for @excluirPastaMensagem.
  ///
  /// In pt, this message translates to:
  /// **'Isso remove a pasta da sincronização (os arquivos não são apagados). Continuar?'**
  String get excluirPastaMensagem;

  /// No description provided for @meuIdTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Meu ID neste aparelho'**
  String get meuIdTitulo;

  /// No description provided for @copiarId.
  ///
  /// In pt, this message translates to:
  /// **'Copiar ID'**
  String get copiarId;

  /// No description provided for @idCopiado.
  ///
  /// In pt, this message translates to:
  /// **'ID copiado.'**
  String get idCopiado;

  /// No description provided for @mostrarQr.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar QR'**
  String get mostrarQr;

  /// No description provided for @adicionarComputador.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar computador'**
  String get adicionarComputador;

  /// No description provided for @colarIdDispositivo.
  ///
  /// In pt, this message translates to:
  /// **'Device ID do computador'**
  String get colarIdDispositivo;

  /// No description provided for @nomeDoComputador.
  ///
  /// In pt, this message translates to:
  /// **'Nome do computador'**
  String get nomeDoComputador;

  /// No description provided for @escanearQr.
  ///
  /// In pt, this message translates to:
  /// **'Escanear QR'**
  String get escanearQr;

  /// No description provided for @removerComputador.
  ///
  /// In pt, this message translates to:
  /// **'Remover computador'**
  String get removerComputador;

  /// No description provided for @renomear.
  ///
  /// In pt, this message translates to:
  /// **'Renomear'**
  String get renomear;

  /// No description provided for @nenhumComputador.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum computador adicionado.'**
  String get nenhumComputador;

  /// No description provided for @nenhumaPastaGerenciar.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma pasta. Toque em + para adicionar.'**
  String get nenhumaPastaGerenciar;

  /// No description provided for @idInvalido.
  ///
  /// In pt, this message translates to:
  /// **'Device ID inválido.'**
  String get idInvalido;

  /// No description provided for @faseVerificando.
  ///
  /// In pt, this message translates to:
  /// **'Verificando'**
  String get faseVerificando;

  /// No description provided for @fasePrecisaPermissao.
  ///
  /// In pt, this message translates to:
  /// **'Precisa de permissão'**
  String get fasePrecisaPermissao;

  /// No description provided for @faseIniciando.
  ///
  /// In pt, this message translates to:
  /// **'Iniciando'**
  String get faseIniciando;

  /// No description provided for @faseConectado.
  ///
  /// In pt, this message translates to:
  /// **'Conectado'**
  String get faseConectado;

  /// No description provided for @faseParado.
  ///
  /// In pt, this message translates to:
  /// **'Parado'**
  String get faseParado;

  /// No description provided for @faseErro.
  ///
  /// In pt, this message translates to:
  /// **'Erro'**
  String get faseErro;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
