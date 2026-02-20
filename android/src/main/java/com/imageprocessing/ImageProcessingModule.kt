package com.imageprocessing

import com.facebook.react.bridge.ReactApplicationContext

class ImageProcessingModule(reactContext: ReactApplicationContext) :
  NativeImageProcessingSpec(reactContext) {

  override fun multiply(a: Double, b: Double): Double {
    return a * b
  }

  companion object {
    const val NAME = NativeImageProcessingSpec.NAME
  }
}
