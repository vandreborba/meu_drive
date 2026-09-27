package com.vandreapps.meu_drive

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.StatFs
import android.provider.Settings
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.zip.ZipEntry
import java.util.zip.ZipFile
import java.util.zip.ZipOutputStream

/**
 * Ponte nativa entre o Flutter e o motor de sincronização.
 *
 * O motor (Syncthing) é embutido no app e executado pelo [MotorService].
 * Expoe: iniciar/parar o motor, importar a configuração do Syncthing-Fork,
 * pedir notificações e gerenciar a permissão "Todos os arquivos".
 */
class MainActivity : FlutterActivity() {

    private val canal = "meu_drive/motor"
    private val tag = "MeuDriveMotor"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, canal).setMethodCallHandler { chamada, resultado ->
            when (chamada.method) {
                "iniciarMotor" -> {
                    MotorService.iniciar(this)
                    resultado.success(true)
                }
                "pararMotor" -> {
                    MotorService.parar(this)
                    resultado.success(true)
                }
                "motorRodando" -> resultado.success(MotorService.rodando)
                "importarConfigMotor" -> {
                    val forcar = chamada.argument<Boolean>("forcar") ?: false
                    resultado.success(importarConfigMotor(forcar))
                }
                "exportarConfigMotor" -> resultado.success(exportarConfigMotor())
                "lerApiKeyMotor" -> resultado.success(lerApiKeyMotor())
                "lerLogMotor" -> resultado.success(lerLogMotor())
                "lerConfigMotor" -> resultado.success(lerConfigMotor())
                "temTodosArquivos" -> resultado.success(temTodosArquivos())
                "pedirTodosArquivos" -> {
                    pedirTodosArquivos()
                    resultado.success(true)
                }
                "pedirNotificacoes" -> {
                    pedirNotificacoes()
                    resultado.success(true)
                }
                "espacoArmazenamento" -> resultado.success(espacoArmazenamento())
                "podeInstalarApks" -> resultado.success(podeInstalarApks())
                "pedirPermissaoInstalar" -> {
                    pedirPermissaoInstalar()
                    resultado.success(true)
                }
                else -> resultado.notImplemented()
            }
        }
    }

    /**
     * Importa a configuração exportada pelo Syncthing-Fork (config.xml + chaves),
     * preservando o mesmo device ID. O arquivo padrão de exportação fica em
     * /storage/emulated/0/backups/syncthing/config.zip.
     */
    private fun importarConfigMotor(forcar: Boolean): Boolean {
        val destino = filesDir
        val jaTemConfig = File(destino, "config.xml").exists()
        if (jaTemConfig && !forcar) {
            Log.d(tag, "Importação ignorada: já existe config.xml")
            return false
        }
        val zip = File(Environment.getExternalStorageDirectory(), "backups/syncthing/config.zip")
        if (!zip.exists()) {
            Log.d(tag, "Importação: ${zip.absolutePath} não encontrado")
            return false
        }
        if (forcar) {
            // Troca de identidade: remove config, chaves e banco antigos.
            listOf("config.xml", "cert.pem", "key.pem", "index-v0.14.0.db").forEach {
                File(destino, it).delete()
            }
            File(destino, "index-v2").deleteRecursively()
        }
        return try {
            ZipFile(zip).use { arquivo ->
                for (nome in listOf(
                    "config.xml",
                    "cert.pem",
                    "key.pem",
                    "https-cert.pem",
                    "https-key.pem",
                )) {
                    val entrada = arquivo.getEntry(nome) ?: continue
                    arquivo.getInputStream(entrada).use { entradaStream ->
                        File(destino, nome).outputStream().use { saida ->
                            entradaStream.copyTo(saida)
                        }
                    }
                }
            }
            Log.i(tag, "Configuração importada de ${zip.absolutePath}")
            true
        } catch (e: Exception) {
            Log.w(tag, "Falha ao importar configuração: $e")
            false
        }
    }

    /** Exporta config.xml e chaves para backups/syncthing/config.zip. */
    private fun exportarConfigMotor(): String? {
        return try {
            val destino = File(Environment.getExternalStorageDirectory(), "backups/syncthing")
            if (!destino.exists()) destino.mkdirs()
            val zip = File(destino, "config.zip")
            ZipOutputStream(zip.outputStream().buffered()).use { saida ->
                for (nome in listOf(
                    "config.xml",
                    "cert.pem",
                    "key.pem",
                    "https-cert.pem",
                    "https-key.pem",
                )) {
                    val arquivo = File(filesDir, nome)
                    if (arquivo.exists()) {
                        saida.putNextEntry(ZipEntry(nome))
                        arquivo.inputStream().use { it.copyTo(saida) }
                        saida.closeEntry()
                    }
                }
            }
            Log.i(tag, "Configuração exportada para ${zip.absolutePath}")
            zip.absolutePath
        } catch (e: Exception) {
            Log.w(tag, "Falha ao exportar configuração: $e")
            null
        }
    }

    /**
     * Lê do config.xml o endereço do GUI (host:porta), o uso de TLS e a API key.
     * O Syncthing-Fork pode gravar uma porta aleatória, então não dá para assumir 8384.
     */
    private fun lerConfigMotor(): Map<String, Any?>? {
        return try {
            val arquivo = File(filesDir, "config.xml")
            if (!arquivo.exists()) return null
            val texto = arquivo.readText()
            val blocoGui = Regex("<gui[^>]*>.*?</gui>", setOf(RegexOption.DOT_MATCHES_ALL))
                .find(texto)?.value
            val endereco = blocoGui
                ?.let { Regex("<address>([^<]+)</address>").find(it)?.groupValues?.get(1) }
                ?.trim()
            val tls = blocoGui
                ?.let { Regex("tls=\"(true|false)\"").find(it)?.groupValues?.get(1)?.toBoolean() }
                ?: false
            val apiKey = Regex("<apikey>([^<]+)</apikey>")
                .find(texto)?.groupValues?.get(1)?.trim()
            mapOf("endereco" to endereco, "tls" to tls, "apiKey" to apiKey)
        } catch (e: Exception) {
            Log.w(tag, "Falha ao ler a config do motor: $e")
            null
        }
    }

    /** Devolve as últimas linhas do log do motor (arquivo em filesDir). */
    private fun lerLogMotor(): String {
        return try {
            val arquivo = File(filesDir, "motor.log")
            if (!arquivo.exists()) "" else arquivo.readLines().takeLast(80).joinToString("\n")
        } catch (e: Exception) {
            Log.w(tag, "Falha ao ler o log do motor: $e")
            ""
        }
    }

    /** Lê a API key do config.xml do motor (permite chamar o REST sem CSRF). */
    private fun lerApiKeyMotor(): String? {
        return try {
            val texto = File(filesDir, "config.xml").readText()
            Regex("<apikey>([^<]+)</apikey>").find(texto)?.groupValues?.get(1)?.trim()
        } catch (e: Exception) {
            Log.w(tag, "Falha ao ler a API key do motor: $e")
            null
        }
    }

    private fun temTodosArquivos(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Environment.isExternalStorageManager()
        } else {
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.READ_EXTERNAL_STORAGE
            ) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun pedirTodosArquivos() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            try {
                val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION)
                intent.data = Uri.parse("package:$packageName")
                startActivity(intent)
            } catch (_: Exception) {
                startActivity(Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION))
            }
        } else {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(
                    Manifest.permission.READ_EXTERNAL_STORAGE,
                    Manifest.permission.WRITE_EXTERNAL_STORAGE
                ),
                101
            )
        }
    }

    /** Espaço total e livre do armazenamento (em bytes). */
    private fun espacoArmazenamento(): Map<String, Long> {
        fun ler(caminho: String): Map<String, Long> {
            val stat = StatFs(caminho)
            return mapOf(
                "total" to stat.blockCountLong * stat.blockSizeLong,
                "livre" to stat.availableBlocksLong * stat.blockSizeLong,
            )
        }
        return try {
            ler(Environment.getExternalStorageDirectory().path)
        } catch (e: Exception) {
            Log.w(tag, "Falha ao ler espaço externo: $e")
            try {
                ler(Environment.getDataDirectory().path)
            } catch (e2: Exception) {
                emptyMap()
            }
        }
    }

    /** Se o app pode instalar APKs (origens desconhecidas). */
    private fun podeInstalarApks(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            packageManager.canRequestPackageInstalls()
        } else {
            true
        }
    }

    /** Abre a tela para permitir "instalar apps desconhecidos" para este app. */
    private fun pedirPermissaoInstalar() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        try {
            val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES)
            intent.data = Uri.parse("package:$packageName")
            startActivity(intent)
        } catch (e: Exception) {
            Log.w(tag, "Falha ao abrir permissão de instalação: $e")
        }
    }

    private fun pedirNotificacoes() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS)
                != PackageManager.PERMISSION_GRANTED
            ) {
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                    102
                )
            }
        }
    }
}
