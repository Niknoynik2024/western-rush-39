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
import android.widget.*

class MainActivity : Activity() {
    private val gold = Color.rgb(255, 166, 0)
    private val serverAddress = "88.119.171.76:7777"
    private lateinit var nickname: EditText

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
        header.addView(roundButton("⚙", 38) { toast("Настройки появятся в следующем обновлении") })
        header.addView(roundButton("i", 38) { toast("Western Rush RP Mobile • Калининград") })
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
        val navItems = listOf("⌂\nГлавная", "▤\nНовости", "★\nДостижения", "▣\nДонат", "☏\nПоддержка")
        navItems.forEachIndexed { index, item ->
            val itemView = label(item, 11, if (index == 0) gold else Color.LTGRAY, index == 0).apply {
                gravity = Gravity.CENTER
                setPadding(dp(6), dp(3), dp(6), dp(3))
                setOnClickListener { toast(if (index == 0) "Вы на главной" else "Раздел «${item.substringAfter('\n')}» скоро появится") }
            }
            nav.addView(itemView, LinearLayout.LayoutParams(0, -1, 1f))
        }
        page.addView(nav, LinearLayout.LayoutParams(-1, dp(50)))
        setContentView(frame)
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

    private fun toast(message: String) =
        Toast.makeText(this, message, Toast.LENGTH_LONG).show()

    private fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()

    private inner class KaliningradBackdropView : View(this@MainActivity) {
        private val p = Paint(Paint.ANTI_ALIAS_FLAG)
        private var carOffset = 0f
        init {
            ValueAnimator.ofFloat(-0.035f, 0.035f).apply {
                duration = 4200L
                repeatCount = ValueAnimator.INFINITE
                repeatMode = ValueAnimator.REVERSE
                addUpdateListener {
                    carOffset = it.animatedValue as Float
                    invalidate()
                }
                start()
            }
        }
        override fun onDraw(canvas: Canvas) {
            super.onDraw(canvas)
            val w = width.toFloat()
            val h = height.toFloat()
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
            // Animated sports car: gently cruises across the city backdrop
            canvas.save()
            canvas.translate(w * carOffset, 0f)
            val carY = h*.79f
            p.color = Color.rgb(5, 7, 11)
            val car = Path().apply {
                moveTo(w*.04f, carY); lineTo(w*.10f, carY-h*.07f)
                lineTo(w*.19f, carY-h*.12f); lineTo(w*.34f, carY-h*.12f)
                lineTo(w*.43f, carY-h*.04f); lineTo(w*.47f, carY)
                close()
            }
            canvas.drawPath(car, p)
            canvas.drawCircle(w*.15f, carY, h*.045f, p)
            canvas.drawCircle(w*.37f, carY, h*.045f, p)
            p.color = Color.rgb(255, 164, 58)
            canvas.drawRect(w*.40f, carY-h*.045f, w*.445f, carY-h*.033f, p)
            canvas.restore()
            // Dark vignette for readable controls
            p.shader = LinearGradient(0f, 0f, w, 0f,
                intArrayOf(Color.argb(10,0,0,0), Color.argb(45,0,0,0), Color.argb(225,0,0,0)),
                null, Shader.TileMode.CLAMP)
            canvas.drawRect(0f, 0f, w, h, p)
            p.shader = null
        }
    }
}
