package com.vandreapps.meu_drive

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.OpenableColumns
import android.util.Log
import android.widget.Toast
import androidx.core.content.IntentCompat
import java.io.File
import java.io.FileOutputStream

/**
 * Recebe arquivos enviados por "Compartilhar" de outros apps e salva na pasta
 * escolhida pelo usuário (ver [PreferenciasCompartilhamento]).
 *
 * A tela é transparente e não mostra interface: copia direto e avisa por Toast.
 * Se nenhuma pasta foi definida, abre o Meu Drive para o usuário configurar.
 */
class CompartilharActivity : Activity() {

    private val tag = "MeuDriveCompartilhar"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val destino = PreferenciasCompartilhamento.ler(this)
        if (destino.isNullOrBlank()) {
            avisar(getString(R.string.compartilhar_defina_pasta))
            abrirApp()
            finish()
            return
        }
        val uris = urisCompartilhadas(intent)
        if (uris.isEmpty()) {
            avisar(getString(R.string.compartilhar_nada_para_salvar))
            finish()
            return
        }
        val pasta = File(destino)
        if (!pasta.exists() && !pasta.mkdirs()) {
            Log.w(tag, "Não foi possível criar a pasta de destino: $destino")
            avisar(getString(R.string.compartilhar_pasta_indisponivel))
            finish()
            return
        }
        var salvos = 0
        for (uri in uris) {
            if (copiar(uri, pasta) != null) salvos++
        }
        if (salvos == 0) {
            avisar(getString(R.string.compartilhar_falhou))
        } else {
            val nomePasta = pasta.name
            val texto = resources.getQuantityString(
                R.plurals.compartilhar_salvo,
                salvos,
                salvos,
                nomePasta,
            )
            avisar(texto)
            iniciarMotor()
        }
        finish()
    }

    /** Lista de URIs do intent (um arquivo ou vários). */
    private fun urisCompartilhadas(intent: Intent?): List<Uri> {
        intent ?: return emptyList()
        return when (intent.action) {
            Intent.ACTION_SEND -> listOfNotNull(
                IntentCompat.getParcelableExtra(intent, Intent.EXTRA_STREAM, Uri::class.java)
            )
            Intent.ACTION_SEND_MULTIPLE -> IntentCompat.getParcelableArrayListExtra(
                intent,
                Intent.EXTRA_STREAM,
                Uri::class.java,
            ) ?: emptyList()
            else -> emptyList()
        }
    }

    /** Copia um URI compartilhado para a pasta, com nome único. Devolve o nome. */
    private fun copiar(uri: Uri, pasta: File): String? {
        return try {
            val nome = nomeExibicao(uri) ?: "arquivo_${System.currentTimeMillis()}"
            val arquivo = nomeUnico(pasta, nome)
            contentResolver.openInputStream(uri)?.use { entrada ->
                FileOutputStream(arquivo).use { saida -> entrada.copyTo(saida) }
            } ?: return null
            Log.i(tag, "Arquivo salvo em ${arquivo.absolutePath}")
            arquivo.name
        } catch (e: Exception) {
            Log.w(tag, "Falha ao copiar $uri: $e")
            null
        }
    }

    /** Nome de exibição do arquivo compartilhado. */
    private fun nomeExibicao(uri: Uri): String? {
        if (uri.scheme == "file") return uri.lastPathSegment
        try {
            contentResolver.query(
                uri,
                arrayOf(OpenableColumns.DISPLAY_NAME),
                null,
                null,
                null,
            )?.use { cursor ->
                val coluna = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (coluna >= 0 && cursor.moveToFirst()) return cursor.getString(coluna)
            }
        } catch (e: Exception) {
            Log.w(tag, "Falha ao ler o nome de $uri: $e")
        }
        return uri.lastPathSegment?.substringAfterLast('/')
    }

    /** Evita sobrescrever: acrescenta " (1)", " (2)" antes da extensão. */
    private fun nomeUnico(pasta: File, nome: String): File {
        var arquivo = File(pasta, nome)
        if (!arquivo.exists()) return arquivo
        val ponto = nome.lastIndexOf('.')
        val base = if (ponto > 0) nome.substring(0, ponto) else nome
        val extensao = if (ponto > 0) nome.substring(ponto) else ""
        var contador = 1
        while (arquivo.exists()) {
            arquivo = File(pasta, "$base ($contador)$extensao")
            contador++
        }
        return arquivo
    }

    /** Acorda o motor para sincronizar o arquivo recebido logo em seguida. */
    private fun iniciarMotor() {
        try {
            MotorService.iniciar(this)
        } catch (e: Exception) {
            Log.w(tag, "Não foi possível iniciar o motor agora: $e")
        }
    }

    private fun abrirApp() {
        try {
            val intent = Intent(this, MainActivity::class.java)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            startActivity(intent)
        } catch (e: Exception) {
            Log.w(tag, "Falha ao abrir o app: $e")
        }
    }

    private fun avisar(texto: String) {
        Toast.makeText(this, texto, Toast.LENGTH_LONG).show()
    }
}
