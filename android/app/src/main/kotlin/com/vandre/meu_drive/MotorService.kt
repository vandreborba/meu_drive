package com.vandre.meu_drive

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.ConnectivityManager
import android.net.LinkProperties
import android.net.Network
import android.net.RouteInfo
import android.net.wifi.WifiManager
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader
import java.net.Inet4Address
import java.net.InetAddress

/**
 * Serviço em primeiro plano que executa o motor de sincronização (Syncthing)
 * embutido no app.
 *
 * O binário é empacotado em `jniLibs/libsyncthing.so` e executado a partir de
 * `nativeLibraryDir` (o Android/SELinux bloqueia executar de `filesDir`).
 * A pasta de configuração é o `filesDir` do app, o mesmo layout usado pelo
 * Syncthing-Fork — o que facilita importar a configuração existente.
 */
class MotorService : Service() {

    companion object {
        private const val TAG = "MeuDriveMotorSvc"
        private const val CANAL_ID = "meu_drive_motor"
        private const val NOTIF_ID = 42

        /** Indica se o motor está rodando (lido pelo canal nativo). */
        @Volatile
        var rodando: Boolean = false
            private set

        fun iniciar(context: Context) {
            val intent = Intent(context, MotorService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun parar(context: Context) {
            context.stopService(Intent(context, MotorService::class.java))
        }
    }

    private var processo: Process? = null
    private var threadMotor: Thread? = null
    private var multicastLock: WifiManager.MulticastLock? = null

    /** Arquivo com a saída do motor, exibido no diagnóstico do app. */
    private val arquivoLog: File
        get() = File(filesDir, "motor.log")

    private fun registrar(texto: String) {
        try {
            if (arquivoLog.length() > 512 * 1024) arquivoLog.delete()
            arquivoLog.appendText(texto + "\n")
        } catch (_: Exception) {
        }
    }

    @Volatile
    private var parando = false

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        criarCanalNotificacao()
        registrar("Serviço criado")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        registrar("onStartCommand recebido")
        try {
            promoverParaForeground()
        } catch (e: Exception) {
            Log.e(TAG, "Falha ao promover para foreground", e)
            registrar("Falha ao promover para foreground: $e")
        }
        if (threadMotor?.isAlive != true) {
            parando = false
            adquirirMulticastLock()
            threadMotor = Thread { lacoDoMotor() }.also { it.start() }
        }
        rodando = true
        Log.i(TAG, "Motor iniciado")
        registrar("Motor iniciado")
        return START_STICKY
    }

    override fun onDestroy() {
        Log.i(TAG, "Motor parando")
        registrar("Serviço destruído")
        parando = true
        try {
            processo?.destroy()
        } catch (_: Exception) {
        }
        processo = null
        liberarMulticastLock()
        rodando = false
        super.onDestroy()
    }

    // ==================== EXECUÇÃO DO MOTOR ====================

    private fun lacoDoMotor() {
        while (!parando) {
            try {
                executarMotor()
            } catch (e: Exception) {
                Log.e(TAG, "Falha ao executar o motor", e)
                registrar("Falha ao executar o motor: $e")
            }
            if (parando) break
            // Reinicia se o motor sair sozinho — é o que resolve o "fecha sozinho".
            try {
                Thread.sleep(3000)
            } catch (_: InterruptedException) {
                break
            }
        }
    }

    private fun executarMotor() {
        val binario = File(applicationInfo.nativeLibraryDir, "libsyncthing.so")
        if (!binario.exists()) {
            Log.e(TAG, "Binário do motor ausente em ${binario.absolutePath}")
            registrar("Binário do motor ausente em ${binario.absolutePath}")
            return
        }

        val home = filesDir
        val builder = ProcessBuilder(
            binario.absolutePath,
            "serve",
            "--no-browser",
            "--home=${home.absolutePath}",
        )
        builder.redirectErrorStream(true)
        val ambiente = builder.environment()
        ambiente["HOME"] = home.absolutePath
        ambiente["STHOMEDIR"] = home.absolutePath
        ambiente["STNOUPGRADE"] = "1"
        ambiente["STMONITORED"] = "1"
        ambiente["STVERSIONEXTRA"] = "Meu Drive"
        ambiente["SQLITE_TMPDIR"] = cacheDir.absolutePath
        ambiente["GOGC"] = "100"
        getGatewayIpV4()?.let { ambiente["FALLBACK_NET_GATEWAY_IPV4"] = it }

        Log.i(TAG, "Executando ${binario.absolutePath} (home=${home.absolutePath})")
        registrar("Executando ${binario.absolutePath} (home=${home.absolutePath})")
        val p = builder.start()
        processo = p

        BufferedReader(InputStreamReader(p.inputStream)).use { leitor ->
            var linha = leitor.readLine()
            while (linha != null) {
                Log.i("MeuDriveSyncthing", linha)
                registrar(linha)
                linha = leitor.readLine()
            }
        }

        val codigo = p.waitFor()
        Log.i(TAG, "Motor saiu com código $codigo")
        registrar("Motor saiu com código $codigo")
        processo = null
    }

    // ==================== NOTIFICAÇÃO EM PRIMEIRO PLANO ====================

    private fun criarCanalNotificacao() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val canal = NotificationChannel(
            CANAL_ID,
            getString(R.string.app_name),
            NotificationManager.IMPORTANCE_LOW,
        )
        canal.description = "Mantém a sincronização de arquivos ativa."
        val gerente = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        gerente.createNotificationChannel(canal)
    }

    private fun construirNotificacao(): Notification {
        val abrir = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        return NotificationCompat.Builder(this, CANAL_ID)
            .setContentTitle(getString(R.string.app_name))
            .setContentText(getString(R.string.motor_sincronizando))
            .setSmallIcon(android.R.drawable.stat_notify_sync)
            .setContentIntent(abrir)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun promoverParaForeground() {
        val notificacao = construirNotificacao()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(NOTIF_ID, notificacao, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(NOTIF_ID, notificacao)
        }
    }

    // ==================== MULTICAST (DESCOBERTA LOCAL) ====================

    private fun adquirirMulticastLock() {
        try {
            val wifi = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            multicastLock = wifi.createMulticastLock("meuDriveMulticast").apply {
                setReferenceCounted(true)
                acquire()
            }
        } catch (e: Exception) {
            Log.w(TAG, "Falha ao adquirir MulticastLock", e)
        }
    }

    private fun liberarMulticastLock() {
        try {
            multicastLock?.release()
        } catch (_: Exception) {
        }
        multicastLock = null
    }

    private fun getGatewayIpV4(): String? {
        return try {
            val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val rede: Network = cm.activeNetwork ?: return null
            val props: LinkProperties = cm.getLinkProperties(rede) ?: return null
            for (rota: RouteInfo in props.routes) {
                val gateway: InetAddress = rota.gateway ?: continue
                if (rota.isDefaultRoute && gateway is Inet4Address) {
                    return gateway.hostAddress
                }
            }
            null
        } catch (_: Exception) {
            null
        }
    }
}
