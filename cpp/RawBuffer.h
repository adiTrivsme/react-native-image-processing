//
//  FloatBuffer.h
//  Pods
//
//  Created by apple on 24/02/26.
//

#include <jsi/jsi.h>

using namespace facebook;

class RawBuffer : public jsi::MutableBuffer {
public:
    RawBuffer(void* data, size_t byteLength)
        : data_(data), size_(byteLength) {}

    ~RawBuffer() {
        free(data_);
    }

    size_t size() const override {
        return size_;
    }

    uint8_t* data() override {
        return reinterpret_cast<uint8_t*>(data_);
    }

private:
    void* data_;
    size_t size_;
};
