/// Utilitários de espaçamento da interface.
library;

import 'package:flutter/widgets.dart';

/// Espaço a reservar no rodapé de listas roláveis para que os botões de
/// navegação do sistema (gesto ou três botões) não cubram o conteúdo.
double espacoInferiorSistema(BuildContext context) =>
    MediaQuery.viewPaddingOf(context).bottom;
