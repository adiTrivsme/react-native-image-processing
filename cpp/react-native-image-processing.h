#pragma once
#include <jsi/jsi.h>

using namespace facebook;

namespace imageProcessingModule {
  void install(jsi::Runtime& jsiRuntime);
  void uninstall(jsi::Runtime& jsiRuntime);
}
