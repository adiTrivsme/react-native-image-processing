package com.imageprocessing.config

enum class ColorFormat(val jsValue: String) {
  RGB("RGB"),
  BGR("BGR"),
  GRAYSCALE("Grayscale");

  companion object {
    private val map = entries.associateBy(ColorFormat::jsValue)

    fun fromJs(value: String?): ColorFormat {
      return map[value] ?: RGB
    }
  }
}

enum class Normalization(val jsValue: String) {
  ZERO_TO_ONE("zeroToOne"),
  NONE("none"),
  MINUS_ONE_TO_ONE("minusOneToOne"),
  MEAN_STD("meanStd");

  companion object {
    private val map = entries.associateBy(Normalization::jsValue)

    fun fromJs(value: String?): Normalization {
      return map[value] ?: ZERO_TO_ONE
    }
  }
}

enum class OutDType(val jsValue: String) {
  FLOAT32("float32"),
  UINT8("uint8");

  companion object {
    private val map = entries.associateBy(OutDType::jsValue)

    fun fromJs(value: String?): OutDType {
      return map[value] ?: FLOAT32
    }
  }
}

enum class ResizeStrategy(val jsValue: String) {
  STRETCH("stretch"),
  ASPECT_FIT("aspectFit"),
  ASPECT_FILL("aspectFill");

  companion object {
    private val map = entries.associateBy(ResizeStrategy::jsValue)

    fun fromJs(value: String?): ResizeStrategy {
      return map[value] ?: ASPECT_FILL
    }
  }
}

enum class TensorLayout(val jsValue: String) {
  NHWC("NHWC"),
  NCHW("NCHW");

  companion object {
    private val map = entries.associateBy(TensorLayout::jsValue)

    fun fromJs(value: String?): TensorLayout {
      return map[value] ?: NHWC
    }
  }
}

enum class OrientationHandling(val jsValue: String) {
  RESPECT_EXIF("respectExif"),
  IGNORE_EXIF("ignoreExif");

  companion object {
    private val map = entries.associateBy(OrientationHandling::jsValue)

    fun fromJs(value: String?): OrientationHandling {
      return map[value] ?: RESPECT_EXIF
    }
  }
}

enum class AlphaHandling(val jsValue: String) {
  DROP_ALPHA("dropAlpha"),
  PREMULTIPLY("premultiply");

  companion object {
    private val map = entries.associateBy(AlphaHandling::jsValue)

    fun fromJs(value: String?): AlphaHandling {
      return map[value] ?: DROP_ALPHA
    }
  }
}
