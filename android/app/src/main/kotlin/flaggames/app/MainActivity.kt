package flaggames.app

import android.os.Bundle
import android.webkit.CookieManager
import io.flutter.embedding.android.FlutterActivity


class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        CookieManager.getInstance().setAcceptCookie(true);
        super.onCreate(savedInstanceState)
    }
}
