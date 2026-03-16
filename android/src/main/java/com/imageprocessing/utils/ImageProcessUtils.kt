package com.imageprocessing.utils

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Matrix
import androidx.core.graphics.createBitmap
import androidx.core.graphics.scale
import androidx.exifinterface.media.ExifInterface
import java.io.InputStream
import java.nio.ByteBuffer

import com.imageprocessing.config.ColorFormat
import com.imageprocessing.config.Normalization
import com.imageprocessing.config.AlphaHandling

import com.imageprocessing.model.RGBValues

fun getExifOrientation(imageStream: InputStream): Int {
  val exif = ExifInterface(imageStream)

  return exif.getAttributeInt(
    ExifInterface.TAG_ORIENTATION,
    ExifInterface.ORIENTATION_NORMAL
  )
}

fun applyExifOrientation(bitmap: Bitmap, imageStream: InputStream): Bitmap {
  val orientation = getExifOrientation(imageStream)
  val matrix = Matrix()

  when (orientation) {
    ExifInterface.ORIENTATION_ROTATE_90 -> matrix.postRotate(90f)
    ExifInterface.ORIENTATION_ROTATE_180 -> matrix.postRotate(180f)
    ExifInterface.ORIENTATION_ROTATE_270 -> matrix.postRotate(270f)
    else -> return bitmap
  }

  return Bitmap.createBitmap(
    bitmap,
    0,
    0,
    bitmap.width,
    bitmap.height,
    matrix,
    true
  )
}

fun computeScaledSize(
  srcWidth: Int,
  srcHeight: Int,
  targetWidth: Int,
  targetHeight: Int,
  useMaxScale: Boolean
): Pair<Int, Int> {

  val scaleW = targetWidth.toFloat() / srcWidth
  val scaleH = targetHeight.toFloat() / srcHeight

  val scale = if (useMaxScale) {
    maxOf(scaleW, scaleH)
  } else {
    minOf(scaleW, scaleH)
  }

  val newWidth = (srcWidth * scale).toInt()
  val newHeight = (srcHeight * scale).toInt()

  return Pair(newWidth, newHeight)
}

fun resizeAspectFit(
  bitmap: Bitmap,
  targetWidth: Int,
  targetHeight: Int
): Bitmap {

  val (newWidth, newHeight) = computeScaledSize(
    bitmap.width,
    bitmap.height,
    targetWidth,
    targetHeight,
    useMaxScale = false
  )

  val scaled = bitmap.scale(newWidth, newHeight)

  val output = createBitmap(targetWidth, targetHeight)

  val canvas = Canvas(output)

  val left = (targetWidth - newWidth) / 2
  val top = (targetHeight - newHeight) / 2

  canvas.drawBitmap(scaled, left.toFloat(), top.toFloat(), null)

  return output
}

fun resizeAspectFill(
  bitmap: Bitmap,
  targetWidth: Int,
  targetHeight: Int
): Bitmap {

  val (newWidth, newHeight) = computeScaledSize(
    bitmap.width,
    bitmap.height,
    targetWidth,
    targetHeight,
    useMaxScale = true
  )

  val scaled = bitmap.scale(newWidth, newHeight)

  val xOffset = (newWidth - targetWidth) / 2
  val yOffset = (newHeight - targetHeight) / 2

  return Bitmap.createBitmap(
    scaled,
    xOffset,
    yOffset,
    targetWidth,
    targetHeight
  )
}

fun rgbOrderAsPerColorFormat(
  colorFormat: ColorFormat,
  rgb: RGBValues
): FloatArray {
  val r = rgb.r
  val g = rgb.g
  val b = rgb.b

  return when (colorFormat) {
    ColorFormat.RGB -> floatArrayOf(
      r,
      g,
      b
    )
    ColorFormat.BGR -> floatArrayOf(
      b,
      g,
      r
    )
    ColorFormat.GRAYSCALE -> {
      val gray = (0.299f * r) + (0.587f * g) + (0.114f * b)
      floatArrayOf(gray)
    }
  }
}


fun normalizePixel(
  r: Int,
  g: Int,
  b: Int,
  a: Int,
  normalization: Normalization,
  alphaHandling: AlphaHandling,
  mean: FloatArray?,
  std: FloatArray?
): RGBValues {

  var rf = r.toFloat()
  var gf = g.toFloat()
  var bf = b.toFloat()

  // ---------- Alpha Handling ----------
  if (alphaHandling == AlphaHandling.PREMULTIPLY) {
    val af = a / 255f
    rf *= af
    gf *= af
    bf *= af
  }

  // ---------- Normalization ----------
  when (normalization) {
    Normalization.ZERO_TO_ONE -> {
      rf /= 255f
      gf /= 255f
      bf /= 255f
    }

    Normalization.MINUS_ONE_TO_ONE -> {
      rf = (rf / 127.5f) - 1f
      gf = (gf / 127.5f) - 1f
      bf = (bf / 127.5f) - 1f
    }

   Normalization.MEAN_STD -> {
      if (mean != null && std != null) {
        rf = ((rf / 255f) - mean[0]) / std[0]
        gf = ((gf / 255f) - mean[1]) / std[1]
        bf = ((bf / 255f) - mean[2]) / std[2]
      }
    }

    else -> {}
  }

  return RGBValues(rf, gf, bf)
}

fun writeTensorPixel(
  buffer: ByteBuffer,
  rgbValues: FloatArray,
  x: Int,
  y: Int,
  width: Int,
  height: Int,
  channelCount: Int,
  isNCHW: Boolean,
  isOutDtypeFloat32: Boolean,
) {
  val pixelIndex = y * width + x
  val floatView = buffer.asFloatBuffer()

  if (isNCHW) {
    val spatialSize = width * height

    for (c in 0 until channelCount) {
      val index = c * spatialSize + pixelIndex

      if (isOutDtypeFloat32) {
        floatView.put(index, rgbValues[c])
      } else {
        val v = rgbValues[c].toInt().coerceIn(0, 255).toByte()
        buffer.put(index, v)
      }
    }
  } else {
    val base = pixelIndex * channelCount

    for (c in 0 until channelCount) {
      if (isOutDtypeFloat32) {
        floatView.put(base + c, rgbValues[c])
      } else {
        val v = rgbValues[c].toInt().coerceIn(0, 255).toByte()
        buffer.put(base + c, v)
      }
    }
  }
}
