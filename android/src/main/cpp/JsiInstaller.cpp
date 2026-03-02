#include <jni.h>
#include <jsi/jsi.h>
#include "react-native-image-processing.h"
#include "Bridge.h"

using namespace facebook;

//JavaVM* g_jvm = nullptr;
//jobject g_react_context = nullptr;

static float* gPixelBuffer = nullptr;
static size_t gElementCount = 0;

extern "C"
JNIEXPORT void JNICALL
Java_com_imageprocessing_ImageProcessingModule_nativeInstall(
  JNIEnv* env,
  jobject,
  jlong runtimePtr,
  jobject context
) {
//    env->GetJavaVM(&g_jvm); // save env for use in JSI
//    g_react_context = env->NewGlobalRef(context);

    auto* runtime = reinterpret_cast<jsi::Runtime*>(runtimePtr);
    imageProcessingModule::install(*runtime);
}

extern "C"
JNIEXPORT void JNICALL
Java_com_imageprocessing_ImageProcessingModule_nativeUninstall(
  JNIEnv*,
  jobject,
  jlong runtimePtr
) {
//    g_jvm = nullptr;
//    g_react_context = nullptr;

    auto* runtime = reinterpret_cast<jsi::Runtime*>(runtimePtr);
    imageProcessingModule::uninstall(*runtime);
}

extern "C"
JNIEXPORT void JNICALL
Java_com_imageprocessing_ImageProcessingModule_nativeSetPixelBuffer(
  JNIEnv* env,
  jobject /* thiz */,
  jobject buffer,
  jint elementCount
) {
  if (buffer == nullptr) {
    gPixelBuffer = nullptr;
    gElementCount = 0;
    return;
  }

  void* addr = env->GetDirectBufferAddress(buffer);
  if (!addr) {
    gPixelBuffer = nullptr;
    gElementCount = 0;
    return;
  }

  gPixelBuffer = static_cast<float*>(addr);
  gElementCount = static_cast<size_t>(elementCount);
}


jsi::Value getTensor(
   jsi::Runtime &rt,
   const jsi::Value &thisVal,
   const jsi::Value *args,
   size_t count
  ) {
  if (!gPixelBuffer || gElementCount == 0) {
    return jsi::Value::null();
  }

  const size_t byteLength = gElementCount * sizeof(float);

  // 1. Get ArrayBuffer constructor from JS
  auto arrayBufferCtor =
    rt.global().getPropertyAsFunction(rt, "ArrayBuffer");

  // 2. Create ArrayBuffer via JS
  auto arrayBufferValue =
    arrayBufferCtor.callAsConstructor(rt, static_cast<double>(byteLength));

  auto arrayBuffer =
    arrayBufferValue.getObject(rt).getArrayBuffer(rt);

  // 3. Copy native memory into JS-owned buffer
  std::memcpy(
    arrayBuffer.data(rt),
    gPixelBuffer,
    byteLength
  );

  return std::move(arrayBufferValue);
}

//jsi::Value getTensor(
//  jsi::Runtime &rt,
//  const jsi::Value &thisVal,
//  const jsi::Value *args,
//  size_t count
//) {
//
//  JNIEnv* env;
//   // Check if the current thread already has an env
//   jint res = g_jvm->GetEnv((void**)&env, JNI_VERSION_1_6);
//
//   if (res == JNI_EDETACHED) {
//       // If the JS thread isn't attached to the JVM yet, attach it
//       if (g_jvm->AttachCurrentThread(&env, nullptr) != JNI_OK) {
//           throw jsi::JSError(rt, "Failed to attach JVM"); // Failed to attach
//       }
//   }
//
//   // Now you can use 'env' to call your Java methods
//   jclass clazz = env->FindClass("com/imageprocessing/ImageProcessingModule");
//   jmethodID constructor = env->GetMethodID(clazz, "<init>", "(Lcom/facebook/react/bridge/ReactApplicationContext;)V");
//    if (constructor == nullptr) {
//        throw jsi::JSError(rt, "Constructor not found for Kotlin class: com/imageprocessing/ImageProcessingModule");
//    }
//
//
//    jobject instance = env->NewObject(clazz, constructor, g_react_context);
//
//   if (clazz == nullptr) {
//        // Handle error (e.g., log a message or throw an exception)
//        throw jsi::JSError(rt, "Failed to find Kotlin class: com/imageprocessing/ImageProcessingModule");
//   }
//
//
//   jmethodID methodId = env->GetMethodID(clazz, "onNativeCallback", "(Ljava/lang/String;)Ljava/lang/String;"); // class, method name, method JNI signature
//
//   if (methodId == nullptr) {
//    throw jsi::JSError(rt, "Failed to find methodId for method: onNativeCallback");
//   }
//
//   // Prepare Arguments
//   // filePath
//   std::string filePathStr = args[0].asString(rt).utf8(rt);
//   jstring filePath = env->NewStringUTF(filePathStr.c_str());
//
//   // options
//    const jsi::Object options = args[1].asObject(rt);
//
//
//
//    // function call
//   jobject resultObject = env->CallObjectMethod(instance, methodId, filePath);
//   auto jResultString = (jstring)resultObject; // java string
//
//
//   const char* rawResult = env->GetStringUTFChars(jResultString, nullptr); // java string to utf8
//   jsi::Value result = jsi::String::createFromUtf8(rt, rawResult); // utf8 to jsi:string
//
//
//   env->ReleaseStringUTFChars(jResultString, rawResult);
//   env->DeleteLocalRef(filePath);
//   env->DeleteLocalRef(resultObject);
//
//   return result;
//
//
////    jmethodID getTensorsMethod = env->GetMethodID(
////            clazz,
////            "getTensors",
////            "(Ljava/lang/String;Lcom/facebook/react/bridge/ReadableMap;)Lcom/facebook/react/bridge/WritableMap;"
////    );
//
//// prepare Arguments
//// handle result
//}

// call Kotlin function in JNI
// call JNI function from JSI
// kotlin > JNI > JSI = working
// kotlin < JNI < JSI < JS

