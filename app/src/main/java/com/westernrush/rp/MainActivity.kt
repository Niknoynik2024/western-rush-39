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
import android.view.View
import android.widget.Button
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import android.widget.Toast

class MainActivity : Activity() {
    private val serverAddress = "88.119.171.76:7777"
    private val gold = Color.rgb(232, 165, 74)
    private val background = Color.rgb(12, 15, 20)
    private val panelColor = Color.rgb(25, 30, 38)
    private lateinit var nicknameInput: EditText

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.statusBarColor = background
        window.navigationBarColor = background
        window.decorView.systemUiVisibility = 0

        val scroll = ScrollView(this).apply {
            setBackgroundColor(background)
            isFillViewport = true
        }
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dp(24), dp(26), dp(24), dp(26))
        }
        scroll.addView(root)

        val topLine = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        val brand = text("WR", 20, gold, true).apply {
            gravity = Gravity.CENTER
            background = rounded(Color.rgb(42, 35, 27), 14)
        }
        topLine.addView(brand, LinearLayout.LayoutParams(dp(48), dp(48)))
        val brandText = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(12), 0, 0, 0)
        }
        brandText.addView(text("WESTERN RUSH", 15, Color.WHITE, true), matchWrap())
        brandText.addView(text("ROLEPLAY • KALININGRAD", 10, gold, true), matchWrap())
        topLine.addView(brandText, LinearLayout.LayoutParams(0, -2, 1f))
        topLine.addView(text("MOBILE", 10, Color.LTGRAY, true).apply {
            setPadding(dp(10), dp(6), dp(10), dp(6))
            background = rounded(Color.rgb(35, 41, 50), 20)
        })
        root.addView(topLine, matchWrap())

        val hero = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(18), dp(34), dp(18), dp(30))
            background = GradientDrawable(
                GradientDrawable.Orientation.TL_BR,
                intArrayOf(Color.rgb(48, 39, 29), Color.rgb(24, 29, 37), Color.rgb(18, 23, 30))
            ).apply { cornerRadius = dp(22).toFloat() }
        }
        val heroParams = matchWrap().apply { topMargin = dp(24) }
        root.addView(hero, heroParams)
        hero.addView(text("ТВОЙ ГОРОД. ТВОЯ ИСТОРИЯ.", 11, gold, true).apply {
            gravity = Gravity.CENTER
            letterSpacing = 0.12f
        }, matchWrap())
        hero.addView(text("WESTERN\nRUSH", 42, Color.WHITE, true).apply {
            gravity = Gravity.CENTER
            typeface = Typeface.create("sans-serif-condensed", Typeface.BOLD)
            setLineSpacing(0f, 0.88f)
        }, matchWrap())
        hero.addView(text("КАЛИНИНГРАД • РОССИЯ", 12, Color.LTGRAY, true).apply {
            gravity = Gravity.CENTER
            letterSpacing = 0.16f
        }, matchWrap())

        val serverCard = card(root, "ИГРОВОЙ СЕРВЕР")
        serverCard.addView(text(serverAddress, 22, Color.WHITE, true).apply {
            gravity = Gravity.CENTER
        }, matchWrap())
        serverCard.addView(text("SAMP MOBILE • ПОДКЛЮЧЕНИЕ ПО IP", 10, Color.GRAY, true).apply {
            gravity = Gravity.CENTER
            letterSpacing = 0.06f
        }, LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(8) })
        val copyButton = button("СКОПИРОВАТЬ IP", Color.rgb(55, 63, 74), Color.WHITE)
        serverCard.addView(copyButton, LinearLayout.LayoutParams(-1, dp(48)).apply {
            topMargin = dp(16)
        })
        copyButton.setOnClickListener { copyAddress() }

        val nicknameCard = card(root, "ИГРОВОЙ НИК")
        nicknameInput = EditText(this).apply {
            setSingleLine(true)
            textSize = 16f
            setTextColor(Color.WHITE)
            setHintTextColor(Color.GRAY)
            hint = "Введи свой ник"
            setPadding(dp(14), 0, dp(14), 0)
            background = rounded(Color.rgb(16, 20, 26), 12, Color.rgb(58, 65, 76))
            setText(getSharedPreferences("western_rush", MODE_PRIVATE).getString("nickname", ""))
        }
        nicknameCard.addView(nicknameInput, LinearLayout.LayoutParams(-1, dp(52)))

        val playButton = button("▶   ИГРАТЬ", gold, Color.rgb(20, 20, 20)).apply {
            textSize = 18f
            typeface = Typeface.DEFAULT_BOLD
        }
        root.addView(playButton, LinearLayout.LayoutParams(-1, dp(58)).apply {
            topMargin = dp(22)
        })
        playButton.setOnClickListener {
            saveNickname()
            connectToServer()
        }

        root.addView(text("ВАЖНО", 10, gold, true).apply {
            letterSpacing = 0.12f
        }, LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(22) })
        root.addView(text(
            "Для входа нужен установленный совместимый клиент SAMP Mobile. Лаунчер не содержит GTA San Andreas или сам игровой клиент.",
            12, Color.LTGRAY, false
        ).apply { setLineSpacing(dp(3).toFloat(), 1f) },
            LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(7) })

        root.addView(text("WESTERN RUSH RP  •  ANDROID", 10, Color.GRAY, true).apply {
            gravity = Gravity.CENTER
        }, LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(30) })

        setContentView(scroll)
    }

    private fun card(parent: LinearLayout, heading: String): LinearLayout {
        val box = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(18), dp(17), dp(18), dp(18))
            background = rounded(panelColor, 18)
        }
        parent.addView(box, LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(16) })
        box.addView(text(heading, 10, gold, true).apply {
            letterSpacing = 0.1f
        }, LinearLayout.LayoutParams(-1, -2).apply { bottomMargin = dp(12) })
        return box
    }

    private fun connectToServer() {
        copyAddress()
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("samp://$serverAddress"))
        try {
            startActivity(Intent.createChooser(intent, "Открыть совместимый SAMP Mobile"))
        } catch (_: Exception) {
            Toast.makeText(this, "IP скопирован. Открой SAMP Mobile и добавь сервер вручную.", Toast.LENGTH_LONG).show()
        }
    }

    private fun saveNickname() {
        getSharedPreferences("western_rush", MODE_PRIVATE).edit()
            .putString("nickname", nicknameInput.text.toString().trim())
            .apply()
    }

    private fun copyAddress() {
        val clipboard = getSystemService(CLIPBOARD_SERVICE) as ClipboardManager
        clipboard.setPrimaryClip(ClipData.newPlainText("SAMP server", serverAddress))
        Toast.makeText(this, "Адрес сервера скопирован", Toast.LENGTH_SHORT).show()
    }

    private fun button(label: String, color: Int, textColor: Int) = Button(this).apply {
        text = label
        textSize = 13f
        setTextColor(textColor)
        backgroundTintList = ColorStateList.valueOf(color)
        isAllCaps = false
    }

    private fun text(value: String, size: Int, color: Int, bold: Boolean) =
        TextView(this).apply {
            text = value
            textSize = size.toFloat()
            setTextColor(color)
            if (bold) setTypeface(typeface, Typeface.BOLD)
        }

    private fun rounded(color: Int, radius: Int, stroke: Int? = null) =
        GradientDrawable().apply {
            setColor(color)
            cornerRadius = dp(radius).toFloat()
            if (stroke != null) setStroke(dp(1), stroke)
        }

    private fun matchWrap() = LinearLayout.LayoutParams(-1, -2)
    private fun dp(value: Int): Int = (value * resources.displayMetrics.density).toInt()
}
