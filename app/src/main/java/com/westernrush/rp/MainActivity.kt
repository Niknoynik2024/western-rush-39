package com.westernrush.rp

import android.app.Activity
import android.animation.ValueAnimator
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Intent
import android.graphics.*
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.view.animation.LinearInterpolator
import android.widget.*
import android.app.DownloadManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.IntentFilter
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

class MainActivity : Activity() {
    private val gold = Color.rgb(255, 166, 0)
    private val serverAddress = "88.119.171.76:7777"
    private lateinit var nickname: EditText
    private var pendingUpdateDownload = -1L
    private val updateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action != DownloadManager.ACTION_DOWNLOAD_COMPLETE) return
            val id = intent.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID, -1L)
            if (id != pendingUpdateDownload) return
            val manager = getSystemService(DOWNLOAD_SERVICE) as DownloadManager
            manager.query(DownloadManager.Query().setFilterById(id)).use { cursor ->
                if (cursor != null && cursor.moveToFirst()) {
                    val status = cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS))
                    if (status == DownloadManager.STATUS_SUCCESSFUL) {
                        val apkUri = manager.getUriForDownloadedFile(id)
                        if (apkUri != null) {
                            val install = Intent(Intent.ACTION_VIEW).apply {
                                setDataAndType(apkUri, "application/vnd.android.package-archive")
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }
                            startActivity(install)
                        } else toast("APK загружен, но Android не вернул файл установки")
                    } else toast("Не удалось загрузить обновление. Проверь интернет и повтори попытку.")
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestedOrientation = android.content.pm.ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE
        window.statusBarColor = Color.rgb(8, 10, 14)
        window.navigationBarColor = Color.rgb(8, 10, 14)

        val frame = FrameLayout(this)
        frame.addView(KaliningradBackdropView(), FrameLayout.LayoutParams(-1, -1))

        val page = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(20), dp(10), dp(20), dp(6))
        }
        frame.addView(page, FrameLayout.LayoutParams(-1, -1))

        val header = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        header.addView(label("WESTERN RUSH RP", 15, Color.WHITE, true), LinearLayout.LayoutParams(0, -2, 1f))
        header.addView(label("ИГРАЙ. ОБЩАЙСЯ. РАЗВИВАЙСЯ.", 11, gold, true))
        header.addView(roundButton("⚙", 38) { showSettings() })
        header.addView(roundButton("i", 38) { showAbout() })
        page.addView(header, LinearLayout.LayoutParams(-1, dp(42)))

        val main = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        page.addView(main, LinearLayout.LayoutParams(-1, 0, 1f))

        val left = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(8), dp(2), dp(18), dp(2))
        }
        main.addView(left, LinearLayout.LayoutParams(0, -1, 1.12f))
        left.addView(label("♛", 36, gold, true).apply { gravity = Gravity.CENTER })
        left.addView(label("WESTERN", 39, Color.WHITE, true).apply {
            gravity = Gravity.CENTER
            typeface = Typeface.create("sans-serif-condensed", Typeface.BOLD)
            letterSpacing = -0.03f
        })
        left.addView(label("RUSH RP", 43, gold, true).apply {
            gravity = Gravity.CENTER
            typeface = Typeface.create("sans-serif-black", Typeface.BOLD_ITALIC)
        })
        left.addView(label("M O B I L E", 15, Color.WHITE, true).apply {
            gravity = Gravity.CENTER
            setPadding(dp(14), dp(3), dp(14), dp(3))
            background = rounded(Color.rgb(185, 103, 0), 5)
        }, LinearLayout.LayoutParams(-2, -2).apply { topMargin = dp(3) })
        left.addView(label("КАЛИНИНГРАД", 18, Color.WHITE, false).apply {
            gravity = Gravity.CENTER
            typeface = Typeface.create("cursive", Typeface.ITALIC)
        }, LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(9) })
        left.addView(label("ТВОЙ ГОРОД. ТВОЯ ИСТОРИЯ.", 9, Color.LTGRAY, true).apply {
            gravity = Gravity.CENTER
        }, LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(5) })

        val right = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(10), dp(4), dp(4), dp(4))
        }
        main.addView(right, LinearLayout.LayoutParams(0, -1, 0.88f))

        val server = card("ИГРОВОЙ СЕРВЕР")
        server.addView(label("Western Rush RP Mobile", 17, Color.WHITE, true))
        server.addView(label("●  СЕРВЕР ДОСТУПЕН ДЛЯ ПОДКЛЮЧЕНИЯ", 10, Color.rgb(105, 220, 90), true),
            LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(4) })
        val ipRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        ipRow.addView(label("IP:  $serverAddress", 14, Color.WHITE, true), LinearLayout.LayoutParams(0, -2, 1f))
        ipRow.addView(smallButton("КОПИРОВАТЬ") { copyIp() })
        server.addView(ipRow, LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(9) })
        server.addView(label("РЕЖИМ:  RolePlay", 11, Color.LTGRAY, false),
            LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(5) })
        right.addView(server, LinearLayout.LayoutParams(-1, -2))

        val player = card("ИГРОВОЙ НИК")
        nickname = EditText(this).apply {
            setSingleLine(true)
            textSize = 14f
            setTextColor(Color.WHITE)
            setHintTextColor(Color.GRAY)
            hint = "Введите никнейм..."
            setPadding(dp(12), 0, dp(12), 0)
            background = rounded(Color.rgb(18, 19, 23), 10, Color.rgb(105, 105, 105))
            setText(getSharedPreferences("western_rush", MODE_PRIVATE).getString("nickname", ""))
        }
        player.addView(nickname, LinearLayout.LayoutParams(-1, dp(44)))
        right.addView(player, LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(8) })

        val play = Button(this).apply {
            text = "▶    ИГРАТЬ    ››"
            textSize = 19f
            isAllCaps = false
            setTextColor(Color.rgb(35, 22, 5))
            typeface = Typeface.DEFAULT_BOLD
            background = GradientDrawable(
                GradientDrawable.Orientation.TOP_BOTTOM,
                intArrayOf(Color.rgb(255, 194, 40), Color.rgb(255, 137, 0))
            ).apply { cornerRadius = dp(15).toFloat(); setStroke(dp(2), Color.rgb(255, 213, 95)) }
        }
        right.addView(play, LinearLayout.LayoutParams(-1, dp(54)).apply { topMargin = dp(10) })
        play.setOnClickListener { saveNickname(); connect() }

        val nav = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            background = rounded(Color.argb(225, 9, 11, 15), 13, Color.rgb(80, 57, 28))
        }
        val navItems = listOf("⌂\nГлавная", "♙\nПрофиль", "▤\nСервер", "⟳\nОбновить", "⚙\nНастройки")
        navItems.forEachIndexed { index, item ->
            val itemView = label(item, 11, if (index == 0) gold else Color.LTGRAY, index == 0).apply {
                gravity = Gravity.CENTER
                setPadding(dp(6), dp(3), dp(6), dp(3))
                setOnClickListener {
                    when (index) {
                        0 -> toast("Вы на главной")
                        1 -> showProfile()
                        2 -> showServer()
                        3 -> checkUpdates()
                        4 -> showSettings()
                    }
                }
            }
            nav.addView(itemView, LinearLayout.LayoutParams(0, -1, 1f))
        }
        page.addView(nav, LinearLayout.LayoutParams(-1, dp(50)))
        setContentView(frame)
        registerReceiver(updateReceiver, IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE))
    }

    private fun card(title: String): LinearLayout {
        val box = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(13), dp(9), dp(13), dp(10))
            background = rounded(Color.argb(220, 12, 14, 18), 13, Color.argb(150, 180, 115, 35))
        }
        box.addView(label(title, 10, gold, true))
        return box
    }

    private fun label(value: String, size: Int, color: Int, bold: Boolean) = TextView(this).apply {
        text = value
        textSize = size.toFloat()
        setTextColor(color)
        if (bold) setTypeface(typeface, Typeface.BOLD)
        setShadowLayer(5f, 1f, 2f, Color.BLACK)
    }

    private fun roundButton(value: String, size: Int, action: () -> Unit) = TextView(this).apply {
        text = value
        textSize = 19f
        gravity = Gravity.CENTER
        setTextColor(Color.WHITE)
        background = rounded(Color.argb(180, 25, 27, 31), 40, Color.GRAY)
        setOnClickListener { action() }
        layoutParams = LinearLayout.LayoutParams(dp(size), dp(size)).apply { leftMargin = dp(7) }
    }

    private fun smallButton(value: String, action: () -> Unit) = TextView(this).apply {
        text = value
        textSize = 9f
        gravity = Gravity.CENTER
        setTextColor(gold)
        setPadding(dp(8), dp(7), dp(8), dp(7))
        background = rounded(Color.rgb(35, 28, 18), 8, gold)
        setOnClickListener { action() }
    }

    private fun rounded(color: Int, radius: Int, stroke: Int? = null) = GradientDrawable().apply {
        setColor(color)
        cornerRadius = dp(radius).toFloat()
        if (stroke != null) setStroke(dp(1), stroke)
    }

    private fun copyIp() {
        val clipboard = getSystemService(CLIPBOARD_SERVICE) as ClipboardManager
        clipboard.setPrimaryClip(ClipData.newPlainText("Server IP", serverAddress))
        toast("IP сервера скопирован")
    }

    private fun saveNickname() {
        getSharedPreferences("western_rush", MODE_PRIVATE).edit()
            .putString("nickname", nickname.text.toString().trim()).apply()
    }

    private fun connect() {
        copyIp()
        try {
            startActivity(Intent.createChooser(
                Intent(Intent.ACTION_VIEW, Uri.parse("samp://$serverAddress")),
                "Открыть совместимый SAMP Mobile клиент"
            ))
        } catch (_: Exception) {
            toast("IP скопирован. Добавьте сервер в SAMP Mobile вручную.")
        }
    }

    private fun showProfile() {
        val input = EditText(this).apply {
            hint = "Например, Ivanov_KLD"
            setSingleLine(true)
            setText(getSharedPreferences("western_rush", MODE_PRIVATE).getString("nickname", ""))
        }
        val wrap = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(22), dp(8), dp(22), 0)
            addView(label("Твой игровой никнейм", 12, Color.LTGRAY, false))
            addView(input)
        }
        android.app.AlertDialog.Builder(this)
            .setTitle("Профиль игрока")
            .setView(wrap)
            .setPositiveButton("СОХРАНИТЬ") { _, _ ->
                val value = input.text.toString().trim()
                if (value.isNotBlank()) {
                    getSharedPreferences("western_rush", MODE_PRIVATE).edit().putString("nickname", value).apply()
                    nickname.setText(value)
                    toast("Профиль сохранён: $value")
                } else toast("Введи игровой никнейм")
            }
            .setNegativeButton("ОТМЕНА", null)
            .show()
    }

    private fun showServer() {
        android.app.AlertDialog.Builder(this)
            .setTitle("Сервер Калининград RP")
            .setMessage("Western Rush RP Mobile\nАдрес: $serverAddress\nРежим: RolePlay")
            .setPositiveButton("КОПИРОВАТЬ IP") { _, _ -> copyIp() }
            .setNeutralButton("ГОТОВО", null)
            .show()
    }

    private fun checkUpdates() {
        toast("Проверяем обновления…")
        Thread {
            var connection: HttpURLConnection? = null
            try {
                connection = (URL("https://api.github.com/repos/Niknoynik2024/western-rush-39/releases/latest").openConnection() as HttpURLConnection).apply {
                    connectTimeout = 10000
                    readTimeout = 10000
                    setRequestProperty("Accept", "application/vnd.github+json")
                    setRequestProperty("User-Agent", "WesternRushRP-Android")
                }
                if (connection.responseCode == 404) {
                    runOnUiThread { showNoReleaseYet() }
                    return@Thread
                }
                if (connection.responseCode !in 200..299) throw IllegalStateException("HTTP " + connection.responseCode)
                val json = JSONObject(connection.inputStream.bufferedReader().use { it.readText() })
                val tag = json.optString("tag_name", "")
                val assets = json.optJSONArray("assets")
                var apkUrl: String? = null
                var apkName = "WesternRush-update.apk"
                if (assets != null) {
                    for (i in 0 until assets.length()) {
                        val asset = assets.getJSONObject(i)
                        val name = asset.optString("name")
                        if (name.endsWith(".apk", true)) {
                            apkUrl = asset.optString("browser_download_url")
                            apkName = name
                            break
                        }
                    }
                }
                val installed = packageManager.getPackageInfo(packageName, 0).versionName ?: "1.0"
                runOnUiThread {
                    if (apkUrl.isNullOrBlank()) {
                        android.app.AlertDialog.Builder(this)
                            .setTitle("Релиз найден: " + tag)
                            .setMessage("В релизе пока нет APK-файла. Добавь APK в Assets GitHub Release.")
                            .setPositiveButton("ПОНЯТНО", null).show()
                    } else if (tag.removePrefix("v") == installed.removePrefix("v")) {
                        toast("Установлена последняя версия: " + installed)
                    } else {
                        android.app.AlertDialog.Builder(this)
                            .setTitle("Доступно обновление " + tag)
                            .setMessage("Текущая версия: " + installed + "\nФайл: " + apkName + "\n\nСкачать APK и передать его установщику Android?")
                            .setPositiveButton("СКАЧАТЬ") { _, _ -> downloadLauncherUpdate(apkUrl!!, apkName) }
                            .setNegativeButton("ПОЗЖЕ", null).show()
                    }
                }
            } catch (e: Exception) {
                runOnUiThread { toast("Не удалось проверить обновления: " + (e.message ?: "ошибка сети")) }
            } finally {
                connection?.disconnect()
            }
        }.start()
    }

    private fun showNoReleaseYet() {
        android.app.AlertDialog.Builder(this)
            .setTitle("Обновлений пока нет")
            .setMessage("В GitHub ещё не опубликован Release с APK. Проверка обновлений подключена; публикация начнётся после загрузки подписанной сборки.")
            .setPositiveButton("ОТКРЫТЬ GITHUB") { _, _ ->
                startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://github.com/Niknoynik2024/western-rush-39/releases")))
            }
            .setNegativeButton("ЗАКРЫТЬ", null).show()
    }

    private fun downloadLauncherUpdate(url: String, fileName: String) {
        try {
            val request = DownloadManager.Request(Uri.parse(url)).apply {
                setTitle("Western Rush RP — обновление")
                setDescription("Загрузка " + fileName)
                setMimeType("application/vnd.android.package-archive")
                setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
                setAllowedOverMetered(true)
                setAllowedOverRoaming(false)
            }
            val manager = getSystemService(DOWNLOAD_SERVICE) as DownloadManager
            pendingUpdateDownload = manager.enqueue(request)
            toast("Загрузка обновления началась. Android попросит подтвердить установку.")
        } catch (e: Exception) {
            toast("Не удалось начать загрузку: " + (e.message ?: "ошибка"))
        }
    }


    private fun showSettings() {
        val prefs = getSharedPreferences("western_rush", MODE_PRIVATE)
        val sound = android.widget.CheckBox(this).apply {
            text = "Звуковые эффекты интерфейса"
            setTextColor(Color.WHITE)
            isChecked = prefs.getBoolean("ui_sounds", true)
        }
        val haptics = android.widget.CheckBox(this).apply {
            text = "Вибрация при нажатии"
            setTextColor(Color.WHITE)
            isChecked = prefs.getBoolean("haptics", false)
        }
        val wrap = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(22), dp(8), dp(22), 0)
            addView(sound)
            addView(haptics)
            addView(label("Игровой сервер: $serverAddress", 12, Color.LTGRAY, false))
        }
        android.app.AlertDialog.Builder(this)
            .setTitle("Настройки лаунчера")
            .setView(wrap)
            .setPositiveButton("СОХРАНИТЬ") { _, _ ->
                prefs.edit().putBoolean("ui_sounds", sound.isChecked)
                    .putBoolean("haptics", haptics.isChecked).apply()
                toast("Настройки сохранены")
            }
            .setNeutralButton("КОПИРОВАТЬ IP") { _, _ -> copyIp() }
            .setNegativeButton("ЗАКРЫТЬ", null)
            .show()
    }

    private fun showAbout() {
        android.app.AlertDialog.Builder(this)
            .setTitle("SAMP MOBILE RP")
            .setMessage("Western Rush RP • Калининград\nСервер: $serverAddress\nЛаунчер версии 1.0.0")
            .setPositiveButton("ПОНЯТНО", null)
            .show()
    }

    private fun toast(message: String) =
        Toast.makeText(this, message, Toast.LENGTH_LONG).show()

    override fun onDestroy() {
        try { unregisterReceiver(updateReceiver) } catch (_: Exception) { }
        super.onDestroy()
    }

    private fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()

    private inner class KaliningradBackdropView : View(this@MainActivity) {
        private val p = Paint(Paint.ANTI_ALIAS_FLAG)
        private var driveProgress = 0f
        private var wheelAngle = 0f
        init {
            ValueAnimator.ofFloat(0f, 1f).apply {
                duration = 9000L
                repeatCount = ValueAnimator.INFINITE
                interpolator = LinearInterpolator()
                addUpdateListener {
                    driveProgress = it.animatedValue as Float
                    wheelAngle = driveProgress * 1800f
                    invalidate()
                }
                start()
            }
        }
        override fun onDraw(canvas: Canvas) {
            super.onDraw(canvas)
            val w = width.toFloat()
            val h = height.toFloat()
            // Gentle camera drift and breathing zoom for a cinematic moving background
            val cameraSway = kotlin.math.sin(driveProgress * Math.PI * 2.0).toFloat() * dp(4)
            val cameraZoom = 1.012f + kotlin.math.sin(driveProgress * Math.PI * 2.0).toFloat() * 0.004f
            canvas.save()
            canvas.scale(cameraZoom, cameraZoom, w * 0.5f, h * 0.5f)
            canvas.translate(cameraSway, 0f)
            p.shader = LinearGradient(0f, 0f, w, h,
                intArrayOf(Color.rgb(18, 21, 38), Color.rgb(72, 47, 49), Color.rgb(7, 12, 18)),
                null, Shader.TileMode.CLAMP)
            canvas.drawRect(0f, 0f, w, h, p)
            p.shader = null

            // Twilight glow and distant city skyline
            p.color = Color.argb(65, 255, 142, 55)
            canvas.drawCircle(w * .46f, h * .48f, h * .43f, p)
            val ground = h * .67f
            p.color = Color.rgb(12, 18, 25)
            val buildings = floatArrayOf(.02f,.11f,.18f,.25f,.34f,.41f,.51f,.59f,.68f,.76f,.86f,.94f)
            buildings.forEachIndexed { i, x ->
                val bw = w * .045f
                val bh = h * (.14f + (i % 4) * .055f)
                canvas.drawRect(w*x, ground-bh, w*x+bw, ground, p)
                p.color = Color.argb(190, 255, 174, 75)
                for (r in 0..3) for (c in 0..2) {
                    canvas.drawRect(w*x+8+c*dp(9), ground-bh+8+r*dp(10),
                        w*x+12+c*dp(9), ground-bh+12+r*dp(10), p)
                }
                p.color = Color.rgb(12, 18, 25)
            }
            // Cathedral silhouette and clock tower
            p.color = Color.rgb(17, 18, 25)
            val cx = w * .62f
            val base = ground
            canvas.drawRect(cx-h*.11f, base-h*.27f, cx+h*.11f, base, p)
            val tower = Path().apply {
                moveTo(cx-h*.055f, base-h*.27f); lineTo(cx, base-h*.57f)
                lineTo(cx+h*.055f, base-h*.27f); close()
            }
            canvas.drawPath(tower, p)
            p.color = Color.rgb(255, 160, 55)
            canvas.drawCircle(cx, base-h*.34f, h*.018f, p)
            // River and reflections
            p.shader = LinearGradient(0f, ground, 0f, h, intArrayOf(Color.rgb(26,35,47), Color.rgb(5,9,14)), null, Shader.TileMode.CLAMP)
            canvas.drawRect(0f, ground, w, h, p)
            p.shader = null
            p.color = Color.argb(95, 255, 151, 56)
            for (i in 0..24) {
                val y = ground + (i * h * .012f)
                canvas.drawRect(w*.18f, y, w*(.35f + (i%4)*.06f), y+dp(1), p)
                canvas.drawRect(w*.58f, y+dp(3), w*(.73f+(i%3)*.04f), y+dp(4), p)
            }
            // Animated road reflections and passing light trails
            val roadY = h * .84f
            for (i in 0..9) {
                val lane = (i / 10f + driveProgress) % 1f
                val sx = lane * w
                val streakWidth = w * (0.025f + (i % 3) * 0.012f)
                p.color = Color.argb(65 + (i % 3) * 18, 255, 151, 64)
                canvas.drawRoundRect(sx, roadY + (i % 3) * dp(7), sx + streakWidth,
                    roadY + (i % 3) * dp(7) + dp(2), dp(2).toFloat(), dp(2).toFloat(), p)
            }

            // Fine diagonal rain catches the city lights as the camera moves
            p.style = Paint.Style.STROKE
            p.strokeWidth = dp(1).toFloat()
            for (i in 0..54) {
                val x = ((i * 73f + driveProgress * w * 0.7f) % (w + dp(30))) - dp(15)
                val y = ((i * 41f) % h)
                p.color = Color.argb(22 + (i % 4) * 7, 190, 208, 225)
                canvas.drawLine(x, y, x - dp(5), y + dp(13), p)
            }
            p.style = Paint.Style.FILL

            // Cinematic coupe driving through the night
            val carOffset = -0.50f + driveProgress * 1.48f
            canvas.save()
            canvas.translate(w * carOffset, 0f)
            val carY = h * .79f
            val carLeft = w * .035f
            val carRight = w * .475f

            // Soft amber headlight cone and road glow
            val beam = Path().apply {
                moveTo(w * .445f, carY - h * .055f)
                lineTo(w * .88f, carY + h * .10f)
                lineTo(w * .88f, carY + h * .19f)
                lineTo(w * .43f, carY + h * .005f)
                close()
            }
            p.shader = LinearGradient(w * .44f, carY, w * .86f, carY + h * .13f,
                intArrayOf(Color.argb(105, 255, 221, 153), Color.argb(0, 255, 164, 48)),
                null, Shader.TileMode.CLAMP)
            canvas.drawPath(beam, p)
            p.shader = null

            // Ground shadow
            p.color = Color.argb(155, 0, 0, 0)
            canvas.drawOval(w * .045f, carY - h * .012f, w * .49f, carY + h * .045f, p)

            // Lower chassis and sculpted body with metallic gradient
            val body = Path().apply {
                moveTo(carLeft, carY - h * .018f)
                lineTo(w * .065f, carY - h * .067f)
                quadTo(w * .105f, carY - h * .083f, w * .155f, carY - h * .087f)
                lineTo(w * .205f, carY - h * .132f)
                quadTo(w * .225f, carY - h * .145f, w * .265f, carY - h * .145f)
                lineTo(w * .345f, carY - h * .133f)
                quadTo(w * .375f, carY - h * .126f, w * .405f, carY - h * .082f)
                lineTo(w * .455f, carY - h * .054f)
                lineTo(carRight, carY - h * .018f)
                lineTo(w * .465f, carY + h * .006f)
                lineTo(w * .055f, carY + h * .006f)
                close()
            }
            p.shader = LinearGradient(0f, carY - h * .15f, 0f, carY + h * .01f,
                intArrayOf(Color.rgb(80, 91, 105), Color.rgb(20, 27, 36), Color.rgb(3, 5, 9)),
                null, Shader.TileMode.CLAMP)
            canvas.drawPath(body, p)
            p.shader = null

            // Window glass, pillars and roofline
            val glass = Path().apply {
                moveTo(w * .105f, carY - h * .077f)
                lineTo(w * .207f, carY - h * .128f)
                quadTo(w * .222f, carY - h * .137f, w * .255f, carY - h * .136f)
                lineTo(w * .285f, carY - h * .134f)
                lineTo(w * .285f, carY - h * .079f)
                close()
                moveTo(w * .298f, carY - h * .134f)
                lineTo(w * .342f, carY - h * .126f)
                quadTo(w * .367f, carY - h * .119f, w * .389f, carY - h * .078f)
                lineTo(w * .298f, carY - h * .079f)
                close()
            }
            p.color = Color.rgb(8, 17, 27)
            canvas.drawPath(glass, p)
            p.color = Color.argb(130, 142, 174, 196)
            p.style = Paint.Style.STROKE
            p.strokeWidth = dp(1).toFloat()
            canvas.drawLine(w * .112f, carY - h * .073f, w * .205f, carY - h * .123f, p)
            canvas.drawLine(w * .294f, carY - h * .128f, w * .294f, carY - h * .078f, p)
            p.style = Paint.Style.FILL

            // Body highlights, side crease, door and handle
            p.color = Color.argb(170, 205, 218, 230)
            p.strokeWidth = (1.2f * resources.displayMetrics.density)
            p.style = Paint.Style.STROKE
            canvas.drawLine(w * .075f, carY - h * .059f, w * .425f, carY - h * .057f, p)
            canvas.drawLine(w * .30f, carY - h * .068f, w * .30f, carY - h * .012f, p)
            p.color = Color.rgb(180, 188, 195)
            canvas.drawLine(w * .325f, carY - h * .066f, w * .35f, carY - h * .066f, p)
            p.style = Paint.Style.FILL

            // Detailed alloy wheels, rotating spokes and brake hubs
            for (wheelX in floatArrayOf(.145f, .375f)) {
                val wx = w * wheelX
                val wy = carY - h * .004f
                val radius = h * .043f
                p.color = Color.argb(210, 0, 0, 0)
                canvas.drawCircle(wx, wy, radius * 1.18f, p)
                p.color = Color.rgb(13, 16, 20)
                canvas.drawCircle(wx, wy, radius, p)
                p.color = Color.rgb(166, 177, 187)
                p.style = Paint.Style.STROKE
                p.strokeWidth = dp(2).toFloat()
                canvas.drawCircle(wx, wy, radius * .79f, p)
                canvas.save()
                canvas.rotate(wheelAngle, wx, wy)
                p.color = Color.rgb(205, 214, 222)
                p.strokeWidth = (1.6f * resources.displayMetrics.density)
                for (spoke in 0..9) {
                    val angle = Math.toRadians((spoke * 36).toDouble())
                    val px = wx + (kotlin.math.cos(angle) * radius * .72).toFloat()
                    val py = wy + (kotlin.math.sin(angle) * radius * .72).toFloat()
                    canvas.drawLine(wx, wy, px, py, p)
                }
                canvas.restore()
                p.style = Paint.Style.FILL
                p.color = Color.rgb(72, 82, 92)
                canvas.drawCircle(wx, wy, radius * .28f, p)
                p.color = Color.rgb(205, 211, 218)
                canvas.drawCircle(wx, wy, radius * .11f, p)
            }

            // Front LED headlights with glow, rear lamps and bumper details
            p.color = Color.argb(90, 255, 220, 145)
            canvas.drawOval(w * .425f, carY - h * .072f, w * .472f, carY - h * .027f, p)
            p.color = Color.rgb(255, 238, 190)
            canvas.drawRoundRect(w * .432f, carY - h * .058f, w * .468f, carY - h * .044f,
                dp(3).toFloat(), dp(3).toFloat(), p)
            p.color = Color.rgb(255, 40, 26)
            canvas.drawRoundRect(w * .045f, carY - h * .049f, w * .078f, carY - h * .028f,
                dp(3).toFloat(), dp(3).toFloat(), p)
            p.color = Color.rgb(42, 48, 55)
            canvas.drawRoundRect(w * .435f, carY - h * .015f, w * .47f, carY + h * .002f,
                dp(3).toFloat(), dp(3).toFloat(), p)

            // Glossy reflection beneath the moving car
            p.shader = LinearGradient(0f, carY, 0f, carY + h * .10f,
                intArrayOf(Color.argb(85, 255, 166, 72), Color.argb(0, 255, 166, 72)),
                null, Shader.TileMode.CLAMP)
            canvas.drawOval(w * .09f, carY + h * .008f, w * .43f, carY + h * .085f, p)
            p.shader = null
            canvas.restore()
            // Dark vignette for readable controls
            p.shader = LinearGradient(0f, 0f, w, 0f,
                intArrayOf(Color.argb(10,0,0,0), Color.argb(45,0,0,0), Color.argb(225,0,0,0)),
                null, Shader.TileMode.CLAMP)
            canvas.drawRect(0f, 0f, w, h, p)
            p.shader = null
            canvas.restore()
        }
    }
}
