package com.imageprocessing

import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap

import com.imageprocessing.utils.*

import android.util.Log

import java.nio.ByteBuffer

class ImageProcessingModule(
  reactContext: ReactApplicationContext,
) :
  NativeImageProcessingSpec(reactContext) {

  private external fun nativeInstall(runtime: Long, context: ReactApplicationContext)
  private external fun nativeUninstall(runtime: Long)
  private external fun nativeSetPixelBuffer(
    buffer: ByteBuffer,
    elementCount: Int
  )

  companion object {
    const val NAME = NativeImageProcessingSpec.NAME
    init {
      System.loadLibrary("react-native-image-processing")
    }
  }

  override fun install(): Boolean {
    val contextHolder = getReactApplicationContext().getJavaScriptContextHolder()

    if (contextHolder != null) {
      nativeInstall(contextHolder.get(), getReactApplicationContext())
      return true
    }

    return false
  }

  override fun uninstall(): Boolean {
    val contextHolder = getReactApplicationContext().getJavaScriptContextHolder()

    if (contextHolder != null) {
      nativeUninstall(contextHolder.get())
      return true
    }

    return false
  }

  @ReactMethod
  override fun processImage(filePath: String, options: ReadableMap): WritableMap {
    try {
      val context = getReactApplicationContext()
      val configs = getConfigs(options)

      val imageWidth: Int = configs.width ?: 0
      val imageHeight: Int = configs.height ?: 0

      val bitmap = decodeToARGB8888(context, filePath, configs)

      val pixelBuffer = extractPixelBuffer(bitmap)

      val floatBuffer = bitmapToFloatTensor(pixelBuffer, configs, bitmap.width, bitmap.height)

      val meta: WritableMap = prepareMeta(bitmap.width, bitmap.height, configs)

      nativeSetPixelBuffer(floatBuffer, imageWidth * imageHeight * 3)

      meta.getMap("meta")?.getString("dType")?.let { Log.d("RNImagePreprocessing", it) }

      return meta
    } catch (e: Exception) {
      Log.d("RNImagePreprocessing", "IMAGE_PROCESS_FAILED")
      Log.d("RNImagePreprocessing", e.toString())

      return Arguments.createMap()
    }
  }
}
