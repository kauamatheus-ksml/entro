package com.example.entro

import android.os.Bundle
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
  override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    // Se você usa algum MethodChannel (config), registre aqui:
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "br.com.sicoobnet.channel/config")
      .setMethodCallHandler { call, result ->
        if (call.method == "getUsuarioLogado") {
          // Exemplo de retorno do login — ajuste conforme sua lógica
          result.success("usuario_de_teste")
        } else {
          result.notImplemented()
        }
      }
  }
}
