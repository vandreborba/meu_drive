package com.vandreapps.meu_drive

import android.content.Context

/**
 * Guarda a pasta escolhida pelo usuário para os arquivos recebidos via
 * "Compartilhar" (ACTION_SEND). É lida tanto pela [CompartilharActivity] quanto
 * pela [MainActivity] (canal do Flutter).
 */
object PreferenciasCompartilhamento {
    private const val ARQUIVO = "meu_drive_prefs"
    private const val CHAVE_PASTA = "pasta_compartilhamento"

    /** Caminho da pasta de destino, ou `null` se o usuário ainda não escolheu. */
    fun ler(context: Context): String? =
        context.getSharedPreferences(ARQUIVO, Context.MODE_PRIVATE)
            .getString(CHAVE_PASTA, null)

    /** Define (ou remove, com `null`/vazio) a pasta de destino. */
    fun definir(context: Context, caminho: String?) {
        context.getSharedPreferences(ARQUIVO, Context.MODE_PRIVATE).edit().apply {
            if (caminho.isNullOrBlank()) remove(CHAVE_PASTA) else putString(CHAVE_PASTA, caminho)
        }.apply()
    }
}
