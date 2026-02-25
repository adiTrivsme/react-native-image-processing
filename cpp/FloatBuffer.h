//
//  FloatBuffer.h
//  Pods
//
//  Created by apple on 24/02/26.
//

#include <jsi/jsi.h>

using namespace facebook;

class FloatBuffer : public jsi::MutableBuffer {
public:
    FloatBuffer(float* data, size_t count) : data_(data), size_(count * sizeof(float)) {}
    ~FloatBuffer() { free(data_); } // Important: JSI will own this and free it when JS GC runs
    size_t size() const override { return size_; }
    uint8_t* data() override { return reinterpret_cast<uint8_t*>(data_); }
private:
    float* data_;
    size_t size_;
};
