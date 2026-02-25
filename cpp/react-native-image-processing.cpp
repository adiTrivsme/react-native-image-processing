#include "react-native-image-processing.h"
#include <jsi/jsi.h>

#import "Bridge.h"

using namespace facebook;

namespace imageProcessingModule {
  void install(jsi::Runtime& jsiRuntime) {
    jsi::Object imageProcessingObj = jsi::Object(jsiRuntime); // create object to define functions within
    
    
    // sayHello ====================================
    auto sayHelloLmd = [](
                          jsi::Runtime& runtime,
                          const jsi::Value& thisValue,
                          const jsi::Value* arguments,
                          size_t count) -> jsi::Value {
                            return jsi::String::createFromUtf8(runtime, "Hello from JSI !!");
                          };
    
    jsi::Function sayHello = jsi::Function::createFromHostFunction(jsiRuntime,jsi::PropNameID::forAscii(jsiRuntime, "sayHello"), 0,sayHelloLmd);
    
    imageProcessingObj.setProperty(jsiRuntime, "sayHello", sayHello); // set function to a property in our module object
     
    // sayHello END ====================================
    
    
    
    // getTensor ====================================
    
    jsi::Function getTensorObj = jsi::Function::createFromHostFunction(jsiRuntime, jsi::PropNameID::forAscii(jsiRuntime, "getTensorObj"), 1, getTensor);
    
    
    imageProcessingObj.setProperty(jsiRuntime, "getTensorObj", getTensorObj);
    
    // getTensor END ====================================
    
    
    // assign the object to a global JS object property __imageProcessing__
    jsiRuntime.global().setProperty(jsiRuntime, "__imageProcessing__", std::move(imageProcessingObj));
  }

void uninstall(jsi::Runtime& jsiRuntime) {
  jsiRuntime.global().setProperty(jsiRuntime, "__imageProcessing__", jsi::Value::undefined());
}
}
