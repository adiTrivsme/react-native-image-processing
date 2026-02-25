//
//  HostObject.h
//  Pods
//
//  Created by apple on 23/02/26.
//

#include <jsi/jsi.h>

using namespace facebook;

// Declare the function so other files know it exists
jsi::Value getTensor(
    facebook::jsi::Runtime &rt,
    const facebook::jsi::Value &thisVal,
    const facebook::jsi::Value *args,
    size_t count
);



