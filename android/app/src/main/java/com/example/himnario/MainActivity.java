package com.br572.himnario;

import android.os.Bundle;
import io.flutter.app.FlutterActivity;
import io.flutter.plugins.GeneratedPluginRegistrant;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;


public class MainActivity extends FlutterActivity {
  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);
    System.out.println("Si tiene soporte");

    // new MethodChannel(getFlutterView(), "PRUEBA").setMethodCallHandler(new MethodChannel.MethodCallHandler() {
    //   @Override
    //   public void onMethodCall(MethodCall call, MethodChannel.Result result) {
    //     if (call.method.equals("test")) {

    //       System.out.println("desde java");
    //       result.success("asdasdsa");
    //     }

    //   }


    // });
    
  }
}
