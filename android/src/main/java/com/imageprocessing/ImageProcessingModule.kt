package com.imageprocessing

import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap

import android.net.Uri
import android.util.Log
import android.util.Base64
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.content.Context

import java.io.FileNotFoundException
import java.nio.ByteBuffer
import java.nio.ByteOrder

class ImageProcessingModule(
  reactContext: ReactApplicationContext,
) :
  NativeImageProcessingSpec(reactContext) {

  val defaultColorFormat: String = "RGB"
  val defaultNormalization: String = "zeroToOne"
  val defaultOutDType: String = "float32"
  val defaultChannelOrder: String = "interleaved"
  val defaultResizeStrategy: String = "centerCrop"
  val defaultTensorLayout: String = "NHWC"
  val defaultOrientationHandling: String = "respectExif"
  val defaultAlphaHandling: String = "dropAlpha"
  val channelCount: Int = 3

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

  fun getConfigs(options: ReadableMap): HashMap<String, Any?> {
    val optionsMap = options?.toHashMap()

    if (optionsMap != null) {
      val inputDimensions = optionsMap["inputDimensions"] as? Map<String, Double?>

      // convert specifically to Int
      val width = (inputDimensions?.get("width") as? Number)?.toInt()
      val height = (inputDimensions?.get("height") as? Number)?.toInt()

      optionsMap["width"] = width
      optionsMap["height"] = height
      optionsMap["colorFormat"] = optionsMap["colorFormat"] ?: this.defaultColorFormat
      optionsMap["normalization"] = optionsMap["normalization"] ?: this.defaultNormalization
      optionsMap["mean"] = if (optionsMap["normalization"] != null) optionsMap["mean"] else null
      optionsMap["std"] = if (optionsMap["normalization"] != null) optionsMap["std"] else null

      optionsMap["outDType"] = optionsMap["outDType"] ?: this.defaultOutDType
      optionsMap["channelOrder"] = optionsMap["channelOrder"] ?: this.defaultChannelOrder
      optionsMap["resizeStrategy"] = optionsMap["resizeStrategy"] ?: this.defaultResizeStrategy
      optionsMap["tensorLayout"] = optionsMap["tensorLayout"] ?: this.defaultTensorLayout
      optionsMap["orientationHandling"] = optionsMap["orientationHandling"] ?: this.defaultOrientationHandling
      optionsMap["alphaHandling"] = optionsMap["alphaHandling"] ?: this.defaultAlphaHandling

      return optionsMap
    }

    return HashMap<String, Any?>()
  }

  fun resizeBitmap(
    bitmap: Bitmap,
    targetWidth: Int,
    targetHeight: Int
  ): Bitmap {
    if (bitmap.width == targetWidth && bitmap.height == targetHeight) {
      return bitmap
    }

    return Bitmap.createScaledBitmap(
      bitmap,
      targetWidth,
      targetHeight,
      true
    )
  }

  fun decodeToARGB8888(
    context: Context,
    imagePath: String,
    targetWidth: Int,
    targetHeight: Int
  ): Bitmap {
    val uri = Uri.parse(imagePath)

    val options = BitmapFactory.Options().apply {
      inPreferredConfig = Bitmap.Config.ARGB_8888
      inScaled = false
    }

    val inputStream = context.contentResolver.openInputStream(uri)
      ?: throw IllegalStateException("Unable to open image stream")

    val bitmap = inputStream.use {
      BitmapFactory.decodeStream(it, null, options)
    } ?: throw IllegalStateException("Bitmap decode failed")

    // Safety net: force copy if decoder ignored config
    if (bitmap.config != Bitmap.Config.ARGB_8888) {
      return bitmap.copy(Bitmap.Config.ARGB_8888, false)
    }

    val resizedBitMap = resizeBitmap(bitmap, targetWidth, targetHeight)

    return resizedBitMap
  }


  fun extractPixelBuffer(bitmap: Bitmap): ByteBuffer {
    val buffer = ByteBuffer
      .allocateDirect(bitmap.byteCount)
      .order(ByteOrder.nativeOrder())

    bitmap.copyPixelsToBuffer(buffer)
    buffer.rewind()

    return buffer
  }

  fun bitmapToFloatTensor(
    pixelBuffer: ByteBuffer,
    normalize: Boolean,
    width: Int,
    height: Int,
  ): ByteBuffer {

    // Ensure predictable reads
    pixelBuffer.rewind()
    pixelBuffer.order(ByteOrder.nativeOrder())

    val pixelStride = 4 // RGBA
    val floatCount = width * height * 3

    // Native float buffer (shareable with JNI / JSI)
    val outBuffer = ByteBuffer
      .allocateDirect(floatCount * 4)
      .order(ByteOrder.nativeOrder())

    val floatView = outBuffer.asFloatBuffer()

    for (y in 0 until height) {
      val rowOffset = y * width * pixelStride

      for (x in 0 until width) {
        val pixelOffset = rowOffset + x * pixelStride

        val r = pixelBuffer.get(pixelOffset).toInt() and 0xFF
        val g = pixelBuffer.get(pixelOffset + 1).toInt() and 0xFF
        val b = pixelBuffer.get(pixelOffset + 2).toInt() and 0xFF

        if (normalize) {
          floatView.put(r / 255f)
          floatView.put(g / 255f)
          floatView.put(b / 255f)
        } else {
          floatView.put(r.toFloat())
          floatView.put(g.toFloat())
          floatView.put(b.toFloat())
        }
      }
    }

    outBuffer.rewind()

    return outBuffer
  }

  fun prepareMeta(
    width: Int,
    height: Int,
    configs: HashMap<String, Any?>
  ): WritableMap {
    val result: WritableMap = Arguments.createMap()

    val shape = Arguments.createArray()
    shape.pushInt(1);
    shape.pushInt(height);
    shape.pushInt(width);
    shape.pushInt(3); // channel count

    val meta = Arguments.createMap()
    meta.putString("layout", configs["tensorLayout"] as? String ?: this.defaultTensorLayout)
    meta.putString("dtype", configs["outDType"] as? String ?: this.defaultOutDType)
    meta.putString("channelOrder", configs["colorFormat"] as? String ?: this.defaultColorFormat)

    result.putArray("shape", shape);
    result.putMap("meta", meta)

    return result
  }

  @ReactMethod
  override fun processImage(filePath: String, options: ReadableMap): WritableMap {
    try {
      val context = getReactApplicationContext()
      val configs = getConfigs(options)

      val imageWidth: Int = (configs["width"] as? Number)?.toInt() ?: 0
      val imageHeight: Int = (configs["height"] as? Number)?.toInt() ?: 0

      val bitmap = decodeToARGB8888(context, filePath, imageWidth, imageHeight)

      val pixelBuffer = extractPixelBuffer(bitmap)

      val floatBuffer = bitmapToFloatTensor(pixelBuffer, true, bitmap.width, bitmap.height)

      val meta: WritableMap = prepareMeta(bitmap.width, bitmap.height, configs)

      nativeSetPixelBuffer(floatBuffer, imageWidth * imageHeight * 3)

      return meta
    } catch (e: Exception) {
      Log.d("NativeImagePreprocessingModule", "IMAGE_PROCESS_FAILED")

      return Arguments.createMap()
    }
  }
}
