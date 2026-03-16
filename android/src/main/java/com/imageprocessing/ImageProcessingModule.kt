package com.imageprocessing

import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap

import com.imageprocessing.utils.*
import com.imageprocessing.model.*

import android.util.Log

import java.nio.ByteBuffer

class ImageProcessingModule(
  reactContext: ReactApplicationContext,
) :
  NativeImageProcessingSpec(reactContext) {

  val defaultColorFormat: String = "RGB"
  val defaultNormalization: String = "zeroToOne"
  val defaultOutDType: String = "float32"
  val defaultResizeStrategy: String = "aspectFill"
  val defaultTensorLayout: String = "NHWC"
  val defaultOrientationHandling: String = "respectExif"
  val defaultAlphaHandling: String = "dropAlpha"

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

  fun getConfigs(options: ReadableMap): PreprocessConfig {
    val optionsMap = options.toHashMap()

    val inputDimensions = optionsMap["inputDimensions"] as? Map<String, *>
    val width = (inputDimensions?.get("width") as? Number)?.toInt()
    val height = (inputDimensions?.get("height") as? Number)?.toInt()

    val colorFormat =
      optionsMap["colorFormat"] as? String ?: this.defaultColorFormat

    val normalization =
      optionsMap["normalization"] as? String ?: this.defaultNormalization

    val mean =
      (optionsMap["mean"] as? List<*>)
        ?.mapNotNull { (it as? Number)?.toFloat() }
        ?.toFloatArray()

    val std =
      (optionsMap["std"] as? List<*>)
        ?.mapNotNull { (it as? Number)?.toFloat() }
        ?.toFloatArray()

    val outDType =
      optionsMap["outDType"] as? String ?: this.defaultOutDType

    val resizeStrategy =
      optionsMap["resizeStrategy"] as? String ?: this.defaultResizeStrategy

    val tensorLayout =
      optionsMap["tensorLayout"] as? String ?: this.defaultTensorLayout

    val orientationHandling =
      optionsMap["orientationHandling"] as? String ?: this.defaultOrientationHandling

    val alphaHandling =
      optionsMap["alphaHandling"] as? String ?: this.defaultAlphaHandling

    val channelCount = if(colorFormat == "Grayscale") 1 else 3

    return PreprocessConfig(
      width = width,
      height = height,
      colorFormat = colorFormat,
      normalization = normalization,
      mean = mean,
      std = std,
      outDType = outDType,
      resizeStrategy = resizeStrategy,
      tensorLayout = tensorLayout,
      orientationHandling = orientationHandling,
      alphaHandling = alphaHandling,
      channelCount = channelCount
    )
  }

  fun prepareMeta(
    width: Int,
    height: Int,
    configs: PreprocessConfig
  ): WritableMap {
    val result: WritableMap = Arguments.createMap()

    val shape = Arguments.createArray()
    shape.pushInt(1); // processing one image at a time
    shape.pushInt(height);
    shape.pushInt(width);
    shape.pushInt(configs.channelCount);

    val meta = Arguments.createMap()
    meta.putString("layout", configs.tensorLayout)
    meta.putString("dType", configs.outDType)

    result.putArray("shape", shape);
    result.putMap("meta", meta)

    return result
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
