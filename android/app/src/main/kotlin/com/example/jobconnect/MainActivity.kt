//// Fixed MainActivity.kt
//// android/app/src/main/kotlin/com/jobconnect/jobconnect/MainActivity.kt
//
//package com.jobconnect.app
//
//import io.flutter.embedding.android.FlutterFragmentActivity
//
//class MainActivity: FlutterFragmentActivity() {
//    // Changed from FlutterActivity to FlutterFragmentActivity
//}


// ============================================================================
// Create/Replace: android/app/src/main/kotlin/com/jobconnect/app/MainActivity.kt
// This ensures deep links are properly handled
// ============================================================================

package com.jobconnect.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import android.content.Intent
import android.os.Bundle
import android.util.Log

class MainActivity: FlutterActivity() {

    companion object {
        private const val TAG = "MainActivity"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        Log.d(TAG, "📱 onCreate called")

        // Handle deep link when app is first launched
        handleDeepLink(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)

        Log.d(TAG, "📱 onNewIntent called")

        // Handle deep link when app is already running
        setIntent(intent)
        handleDeepLink(intent)
    }

    private fun handleDeepLink(intent: Intent?) {
        if (intent?.action == Intent.ACTION_VIEW) {
            val data = intent.data

            Log.d(TAG, "🔗 Deep link detected!")
            Log.d(TAG, "   Action: ${intent.action}")
            Log.d(TAG, "   Data: $data")
            Log.d(TAG, "   Scheme: ${data?.scheme}")
            Log.d(TAG, "   Host: ${data?.host}")
            Log.d(TAG, "   Path: ${data?.path}")
            Log.d(TAG, "   Query: ${data?.query}")

            if (data != null) {
                // Check if it's our OAuth callback
                if (data.scheme == "com.jobconnect" && data.host == "auth") {
                    Log.d(TAG, "✅ OAuth callback detected!")

                    val code = data.getQueryParameter("code")
                    val state = data.getQueryParameter("state")
                    val error = data.getQueryParameter("error")

                    Log.d(TAG, "   Code: ${code?.take(10)}...")
                    Log.d(TAG, "   State: ${state?.take(10)}...")
                    Log.d(TAG, "   Error: $error")

                    // FlutterWebAuth2 and uni_links will handle this automatically
                    // We're just logging for debugging
                } else {
                    Log.w(TAG, "⚠️ Unrecognized deep link: $data")
                }
            }
        } else {
            Log.d(TAG, "📱 Regular app launch (no deep link)")
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d(TAG, "🔧 Flutter engine configured")
    }
}