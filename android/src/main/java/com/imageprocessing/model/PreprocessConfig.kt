package com.imageprocessing.model

data class PreprocessConfig(
  val width: Int?,
  val height: Int?,
  val colorFormat: String,
  val normalization: String?,
  val mean: FloatArray?,
  val std: FloatArray?,
  val outDType: String,
  val resizeStrategy: String,
  val tensorLayout: String,
  val orientationHandling: String,
  val alphaHandling: String,
  val channelCount: Int,
)