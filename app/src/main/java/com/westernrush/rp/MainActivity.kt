package com.westernrush.rp

import android.app.Activity
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.net.Uri
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast

class MainActivity : Activity() {
    private val serverAddress = "88.119.171.76:7777"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.statusBarColor = Color.rgb(12, 14, 18)
        window.navigationBarColor = Color.rgb(12, 14, 18)
        window.decorView.systemUiVisibility = 0

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(28), dp(30), dp(28), dp(30))
            setBackgroundColor(Color.rgb(12, 14, 18))
        }

        val eyebrow = text("KALININGRAD • ROLEPLAY", 12, Color.rgb(230, 154, 55), true)
        eyebrow.letterSpacing = 0.18f
        root.addView(eyebrow, matchWrap())

        val title = text("WESTERN RUSH", 34, Color.WHITE, true)
        title.typeface = Typeface.create("sans-serif-condensed", Typeface.BOLD)
        title.gravity = Gravity.CENTER
        val titleParams = matchWrap()
        titleParams.topMargin = dp(12)
        root.addView(title, titleParams)

        val subtitle = text("ТВОЯ ИСТОРИЯ НАЧИНАЕТСЯ ЗДЕСЬ", 12, Color.LTGRAY, false)
        subtitle.gravity = Gravity.CENTER
        val subParams = matchWrap()
        subParams.topMargin = dp(8)
        root.addView(subtitle, subParams)

        val panel = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(20), dp(22), dp(20), dp(22))
            setBackgroundColor(Color.rgb(27, 30, 36))
        }
        val panelParams = matchWrap()
        panelParams.topMargin = dp(42)
        root.addView(panel, panelParams)

        val serverLabel = text("ИГРОВОЙ СЕРВЕР", 11, Color.GRAY, true)
        serverLabel.gravity = Gravity.CENTER
        panel.addView(serverLabel, matchWrap())

        val address = text(serverAddress, 21, Color.WHITE, true)
        address.gravity = Gravity.CENTER
        val addressParams = matchWrap()
        addressParams.topMargin = dp(12)
        panel.addView(address, addressParams)

        val copy = Button(this).apply {
            text = "СКОПИРОВАТЬ IP"
            setTextColor(Color.WHITE)
            setBackgroundTintList(android.content.res.ColorStateList.valueOf(Color.rgb(65, 72, 82)))
            setOnClickListener { copyAddress() }
        }
        val copyParams = matchWrap()
        copyParams.topMargin = dp(18)
        panel.addView(copy, copyParams)

        val connect = Button(this).apply {
            text = "ИГРАТЬ"
            textSize = 17f
            setTextColor(Color.BLACK)
            setBackgroundTintList(android.content.res.ColorStateList.valueOf(Color.rgb(230, 154, 55)))
            setOnClickListener { connectToServer() }
        }
        val connectParams = matchWrap()
        connectParams.topMargin = dp(22)
        root.addView(connect, connectParams)

        val note = text("Для игры требуется совместимый клиент SAMP Mobile.", 12, Color.GRAY, false)
        note.gravity = Gravity.CENTER
        note.maxLines = 2
        val noteParams = matchWrap()
        noteParams.topMargin = dp(18)
        root.addView(note, noteParams)

        val version = text("WESTERN RUSH RP  •  v1.0", 10, Color.DKGRAY, false)
        version.gravity = Gravity.CENTER
        val versionParams = matchWrap()
        versionParams.topMargin = dp(38)
        root.addView(version, versionParams)

        setContentView(root)
    }

    private fun connectToServer() {
        copyAddress()
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("samp://$serverAddress"))
        try {
            startActivity(Intent.createChooser(intent, "Открыть SAMP Mobile"))
        } catch (_: Exception) {
            Toast.makeText(this, "IP скопирован. Открой SAMP Mobile и добавь сервер вручную.", Toast.LENGTH_LONG).show()
        }
    }

    private fun copyAddress() {
        val clipboard = getSystemService(CLIPBOARD_SERVICE) as ClipboardManager
        clipboard.setPrimaryClip(ClipData.newPlainText("SAMP server", serverAddress))
        Toast.makeText(this, "Адрес сервера скопирован", Toast.LENGTH_SHORT).show()
    }

    private fun text(value: String, size: Int, color: Int, bold: Boolean): TextView =
        TextView(this).apply {
            text = value
            textSize = size.toFloat()
            setTextColor(color)
            if (bold) setTypeface(typeface, Typeface.BOLD)
        }

    private fun matchWrap() = LinearLayout.LayoutParams(
        LinearLayout.LayoutParams.MATCH_PARENT,
        LinearLayout.LayoutParams.WRAP_CONTENT
    )

    private fun dp(value: Int): Int = (value * resources.displayMetrics.density).toInt()
}
