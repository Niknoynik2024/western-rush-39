package com.westernrush.rp

import android.app.Activity
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Intent
import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.os.Bundle
import android.view.Gravity
import android.widget.Button
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import android.widget.Toast

class MainActivity : Activity() {
    private val serverAddress = "88.119.171.76:7777"
    private val gold = Color.rgb(232, 165, 74)
    private val bg = Color.rgb(10, 13, 18)
    private val panel = Color.rgb(25, 30, 38)
    private lateinit var nickname: EditText

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.statusBarColor = bg
        window.navigationBarColor = bg

        val scroll = ScrollView(this).apply { setBackgroundColor(bg); isFillViewport = true }
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            setPadding(dp(22), dp(14), dp(22), dp(14))
        }
        scroll.addView(layout)

        // Left side: cinematic identity panel
        val left = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(18), dp(12), dp(22), dp(12))
        }
        layout.addView(left, LinearLayout.LayoutParams(0, -1, 1.05f))

        val logoRow = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL; gravity = Gravity.CENTER_VERTICAL }
        val logo = text("WR", 19, gold, true).apply {
            gravity = Gravity.CENTER
            background = rounded(Color.rgb(48, 37, 25), 13)
        }
        logoRow.addView(logo, LinearLayout.LayoutParams(dp(46), dp(46)))
        val logoLabels = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(11), 0, 0, 0)
        }
        logoLabels.addView(text("WESTERN RUSH", 15, Color.WHITE, true), wrap())
        logoLabels.addView(text("ROLEPLAY • KALININGRAD", 10, gold, true), wrap())
        logoRow.addView(logoLabels, LinearLayout.LayoutParams(0, -2, 1f))
        left.addView(logoRow, match())

        val hero = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(14), dp(20), dp(14), dp(20))
            background = GradientDrawable(
                GradientDrawable.Orientation.TL_BR,
                intArrayOf(Color.rgb(61, 43, 27), Color.rgb(27, 32, 40), Color.rgb(16, 21, 28))
            ).apply { cornerRadius = dp(22).toFloat() }
        }
        left.addView(hero, LinearLayout.LayoutParams(-1, 0, 1f).apply { topMargin = dp(16); bottomMargin = dp(10) })
        hero.addView(text("ТВОЙ ГОРОД. ТВОЯ ИСТОРИЯ.", 10, gold, true).apply {
            gravity = Gravity.CENTER; letterSpacing = 0.12f
        }, wrap())
        hero.addView(text("WESTERN\nRUSH", 42, Color.WHITE, true).apply {
            gravity = Gravity.CENTER
            typeface = Typeface.create("sans-serif-condensed", Typeface.BOLD)
            setLineSpacing(0f, 0.86f)
        }, wrap())
        hero.addView(text("КАЛИНИНГРАД • РОССИЯ", 11, Color.LTGRAY, true).apply {
            gravity = Gravity.CENTER; letterSpacing = 0.12f
        }, wrap())
        left.addView(text("MOBILE ROLEPLAY  •  ANDROID", 9, Color.GRAY, true).apply {
            gravity = Gravity.CENTER; letterSpacing = 0.1f
        }, match())

        // Right side: player controls
        val right = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(12), dp(4), dp(4), dp(4))
        }
        layout.addView(right, LinearLayout.LayoutParams(0, -1, 0.95f))

        val serverCard = card(right, "ИГРОВОЙ СЕРВЕР")
        serverCard.addView(text(serverAddress, 20, Color.WHITE, true).apply { gravity = Gravity.CENTER }, match())
        serverCard.addView(text("SAMP MOBILE • ПОДКЛЮЧЕНИЕ ПО IP", 9, Color.GRAY, true).apply {
            gravity = Gravity.CENTER; letterSpacing = 0.04f
        }, LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(5) })
        val copy = button("КОПИРОВАТЬ IP", Color.rgb(55, 63, 74), Color.WHITE)
        serverCard.addView(copy, LinearLayout.LayoutParams(-1, dp(42)).apply { topMargin = dp(10) })
        copy.setOnClickListener { copyAddress() }

        val playerCard = card(right, "ИГРОВОЙ НИК")
        nickname = EditText(this).apply {
            setSingleLine(true)
            textSize = 15f
            setTextColor(Color.WHITE)
            setHintTextColor(Color.GRAY)
            hint = "Введи свой ник"
            setPadding(dp(12), 0, dp(12), 0)
            background = rounded(Color.rgb(15, 19, 25), 10, Color.rgb(58, 65, 76))
            setText(getSharedPreferences("western_rush", MODE_PRIVATE).getString("nickname", ""))
        }
        playerCard.addView(nickname, LinearLayout.LayoutParams(-1, dp(46)))

        val play = button("▶   ИГРАТЬ", gold, Color.rgb(20, 20, 20)).apply {
            textSize = 17f
            typeface = Typeface.DEFAULT_BOLD
        }
        right.addView(play, LinearLayout.LayoutParams(-1, dp(54)).apply { topMargin = dp(14) })
        play.setOnClickListener { saveNickname(); connectToServer() }

        right.addView(text(
            "Нужен установленный совместимый клиент SAMP Mobile. Игра не входит в APK лаунчера.",
            10, Color.GRAY, false
        ).apply { gravity = Gravity.CENTER; setLineSpacing(dp(2).toFloat(), 1f) },
            LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(10) })

        setContentView(scroll)
    }

    private fun card(parent: LinearLayout, heading: String): LinearLayout {
        val box = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(15), dp(12), dp(15), dp(14))
            background = rounded(panel, 16)
        }
        parent.addView(box, LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(10) })
        box.addView(text(heading, 10, gold, true).apply { letterSpacing = 0.1f },
            LinearLayout.LayoutParams(-1, -2).apply { bottomMargin = dp(9) })
        return box
    }

    private fun connectToServer() {
        copyAddress()
        try {
            startActivity(Intent.createChooser(Intent(Intent.ACTION_VIEW, Uri.parse("samp://$serverAddress")), "Открыть SAMP Mobile"))
        } catch (_: Exception) {
            Toast.makeText(this, "IP скопирован. Добавь сервер в SAMP Mobile вручную.", Toast.LENGTH_LONG).show()
        }
    }

    private fun saveNickname() {
        getSharedPreferences("western_rush", MODE_PRIVATE).edit()
            .putString("nickname", nickname.text.toString().trim()).apply()
    }

    private fun copyAddress() {
        val clipboard = getSystemService(CLIPBOARD_SERVICE) as ClipboardManager
        clipboard.setPrimaryClip(ClipData.newPlainText("SAMP server", serverAddress))
        Toast.makeText(this, "IP сервера скопирован", Toast.LENGTH_SHORT).show()
    }

    private fun button(label: String, color: Int, textColor: Int) = Button(this).apply {
        text = label; textSize = 12f; setTextColor(textColor)
        backgroundTintList = ColorStateList.valueOf(color); isAllCaps = false
    }

    private fun text(value: String, size: Int, color: Int, bold: Boolean) = TextView(this).apply {
        text = value; textSize = size.toFloat(); setTextColor(color)
        if (bold) setTypeface(typeface, Typeface.BOLD)
    }

    private fun rounded(color: Int, radius: Int, stroke: Int? = null) = GradientDrawable().apply {
        setColor(color); cornerRadius = dp(radius).toFloat()
        if (stroke != null) setStroke(dp(1), stroke)
    }

    private fun match() = LinearLayout.LayoutParams(-1, -2)
    private fun wrap() = LinearLayout.LayoutParams(-2, -2)
    private fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()
}
