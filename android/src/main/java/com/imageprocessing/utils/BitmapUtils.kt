package com.imageprocessing.utils

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.util.Log
import androidx.core.graphics.scale
import com.imageprocessing.model.PreprocessConfig
import java.nio.ByteBuffer
import java.nio.ByteOrder

fun resizeBitmap(
  bitmap: Bitmap,
  targetWidth: Int,
  targetHeight: Int,
  strategy: String,
): Bitmap {
  if (bitmap.width == targetWidth && bitmap.height == targetHeight) {
    return bitmap
  }

  return when (strategy) {
    "aspectFit" -> resizeAspectFit(bitmap, targetWidth, targetHeight)
    "aspectFill" -> resizeAspectFill(bitmap, targetWidth, targetHeight)
    else -> bitmap.scale(targetWidth, targetHeight)
  }
}

fun decodeToARGB8888(
  context: Context,
  imagePath: String,
  configs: PreprocessConfig,
): Bitmap {
  val uri = Uri.parse(imagePath)

  val targetWidth = configs.width ?: 0
  val targetHeight = configs.height ?: 0

  val options = BitmapFactory.Options().apply {
    inPreferredConfig = Bitmap.Config.ARGB_8888
    inScaled = false
  }

  val inputStream = context.contentResolver.openInputStream(uri)
    ?: throw IllegalStateException("Unable to open image stream")

  var bitmap = inputStream.use {
    BitmapFactory.decodeStream(it, null, options)
  } ?: throw IllegalStateException("Bitmap decode failed")

  // Safety net: force copy if decoder ignored config
  if (bitmap.config != Bitmap.Config.ARGB_8888) {
    bitmap = bitmap.copy(Bitmap.Config.ARGB_8888, false)
  }

  if (configs.orientationHandling == "respectExif") {
    bitmap = applyExifOrientation(bitmap, inputStream)
  }

  bitmap = resizeBitmap(bitmap, targetWidth, targetHeight, configs.resizeStrategy)

  return bitmap
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
  configs: PreprocessConfig,
  width: Int,
  height: Int,
): ByteBuffer {

  val colorFormat = configs.colorFormat
  var normalization = configs.normalization
  val alphaHandling = configs.alphaHandling
  val mean = configs.mean
  val std = configs.std
  val layout = configs.tensorLayout
  val channelCount = configs.channelCount
  val outDType = configs.outDType
  val isNCHW = layout == "NCHW"
  val outDTypeFloat32 = outDType == "float32"

  if (outDType == "uint8" && normalization != "none") {
    Log.d(
      "RNImagePreprocessing",
      "Invalid config: uint8 tensors cannot use normalization. Forcing 'none'."
    )

    normalization = "none"
  }

  // Ensure predictable reads
  pixelBuffer.rewind()
  pixelBuffer.order(ByteOrder.nativeOrder())

  val pixelStride = 4 // RGBA

  val elementSize = if (outDType == "float32") 4 else 1
  val bufferSize = width * height * channelCount * elementSize

  // Native buffer (shareable with JNI / JSI)
  val outBuffer = ByteBuffer
    .allocateDirect(bufferSize)
    .order(ByteOrder.nativeOrder())

  for (y in 0 until height) {
    val rowOffset = y * width * pixelStride

    for (x in 0 until width) {
      val pixelOffset = rowOffset + x * pixelStride

      // !! Order might be BGRA on some device, Todo: test the channel order explicitly
      val r = pixelBuffer.get(pixelOffset).toInt() and 0xFF
      val g = pixelBuffer.get(pixelOffset + 1).toInt() and 0xFF
      val b = pixelBuffer.get(pixelOffset + 2).toInt() and 0xFF
      val a = pixelBuffer.get(pixelOffset + 3).toInt() and 0xFF

      val rgb = normalizePixel(
        r,
        g,
        b,
        a,
        normalization,
        alphaHandling,
        mean,
        std
      )

      val rgbValues = rgbOrderAsPerColorFormat(colorFormat, rgb)

      writeTensorPixel(
        outBuffer,
        rgbValues,
        x,
        y,
        width,
        height,
        channelCount,
        isNCHW,
        outDTypeFloat32
      )
    }
  }

  outBuffer.rewind()

  return outBuffer
}
